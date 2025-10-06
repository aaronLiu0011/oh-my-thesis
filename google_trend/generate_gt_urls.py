# -*- coding: utf-8 -*-
import textwrap

# === Parameters ===
diseases = {
    "SYPHILIS": "%2Fm%2F074m2",
    "GONORRHEA": "%2Fm%2F0mh4s",
    "CHLAMYDIA": "%2Fm%2F020gd"
}

date_param = "2018-01-01%202025-08-31"
base_url = "https://trends.google.com/trends/explore"
output_file = "gt_batches_url" \
".txt"

# === State full names and corresponding codes ===
state_code_map = {
    "Alabama": "US-AL", "Alaska": "US-AK", "Arizona": "US-AZ", "Arkansas": "US-AR",
    "California": "US-CA", "Colorado": "US-CO", "Connecticut": "US-CT", "Delaware": "US-DE",
    "District of Columbia": "US-DC", "Florida": "US-FL", "Georgia": "US-GA", "Hawaii": "US-HI",
    "Idaho": "US-ID", "Illinois": "US-IL", "Indiana": "US-IN", "Iowa": "US-IA", "Kansas": "US-KS",
    "Kentucky": "US-KY", "Louisiana": "US-LA", "Maine": "US-ME", "Maryland": "US-MD",
    "Massachusetts": "US-MA", "Michigan": "US-MI", "Minnesota": "US-MN", "Mississippi": "US-MS",
    "Missouri": "US-MO", "Montana": "US-MT", "Nebraska": "US-NE", "Nevada": "US-NV",
    "New Hampshire": "US-NH", "New Jersey": "US-NJ", "New Mexico": "US-NM", "New York": "US-NY",
    "North Carolina": "US-NC", "North Dakota": "US-ND", "Ohio": "US-OH", "Oklahoma": "US-OK",
    "Oregon": "US-OR", "Pennsylvania": "US-PA", "Rhode Island": "US-RI", "South Carolina": "US-SC",
    "South Dakota": "US-SD", "Tennessee": "US-TN", "Texas": "US-TX", "Utah": "US-UT",
    "Vermont": "US-VT", "Virginia": "US-VA", "Washington": "US-WA", "West Virginia": "US-WV",
    "Wisconsin": "US-WI", "Wyoming": "US-WY"
}

# Sort by full name (alphabetical)
sorted_states = sorted(state_code_map.items(), key=lambda x: x[0])

# Separate California (anchor)
other_states = [(name, code) for name, code in sorted_states if name != "California"]

# Group into chunks of 4 (CA + 4 others = 5 per group)
groups = [other_states[i:i+4] for i in range(0, len(other_states), 4)]

lines = []

for disease, code in diseases.items():
    for i, group in enumerate(groups, 1):
        # Add California + 4 others
        all_states = [("California", state_code_map["California"])] + group
        geo_codes = [c for _, c in all_states]
        geo_part = ",".join(geo_codes)
        q_part = ",".join([code] * len(all_states))
        url = f"{base_url}?date={','.join([date_param]*len(all_states))}&geo={geo_part}&q={q_part}"
        lines.append(f"[{disease} - Group {i:02d}]\n{url}\n")

# === Write to txt ===
with open(output_file, "w") as f:
    f.write("\n".join(lines))

print(f"✅ URLs (sorted by full state names incl. DC) written to {output_file}")
