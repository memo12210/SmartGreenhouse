import uuid
from typing import List
from sqlalchemy import select
from app.domain.greenhouse import Greenhouse
from app.repositories.base import BaseRepository


class GreenhouseRepository(BaseRepository[Greenhouse]):
    def __init__(self, session):
        super().__init__(Greenhouse, session)

    async def get_by_owner(self, owner_id: uuid.UUID) -> List[Greenhouse]:
        query = select(Greenhouse).where(Greenhouse.owner_id == owner_id)
        result = await self.session.execute(query)
        return list(result.scalars().all())
