import uuid
from datetime import datetime
from typing import List, Optional
from sqlalchemy import select, and_, desc
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from app.domain.telemetry import Telemetry


class TelemetryRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, telemetry: Telemetry) -> Optional[Telemetry]:
        # Telemetry's primary key is (timestamp, device_id); duplicate delivery
        # (MQTT QoS-1 redelivery, device retransmit) would otherwise raise an
        # IntegrityError that aborts the whole ingest transaction. Wrap the insert
        # in a SAVEPOINT so a duplicate is a no-op that returns None instead of
        # poisoning the surrounding transaction.
        try:
            async with self.session.begin_nested():
                self.session.add(telemetry)
                await self.session.flush()
            return telemetry
        except IntegrityError:
            return None

    async def create_bulk(self, telemetry_list: List[Telemetry]):
        self.session.add_all(telemetry_list)
        await self.session.flush()

    async def get_by_device(
        self,
        device_id: uuid.UUID,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        limit: int = 100
    ) -> List[Telemetry]:
        query = select(Telemetry).where(Telemetry.device_id == device_id)

        if start_time:
            query = query.where(Telemetry.timestamp >= start_time)
        if end_time:
            query = query.where(Telemetry.timestamp <= end_time)

        query = query.order_by(desc(Telemetry.timestamp)).limit(limit)

        result = await self.session.execute(query)
        return list(result.scalars().all())

    async def get_aggregated_metrics(
        self,
        greenhouse_id: uuid.UUID,
        start_time: datetime,
        end_time: datetime
    ) -> dict:
        from sqlalchemy import func
        from app.domain.device import Device

        query = (
            select(
                func.avg(Telemetry.temperature).label("avg_temp"),
                func.min(Telemetry.temperature).label("min_temp"),
                func.max(Telemetry.temperature).label("max_temp"),
                func.avg(Telemetry.humidity).label("avg_humidity"),
                func.avg(Telemetry.co2).label("avg_co2"),
                func.avg(Telemetry.light_intensity).label("avg_light")
            )
            .join(Device, Telemetry.device_id == Device.id)
            .where(Device.greenhouse_id == greenhouse_id)
            .where(Telemetry.timestamp >= start_time)
            .where(Telemetry.timestamp <= end_time)
        )

        result = await self.session.execute(query)
        row = result.first()

        if not row or row.avg_temp is None:
            return {}

        return {
            "avg_temperature_C": float(row.avg_temp),
            "min_temperature_C": float(row.min_temp),
            "max_temperature_C": float(row.max_temp),
            "humidity_percent": float(row.avg_humidity),
            "co2_ppm": float(row.avg_co2),
            "light_intensity_lux": float(row.avg_light)
        }
