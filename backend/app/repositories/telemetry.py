import uuid
from datetime import datetime
from typing import List, Optional
from sqlalchemy import select, and_, desc
from sqlalchemy.ext.asyncio import AsyncSession
from app.domain.telemetry import Telemetry


class TelemetryRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, telemetry: Telemetry) -> Telemetry:
        self.session.add(telemetry)
        await self.session.flush()
        return telemetry

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
