import pandas as pd
import networkx as nx
import osmnx as ox
import numpy as np
import time


def calculate_walking_distance_matrix(csv_file, graphml_file, station_ids):
    # --- Load Data and Graph ---
    print(f"Loading station data from '{csv_file}'...")
    try:
        stations_df = pd.read_csv(csv_file)
    except FileNotFoundError:
        return f"Error: The file '{csv_file}' was not found. Please ensure it's uploaded."

    print(f"Loading walkable network graph from '{graphml_file}'...")
    try:
        G = ox.load_graphml(graphml_file)
    except FileNotFoundError:
        return f"Error: The file '{graphml_file}' was not found. Please upload it."

    # --- Prepare Stations ---
    # Filter the DataFrame to get only the stations we need for the matrix
    matrix_stations = stations_df[stations_df['start_station_number'].isin(station_ids)].copy()
    print(f"Preparing to calculate a {len(matrix_stations)}x{len(matrix_stations)} distance matrix.")

    # --- Pre-calculate Nearest Network Nodes (for efficiency) ---
    print("Finding nearest network nodes for all selected stations...")
    points = list(zip(matrix_stations['latitude'], matrix_stations['longitude']))
    nearest_nodes = ox.distance.nearest_nodes(G, X=[p[1] for p in points], Y=[p[0] for p in points])
    matrix_stations['nearest_node'] = nearest_nodes

    # Create a mapping from station_id to its nearest_node for quick lookups
    node_map = pd.Series(
        matrix_stations.nearest_node.values,
        index=matrix_stations.start_station_number
    ).to_dict()

    # --- Calculate Distance Matrix ---
    print("Calculating shortest path distances... (This may take a long time)")
    start_calc_time = time.time()
    distance_matrix = pd.DataFrame(index=station_ids, columns=station_ids, dtype=float)

    for i, start_id in enumerate(station_ids):
        # Progress indicator
        if i > 0 and i % 2 == 0:
            print(f"  ...processed {i} of {len(station_ids)} stations.")

        for end_id in station_ids:
            if start_id == end_id:
                distance_matrix.loc[start_id, end_id] = 0.0
                continue

            start_node = node_map.get(start_id)
            end_node = node_map.get(end_id)

            # Check if nodes were found
            if start_node is None or end_node is None:
                distance_matrix.loc[start_id, end_id] = np.nan
                continue

            try:
                # Calculate shortest path length using the 'length' attribute (in meters)
                length_meters = nx.shortest_path_length(G, start_node, end_node, weight='length')
                distance_matrix.loc[start_id, end_id] = round(length_meters, 2)
            except nx.NetworkXNoPath:
                # This can happen if a station is on an isolated part of the graph
                distance_matrix.loc[start_id, end_id] = float('inf')

    calc_duration = time.time() - start_calc_time
    print(f"Distance calculation completed in {calc_duration / 60:.2f} minutes.")
    return distance_matrix


# ==============================================================================
#                                 CONFIGURATION
# ==============================================================================

CALCULATE_FOR_ALL_STATIONS = True

# --- File Paths ---
CSV_FILE_PATH = 'monthly_demand.csv'

GRAPHML_FILE_PATH = 'london_walk.graphml'

# --- Station Selection (only used if CALCULATE_FOR_ALL_STATIONS is False) ---
sample_station_ids = [959, 960, 961]

# ==============================================================================
#                                  EXECUTION
# ==============================================================================

if __name__ == "__main__":

    try:
        all_stations_df = pd.read_csv(CSV_FILE_PATH)
        all_station_ids = all_stations_df['start_station_number'].tolist()
    except FileNotFoundError:
        print(f"Fatal Error: Cannot find the station file '{CSV_FILE_PATH}' to begin.")
        exit()

    if CALCULATE_FOR_ALL_STATIONS:
        print("--- Mode: Calculate Distance Matrix for ALL Stations ---")
        station_ids_to_process = all_station_ids
    else:
        print("--- Mode: Calculate Distance Matrix for SAMPLE Stations ---")
        station_ids_to_process = sample_station_ids

    final_distance_matrix = calculate_walking_distance_matrix(
        CSV_FILE_PATH,
        GRAPHML_FILE_PATH,
        station_ids_to_process
    )

    # --- Display and Save the final result ---
    if isinstance(final_distance_matrix, pd.DataFrame):
        print("\n" + "=" * 50)
        print("      WALKING DISTANCE MATRIX (meters) - PREVIEW")
        print("=" * 50)

        print(final_distance_matrix.head())
        print("=" * 50)

        # --- Save the matrix to a CSV file ---
        output_filename = "station_walking_distance_matrix.csv"
        print(f"\nSaving the full distance matrix to '{output_filename}'...")
        final_distance_matrix.to_csv(output_filename)
        print("Save complete.")
    else:

        print(f"\nAn error occurred: {final_distance_matrix}")