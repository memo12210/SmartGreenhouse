import uuid
from datetime import datetime
from enum import Enum
from typing import List, TYPE_CHECKING
from sqlalchemy import String, Enum as SQLEnum, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.infrastructure.database import Base
from app.domain.base import BaseEntity

if TYPE_CHECKING:
    from .greenhouse import Greenhouse


class UserRole(str, Enum):
    ADMIN = "admin"
    OPERATOR = "operator"
    VIEWER = "viewer"


class User(Base, BaseEntity):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=True)
    role: Mapped[UserRole] = mapped_column(
        SQLEnum(UserRole), default=UserRole.VIEWER, nullable=False
    )
    is_active: Mapped[bool] = mapped_column(default=True)

    greenhouses: Mapped[List["Greenhouse"]] = relationship(
        "Greenhouse", back_populates="owner", cascade="all, delete-orphan"
    )


class RefreshToken(Base, BaseEntity):
    __tablename__ = "refresh_tokens"

    token: Mapped[str] = mapped_column(String(511), index=True, nullable=False)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_revoked: Mapped[bool] = mapped_column(default=False)
