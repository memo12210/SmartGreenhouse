import pytest
from app.ml.services.inference import InferenceService
from app.ml.data.schemas import PredictionInput
from datetime import date
import os

@pytest.fixture
def inference_service():
    return InferenceService()

def test_inference_service_initialization(inference_service):
    assert inference_service.version == "v1.0.0"
    assert inference_service.feature_pipeline is not None

def test_predict_single(inference_service):
    # Ensure model exists
    model_path = os.getenv("ML_MODEL_PATH", "app/ml/models/best_model.joblib")
    if not os.path.exists(model_path):
        pytest.skip("Model not found, skipping inference test")

    sample_input = PredictionInput(
        greenhouse_id=1.0,
        crop_type="Tomato",
        variety="Beefsteak",
        planting_date=date(2023, 11, 2),
        harvest_date=date(2024, 1, 8),
        days_to_maturity=67.0,
        avg_temperature_C=27.6,
        min_temperature_C=25.8,
        max_temperature_C=30.6,
        humidity_percent=73.6,
        co2_ppm=917.0,
        light_intensity_lux=16821.0,
        photoperiod_hours=10.0,
        irrigation_mm=9.8,
        fertilizer_N_kg_ha=167.0,
        fertilizer_P_kg_ha=74.0,
        fertilizer_K_kg_ha=154.0,
        pest_severity=1.3,
        soil_pH=6.1
    )

    result = inference_service.predict(sample_input)
    assert result.yield_kg_per_m2 > 0
    assert result.model_version == "v1.0.0"
