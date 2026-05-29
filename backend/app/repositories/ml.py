import uuid
from typing import List
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
from app.domain.ml import Prediction

class PredictionRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, prediction: Prediction) -> Prediction:
        self.session.add(prediction)
        await self.session.flush()
        return prediction

    async def get_by_greenhouse(
        self,
        greenhouse_id: uuid.UUID,
        limit: int = 100
    ) -> List[Prediction]:
        query = (
            select(Prediction)
            .where(Prediction.greenhouse_id == greenhouse_id)
            .order_by(desc(Prediction.timestamp))
            .limit(limit)
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())
