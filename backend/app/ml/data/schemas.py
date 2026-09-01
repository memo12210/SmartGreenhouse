from datetime import date
from typing import Optional, List
from pydantic import BaseModel, Field

class GreenhouseSensorData(BaseModel):
    greenhouse_id: float
    crop_type: str
    variety: str
    planting_date: date
    harvest_date: date
    days_to_maturity: float
    avg_temperature_C: Optional[float] = None
    min_temperature_C: Optional[float] = None
    max_temperature_C: Optional[float] = None
    humidity_percent: Optional[float] = None
    co2_ppm: Optional[float] = None
    light_intensity_lux: Optional[float] = None
    photoperiod_hours: float
    irrigation_mm: float
    fertilizer_N_kg_ha: Optional[float] = None
    fertilizer_P_kg_ha: Optional[float] = None
    fertilizer_K_kg_ha: Optional[float] = None
    pest_severity: Optional[float] = None
    soil_pH: Optional[float] = None

class PredictionInput(GreenhouseSensorData):
    pass

class PredictionOutput(BaseModel):
    yield_kg_per_m2: float
    model_version: str
    prediction_timestamp: str

class BatchPredictionInput(BaseModel):
    data: List[PredictionInput]

class BatchPredictionOutput(BaseModel):
    predictions: List[PredictionOutput]
