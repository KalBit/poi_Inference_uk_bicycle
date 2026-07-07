import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from georegression.weight_model import WeightModel
from sklearn.metrics import r2_score
import pysal.lib
import pysal.explore

# Load the data
try:
    data = pd.read_csv('data/January_m.csv')
except FileNotFoundError:
    print("Error: 'data/January_m.csv' not found. Make sure the script is run from the 'georegression' directory.")
    exit()


# Prepare the data
y = data['count'].values
points = data[['longitude', 'latitude']].values
X = data.drop(['start_station_number', 'count', 'longitude', 'latitude'], axis=1).values

X_plus = np.concatenate([X, points], axis=1)

# Configure and run the model
distance_measure = "euclidean"
kernel_type = "bisquare"

grf_neighbour_count=0.3
grf_n_estimators=50
model = WeightModel(
    RandomForestRegressor(n_estimators=grf_n_estimators, random_state=42),
    distance_measure,
    kernel_type,
    neighbour_count=grf_neighbour_count,
)
model.fit(X_plus, y, [points])
print('STRF R2 Score: ', model.llocv_score_)

# --- Alternative ---
y_predict = model.local_predict_
score = r2_score(y, y_predict)
print('Alternative R2 score:', score)

# Calculate Moran's I for residuals
residuals = y - y_predict

# Create spatial weights matrix (e.g., K-Nearest Neighbors with k=8)
# The number of neighbors (k) is a parameter that might need tuning.
# Let's start with a common value, k=8.
try:
    weights = pysal.lib.weights.KNN.from_array(points, k=8)
    weights.transform = 'r' # Row-standardization

    # Calculate Moran's I
    moran = pysal.explore.esda.Moran(residuals, weights)

    print("\nMoran's I for residuals:")
    print("Moran's I:", moran.I)
    print("p-value:", moran.p_sim)
    print("Z-score:", moran.z_sim)

except Exception as e:
    print(f"\nCould not calculate Moran's I. Error: {e}")
    print("Please ensure 'pysal' is installed in your environment (`pip install pysal`).")
