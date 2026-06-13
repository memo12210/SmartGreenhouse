import uuid
import logging
from datetime import datetime, timezone, date
from typing import Optional

from app.repositories.ml import PredictionRepository
from app.repositories.telemetry import TelemetryRepository
from app.repositories.greenhouse import GreenhouseRepository
from app.ml.services.inference import InferenceService
from app.ml.data.schemas import PredictionInput
from app.domain.ml import Prediction

logger = logging.getLogger(__name__)

class MLPredictionService:
    # Constants from dataset averages
    PHOTOPERIOD_HOURS = 12.46
    IRRIGATION_MM = 7.00
    PEST_SEVERITY = 1.81
    SOIL_PH = 6.32

    def __init__(
        self,
        prediction_repo: PredictionRepository,
        telemetry_repo: TelemetryRepository,
        greenhouse_repo: GreenhouseRepository,
        inference_service: InferenceService
    ):
        self.prediction_repo = prediction_repo
        self.telemetry_repo = telemetry_repo
        self.greenhouse_repo = greenhouse_repo
        self.inference_service = inference_service

    async def run_prediction_for_greenhouse(
        self,
        greenhouse_id: uuid.UUID,
        start_time: datetime,
        end_time: datetime
    ) -> Optional[Prediction]:
        try:
            # 1. Get Greenhouse metadata
            greenhouse = await self.greenhouse_repo.get(greenhouse_id)
            if not greenhouse:
                logger.warning(f"Greenhouse {greenhouse_id} not found for prediction")
                return None

            metadata = greenhouse.extra_metadata

            # Required metadata fields
            try:
                crop_type = metadata["crop_type"]
                variety = metadata["variety"]
                planting_date_str = metadata["planting_date"]
                harvest_date_str = metadata["harvest_date"]

                # Fertilizer fields
                fertilizer_n = float(metadata.get("fertilizer_N_kg_ha", 0))
                fertilizer_p = float(metadata.get("fertilizer_P_kg_ha", 0))
                fertilizer_k = float(metadata.get("fertilizer_K_kg_ha", 0))

                planting_date = date.fromisoformat(planting_date_str)
                harvest_date = date.fromisoformat(harvest_date_str)
                days_to_maturity = float((harvest_date - planting_date).days)
            except (KeyError, ValueError) as e:
                logger.error(f"Missing or invalid metadata for greenhouse {greenhouse_id}: {e}")
                return None

            # 2. Get Aggregated Telemetry
            metrics = await self.telemetry_repo.get_aggregated_metrics(greenhouse_id, start_time, end_time)
            if not metrics:
                logger.debug(f"No telemetry data for greenhouse {greenhouse_id} in period {start_time} to {end_time}")
                return None

            # 3. Prepare Prediction Input
            prediction_input = PredictionInput(
                # Stable numerical id derived from the UUID. Python's hash() is
                # salted per-process (PYTHONHASHSEED), so it would yield a
                # different feature value after every restart.
                greenhouse_id=float(greenhouse_id.int % 10**8),
                crop_type=crop_type,
                variety=variety,
                planting_date=planting_date,
                harvest_date=harvest_date,
                days_to_maturity=days_to_maturity,
                avg_temperature_C=metrics["avg_temperature_C"],
                min_temperature_C=metrics["min_temperature_C"],
                max_temperature_C=metrics["max_temperature_C"],
                humidity_percent=metrics["humidity_percent"],
                co2_ppm=metrics["co2_ppm"],
                light_intensity_lux=metrics["light_intensity_lux"],
                photoperiod_hours=self.PHOTOPERIOD_HOURS,
                irrigation_mm=self.IRRIGATION_MM,
                fertilizer_N_kg_ha=fertilizer_n,
                fertilizer_P_kg_ha=fertilizer_p,
                fertilizer_K_kg_ha=fertilizer_k,
                pest_severity=self.PEST_SEVERITY,
                soil_pH=self.SOIL_PH
            )

            # 4. Run Inference
            result = self.inference_service.predict(prediction_input)

            # 5. Save Prediction
            prediction = Prediction(
                greenhouse_id=greenhouse_id,
                yield_kg_per_m2=result.yield_kg_per_m2,
                model_version=result.model_version,
                timestamp=datetime.now(timezone.utc)
            )

            return await self.prediction_repo.create(prediction)

        except Exception as e:
            logger.error(f"Error running prediction for greenhouse {greenhouse_id}: {e}")
            return None
