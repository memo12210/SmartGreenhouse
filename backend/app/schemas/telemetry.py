import uuid
from datetime import datetime, timezone
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class TelemetryBase(BaseModel):
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    soil_moisture: Optional[float] = None
    light_intensity: Optional[float] = None
    co2: Optional[float] = None
    battery_level: Optional[float] = None


class TelemetryCreate(TelemetryBase):
    device_id: uuid.UUID
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class TelemetryRead(TelemetryBase):
    device_id: uuid.UUID
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)
