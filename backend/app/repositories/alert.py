import uuid
from typing import List

from sqlalchemy import desc, select

from app.domain.alert import Alert, AlertRule
from app.repositories.base import BaseRepository


class AlertRepository(BaseRepository[Alert]):
    def __init__(self, session):
        super().__init__(Alert, session)

    async def get_by_greenhouse(self, greenhouse_id: uuid.UUID) -> List[Alert]:
        query = (
            select(Alert)
            .where(Alert.greenhouse_id == greenhouse_id)
            .order_by(desc(Alert.created_at))
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())

    async def get_unacknowledged_by_greenhouse(
        self,
        greenhouse_id: uuid.UUID,
    ) -> List[Alert]:
        query = (
            select(Alert)
            .where(
                Alert.greenhouse_id == greenhouse_id,
                Alert.is_acknowledged == False,
            )
            .order_by(desc(Alert.created_at))
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())

    async def get_unacknowledged_by_device_and_type(
        self,
        device_id: uuid.UUID,
        alert_type: str,
    ) -> List[Alert]:
        query = select(Alert).where(
            Alert.device_id == device_id,
            Alert.alert_type == alert_type,
            Alert.is_acknowledged == False,
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())


class AlertRuleRepository(BaseRepository[AlertRule]):
    def __init__(self, session):
        super().__init__(AlertRule, session)

    async def get_by_device(self, device_id: uuid.UUID) -> List[AlertRule]:
        query = select(AlertRule).where(AlertRule.device_id == device_id)
        result = await self.session.execute(query)
        return list(result.scalars().all())

    async def get_enabled_by_device(self, device_id: uuid.UUID) -> List[AlertRule]:
        query = select(AlertRule).where(
            AlertRule.device_id == device_id,
            AlertRule.is_enabled == True,
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())