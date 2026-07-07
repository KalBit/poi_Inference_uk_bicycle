import os
import pandas as pd

if os.path.exists("../data/January_h.csv"):
    
    hourly_data = pd.read_csv("../data/January_h.csv")
    hourly_data['s_date'] = pd.to_datetime(hourly_data['s_date'])
    
    
    aggregation = {
    # Demand: Sum all hourly counts for the month
    'count': 'sum',
    # Static Features: Take the first occurrence (since they don't change)
    'longitude': 'first',
    'latitude': 'first'
    }
    
    for col in hourly_data.columns:
        if ('dist' in col or 'count' in col) and col not in aggregation:
            aggregation[col] = 'first'
            
    monthly_aggregated = hourly_data.groupby(['start_station_number']).agg(aggregation).reset_index()
    print(monthly_aggregated.shape)
    
    
else:
    print("No Dataset Found!")

