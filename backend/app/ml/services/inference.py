import os
import joblib
import pandas as pd
from datetime import datetime
from typing import List, Optional, Union
from app.ml.data.schemas import PredictionInput, PredictionOutput
from app.ml.features.pipeline import FeaturePipeline

class InferenceService:
    def __init__(self, model_path: str = None):
        self.model_path = model_path or os.getenv("ML_MODEL_PATH", "app/ml/models/best_model.joblib")
        self.model = None
        self.version = "v1.0.0" # Placeholder for versioning logic
        self.feature_pipeline = FeaturePipeline()

    def _load_model(self):
        if self.model is None:
            if os.path.exists(self.model_path):
                self.model = joblib.load(self.model_path)
            else:
                raise FileNotFoundError(f"Model file not found at {self.model_path}. Please run training first.")

    def predict(self, input_data: Union[PredictionInput, List[PredictionInput]]) -> Union[PredictionOutput, List[PredictionOutput]]:
        self._load_model()

        if isinstance(input_data, PredictionInput):
            data_list = [input_data.model_dump()]
            single_prediction = True
        else:
            data_list = [item.model_dump() for item in input_data]
            single_prediction = False

        df = pd.DataFrame(data_list)
        df = self.feature_pipeline.transform_input(df)

        predictions = self.model.predict(df)

        results = []
        timestamp = datetime.now().isoformat()
        for pred in predictions:
            results.append(PredictionOutput(
                yield_kg_per_m2=float(pred),
                model_version=self.version,
                prediction_timestamp=timestamp
            ))

        return results[0] if single_prediction else results


# Module-level singleton: the model is loaded from disk once (lazily on first
# predict) and reused across requests/workers instead of re-reading the joblib
# file on every call.
_inference_service: Optional[InferenceService] = None


def get_inference_service() -> InferenceService:
    global _inference_service
    if _inference_service is None:
        _inference_service = InferenceService()
    return _inference_service
