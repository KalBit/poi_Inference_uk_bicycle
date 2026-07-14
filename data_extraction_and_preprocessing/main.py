import pandas as pd
import numpy as np
import json
import osmnx as ox
import geopandas as gpd
from shapely.geometry import Point
import networkx as nx
from sklearn.neighbors import KDTree
import requests
import os

from get_station_location_data import extract_station_location_data
from get_walkable_graph import create_graphml
from get_amenity_distance_data import extract_amenity_distance_data
from get_amenity_count_data import extract_amenity_count_data
from get_holiday_data import extract_holiday_data
from get_bikeshare_data import extract_and_finalize_dataset

def main():
    print("Fetching Bike Station Location Data...")
    if (os.path.exists("../data/station_location.csv")):
        print("Bike Station Location Data file already exist!")
    else:
        extract_station_location_data()
        
    print("Creating Graphml File For London...")
    if (os.path.exists("../data/london_walkable_graph.graphml")):
        print("Graphml file already exist!")
    else:
        create_graphml()
        
    print("Fetching Amenity Distance Data...")
    if (os.path.exists("../data/stationwise_amenity_dist.csv")):
        print("Amenity Distance Data file already exist!")
    else:
        extract_amenity_distance_data()
        
    print("Fetching Amenity Count Data...")
    if (os.path.exists("../data/stationwise_amenity_count.csv")):
        print("Amenity Count Data file already exist!")
    else:
        extract_amenity_count_data()
    
    print("Fetching UK Holiday Data")
    if (os.path.exists("../data/uk_holiday.csv")):
        print("UK Holiday file already exist!")
    else:
        extract_holiday_data()
    
    
    print("Feching Bike Share Data")
    extract_and_finalize_dataset()
    
    
    print("Dataset Preparation Completed!!")
    

if __name__ == "__main__":
    main()
