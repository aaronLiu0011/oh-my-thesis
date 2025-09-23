# **Standard Operating Procedure (SOP): Analyzing the Impact of US Abortion Laws on STD-Related Search Behavior Using Google Trends**

**Version**: 1.0
**Date**: September 17, 2025

## **1.0 Research Objective & Core Hypothesis**

  * **1.1 Objective**: To systematically evaluate the specific impact of differentiated state-level abortion policies on public search interest in Sexually Transmitted Diseases (STDs) following the overturning of Roe v. Wade in June 2022.
  * **1.2 Hypothesis**: Compared to states where abortion rights are protected, states where abortion rights are restricted or banned will exhibit significant changes in public search interest for STDs (after normalization and calibration).

## **2.0 Definition of Key Terms**

  * **GFT Index**: The raw, relative search interest value (0-100) downloaded directly from Google Trends.
  * **Benchmark State**: A fixed, high-population state used as a constant reference in every GFT query. **Selected for this project: California (CA)**.
  * **Anchor Term**: A high-volume, universal, and non-topically related term used to calibrate for general search activity across different regions and times. **Selected for this project: `Weather` (Topic)**.
  * **Normalized Index**: The ratio of a state's GFT Index to the Benchmark State's GFT Index, which solves the problem of cross-state comparability.
  * **Calibrated Index**: The final core metric used in this study. It is calculated by dividing the target keyword's "Normalized Index" by the anchor term's "Normalized Index," reflecting the "proportional share of specific interest."
  * **Ground Truth Data**: The official, authoritative data used for validation. **For this project: Annual STD infection rates by state, published by the U.S. CDC**.

## **3.0 Required Tools & Data Sources**

  * **Software**: Spreadsheet software (Microsoft Excel or Google Sheets).
  * **Data Sources**:
      * Google Trends ([https://trends.google.com](https://trends.google.com))
      * U.S. CDC STD Data & Statistics ([https://www.cdc.gov/std/statistics/](https://www.google.com/search?q=https://www.cdc.gov/std/statistics/))

-----

## **4.0 Experimental Procedure**

The experiment is divided into four main phases: Validation, Collection, Processing, and Analysis. **Please execute these phases in strict sequential order.**

### **Phase I: Pilot Validation Study**

**The goal of this phase is to confirm the validity of GFT data as a proxy for real-world infection rates. If this phase fails, the entire project must be re-evaluated.**

  * **4.1.1 Obtain Ground Truth Data**:

    1.  Visit the CDC website and locate the STD Surveillance data tables.
    2.  Download the **rates per 100,000 population** for **Chlamydia**, **Gonorrhea**, and **Syphilis** by state, from 2018 to the latest available year.
    3.  Organize this data into a table with the columns: `Year`, `State`, `Disease`, `Infection_Rate`.

  * **4.1.2 Select the Pilot Sample**:

      * **Keyword Sample**: `Chlamydia` (Topic), `Gonorrhea` (Topic), `Syphilis` (Disease).
      * **State Sample**: `California` (Benchmark), `Texas`, `Florida`, `Illinois`, `Washington`, `Wyoming`, `New York`.

  * **4.1.3 Collect Pilot GFT Data**:

    1.  **For the 3 keywords and 7 states sampled above ONLY**, strictly follow the **full data collection methodology outlined in Phase II** (see 4.2.3) to collect monthly GFT data from January 1, 2018, to the present.
    2.  Simultaneously, collect the GFT data for the anchor term `Weather` for these same 7 states.

  * **4.1.4 Process Pilot Data and Conduct Correlation Analysis**:

    1.  For the collected pilot GFT data, complete the **data processing steps from Phase III** (see 4.3) to calculate the monthly **Calibrated Index** for each sample state.
    2.  **Aggregate the monthly Calibrated Index into an annual average** to get the `Annual_Calibrated_Index`.
    3.  For each disease, perform a **Pearson correlation analysis (*r*)** between the `Annual_Calibrated_Index` and the CDC's `Infection_Rate`.

  * **4.1.5 Make a "Go/No-Go" Decision**:

      * If **r \> 0.4** (moderate to strong positive correlation): Validation is successful. **Proceed to Phase II**.
      * If **r \< 0.4** (weak or no correlation): Validation has failed. **Halt the project** or return to redesign the keywords (e.g., attempt to validate behavioral terms like `STD testing` instead).

### **Phase II: Full-Scale Data Collection**

**Assuming Phase I was successful, begin the systematic data collection for all target states and keywords.**

  * **4.2.1 Prepare the Master Datasheet**:

      * Create a master worksheet in your spreadsheet software with the columns: `Date` (YYYY-MM), `State`, `Keyword`, `GFT_Index`.

  * **4.2.2 Define Keywords and State Groups**:

      * **Keyword List**: See Appendix A.
      * **State Grouping**: Divide the 50 regions (states + D.C.) other than California into 13 groups of 4. See Appendix B for an example.

  * **4.2.3 Execute Systematic Data Collection (Looping Process)**:

    1.  **Outer Loop (By Keyword)**: Select the first keyword from your list (e.g., `Syphilis`).
    2.  **Inner Loop (By State Group)**: Select the first group of states (e.g., `Alabama`, `Alaska`, `Arizona`, `Arkansas`).
    3.  **GFT Operation**:
          * Go to Google Trends.
          * Search Term: `"Syphilis"` (Topic: Disease).
          * Region: United States.
          * Time Period: `2018-01-01` to Present.
          * In the "Compare by sub-region" module, enter `California` and the 4 states from the current group.
    4.  **Download and Save**:
          * Download the monthly time-series data as a CSV file.
          * **Strictly adhere to the naming convention**: `Keyword_StateGroup_DateRange.csv` (e.g., `Syphilis_Group1_2018-Present.csv`).
    5.  **Repeat**: Repeat steps 3-4 for all state groups. After completing one keyword, return to step 1 and select the next keyword, continuing until data for all keywords (including the anchor term `Weather`) have been collected.

### **Phase III: Data Cleaning and Processing**

**The goal of this phase is to consolidate all raw data files into a single, clean master dataset ready for analysis.**

  * **4.3.1 Consolidate Raw Data**:

      * Systematically copy-paste or use a script to import the data from all downloaded CSV files into your master datasheet.

  * **4.3.2 Calculate the Normalized Index**:

    1.  Add a new column to your master datasheet: `Normalized_Index`.
    2.  For each row, find the `GFT_Index` of the benchmark state (CA) for the same date and keyword.
    3.  Apply the formula: $$Normalized\_Index = \frac{\text{Current Row's GFT\_Index}}{\text{Corresponding Benchmark State's GFT\_Index}}$$
    4.  Perform this calculation for all target keywords and the anchor term.

  * **4.3.3 Calculate the Final Calibrated Index**:

    1.  Add a final column to your master datasheet: `Calibrated_Index`.
    2.  For each row (representing a target keyword), find the `Normalized_Index` of the **anchor term `Weather`** for the same date and state.
    3.  Apply the formula: $$Calibrated\_Index = \frac{\text{Target Keyword's Normalized\_Index}}{\text{Anchor Term 'Weather's' Normalized\_Index}}$$
    4.  Once completed, the `Calibrated_Index` column is your final core metric for analysis.

### **Phase IV: Analysis and Interpretation**

**This phase involves the actual research analysis.**

  * **4.4.1 Data Visualization**:
      * Plot the time-series of the `Calibrated_Index` for various states to visually inspect for changes around June 2022.
  * **4.4.2 Statistical Analysis**:
      * Employ an **Interrupted Time Series Analysis (ITSA)** to assess the "breakpoint" effect of the policy change.
      * Use a **Difference-in-Differences (DiD)** model to compare the change in `Calibrated_Index` between states with strict abortion laws (treatment group) and states with lenient laws (control group) before and after the policy change.
  * **4.4.3 Interpretation of Results**:
      * Based on the statistical analysis, explain whether the changes in abortion laws are statistically associated with significant changes in public search interest for STDs.

-----

## **5.0 Data Management and Quality Control**

  * **File Naming Convention**: Strictly follow the file naming rules mentioned in section 4.2.3.
  * **Version Control**: Regularly back up your master datasheet (e.g., `MasterData_v1.0.xlsx`, `MasterData_v2.0.xlsx`).
  * **Quality Checks**: At each stage of data processing, randomly select a few states and dates and perform the calculations manually to verify the accuracy of your formulas.

## **6.0 Limitations Statement**

In the final research paper, you must acknowledge the inherent limitations of this methodology:

  * Search interest does not perfectly equate to real-world behavior or cases.
  * External events, such as media coverage, can confound search trends.
  * The Ecological Fallacy: Regional-level trends do not necessarily apply to individuals.

-----

## **Appendices**

### **Appendix A: Suggested Keyword List (Topics preferred)**

  * **Core Diseases**: `Syphilis`, `Chlamydia`, `Gonorrhea`, `Herpes`, `HIV`
  * **Behavior & Prevention**: `STD testing`, `Get tested`, `Condom`, `STD symptoms`
  * **Anchor Term**: `Weather`

### **Appendix B: State Grouping Example**

  * **Group 1**: CA, AL, AK, AZ, AR
  * **Group 2**: CA, CO, CT, DE, FL
  * **Group 3**: CA, GA, HI, ID, IL
  * ...and so on, until all regions are covered.