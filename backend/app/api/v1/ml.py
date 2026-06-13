import asyncio
import logging
import os
from typing import List

from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.domain.user import User, UserRole
from app.domain.greenhouse import Greenhouse
from app.ml.data.schemas import (
    PredictionInput,
    PredictionOutput,
    BatchPredictionInput,
    BatchPredictionOutput
)
from app.ml.services.inference import InferenceService, get_inference_service
from app.repositories.ml import PredictionRepository
from app.schemas.prediction import PredictionRead
from app.workers.ml_training_worker import ml_training_worker

logger = logging.getLogger(__name__)

router = APIRouter()

# Upper bound on a single batch request to prevent CPU/memory exhaustion.
MAX_BATCH_SIZE = 100


@router.post("/predict", response_model=PredictionOutput)
async def predict(
    input_data: PredictionInput,
    service: InferenceService = Depends(get_inference_service),
    current_user: User = Depends(deps.get_current_user),
):
    try:
        # predict() is CPU-bound (pandas + scikit-learn); keep it off the loop.
        return await asyncio.to_thread(service.predict, input_data)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Prediction model is not available")
    except Exception:
        logger.exception("Prediction failed")
        raise HTTPException(status_code=500, detail="Prediction failed")

@router.post("/predict/batch", response_model=BatchPredictionOutput)
async def predict_batch(
    input_data: BatchPredictionInput,
    service: InferenceService = Depends(get_inference_service),
    current_user: User = Depends(deps.get_current_user),
):
    if len(input_data.data) > MAX_BATCH_SIZE:
        raise HTTPException(
            status_code=413,
            detail=f"Batch too large; maximum {MAX_BATCH_SIZE} items per request",
        )
    try:
        predictions = await asyncio.to_thread(service.predict, input_data.data)
        return BatchPredictionOutput(predictions=predictions)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Prediction model is not available")
    except Exception:
        logger.exception("Batch prediction failed")
        raise HTTPException(status_code=500, detail="Batch prediction failed")

@router.post("/train")
async def train_model(
    current_user: User = Depends(deps.check_role([UserRole.ADMIN])),
):
    if ml_training_worker.is_training:
        return {"message": "Training is already in progress"}

    # Manual retrain: force even if a model already exists.
    ml_training_worker.start(force=True)
    return {
        "message": "Training started in background"
    }

@router.get(
    "/predictions/greenhouse/{greenhouse_id}",
    response_model=List[PredictionRead],
)
async def list_greenhouse_predictions(
    greenhouse: Greenhouse = Depends(deps.get_greenhouse_or_404),
    db: AsyncSession = Depends(deps.get_db),
    limit: int = Query(100, ge=1, le=500),
):
    """Historical yield predictions for a greenhouse, newest first.

    Ownership is enforced by get_greenhouse_or_404 (404 for greenhouses the
    caller does not own).
    """
    repo = PredictionRepository(db)
    return await repo.get_by_greenhouse(greenhouse.id, limit=limit)


@router.get("/health")
async def ml_health():
    model_path = os.getenv("ML_MODEL_PATH", "app/ml/models/best_model.joblib")
    model_exists = os.path.exists(model_path)
    return {
        "status": "ok",
        "model_loaded": model_exists,
        "model_path": model_path
    }
