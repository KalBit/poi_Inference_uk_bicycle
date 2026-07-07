import osmnx as ox
import geopandas as gpd
import pandas as pd
from shapely.geometry import Point



def extract_amenity_count_data():


    WALK_DISTANCE = 375  
    # SAMPLE_SIZE = 15 

    POI_TAGS = [
        {'amenity': 'cafe'},
        {'amenity': 'atm'},
        {'amenity': 'pub'},
        {'amenity': 'school'},
        {'amenity': 'university'},
        {'amenity': 'college'},
        {'amenity': 'bank'},
        {'amenity': 'post_office'},
        {'amenity': 'library'},
        {'amenity': 'cinema'},
        {'shop': 'supermarket'},
        {'public_transport': 'platform'},
        {'public_transport': 'stop_position'},
        {'railway': 'station'},
        {'highway': 'bus_stop'}
    ]

    df = pd.read_csv('../data/station_location.csv')
    stations_sample = df.drop_duplicates(subset=['latitude', 'longitude'])

    G_proj = ox.load_graphml('../data/london_walkable_graph.graphml')


    all_pois = []
    for tag in POI_TAGS:
        key, value = list(tag.items())[0]
        try:
            
            pois = ox.features_from_place('London, UK', tags={key: value})
            if pois.empty:
                print(f"No results for {key}={value} — skipping")
                continue
            pois = pois[pois.geometry.type == 'Point']
            pois['poi_type'] = f"{key}={value}"
            all_pois.append(pois)
        except Exception as e:
            print(f"Error fetching {key}={value}: {e}")
            
    if not all_pois:
        raise ValueError("No POIs were fetched. Exiting.")
    pois_all = pd.concat(all_pois)
    pois_all = pois_all.to_crs(G_proj.graph['crs'])
    pois_sindex = pois_all.sindex




    # Process each station
    results = []

    for idx, row in stations_sample.iterrows():
        station_name = row.get('start_station_name', f"Station_{idx}")
        try:
            
            point_proj = ox.projection.project_geometry(Point(row['longitude'], row['latitude']), to_crs=G_proj.graph['crs'])[0]
            node = ox.distance.nearest_nodes(G_proj, point_proj.x, point_proj.y)

            
            subgraph = ox.truncate.truncate_graph_dist(G_proj, node, dist=WALK_DISTANCE, weight='length')

        
            nodes = [Point((G_proj.nodes[n]['x'], G_proj.nodes[n]['y'])) for n in subgraph.nodes]
            walkable_area = gpd.GeoSeries(nodes).unary_union.convex_hull

            # Count POIs
            counts = {}
            for tag in POI_TAGS:
                poi_type = f"{list(tag.items())[0][0]}={list(tag.items())[0][1]}"
                matches_idx = list(pois_sindex.intersection(walkable_area.bounds))
                if not matches_idx:
                    counts[f'{poi_type}_count_5min_walk'] = 0
                    continue
                possible = pois_all.iloc[matches_idx]
                matched = possible[(possible['poi_type'] == poi_type) & (possible.geometry.within(walkable_area))]
                counts[f'{poi_type}_count_5min_walk'] = matched.shape[0]

            results.append({**row.to_dict(), **counts, 'status': 'success'})


        except Exception as e:
            empty_counts = {f"{list(tag.items())[0][0]}={list(tag.items())[0][1]}_count_5min_walk": 0 for tag in POI_TAGS}
            results.append({**row.to_dict(), **empty_counts, 'status': str(e)})
            print(f"{station_name}: Failed — {str(e)}")


    result_df = pd.DataFrame(results)
    output = pd.merge(
        df,
        result_df[['latitude', 'longitude'] + [col for col in result_df.columns if '_count_5min_walk' in col]],
        on=['latitude', 'longitude'],
        how='left'
    )
    output.to_csv('../data/stationwise_amenity_count.csv', index=False)

    print(f"Amenity Count Data saved!")
