from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from typing import List
from app.ml.data.schemas import (
    PredictionInput,
    PredictionOutput,
    BatchPredictionInput,
    BatchPredictionOutput
)
from app.ml.services.inference import InferenceService
from app.ml.training.trainer import ModelTrainer
from app.workers.ml_training_worker import ml_training_worker
import os

router = APIRouter()

# Dependency for InferenceService
def get_inference_service():
    return InferenceService()

@router.post("/predict", response_model=PredictionOutput)
async def predict(
    input_data: PredictionInput,
    service: InferenceService = Depends(get_inference_service)
):
    try:
        return service.predict(input_data)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@router.post("/predict/batch", response_model=BatchPredictionOutput)
async def predict_batch(
    input_data: BatchPredictionInput,
    service: InferenceService = Depends(get_inference_service)
):
    try:
        predictions = service.predict(input_data.data)
        return BatchPredictionOutput(predictions=predictions)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Batch prediction failed: {str(e)}")

@router.post("/train")
async def train_model():
    if ml_training_worker.is_training:
        return {"message": "Training is already in progress"}

    ml_training_worker.start()
    return {
        "message": "Training started in background"
    }

@router.get("/health")
async def ml_health():
    model_path = os.getenv("ML_MODEL_PATH", "app/ml/models/best_model.joblib")
    model_exists = os.path.exists(model_path)
    return {
        "status": "ok",
        "model_loaded": model_exists,
        "model_path": model_path
    }
