# -*- coding: utf-8 -*-
"""
Durable Google Trends Harvester (2016-2025)
- Crawl per (state, keyword) to avoid rate limits
- Exponential backoff on errors (incl. 429)
- Save each job to disk immediately (weekly + monthly)
- Checkpoint file to support resume
"""

import os, time, json, math, re
import pandas as pd
from datetime import datetime
from pytrends.request import TrendReq

# ========= Config =========
TIMEFRAME = "2016-01-01 2025-12-31"
OUTDIR = "gt_out"
CHECKPOINT = os.path.join(OUTDIR, "checkpoint.csv")
LOGFILE = os.path.join(OUTDIR, "runner.log")

# Keywords
KEYWORDS = [
    "syphilis", "gonorrhea", "chlamydia",
    "syphilis symptoms", "gonorrhea symptoms", "chlamydia symptoms",
    "STD test", "HIV testing", "STD clinic"
]

# 50 states + DC
US_STATES = [
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
    "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
    "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
    "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
    "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"
]

# Rate-limit policy
BASE_SLEEP = 8         # seconds between successful requests
MAX_RETRIES = 5
BACKOFF_FACTOR = 2     # 8s -> 16s -> 32s ...
COOLDOWN_ON_429 = 60   # cool down when hitting 429

# =========================

def log(msg):
    os.makedirs(OUTDIR, exist_ok=True)
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOGFILE, "a", encoding="utf-8") as f:
        f.write(f"[{ts}] {msg}\n")
    print(f"[{ts}] {msg}")

def slugify(s):
    s = s.lower().strip()
    s = re.sub(r"[^a-z0-9]+","_", s)
    return s.strip("_")

def weekly_to_monthly(df_weekly):
    df = df_weekly.copy()
    if "isPartial" in df.columns:
        df = df.drop(columns=["isPartial"], errors="ignore")
    df.index = pd.to_datetime(df.index)
    monthly = df.resample("MS").mean(numeric_only=True)
    return monthly

def load_checkpoint():
    if os.path.exists(CHECKPOINT):
        df = pd.read_csv(CHECKPOINT)
    else:
        rows = []
        for st in US_STATES:
            for kw in KEYWORDS:
                rows.append({"state": st, "keyword": kw, "done": 0, "path_weekly": "", "path_monthly": ""})
        df = pd.DataFrame(rows)
        os.makedirs(OUTDIR, exist_ok=True)
        df.to_csv(CHECKPOINT, index=False)
    return df

def save_checkpoint(df):
    df.to_csv(CHECKPOINT, index=False)

def fetch_one(pytrends, keyword, state):
    """Return weekly DataFrame with single column [keyword]."""
    geo = f"US-{state}"
    pytrends.build_payload([keyword], timeframe=TIMEFRAME, geo=geo, gprop="")
    df = pytrends.interest_over_time()
    if df is None or df.empty:
        return pd.DataFrame()
    if "isPartial" in df.columns:
        df = df.drop(columns=["isPartial"])
    return df

def run():
    pytrends = TrendReq(hl="en-US", tz=360)
    ckpt = load_checkpoint()

    total = len(ckpt)
    done_before = ckpt["done"].sum()
    log(f"Jobs total: {total}, already done: {done_before}")

    for idx, row in ckpt.iterrows():
        if int(row["done"]) == 1:
            continue
        kw = row["keyword"]
        st = row["state"]
        kw_slug = slugify(kw)

        # Output paths
        outdir_pair = os.path.join(OUTDIR, f"{kw_slug}", st)
        os.makedirs(outdir_pair, exist_ok=True)
        f_weekly = os.path.join(outdir_pair, f"{kw_slug}__{st}__weekly.csv")
        f_month = os.path.join(outdir_pair, f"{kw_slug}__{st}__monthly.csv")

        # Skip if both exist
        if os.path.exists(f_weekly) and os.path.exists(f_month):
            ckpt.at[idx, "done"] = 1
            ckpt.at[idx, "path_weekly"] = f_weekly
            ckpt.at[idx, "path_monthly"] = f_month
            save_checkpoint(ckpt)
            continue

        log(f"Fetching [{kw}] for state [{st}] ...")

        # Retry with exponential backoff
        last_err = None
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                weekly = fetch_one(pytrends, kw, st)
                if weekly.empty:
                    log(f"Empty response for {st} - {kw}. Saving empty and continue.")
                    pd.DataFrame().to_csv(f_weekly, index=False)
                    pd.DataFrame().to_csv(f_month, index=False)
                else:
                    weekly.to_csv(f_weekly)  # date index + column=kw
                    monthly = weekly_to_monthly(weekly)
                    monthly.to_csv(f_month)
                # Mark checkpoint
                ckpt.at[idx, "done"] = 1
                ckpt.at[idx, "path_weekly"] = f_weekly
                ckpt.at[idx, "path_monthly"] = f_month
                save_checkpoint(ckpt)

                # polite sleep
                time.sleep(BASE_SLEEP)
                break

            except Exception as e:
                last_err = e
                msg = str(e)
                log(f"Error (attempt {attempt}/{MAX_RETRIES}) {st}-{kw}: {msg}")

                # 429 handling hint
                if "429" in msg or "TooManyRequests" in msg:
                    log(f"Hit 429; cooling down {COOLDOWN_ON_429}s")
                    time.sleep(COOLDOWN_ON_429)

                # exponential backoff
                backoff = BASE_SLEEP * (BACKOFF_FACTOR ** (attempt - 1))
                backoff = max(backoff, BASE_SLEEP)
                log(f"Backoff sleeping {int(backoff)}s")
                time.sleep(backoff)

        else:
            log(f"FAILED after {MAX_RETRIES} attempts: {st}-{kw} | {last_err}")
            # do not mark done; it will retry next run

    log("All jobs processed (or attempted).")

if __name__ == "__main__":
    run()
