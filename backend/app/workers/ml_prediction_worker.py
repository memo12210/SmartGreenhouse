import asyncio
import logging
from datetime import datetime, timedelta, timezone
from app.infrastructure.database import SessionLocal
from app.repositories.greenhouse import GreenhouseRepository
from app.repositories.telemetry import TelemetryRepository
from app.repositories.ml import PredictionRepository
from app.services.ml import MLPredictionService
from app.ml.services.inference import InferenceService

logger = logging.getLogger(__name__)

class MLPredictionWorker:
    def __init__(self, interval_seconds: int = 120):
        self.interval_seconds = interval_seconds
        self._task = None

    async def run_periodic_predictions(self):
        logger.info(f"ML Prediction Worker started with interval {self.interval_seconds}s")
        while True:
            try:
                end_time = datetime.now(timezone.utc)
                start_time = end_time - timedelta(seconds=self.interval_seconds)

                async with SessionLocal() as db:
                    greenhouse_repo = GreenhouseRepository(db)
                    telemetry_repo = TelemetryRepository(db)
                    prediction_repo = PredictionRepository(db)
                    inference_service = InferenceService()

                    ml_service = MLPredictionService(
                        prediction_repo=prediction_repo,
                        telemetry_repo=telemetry_repo,
                        greenhouse_repo=greenhouse_repo,
                        inference_service=inference_service
                    )

                    # Get all greenhouses
                    greenhouses = await greenhouse_repo.get_multi(limit=100)

                    for greenhouse in greenhouses:
                        prediction = await ml_service.run_prediction_for_greenhouse(
                            greenhouse.id, start_time, end_time
                        )
                        if prediction:
                            logger.info(f"Generated prediction for greenhouse {greenhouse.id}: {prediction.yield_kg_per_m2} kg/m2")

                    await db.commit()

            except Exception as e:
                logger.error(f"Error in ML Prediction Worker loop: {e}")

            await asyncio.sleep(self.interval_seconds)

    def start(self):
        if self._task is None:
            self._task = asyncio.create_task(self.run_periodic_predictions())
            logger.info("ML Prediction Worker task created")

ml_prediction_worker = MLPredictionWorker()
