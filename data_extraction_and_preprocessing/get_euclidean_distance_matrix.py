import pandas as pd
import numpy as np
import geopandas as gpd
from sklearn.metrics.pairwise import euclidean_distances


def get_euclidean_matrix(data):

    try:
        df = pd.read_csv(data)
    except FileNotFoundError:
        exit()


    gdf = gpd.GeoDataFrame(
        df, 
        geometry=gpd.points_from_xy(df.longitude, df.latitude),
        crs="EPSG:4326"  # WGS84 
    )

    gdf_proj = gdf.to_crs(epsg=27700) # British National Grid (EPSG:27700)

    coordinates_meters = np.array([geom.coords[0] for geom in gdf_proj.geometry])

    distance_matrix_meters = euclidean_distances(coordinates_meters)

    station_ids = df['start_station_number'].tolist()

    dist_matrix_df = pd.DataFrame(distance_matrix_meters, index=station_ids, columns=station_ids)

    output_filename = "euclidean_distance_matrix_meters.csv"
    dist_matrix_df.to_csv(output_filename)


 ## should be January_M  create a file to make the january m dataset