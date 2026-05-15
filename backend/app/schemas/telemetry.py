from typing import Optional
from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime

# Shared properties
class TelemetryBase(BaseModel):
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    light: Optional[float] = None
    soil_moisture: Optional[float] = None

# Properties to return via API
class Telemetry(TelemetryBase):
    id: UUID
    device_id: UUID
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)
