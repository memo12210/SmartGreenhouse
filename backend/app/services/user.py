import uuid
from typing import Optional, List
from app.domain.user import User
from app.repositories.user import UserRepository
from app.schemas.user import UserCreate, UserUpdate
from app.core.security import get_password_hash


class UserService:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    async def get_user(self, user_id: uuid.UUID) -> Optional[User]:
        return await self.user_repo.get(user_id)

    async def get_user_by_email(self, email: str) -> Optional[User]:
        return await self.user_repo.get_by_email(email)

    async def create_user(self, user_in: UserCreate) -> User:
        user = User(
            email=user_in.email,
            hashed_password=get_password_hash(user_in.password),
            full_name=user_in.full_name,
            role=user_in.role,
            is_active=user_in.is_active,
        )
        created_user = await self.user_repo.create(user)
        await self.user_repo.commit()
        return created_user

    async def update_user(self, user_id: uuid.UUID, user_in: UserUpdate) -> Optional[User]:
        db_user = await self.user_repo.get(user_id)
        if not db_user:
            return None

        update_data = user_in.model_dump(exclude_unset=True)
        if "password" in update_data:
            update_data["hashed_password"] = get_password_hash(update_data.pop("password"))

        updated_user = await self.user_repo.update(db_user, update_data)
        await self.user_repo.commit()
        return updated_user
