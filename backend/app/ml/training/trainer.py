import os
import pandas as pd
import numpy as np
import mlflow
import mlflow.sklearn
import joblib
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from app.ml.features.pipeline import FeaturePipeline

class ModelTrainer:
    def __init__(self, experiment_name: str = "Greenhouse_Yield_Prediction"):
        self.experiment_name = experiment_name
        self.feature_pipeline = FeaturePipeline()
        mlflow.set_experiment(self.experiment_name)

    def load_data(self, data_path: str) -> pd.DataFrame:
        if not os.path.exists(data_path):
            raise FileNotFoundError(f"Data file not found at {data_path}")
        return pd.read_csv(data_path)

    def train(self, data_path: str, model_save_path: str = None):
        if model_save_path is None:
            # Default to backend/app/ml/models/best_model.joblib
            current_file_path = os.path.abspath(__file__)
            # training/trainer.py -> ml/models/best_model.joblib
            ml_dir = os.path.dirname(os.path.dirname(current_file_path))
            model_save_path = os.path.join(ml_dir, "models", "best_model.joblib")
        else:
            model_save_path = os.path.abspath(model_save_path)

        df = self.load_data(data_path)
        TARGET = "yield_kg_per_m2"

        X = df.drop(columns=[TARGET])
        y = df[TARGET]

        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )

        preprocessor = self.feature_pipeline.get_preprocessor()

        model = GradientBoostingRegressor(random_state=42)

        pipeline = Pipeline([
            ("preprocessor", preprocessor),
            ("model", model)
        ])

        with mlflow.start_run():
            # Log parameters
            mlflow.log_param("model_type", "GradientBoostingRegressor")
            mlflow.log_param("test_size", 0.2)
            mlflow.log_param("random_state", 42)

            # Fit model
            pipeline.fit(X_train, y_train)

            # Evaluate
            y_pred = pipeline.predict(X_test)
            mae = mean_absolute_error(y_test, y_pred)
            rmse = np.sqrt(mean_squared_error(y_test, y_pred))
            r2 = r2_score(y_test, y_pred)

            # Log metrics
            mlflow.log_metric("mae", mae)
            mlflow.log_metric("rmse", rmse)
            mlflow.log_metric("r2", r2)

            # Log model
            mlflow.sklearn.log_model(pipeline, "model")

            # Save locally for inference service
            os.makedirs(os.path.dirname(model_save_path), exist_ok=True)
            joblib.dump(pipeline, model_save_path)

            print(f"Model trained and saved to {model_save_path}")
            print(f"Metrics: MAE={mae:.4f}, RMSE={rmse:.4f}, R2={r2:.4f}")

        return pipeline
