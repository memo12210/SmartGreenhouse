import uuid
from typing import Optional
from sqlalchemy import select
from app.domain.user import User, RefreshToken
from app.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    def __init__(self, session):
        super().__init__(User, session)

    async def get_by_email(self, email: str) -> Optional[User]:
        query = select(User).where(User.email == email)
        result = await self.session.execute(query)
        return result.scalar_one_or_none()


class RefreshTokenRepository(BaseRepository[RefreshToken]):
    def __init__(self, session):
        super().__init__(RefreshToken, session)

    async def get_by_token(self, token: str) -> Optional[RefreshToken]:
        query = select(RefreshToken).where(RefreshToken.token == token)
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def revoke_user_tokens(self, user_id: uuid.UUID):
        from sqlalchemy import update
        query = update(RefreshToken).where(RefreshToken.user_id == user_id).values(is_revoked=True)
        await self.session.execute(query)
        await self.session.flush()
