import uuid
from enum import Enum
from datetime import datetime
from typing import TYPE_CHECKING, List
from sqlalchemy import String, ForeignKey, Enum as SQLEnum, DateTime, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.infrastructure.database import Base
from app.domain.base import BaseEntity

if TYPE_CHECKING:
    from .greenhouse import Greenhouse


class DeviceStatus(str, Enum):
    ONLINE = "online"
    OFFLINE = "offline"
    MAINTENANCE = "maintenance"
    INACTIVE = "inactive"


class Device(Base, BaseEntity):
    __tablename__ = "devices"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    serial_number: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    device_type: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[DeviceStatus] = mapped_column(
        SQLEnum(DeviceStatus), default=DeviceStatus.INACTIVE, nullable=False
    )
    firmware_version: Mapped[str] = mapped_column(String(50), nullable=True)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)

    greenhouse_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("greenhouses.id", ondelete="CASCADE"), nullable=False
    )
    greenhouse: Mapped["Greenhouse"] = relationship("Greenhouse", back_populates="devices")


class DeviceCommand(Base, BaseEntity):
    __tablename__ = "device_commands"

    device_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("devices.id", ondelete="CASCADE"), nullable=False
    )
    command: Mapped[str] = mapped_column(String(255), nullable=False)
    payload: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)
    status: Mapped[str] = mapped_column(String(50), default="pending") # pending, sent, acknowledged, failed
    issued_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=True)
