# **Google Trends Data Workflow**

**Project Module:** `google_trend`
**Objective:** Validate, collect, and process Google Trends (GT) data as a proxy for CDC STD statistics across U.S. states.

## **1. Validation: GT as a CDC Proxy**

### **Goal**

Verify whether Google Trends indices for `chlamydia`, `gonorrhea`, and `syphilis` can serve as valid proxies for CDC-reported STD incidence.

### **Methods**

1. **Primary Validation**

   * **Statistical Tests:**

     * *Pearson correlation coefficient (r)* between annualized GT index and CDC incidence.
     * *Two-way Fixed Effects (FE) regression model* controlling for state and year effects.
   * **Data Range:** 2018–2023
   * **Result:** A consistently strong positive correlation confirms that GT search indices reflect real-world STD infection patterns, validating GT as a proxy variable.

2. **Placebo Test**

   * **Purpose:** To confirm that the observed correlation is not spurious or driven by unrelated temporal patterns.
   * **Design:**

     * Replace true CDC infection data with an irrelevant series (e.g., coffee consumption or randomly generated noise).
     * Re-run both Pearson and FE regressions using identical specifications.
   * **Expected Outcome:**

     * Placebo correlations should be statistically insignificant.
     * Confirms that GT–CDC relationships are disease-specific.
   * **Result:** Placebo tests show no significant relationship, reinforcing the robustness of GT as a valid proxy.

### **Reference Notebooks**

📄 [`google_trend/validation/validate_cdc_gt.ipynb`](validation/validate_cdc_gt.ipynb)
📄 [`google_trend/placebo_test`](placebo_test)

## **2. Construction of Cross-State Comparable Metrics**

### **Problem**

Google Trends indices are *relative* (0–100 scaled) within each query, making them incomparable across states.

### **Solution**

Follow the anchor-based rescaling approach adapted from:
[Analytics Vidhya – *Compare More Than 5 Keywords in Google Trends Using Pytrends*](https://medium.com/analytics-vidhya/compare-more-than-5-keywords-in-google-trends-search-using-pytrends-3462d6b5ad62)

### **Method Summary**

* **Benchmark State:** California (CA)
* **Grouping:** Divide the other 50 states into **13 groups** (CA + 4 states each)
* **Process:**

  1. Retrieve Google Trends data for each group and keyword
  2. Normalize each state’s value by California’s
  3. Merge all batches into one comparable dataset

## **3. Time-Series Processing (In Progress)**

Post-validation processing steps (seasonal adjustment, detrending, event-study formatting) will be added in later versions.
📄 *Work-in-progress scripts:* `google_trend/processing/`

## **4. Supplement: GT Data Collection Notes**

### **0. Nature of GT Data**

* GT indices are **relative (0–100)** within each query.
* The peak value 100 represents the maximum search intensity for that query, region, and time.
* Direct state-to-state comparison is invalid without proper normalization.

### **1. Single-State Collection (Using Pytrends)**

> [!NOTE]
> Pytrends requires a **stable network connection and Google authentication**, which can fail intermittently on local machines.

> [!TIP]
> **Run all Pytrends scripts on Google Colab** to ensure a consistent IP and avoid CAPTCHA or connection resets.

📄 [`google_trend/gt_anchor_based_rescaling_V2.ipynb`](gt_anchor_based_rescaling_V2.ipynb)


### **2. Multi-State Comparison (Manual Collection)**

> [!WARNING]
> Pytrends does **not support** comparing multiple *regions* for the **same keyword** in one call.
> You must collect cross-state comparisons **manually** via the Google Trends web interface.

To facilitate this:

* Each comparison query uses the same keyword and includes California (benchmark) + 4 states.
* 13 total groups cover all 51 regions.

### **3. Manual Collection via URL**

> [!NOTE]
> Google Trends URLs encode all query parameters (date, keyword, and region) and can be reused directly for manual downloads.

Example format:

```
https://trends.google.com/trends/explore?date=2018-01-01%202025-08-31&geo=US-CA,US-TX&q=%2Fm%2F074m2
```

Each URL specifies:

* **Time period:** 2018–2025
* **Regions:** e.g., `US-CA,US-TX`
* **Keyword:** Topic ID (e.g., `%2Fm%2F074m2` for Syphilis)

A complete list of manually constructed URLs is stored in:
📄 [`google_trend/gt_url_batches.txt`](gt_url_batches.txt)


## **5. File Structure Overview**

```
google_trend/
│
├── CDC/                              # CDC ground truth infection data
│
├── placebo_test/                     # Placebo tests verifying robustness
│
├── raw_data_gt_group/                # GT data (group-level collection: CA + 4 states)
│
├── raw_data_gt_single/               # GT data (single-state Pytrends collection)
│
├── validation/                       # Validation notebooks and results
│   └── validate_cdc_gt.ipynb
│
├── DMA_FIPS_County_Mapping.csv       # County–FIPS–DMA mapping table
│
├── gt_anchor_based_rescaling_V1.ipynb  # Initial rescaling prototype
├── gt_anchor_based_rescaling_V2.ipynb  # Finalized single-state collection
│
├── gTrend.ipynb                      # Core workflow integrating data and normalization
│
├── GTScraper.py                      # Utility for GT scraping (under development)
│
└── README.md                         # This documentation
```
