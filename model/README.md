# uk-bike

2 Main inputs:

1. Feature matrix X – conditions at each station or location [Shape: (n_samples, n_features)]

| Hour | Day | Temp (°C) | Humidity (%) | Wind (km/h) | IsWeekend | AvgTripsPastHour | DistToCenter (km) | BikesAvailableNow |
|------|-----|-----------|---------------|-------------|-----------|------------------|--------------------|--------------------|
| 8    | 0   | 16        | 80            | 10          | 0         | 22               | 1.2                | 10                 |
| 9    | 0   | 18        | 75            | 8           | 0         | 30               | 2.1                | 7                  |
| 17   | 1   | 23        | 60            | 12          | 0         | 44               | 0.5                | 4                  |
| 14   | 5   | 27        | 55            | 5           | 1         | 12               | 3.0                | 15                 |
| 18   | 6   | 21        | 70            | 7           | 1         | 33               | -                  | -                  |


```python
    X = np.array([
        [8, 0, 16, 80, 10, 0, 22, 1.2, 10],
        [9, 0, 18, 75, 8, 0, 30, 2.1, 7],
        [17, 1, 23, 60, 12, 0, 44, 0.5, 4],
        [14, 5, 27, 55, 5, 1, 12, 3.0, 15],
        [18, 6, 21, 70, 7, 1, 33, 0.9, 3]
    ])
```

2.  Coordinate matrix coords – latitude & longitude [Shape: (n_samples, 2)]
```python
    coords = [
        [51.5074, -0.1278],  # station 0
        [51.5155, -0.0922],  # station 1
        ]
```

3. Target Vector Y - bike availability at each station [Shape: (n_samples,)]
```python
    Y = [100, 50]  # biks needed at each station
```

Fitting : 
```python
    
    model = SpatialRandomForest(n_estimators=3, max_depth=6)
    model.fit(X, y, coords)
    
    #
    X_new = np.array([[10, 0, 17, 72, 9, 0, 20, 0.5, 8]])  # 1 row, same shape as X
    coord_new = np.array([[40.7300, -74.0000]])
    
    pred = model.predict(X_new, coord_new)
    print(f"Predicted bikes needed: {pred[0]:.0f}")

    # distance matrices (Geographically Weighted Regression (GWR), Kriging, or Spatial Autocorrelation)
    
    dist_matrix = cdist(coords, coords, metric='euclidean')
    avg_distances = dist_matrix.mean(axis=1).reshape(-1, 1)
    
    # add to X
    X = np.hstack([X_base, avg_distances])
```