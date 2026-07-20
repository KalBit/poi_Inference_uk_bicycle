import pandas as pd
import geopandas as gpd
from shapely.geometry import Point
import osmnx as ox
import networkx as nx
from sklearn.neighbors import KDTree
import numpy as np


def extract_amenity_distance_data():
    POIS = {
    "cafe": {'amenity': 'cafe'},
    "pub": {'amenity': 'pub'},
    "university": {'amenity': 'university'},
    "bank":{'amenity': 'bank'},
    # # "railway_station":{'railway': 'station'},
    # # "atm":{'amenity': 'atm'},
    # # "school":{'amenity': 'school'},
    # # "college":{'amenity': 'college'},
    # # "post_office":{'amenity': 'post_office'},
    # # "library":{'amenity': 'library'},
    # # "cinema":{'amenity': 'cinema'},
    "supermarket":{'shop': 'supermarket'},
    # "platform":{'public_transport': 'platform'},
    # "stop_position":{'public_transport': 'stop_position'},
    # "bus_stop":{'highway': 'bus_stop'}
    "station":{"public_transport":"station"}
    }


    BUFFER_For_Study_Area = 2000
    K_NEAREST = 10


    
    stations_df = pd.read_csv("../data/station_location.csv")
    stations_gdf = gpd.GeoDataFrame(
        stations_df,
        geometry= gpd.points_from_xy(stations_df.longitude, stations_df.latitude),
        crs="EPSG:4326"
    )
    stations_gdf.head()
    
    stations_proj = stations_gdf.to_crs(epsg=3857)
    study_area_proj = stations_proj.union_all().buffer(BUFFER_For_Study_Area)
    study_area_wgs = gpd.GeoSeries([study_area_proj], crs=stations_proj.crs).to_crs(epsg=4326).iloc[0]
    
    G_proj = ox.load_graphml(filepath="../data/london_walkable_graph.graphml")
    
    

    station_nodes = ox.nearest_nodes(G_proj, stations_proj.geometry.x.values, stations_proj.geometry.y.values)
    stations_proj = stations_gdf.to_crs(epsg=3857)
    stations_xy = np.column_stack((
        stations_proj.geometry.x,
        stations_proj.geometry.y
    ))

    for amen in POIS.keys():
        
        print(f"Processing {amen}")
        
        tags = POIS[amen]
        try:
            amenity = ox.features_from_polygon(study_area_wgs, tags)
        except Exception as e:
            print(e)
            print(amen)
            continue
        amenity.reset_index()
        if amenity.empty:
            raise RuntimeError(f"No {amenity}s found in the area")
        
        amenity_proj = amenity[amenity.geometry.notnull()].copy().to_crs(epsg=3857)
        amenity_proj["geometry"] = amenity_proj.geometry.centroid
        amenity_proj = amenity_proj.reset_index().rename(columns={"id":"osmid"})
        
        amenity_nodes = ox.nearest_nodes(G_proj, amenity_proj.geometry.x.values, amenity_proj.geometry.y.values)
        
        
        amenity_xy = np.vstack([amenity_proj.geometry.x.values, amenity_proj.geometry.y.values]).T
        kdt = KDTree(amenity_xy)
        
        result = []

        for i, station in stations_gdf.iterrows():
            station_node = station_nodes[i]
            
            dists_k, idxs_k = kdt.query([stations_xy[i]], k=min(K_NEAREST, len(amenity)))
            best_dist = float("inf")
            best_idx = None
            
            for idx in np.atleast_1d(idxs_k[0]):
                amenity_node = amenity_nodes[int(idx)]
                try:
                    length_m = nx.shortest_path_length(G_proj, station_node, amenity_node, weight="length")
                except(nx.NetworkXNoPath, Exception):
                    continue
                
                if length_m < best_dist:
                    best_dist = length_m
                    best_idx =  int(idx)
                
                
            if best_idx is None:
                result.append({
                    "start_station_number": station["start_station_number"],
                    f"nearest_{amen}_osmid": None,
                    f"nearest_{amen}_lon": None,
                    f"nearest_{amen}_lat": None,
                    f"dist_to_nearest_{amen}": np.nan,
                    
                })
                
            else:
                amenity_geom = amenity_proj.iloc[best_idx].geometry
                
                amenity_geom_wgs = gpd.GeoSeries([amenity_geom], crs='EPSG:3857').to_crs(epsg=4326).iloc[0]
                
                result.append({
                    "start_station_name": station["start_station_name"],
                    f"nearest_{amen}_osmid": amenity_proj.iloc[best_idx]["osmid"],
                    f"nearest_{amen}_lon": amenity_geom_wgs.x,
                    f"nearest_{amen}_lat": amenity_geom_wgs.y,
                    f"dist_to_nearest_{amen}": best_dist,
                })
                    
        results_df = pd.DataFrame(result)
        stations_df = pd.merge(
            stations_df,
            results_df,
            on="start_station_name",
            how="left"
        )
    
    
    stations_df.to_csv("../data/stationwise_amenity_dist.csv", index=False)
    print("Amenity Distances Saved!")
    