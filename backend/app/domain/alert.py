import uuid
from enum import Enum
from sqlalchemy import String, ForeignKey, Enum as SQLEnum, Float, Boolean, JSON
from sqlalchemy.orm import Mapped, mapped_column
from app.infrastructure.database import Base
from app.domain.base import BaseEntity


class AlertSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


class Alert(Base, BaseEntity):
    __tablename__ = "alerts"

    device_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("devices.id", ondelete="CASCADE"), nullable=False
    )
    greenhouse_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("greenhouses.id", ondelete="CASCADE"), nullable=False
    )

    alert_type: Mapped[str] = mapped_column(String(100), nullable=False) # e.g., "high_temp", "low_moisture"
    severity: Mapped[AlertSeverity] = mapped_column(
        SQLEnum(AlertSeverity), default=AlertSeverity.WARNING, nullable=False
    )
    message: Mapped[str] = mapped_column(String(500), nullable=False)
    value: Mapped[float] = mapped_column(Float, nullable=True)

    is_acknowledged: Mapped[bool] = mapped_column(Boolean, default=False)
    acknowledged_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), nullable=True)
    extra_metadata: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)
