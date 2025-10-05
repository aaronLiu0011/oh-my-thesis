# **Google Trends Data Workflow**

**Project Module:** `google_trend`
**Objective:** Validate, collect, and process Google Trends (GT) data as a proxy for CDC STD statistics across U.S. states.

---

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

   * **Purpose:** To ensure that the observed correlation is not spurious or driven by common shocks unrelated to STD trends.
   * **Design:**

     * Replace the true CDC STD data with an unrelated variable (e.g., coffee consumption or random noise series).
     * Re-run both Pearson correlation and FE regressions using the same specification.
   * **Expected Outcome:**

     * No significant correlation should appear in placebo regressions.
     * Confirms that the GT–CDC correlation is specific to disease-related search behavior.
   * **Result:** The placebo test yielded insignificant coefficients, reinforcing the robustness of GT as a valid proxy.

### **Reference Notebooks**

📄 [`google_trend/validation/validate_cdc_gt.ipynb`](validation/validate_cdc_gt.ipynb)

---

## **2. Construction of Cross-State Comparable Metrics**

### **Problem**

Google Trends indices are *relative* (0–100 scaled) within each query, making them **incomparable across states**.

### **Solution**

Follow the anchor-based rescaling approach inspired by
[Analytics Vidhya: *Compare More Than 5 Keywords in Google Trends Using Pytrends*](https://medium.com/analytics-vidhya/compare-more-than-5-keywords-in-google-trends-search-using-pytrends-3462d6b5ad62)

### **Method Summary**

* Select **California (CA)** as the benchmark state.
* Divide the remaining 50 states into **13 groups** (each group: CA + 4 other states).
* For each group and each keyword:

  1. Retrieve Google Trends data.
  2. Normalize each state’s value by CA’s index within the same query.
  3. Merge all groups into a unified, comparable dataset.

---

## **3. Time-Series Processing (Ongoing)**

Further steps (seasonal adjustment, detrending, event-study preparation) will be implemented in later updates.
📄 Work-in-progress notebook: *to be added in* `google_trend/processing/`

---

## **4. Supplement: GT Data Collection Notes**

### **0. Nature of GT Data**

* GT indices are **relative** values ranging from 0–100.
* The peak value (100) represents the maximum search interest *within the selected time and region*.
* Therefore, direct cross-state comparisons are invalid without rescaling.

### **1. Single-State Collection**

* For collecting one state’s data, use **Pytrends**.
* Reference: [`google_trend/gt_anchor_based_rescaling_V2.ipynb`](gt_anchor_based_rescaling_V2.ipynb)

### **2. Multi-State Comparison**

* Pytrends does **not support** comparing multiple regions for the *same keyword* in a single automated call.
* These comparisons must be **collected manually** from the Google Trends interface.

### **3. Manual Collection via URL**

* Google Trends URLs encode query parameters in a reproducible format.
  Example pattern:

  ```
  https://trends.google.com/trends/explore?date=2018-01-01%202025-08-31&geo=US-CA,US-TX&q=%2Fm%2F074m2
  ```
* Each URL corresponds to a specific combination of:

  * Time range
  * Region list
  * Keyword (as topic ID)
* A complete list of URLs used in this project is available in:
  📄 [`google_trend/url_batches.txt`](url_batches.txt)

---

## **5. File Structure Overview**

```
google_trend/
│
├── validation/
│   └── validate_cdc_gt.ipynb      # GT-CDC proxy validation
│
├── processing/
│   └── (planned) time-series processing scripts
│
├── gt_anchor_based_rescaling_V2.ipynb  # Single-state collection using Pytrends
│
└── gt_url_batches.txt                 # Manually constructed GT URLs for state comparisons
```
