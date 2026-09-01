from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.core.config import settings
from app.schemas.user import Token, UserRegister, UserRead
from app.services.auth import AuthService
from app.services.user import UserService
from app.repositories.user import UserRepository, RefreshTokenRepository

router = APIRouter()


@router.post("/login", response_model=Token)
async def login(
    db: AsyncSession = Depends(deps.get_db),
    form_data: OAuth2PasswordRequestForm = Depends()
):
    auth_service = AuthService(UserRepository(db), RefreshTokenRepository(db))
    user = await auth_service.authenticate(form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    return await auth_service.create_tokens(user)


@router.post("/refresh", response_model=Token)
async def refresh_token(
    refresh_token: str,
    db: AsyncSession = Depends(deps.get_db)
):
    auth_service = AuthService(UserRepository(db), RefreshTokenRepository(db))
    tokens = await auth_service.refresh_access_token(refresh_token)
    if not tokens:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )
    return tokens


@router.post("/register", response_model=UserRead)
async def register(
    user_in: UserRegister,
    db: AsyncSession = Depends(deps.get_db)
):
    user_service = UserService(UserRepository(db))
    user = await user_service.get_user_by_email(user_in.email)
    if user:
        raise HTTPException(
            status_code=400,
            detail="A user with this email already exists in the system",
        )
    return await user_service.create_user(user_in)
