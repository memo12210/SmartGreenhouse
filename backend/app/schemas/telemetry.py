import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator


# Allowed clock skew for device-supplied timestamps before a reading is rejected.
MAX_FUTURE_SKEW = timedelta(minutes=5)


class TelemetryBase(BaseModel):
    # Physically plausible bounds reject obviously-bad sensor data (e.g. a stuck
    # sensor reporting -9999) before it can drive alerts or pollute the model.
    temperature: Optional[float] = Field(default=None, ge=-50, le=100)       # deg C
    humidity: Optional[float] = Field(default=None, ge=0, le=100)            # %
    soil_moisture: Optional[float] = Field(default=None, ge=0, le=100)       # %
    light_intensity: Optional[float] = Field(default=None, ge=0, le=200000)  # lux/percent
    co2: Optional[float] = Field(default=None, ge=0, le=50000)               # ppm
    battery_level: Optional[float] = Field(default=None, ge=0, le=100)       # %


class TelemetryCreate(TelemetryBase):
    device_id: uuid.UUID
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

    @field_validator("timestamp")
    @classmethod
    def normalize_timestamp(cls, v: datetime) -> datetime:
        # Treat naive timestamps as UTC so the hypertable never mixes tz-aware
        # and tz-naive values.
        if v.tzinfo is None:
            v = v.replace(tzinfo=timezone.utc)
        # Reject readings from too far in the future (device clock badly skewed).
        if v > datetime.now(timezone.utc) + MAX_FUTURE_SKEW:
            raise ValueError("timestamp is too far in the future")
        return v


class TelemetryRead(TelemetryBase):
    device_id: uuid.UUID
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)
