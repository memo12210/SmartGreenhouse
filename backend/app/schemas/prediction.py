import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict


class PredictionRead(BaseModel):
    id: uuid.UUID
    greenhouse_id: uuid.UUID
    yield_kg_per_m2: float
    model_version: str
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)
