import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score, KFold
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
import matplotlib.pyplot as plt
import seaborn as sns
import warnings

warnings.filterwarnings('ignore')


class SpatialRandomForestModel:
    def __init__(self, n_estimators=100, max_depth=None, min_samples_leaf=2, random_state=42):
        self.n_estimators = n_estimators
        self.max_depth = max_depth
        self.min_samples_leaf = min_samples_leaf
        self.random_state = random_state
        self.model = None
        self.preprocessor = None
        self.feature_names = None

    def prepare_features(self, df):
        data = df.copy()

        spatial_features = ['longitude', 'latitude']

        poi_features = [
            'cafe_count_5min_walk', 'atm_count_5min_walk', 'pub_count_5min_walk',
            'school_count_5min_walk', 'university_count_5min_walk', 'college_count_5min_walk',
            'bank_count_5min_walk', 'post_office_count_5min_walk', 'library_count_5min_walk',
            'cinema_count_5min_walk', 'supermarket_count_5min_walk', 'station_count_5min_walk',
            'platform_count_5min_walk', 'stop_position_count_5min_walk',
            'railway_station_count_5min_walk', 'tram_stop_count_5min_walk',
            'railway_halt_count_5min_walk', 'highway_bus_stop_count_5min_walk'
        ]

        temporal_numeric = ['s_hour', 'week_of_the_month', 'day_of_week']
        temporal_categorical = ['time_of_day', 'peak_off_peak', 'weekday_or_weekend_sdate']

        if 's_date' in data.columns:
            data['s_date'] = pd.to_datetime(data['s_date'])
            data['month'] = data['s_date'].dt.month
            data['day_of_year'] = data['s_date'].dt.dayofyear
            temporal_numeric.extend(['month', 'day_of_year'])

        numeric_features = spatial_features + poi_features + temporal_numeric

        numeric_transformer = StandardScaler()
        categorical_transformer = OneHotEncoder(drop='first', sparse_output=False)

        self.preprocessor = ColumnTransformer(
            transformers=[
                ('num', numeric_transformer, numeric_features),
                ('cat', categorical_transformer, temporal_categorical)
            ]
        )

        self.numeric_features = numeric_features
        self.categorical_features = temporal_categorical

        return data

    def fit(self, X, y):
        X_processed = self.prepare_features(X)
        feature_columns = (self.numeric_features + self.categorical_features)
        X_features = X_processed[feature_columns]

        self.model = Pipeline([
            ('preprocessor', self.preprocessor),
            ('regressor', RandomForestRegressor(
                n_estimators=self.n_estimators,
                max_depth=self.max_depth,
                min_samples_leaf=self.min_samples_leaf,
                random_state=self.random_state,
                n_jobs=-1
            ))
        ])

        self.model.fit(X_features, y)

        try:
            cat_feature_names = []
            if hasattr(self.preprocessor.named_transformers_['cat'], 'get_feature_names_out'):
                cat_feature_names = list(
                    self.preprocessor.named_transformers_['cat'].get_feature_names_out(self.categorical_features))

            self.feature_names = self.numeric_features + cat_feature_names
        except:
            self.feature_names = [f'feature_{i}' for i in
                                  range(len(self.numeric_features) + len(self.categorical_features))]

        return self

    def predict(self, X):
        X_processed = self.prepare_features(X)
        feature_columns = (self.numeric_features + self.categorical_features)
        X_features = X_processed[feature_columns]
        return self.model.predict(X_features)

    def get_feature_importance(self):
        if self.model is None:
            raise ValueError("Model must be fitted first")

        importance = self.model.named_steps['regressor'].feature_importances_

        importance_df = pd.DataFrame({
            'feature': self.feature_names[:len(importance)],
            'importance': importance
        }).sort_values('importance', ascending=False)

        return importance_df

    def plot_feature_importance(self, top_n=20):
        importance_df = self.get_feature_importance().head(top_n)

        plt.figure(figsize=(12, 8))
        sns.barplot(data=importance_df, x='importance', y='feature', palette='viridis')
        plt.title(f'Top {top_n} Feature Importance')
        plt.xlabel('Feature Importance')
        plt.ylabel('Features')
        plt.tight_layout()
        plt.show()

        return importance_df

    def evaluate_model(self, X_test, y_test):
        y_pred = self.predict(X_test)

        mse = mean_squared_error(y_test, y_pred)
        rmse = np.sqrt(mse)
        mae = mean_absolute_error(y_test, y_pred)
        r2 = r2_score(y_test, y_pred)
        mape = np.mean(np.abs((y_test - y_pred) / np.maximum(y_test, 1))) * 100

        print("=== Model Evaluation ===")
        print(f"R² Score: {r2:.4f}")
        print(f"RMSE: {rmse:.4f}")
        print(f"MAE: {mae:.4f}")
        print(f"MAPE: {mape:.2f}%")

        plt.figure(figsize=(12, 5))

        plt.subplot(1, 2, 1)
        plt.scatter(y_test, y_pred, alpha=0.6, color='blue')
        min_val = min(min(y_test), min(y_pred))
        max_val = max(max(y_test), max(y_pred))
        plt.plot([min_val, max_val], [min_val, max_val], 'r--', lw=2)
        plt.xlabel('Actual Count')
        plt.ylabel('Predicted Count')
        plt.title('Actual vs Predicted')
        plt.grid(True, alpha=0.3)

        plt.subplot(1, 2, 2)
        residuals = y_test - y_pred
        plt.scatter(y_pred, residuals, alpha=0.6, color='green')
        plt.axhline(y=0, color='r', linestyle='--')
        plt.xlabel('Predicted Count')
        plt.ylabel('Residuals')
        plt.title('Residuals Plot')
        plt.grid(True, alpha=0.3)

        plt.tight_layout()
        plt.show()

        return {
            'r2_score': r2,
            'rmse': rmse,
            'mae': mae,
            'mape': mape,
            'predictions': y_pred,
            'residuals': residuals
        }

    def cross_validation(self, X, y, cv_folds=5):
        X_processed = self.prepare_features(X)
        feature_columns = (self.numeric_features + self.categorical_features)
        X_features = X_processed[feature_columns]

        kf = KFold(n_splits=cv_folds, shuffle=True, random_state=self.random_state)

        cv_r2_scores = cross_val_score(self.model, X_features, y, cv=kf, scoring='r2')
        cv_rmse_scores = -cross_val_score(self.model, X_features, y, cv=kf, scoring='neg_root_mean_squared_error')

        print("=== Cross-Validation Results ===")
        print(f"R² Score: {cv_r2_scores.mean():.4f} (+/- {cv_r2_scores.std() * 2:.4f})")
        print(f"RMSE: {cv_rmse_scores.mean():.4f} (+/- {cv_rmse_scores.std() * 2:.4f})")

        return cv_r2_scores, cv_rmse_scores


# Load your dataset
df = pd.read_csv('data/dataset.csv')
print(f"Dataset shape: {df.shape}")
print(f"Target stats - Mean: {df['count'].mean():.2f}, Std: {df['count'].std():.2f}")

# Prepare features and target
X = df.drop(['count', 'cluster', 'start_station_number'], axis=1, errors='ignore')
y = df['count']

# 80/20 split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

print(f"Training set: {X_train.shape}")
print(f"Test set: {X_test.shape}")

# Train model
model = SpatialRandomForestModel(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Evaluate
results = model.evaluate_model(X_test, y_test)

# Feature importance
importance_df = model.plot_feature_importance(top_n=15)
print("\nTop 10 Features:")
print(importance_df.head(10))

# Cross-validation
cv_r2, cv_rmse = model.cross_validation(X_train, y_train, cv_folds=5)