import uuid
from datetime import datetime
from typing import List, Optional
from app.domain.telemetry import Telemetry
from app.repositories.telemetry import TelemetryRepository
from app.schemas.telemetry import TelemetryCreate


class TelemetryService:
    def __init__(self, telemetry_repo: TelemetryRepository):
        self.telemetry_repo = telemetry_repo

    async def ingest_telemetry(self, telemetry_in: TelemetryCreate) -> Telemetry:
        telemetry = Telemetry(
            device_id=telemetry_in.device_id,
            timestamp=telemetry_in.timestamp,
            temperature=telemetry_in.temperature,
            humidity=telemetry_in.humidity,
            soil_moisture=telemetry_in.soil_moisture,
            light_intensity=telemetry_in.light_intensity,
            co2=telemetry_in.co2,
            battery_level=telemetry_in.battery_level
        )
        return await self.telemetry_repo.create(telemetry)

    async def get_device_telemetry(
        self,
        device_id: uuid.UUID,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        limit: int = 100
    ) -> List[Telemetry]:
        return await self.telemetry_repo.get_by_device(device_id, start_time, end_time, limit)
