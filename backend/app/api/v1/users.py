from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.domain.user import User, UserRole
from app.schemas.user import UserRead, UserUpdate
from app.services.user import UserService
from app.repositories.user import UserRepository

router = APIRouter()


@router.get("/me", response_model=UserRead)
async def read_user_me(
    current_user: User = Depends(deps.get_current_user),
):
    return current_user


@router.patch("/me", response_model=UserRead)
async def update_user_me(
    user_in: UserUpdate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    user_service = UserService(UserRepository(db))
    return await user_service.update_user(current_user.id, user_in)
