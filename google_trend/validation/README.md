# 📄 Pilot Validation SOP

## 1. Objective

To test whether a **statistically significant correlation** exists between state-level **Google Trends search index** (proxy) and **CDC-reported syphilis infection rates** (ground truth), before scaling to national-level analysis.

---

## 2. Tools & Data

- **Language**: Python (or R)
- **Libraries**: `pandas`, `scipy`, `matplotlib` / `seaborn`
- **Data Sources**:
  - Google Trends (`https://trends.google.com`)
  - CDC STD Surveillance Reports (`https://www.cdc.gov/std/statistics/`)

---

## 3. Sample

- **Keyword**: `Syphilis`, `Gonorrhea`, `Chlamydia` (Infection)
- **States**: CA, TX, FL, IL, WA, WY, NY  
  *(Chosen for diversity in population, geography, and infection rate)*

---

## 4. Procedure

### A. Google Trends Data (Proxy)

- Set time range: `2018-01-01` to present.
- File naming: `val_Syphilis_CA.csv`, etc.

### B. CDC Data (Ground Truth)

- Download state-level syphilis infection rates from CDC.
- Keep columns: `Year`, `FIPS`, `cdc_rate`
- Save as: `Syphilis_state_2018_2023.csv`

### C. Data Processing

- For each GT file:
  - Extract `Month`, `gt_index`
  - Compute **annual average** (no normalization)
- Merge with CDC data by `Year` and `FIPS`.
- Compute **Pearson correlation**:
  - Per state
  - Overall

### D. Output

- Table of correlation coefficients (`r`) and `p`-values per state.
- Overall correlation result.
- Optional: scatter plots or time-series visualization.

---

## 5. Interpretation Rules

| Rule                      | Action                          |
|---------------------------|---------------------------------|
| r > 0.4 and p < 0.05      |   Proceed to national study     |
| Mixed significance        |   Adjust keywords or methods    |
| No significant correlation|   Reconsider GT as proxy        |

---