import uuid
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import select, delete, or_
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

    async def delete_stale_tokens(self, user_id: uuid.UUID):
        """Remove a user's expired or already-revoked refresh tokens so the
        table does not grow without bound across repeated logins/rotations."""
        query = delete(RefreshToken).where(
            RefreshToken.user_id == user_id,
            or_(
                RefreshToken.is_revoked.is_(True),
                RefreshToken.expires_at < datetime.now(timezone.utc),
            ),
        )
        await self.session.execute(query)
        await self.session.flush()
