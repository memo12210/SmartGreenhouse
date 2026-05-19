import uuid
from typing import List
from sqlalchemy import select
from app.domain.alert import Alert
from app.repositories.base import BaseRepository


class AlertRepository(BaseRepository[Alert]):
    def __init__(self, session):
        super().__init__(Alert, session)

    async def get_by_greenhouse(self, greenhouse_id: uuid.UUID) -> List[Alert]:
        query = select(Alert).where(Alert.greenhouse_id == greenhouse_id)
        result = await self.session.execute(query)
        return list(result.scalars().all())

    async def get_unacknowledged_by_greenhouse(self, greenhouse_id: uuid.UUID) -> List[Alert]:
        query = select(Alert).where(
            Alert.greenhouse_id == greenhouse_id,
            Alert.is_acknowledged == False
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())
