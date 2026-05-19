from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple
from jose import jwt, JWTError
from app.domain.user import User, RefreshToken
from app.repositories.user import UserRepository, RefreshTokenRepository
from app.core.security import verify_password, create_access_token, create_refresh_token
from app.core.config import settings
from app.schemas.user import Token


class AuthService:
    def __init__(self, user_repo: UserRepository, token_repo: RefreshTokenRepository):
        self.user_repo = user_repo
        self.token_repo = token_repo

    async def authenticate(self, email: str, password: str) -> Optional[User]:
        user = await self.user_repo.get_by_email(email)
        if not user or not verify_password(password, user.hashed_password):
            return None
        return user

    async def create_tokens(self, user: User) -> Token:
        access_token = create_access_token(user.id)
        refresh_token_str = create_refresh_token(user.id)

        # Save refresh token to DB
        expires_at = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
        db_token = RefreshToken(
            token=refresh_token_str,
            user_id=user.id,
            expires_at=expires_at
        )
        await self.token_repo.create(db_token)
        await self.token_repo.commit()

        return Token(
            access_token=access_token,
            refresh_token=refresh_token_str,
            token_type="bearer"
        )

    async def refresh_access_token(self, refresh_token_str: str) -> Optional[Token]:
        try:
            payload = jwt.decode(refresh_token_str, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            user_id = payload.get("sub")
            if not user_id or payload.get("type") != "refresh":
                return None
        except JWTError:
            return None

        db_token = await self.token_repo.get_by_token(refresh_token_str)
        if not db_token or db_token.is_revoked or db_token.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
            return None

        user = await self.user_repo.get(uuid.UUID(user_id))
        if not user:
            return None

        # Optional: rotate refresh token
        await self.token_repo.revoke_user_tokens(user.id)
        return await self.create_tokens(user)
