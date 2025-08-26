import requests
import pandas as pd

url_county = (
    "https://api.census.gov/data/timeseries/poverty/saipe"
    "?get=NAME,SAEMHI_PT,STATE,COUNTY&for=county:*&time=from+2010+to+2023"
)