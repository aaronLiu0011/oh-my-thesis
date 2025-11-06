# Util: CSV File Analysis Tool

## Overview

A Python script to analyze CSV files in a folder, displaying headers, data types, and statistics for each column.

## Features

- Automatically scans all CSV files in a folder
- Displays headers and basic information
- Shows data types for each column
- Calculates mean values for numeric columns
- Shows unique value counts for non-numeric columns
- Two analysis modes: simple and detailed

## Usage

### Interactive Mode

```bash
python analyze_csv_files.py
```

Then enter the folder path and select the analysis mode.

### Direct Function Call

```python
from analyze_csv_files import analyze_csv_files, analyze_csv_detailed

# Simple analysis
analyze_csv_files('/path/to/csv/folder')

# Detailed analysis
analyze_csv_detailed('/path/to/csv/folder')
```

### Modify Script

Edit the script to specify your folder path:

```python
if __name__ == "__main__":
    folder_path = "/your/csv/folder"
    analyze_csv_files(folder_path)
```

## Analysis Modes

### Simple Mode
- File name
- Headers list
- Row and column counts
- Data type for each column
- Mean value for numeric columns
- Unique value count for non-numeric columns

### Detailed Mode
All simple mode information plus:
- Numeric columns: median, std dev, min, max, missing values
- Non-numeric columns: top 5 most frequent values
- Data type distribution summary

## Output Example

```
Found 2 CSV files

================================================================================

File: sales_data.csv
--------------------------------------------------------------------------------
Headers: ['Product', 'Price', 'Quantity', 'Date', 'Category']
Rows: 5
Columns: 5

Column Analysis:
Column Name                    Data Type       Mean/Info                     
--------------------------------------------------------------------------------
Product                        object          Unique values: 5              
Price                          float64         Mean: 8259.9900               
Quantity                       int64           Mean: 210.0000                
Date                           object          Unique values: 5              
Category                       object          Unique values: 1              

================================================================================
```

## Notes

- Ensure CSV files are UTF-8 encoded
- Mean calculations automatically ignore NaN values
- Errors are displayed for unreadable files
- Only scans the specified folder, not subfolders

## Extending Functionality

To scan subfolders recursively, change:
```python
csv_files = list(folder.glob('*.csv'))
```
to:
```python
csv_files = list(folder.rglob('*.csv'))
```

To filter specific files:
```python
csv_files = list(folder.glob('sales_*.csv'))
```