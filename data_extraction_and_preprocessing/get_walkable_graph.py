import pandas as pd
import geopandas as gpd
import osmnx as ox


def create_graphml():

    BUFFER_For_Study_Area = 2000


    stations_df = pd.read_csv("../data/station_location.csv")
    stations_gdf = gpd.GeoDataFrame(
        stations_df,
        geometry= gpd.points_from_xy(stations_df.longitude, stations_df.latitude),
        crs="EPSG:4326"
    )

    stations_proj = stations_gdf.to_crs(epsg=3857)
    study_area_proj = stations_proj.union_all().buffer(BUFFER_For_Study_Area)
    study_area_wgs = gpd.GeoSeries([study_area_proj], crs=stations_proj.crs).to_crs(epsg=4326).iloc[0]

    G = ox.graph_from_polygon(study_area_wgs, network_type="walk",simplify=False)
    G_proj = ox.project_graph(G, to_crs="EPSG:3857")


    ox.save_graphml(G_proj, filepath="../data/london_walkable_graph.graphml")
    print("London Walkable Graphml File Saved!")


