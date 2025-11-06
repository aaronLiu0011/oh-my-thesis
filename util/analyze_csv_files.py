import os
import pandas as pd
import numpy as np
from pathlib import Path


def analyze_csv_files(folder_path):
    folder = Path(folder_path)
    
    if not folder.exists():
        print(f"Error: Folder '{folder_path}' does not exist")
        return
    
    csv_files = list(folder.glob('*.csv'))
    
    if not csv_files:
        print(f"No CSV files found in '{folder_path}'")
        return
    
    print(f"Found {len(csv_files)} CSV files\n")
    print("=" * 80)
    
    for csv_file in csv_files:
        print(f"\nFile: {csv_file.name}")
        print("-" * 80)
        
        try:
            df = pd.read_csv(csv_file)
            
            print(f"Headers: {list(df.columns)}")
            print(f"Rows: {len(df)}")
            print(f"Columns: {len(df.columns)}")
            print()
            
            print("Column Analysis:")
            print(f"{'Column Name':<30} {'Data Type':<15} {'Mean/Info':<30}")
            print("-" * 80)
            
            for column in df.columns:
                col_type = str(df[column].dtype)
                
                if pd.api.types.is_numeric_dtype(df[column]):
                    mean_value = df[column].mean()
                    if pd.notna(mean_value):
                        info = f"Mean: {mean_value:.4f}"
                    else:
                        info = "No valid data"
                else:
                    unique_count = df[column].nunique()
                    info = f"Unique values: {unique_count}"
                
                print(f"{column:<30} {col_type:<15} {info:<30}")
            
            print("\n" + "=" * 80)
            
        except Exception as e:
            print(f"Error reading file: {str(e)}")
            print("=" * 80)


def analyze_csv_detailed(folder_path):
    folder = Path(folder_path)
    
    if not folder.exists():
        print(f"Error: Folder '{folder_path}' does not exist")
        return
    
    csv_files = list(folder.glob('*.csv'))
    
    if not csv_files:
        print(f"No CSV files found in '{folder_path}'")
        return
    
    print(f"Found {len(csv_files)} CSV files\n")
    
    for csv_file in csv_files:
        print(f"\n{'='*80}")
        print(f"File: {csv_file.name}")
        print(f"{'='*80}\n")
        
        try:
            df = pd.read_csv(csv_file)
            
            print("Basic Information")
            print(f"  Rows: {len(df)}")
            print(f"  Columns: {len(df.columns)}")
            print(f"  Headers: {list(df.columns)}")
            print()
            
            print("Data Type Summary")
            dtype_counts = df.dtypes.value_counts()
            for dtype, count in dtype_counts.items():
                print(f"  {dtype}: {count} columns")
            print()
            
            numeric_columns = df.select_dtypes(include=[np.number]).columns
            if len(numeric_columns) > 0:
                print("Numeric Columns Statistics")
                for col in numeric_columns:
                    print(f"\n  Column: {col}")
                    print(f"    Data type: {df[col].dtype}")
                    print(f"    Mean: {df[col].mean():.4f}")
                    print(f"    Median: {df[col].median():.4f}")
                    print(f"    Std dev: {df[col].std():.4f}")
                    print(f"    Min: {df[col].min():.4f}")
                    print(f"    Max: {df[col].max():.4f}")
                    print(f"    Missing: {df[col].isna().sum()}")
            
            non_numeric_columns = df.select_dtypes(exclude=[np.number]).columns
            if len(non_numeric_columns) > 0:
                print("\nNon-Numeric Columns Statistics")
                for col in non_numeric_columns:
                    print(f"\n  Column: {col}")
                    print(f"    Data type: {df[col].dtype}")
                    print(f"    Unique values: {df[col].nunique()}")
                    print(f"    Missing: {df[col].isna().sum()}")
                    top_values = df[col].value_counts().head(5)
                    if len(top_values) > 0:
                        print(f"    Top values:")
                        for val, count in top_values.items():
                            print(f"      '{val}': {count}")
            
            print("\n")
            
        except Exception as e:
            print(f"Error reading file: {str(e)}\n")


if __name__ == "__main__":
    print("CSV File Analysis Tool")
    print("=" * 80)
    
    print("\nEnter the folder path containing CSV files:")
    print("(e.g., /home/user/data or ./data)")
    folder_path = input("Path: ").strip()
    
    if not folder_path:
        folder_path = "."
    
    print("\nSelect analysis mode:")
    print("1. Simple mode - headers, data types, and means")
    print("2. Detailed mode - complete statistical information")
    mode = input("Choose (1 or 2, default 1): ").strip()
    
    print("\nStarting analysis...\n")
    
    if mode == "2":
        analyze_csv_detailed(folder_path)
    else:
        analyze_csv_files(folder_path)
    
    print("\nAnalysis complete!")