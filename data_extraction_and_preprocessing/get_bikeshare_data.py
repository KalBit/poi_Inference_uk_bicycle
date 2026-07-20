import pandas as pd
import numpy as np
import json
import os 



def extract_and_finalize_dataset():


    url_list_main_dataset = [
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/350JourneyDataExtract26Dec2022-01Jan2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/351JourneyDataExtract02Jan2023-08Jan2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/352JourneyDataExtract09Jan2023-15Jan2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/353JourneyDataExtract16Jan2023-22Jan2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/354JourneyDataExtract23Jan2023-29Jan2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/355JourneyDataExtract30Jan2023-05Feb2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/356JourneyDataExtract06Feb2023-12Feb2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/357JourneyDataExtract13Feb2023-19Feb2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/358JourneyDataExtract20Feb2023-26Feb2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/359JourneyDataExtract27Feb2023-05Mar2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/360JourneyDataExtract06Mar2023-12Mar2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/361JourneyDataExtract13Mar2023-19Mar2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/362JourneyDataExtract20Mar2023-26Mar2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/363JourneyDataExtract27Mar2023-02Apr2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/364JourneyDataExtract03Apr2023-09Apr2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/365JourneyDataExtract10Apr2023-16Apr2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/366JourneyDataExtract17Apr2023-23Apr2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/367JourneyDataExtract24Apr2023-30Apr2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/368JourneyDataExtract01May2023-07May2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/369JourneyDataExtract08May2023-14May2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/370JourneyDataExtract15May2023-21May2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/371JourneyDataExtract22May2023-28May2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/372JourneyDataExtract29May2023-04Jun2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/373JourneyDataExtract05Jun2023-11Jun2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/374JourneyDataExtract12Jun2023-18Jun2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/375JourneyDataExtract19Jun2023-30Jun2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/376JourneyDataExtract01Jul2023-14Jul2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/377JourneyDataExtract15Jul2023-31Jul2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/378JourneyDataExtract01Aug2023-14Aug2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/378JourneyDataExtract15Aug2023-31Aug2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/379JourneyDataExtract01Sep2023-14Sep2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/380JourneyDataExtract15Sep2023-30Sep2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/381JourneyDataExtract01Oct2023-14Oct2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/382JourneyDataExtract15Oct2023-31Oct2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/383JourneyDataExtract01Nov2023-14Nov2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/384JourneyDataExtract15Nov2023-30Nov2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/385JourneyDataExtract01Dec2023-14Dec2023.csv"
        },
        {
        "url": "s3://cycling.data.tfl.gov.uk/usage-stats/386JourneyDataExtract15Dec2023-31Dec2023.csv"
        }
    ]


    # stationwise_amenity_counts = pd.read_csv("../data/stationwise_amenity_count.csv")
    stationwise_nearest_amenity_dist = pd.read_csv("../data/stationwise_amenity_dist.csv")
    stations_with_coords = pd.read_csv("../data/station_location.csv")
    uk_holidays = pd.read_csv("../data/uk_holiday.csv")
    uk_holidays["date"] = pd.to_datetime(uk_holidays["date"], format="%d/%m/%Y")


    month_map = {
        "Jan":1,
        "Feb":2,
        "Mar":3,
        "Apr":4,
        "May":5,
        "Jun":6,
        "Jul":7,
        "Aug":8,
        "Sep":9,
        "Oct":10,
        "Nov":11,
        "Dec":12
    }

    output_filename_map = {
        "Jan":"January_h",
        "Feb":"February_h",
        "Mar":"March_h",
        "Apr":"April_h",
        "May":"May_h",
        "Jun":"June_h",
        "Jul":"July_h",
        "Aug":"August_h",
        "Sep":"September_h",
        "Oct":"October_h",
        "Nov":"November_h",
        "Dec":"December_h"
    }

    # #for m in month_map.keys():
    month = "Jan" # Ex: Jan, Feb, Mar

    # if(os.path.exists(f"../data/{output_filename_map[month]}.csv")):
    #     print(f"{output_filename_map[month]}.csv already exist!")
    #     return None

    print(f"Processing {month} data...")

    urls_for_month = []

    for url in url_list_main_dataset:
        if month in  url["url"]:
            urls_for_month.append(url["url"])

    data = pd.concat([pd.read_csv(file) for file in urls_for_month], ignore_index=True)

    # Remove Records with duration less than 1 minute
    data = data[data["Total duration (ms)"] > 60000]

    data = data.rename(columns={"Start station number": "start_station_number",
                                "Start station":"start_station_name",
                                "Start date":"s_date"})


    data["s_date"] = pd.to_datetime(data["s_date"])
    
    Month_data = data[data["s_date"].dt.month == month_map[month]]
    
    drop_column_list = ["Number", "End date", "End station number", "End station", "Bike number", "Bike model", "Total duration", "Total duration (ms)" ]
    Month_data = Month_data.drop(columns=drop_column_list)
    
    Month_data["s_hour"] = Month_data["s_date"].dt.hour
    Month_data["s_date"] = pd.to_datetime(Month_data["s_date"].dt.date)
    
    Month_data = Month_data.groupby(['s_date', 's_hour', 'start_station_number', 'start_station_name']).size().reset_index(name='count')
    
    all_dates = Month_data["s_date"].unique()
    all_hours = Month_data["s_hour"].unique()
    all_stations = Month_data["start_station_number"].unique()
    
    station_map = Month_data[['start_station_name', 'start_station_number']].drop_duplicates().dropna()


    full_index = pd.MultiIndex.from_product(
        [all_dates, all_hours, all_stations],
        names=["s_date", "s_hour", "start_station_number"]
    )

    full_grid = pd.DataFrame(index=full_index).reset_index()


    aggregated = Month_data.groupby(["s_date", "s_hour", "start_station_number"]).agg({
        'count':'first'
    }).reset_index()

    aggregated["start_station_number"] = aggregated["start_station_number"].astype('object')
    
    Month_data = full_grid.merge(aggregated, on=["s_date", "s_hour", "start_station_number"], how='left')
    
    Month_data = Month_data.merge(
        station_map, 
        on='start_station_number', 
        how='left'
        )
    
    Month_data["day_of_week"] = Month_data["s_date"].dt.day_of_week
    Month_data["week_of_month"] = (Month_data["s_date"].dt.day - 1) // 7 + 1   
    Month_data["is_weekend"] = Month_data["day_of_week"].isin([5,6])
    Month_data["weekend_or_weekday_sdate"] = Month_data["is_weekend"].map({True: "weekend", False: "weekday"})
    Month_data = Month_data.drop(columns=["is_weekend"])
    Month_data["count"] = Month_data["count"].fillna(0)

    time_of_day_conditions = [
            (Month_data["s_hour"] >= 0) & (Month_data["s_hour"] <= 5),
            (Month_data["s_hour"] >= 6) & (Month_data["s_hour"] <= 11),
            (Month_data["s_hour"] >= 12) & (Month_data["s_hour"] <= 17),
            (Month_data["s_hour"] >= 18) & (Month_data["s_hour"] <= 21),
            (Month_data["s_hour"] >= 22) & (Month_data["s_hour"] <= 23),
            
        ]

    time_of_day_choices = ["night", "morning", "day", "evening", "night"]

    Month_data["time_of_day"] = np.select(condlist=time_of_day_conditions, choicelist=time_of_day_choices, default="Unknown")

    
    stations_with_coords = stations_with_coords[
        stations_with_coords['latitude'].notna() & 
        stations_with_coords['longitude'].notna()
    ]

    stations_with_coords["start_station_number"] = stations_with_coords["start_station_number"].astype("object")
    Month_data["start_station_number"] = Month_data["start_station_number"].astype("object")


    Month_data = pd.merge(
        Month_data,
        stations_with_coords[["start_station_number", "longitude", "latitude"]],
        left_on="start_station_number",
        right_on="start_station_number",
        how="inner"
    )
    
    holiday_indicator = uk_holidays[['date']].copy()
    holiday_indicator['is_holiday'] = True

    Month_data = Month_data.merge(holiday_indicator, 
                left_on='s_date', 
                right_on='date', 
                how='left')

    pd.set_option('future.no_silent_downcasting', True)
    Month_data['is_holiday'] = Month_data['is_holiday'].fillna(False)
    Month_data = Month_data.drop(columns=['date'])
    
    Month_data['start_station_name'] = Month_data['start_station_name'].str.strip().str.lower()
    # stationwise_amenity_counts['start_station_name'] = stationwise_amenity_counts['start_station_name'].str.strip().str.lower()
    stationwise_nearest_amenity_dist['start_station_name'] = stationwise_nearest_amenity_dist['start_station_name'].str.lower()

    # stationwise_amenity_counts = stationwise_amenity_counts.drop(columns=["longitude", "latitude"], axis=1)

    # amenity_count_col_corrected = {
    #     "amenity=cafe_count_5min_walk":"cafe_count_5min_walk",
    #     # "amenity=pub_count_5min_walk":"pub_count_5min_walk",
    #     # "amenity=university_count_5min_walk":"university_count_5min_walk",
    #     # "amenity=bank_count_5min_walk":"bank_count_5min_walk",
    #     # "railway=station_count_5min_walk":"station_count_5min_walk"
        
        
    # }

    # Month_data = Month_data.merge(
    #         stationwise_amenity_counts,
    #         left_on="start_station_name",
    #         right_on="start_station_name",
    #         how="left"
    #     )
    
    # Month_data = Month_data.rename(columns=amenity_count_col_corrected)

    amenity_distance_col_list = [
            "start_station_name", 
            # 'dist_to_nearest_cafe',
            # 'dist_to_nearest_pub',
            # 'dist_to_nearest_university',
            # 'dist_to_nearest_bank', 
            'dist_to_nearest_station'
            ]


    Month_data = Month_data.merge(
        stationwise_nearest_amenity_dist[[col for col in amenity_distance_col_list]],
        left_on="start_station_name",
        right_on="start_station_name",
        how="left"
    )

    Month_data = Month_data.drop(columns=["start_station_name"])
    
    print(f"Saving {month} data...")

    Month_data.to_csv(f"../data/{output_filename_map[month]}.csv", index=False)
    
    print(f"Final Dataset for {month} Saved!")
    



