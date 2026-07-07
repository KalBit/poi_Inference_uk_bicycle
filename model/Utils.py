import numpy as np
import pandas as pd
import numpy as np
from libpysal.weights import KNN, lag_spatial
from esda.moran import Moran
from matplotlib import pyplot as plt
import seaborn as sns


# -------------------------------------------------------------------
# Helper Functions
# -------------------------------------------------------------------

def to_radians(x):
    """
    Convert an angle in degrees to radians
    
    Args:
        x: Angle in degrees 
        
    Returns:
        Angle in radians
    """
    return np.radians(x)

def to_sin(x):
    """
    Apply sin function
    
    Args:
        x: Angle in radians 
        
    Returns:
        Sine of x
    """
    return np.sin(x)

def to_cos(x):
    """
    Apply cos function
    
    Args:
        x: Angle in radians
        
    Returns:
        Cosine of x
    """
    
    return np.cos(x)

def hour_to_sin(x):
       
    return np.sin(2 * np.pi * x / 24.0)

def hour_to_cos(x):
    return np.cos(2 * np.pi * x / 24.0)
    
    
# -------------------------------------------------------------------
# Spatial Functions
# -------------------------------------------------------------------


def calculate_bearing(lat1, lon1, lat2, lon2):
    """
    Calculates the bearing (angle from true North) between two points.
    
    Args:
        lat1, lon1: Coordinates of the origin point.
        lat2, lon2: Coordinates of the destination point.
        
    Returns:
        The bearing in degrees (0 to 360).
    """
    # Convert degrees to radians
    lat1_rad = np.radians(lat1)
    lon1_rad = np.radians(lon1)
    lat2_rad = np.radians(lat2)
    lon2_rad = np.radians(lon2)

    # Calculate the differences in coordinates
    d_lon = lon2_rad - lon1_rad
    
    # Calculate the bearing components (using the formula for initial bearing)
    y = np.sin(d_lon) * np.cos(lat2_rad)
    x = (np.cos(lat1_rad) * np.sin(lat2_rad) - 
         np.sin(lat1_rad) * np.cos(lat2_rad) * np.cos(d_lon))
    
    # Calculate the angle (atan2 returns the angle in radians)
    bearing_rad = np.arctan2(y, x)
    
    # Convert radians to degrees and normalize to 0-360 range
    bearing_deg = np.degrees(bearing_rad)
    return (bearing_deg + 360) % 360

def calculate_haversine_distance(lat1, lon1, lat2, lon2):
    """
    Calculates the great-circle distance between two points on the Earth surface.
    
    Args:
        lat1, lon1: Start point coordinates (scalar or array) in DEGREES
        lat2, lon2: End point coordinates (scalar or array) in DEGREES
        
    Returns:
        Distance in METERS
    """
    # Earth radius in meters
    R = 6371000.0
    
    # Convert degrees to radians
    phi1, phi2 = np.radians(lat1), np.radians(lat2)
    dphi = np.radians(lat2 - lat1)
    dlambda = np.radians(lon2 - lon1)
    
    # Haversine formula
    a = np.sin(dphi / 2.0)**2 + \
        np.cos(phi1) * np.cos(phi2) * \
        np.sin(dlambda / 2.0)**2
    
    c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))
    
    return R * c


def calculate_global_moran(df, resid_col, station_id_col, lat_col, lon_col, k=8, plot=False):
    """
    Aggregates residuals by station, calculates Global Moran's I, and optionally plots a scatterplot.

    Args:
        df: The DataFrame containing residuals and station info.
        resid_col: Name of the residual column.
        station_id_col: Name of the station ID column.
        lat_col: Name of the latitude column.
        lon_col: Name of the longitude column.
        k: Number of nearest neighbors (default 8).
        plot: Boolean, whether to generate the Moran Scatterplot.

    Returns:
        dict: Stats (Moran's I, p-value, etc.)
        DataFrame: Aggregated data with spatial lag info.
    """
    
    # Aggregate residuals by Station
    agg_df = df.groupby(station_id_col).agg({
        resid_col: 'mean',
        lat_col: 'first',
        lon_col: 'first'
    }).reset_index()

    # Create Spatial Weights Matrix
    coords = list(zip(agg_df[lon_col], agg_df[lat_col]))
    w = KNN.from_array(coords, k=k)
    w.transform = 'r' # Row-standardize

    # Calculate Global Moran's I
    y = agg_df[resid_col].values
    moran = Moran(y, w, permutations=999)
    
    if moran.p_sim <= 0.05:
        intepretation = "The residuals are clustered (p <= 0.05)"
    else :
        intepretation = "The residuals are random (p <= 0.05)"

    results = {
        "Moran's I": moran.I,
        "p-value": moran.p_sim,
        "z-score": moran.z_sim,
        "conclusion(p_value)": intepretation
    }
    
    agg_df['residual_std'] = y_std
    agg_df['spatial_lag_std'] = lag_y_std

    return results, agg_df
