import uuid
from typing import AsyncGenerator, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.infrastructure.database import get_db
from app.domain.user import User, UserRole
from app.repositories.user import UserRepository, RefreshTokenRepository
from app.repositories.greenhouse import GreenhouseRepository
from app.repositories.device import DeviceRepository
from app.services.user import UserService
from app.services.auth import AuthService
from app.schemas.user import TokenData

reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/auth/login"
)

async def get_current_user(
    db: AsyncSession = Depends(get_db),
    token: str = Depends(reusable_oauth2)
) -> User:
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        token_data = TokenData(**payload)
    except (JWTError, Exception):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        )

    user_repo = UserRepository(db)
    user = await user_repo.get(uuid.UUID(token_data.sub))
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return user


async def get_greenhouse_or_404(
    greenhouse_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> "Greenhouse":
    from app.domain.greenhouse import Greenhouse
    repo = GreenhouseRepository(db)
    greenhouse = await repo.get(greenhouse_id)
    if not greenhouse or greenhouse.owner_id != current_user.id:
        raise HTTPException(status_code=404, detail="Greenhouse not found")
    return greenhouse


async def get_device_or_404(
    device_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> "Device":
    from app.domain.device import Device
    repo = DeviceRepository(db)
    device = await repo.get(device_id)
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    # Check if the greenhouse it belongs to is owned by the user
    greenhouse_repo = GreenhouseRepository(db)
    greenhouse = await greenhouse_repo.get(device.greenhouse_id)
    if not greenhouse or greenhouse.owner_id != current_user.id:
        raise HTTPException(status_code=404, detail="Device not found")
    return device


def check_role(roles: list[UserRole]):
    def role_checker(user: User = Depends(get_current_user)):
        if user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="The user doesn't have enough privileges",
            )
        return user
    return role_checker
