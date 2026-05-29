import pandas as pd
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.impute import SimpleImputer

class FeaturePipeline:
    def __init__(self):
        self.numeric_cols = [
            "greenhouse_id",
            "days_to_maturity",
            "avg_temperature_C",
            "min_temperature_C",
            "max_temperature_C",
            "humidity_percent",
            "co2_ppm",
            "light_intensity_lux",
            "photoperiod_hours",
            "irrigation_mm",
            "fertilizer_N_kg_ha",
            "fertilizer_P_kg_ha",
            "fertilizer_K_kg_ha",
            "pest_severity",
            "soil_pH",
        ]
        self.categorical_cols = [
            "crop_type",
            "variety",
            "planting_date",
            "harvest_date",
        ]

    def get_preprocessor(self) -> ColumnTransformer:
        numeric_pipeline = Pipeline([
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler())
        ])

        categorical_pipeline = Pipeline([
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("encoder", OneHotEncoder(handle_unknown="ignore"))
        ])

        preprocessor = ColumnTransformer([
            ("num", numeric_pipeline, self.numeric_cols),
            ("cat", categorical_pipeline, self.categorical_cols)
        ])

        return preprocessor

    def transform_input(self, data: pd.DataFrame) -> pd.DataFrame:
        """
        Ensure dates are strings as expected by the encoder if they are objects.
        """
        for col in self.categorical_cols:
            if col in data.columns:
                data[col] = data[col].astype(str)
        return data
