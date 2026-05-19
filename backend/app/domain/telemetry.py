import uuid
from datetime import datetime, timezone
from sqlalchemy import Float, ForeignKey, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.infrastructure.database import Base


class Telemetry(Base):
    __tablename__ = "telemetry"

    # In TimescaleDB, the time column is the primary partitioning key
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), primary_key=True, default=lambda: datetime.now(timezone.utc)
    )
    device_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("devices.id", ondelete="CASCADE"), primary_key=True
    )

    temperature: Mapped[float] = mapped_column(Float, nullable=True)
    humidity: Mapped[float] = mapped_column(Float, nullable=True)
    soil_moisture: Mapped[float] = mapped_column(Float, nullable=True)
    light_intensity: Mapped[float] = mapped_column(Float, nullable=True)
    co2: Mapped[float] = mapped_column(Float, nullable=True)
    battery_level: Mapped[float] = mapped_column(Float, nullable=True)

    # Composite index for efficient querying
    __table_args__ = (
        Index("ix_telemetry_device_id_timestamp", "device_id", "timestamp"),
    )
