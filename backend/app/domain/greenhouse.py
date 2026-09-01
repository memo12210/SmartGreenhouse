import uuid
from typing import List, TYPE_CHECKING
from sqlalchemy import String, ForeignKey, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.infrastructure.database import Base
from app.domain.base import BaseEntity

if TYPE_CHECKING:
    from .user import User
    from .device import Device


class Greenhouse(Base, BaseEntity):
    __tablename__ = "greenhouses"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    location: Mapped[str] = mapped_column(String(255), nullable=True)
    extra_metadata: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)

    owner_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    owner: Mapped["User"] = relationship("User", back_populates="greenhouses")

    devices: Mapped[List["Device"]] = relationship(
        "Device", back_populates="greenhouse", cascade="all, delete-orphan"
    )
