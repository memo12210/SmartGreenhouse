import uuid
from typing import List, Optional

from sqlalchemy import select

from app.domain.fcm_token import FcmToken
from app.repositories.base import BaseRepository


class FcmTokenRepository(BaseRepository[FcmToken]):
    def __init__(self, session):
        super().__init__(FcmToken, session)

    async def get_by_token(self, token: str) -> Optional[FcmToken]:
        query = select(FcmToken).where(FcmToken.token == token)
        result = await self.session.execute(query)
        return result.scalars().first()

    async def get_active_by_user(self, user_id: uuid.UUID) -> List[FcmToken]:
        query = select(FcmToken).where(
            FcmToken.user_id == user_id,
            FcmToken.is_active == True,
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())