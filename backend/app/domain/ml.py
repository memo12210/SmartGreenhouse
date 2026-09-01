import uuid
from datetime import datetime, timezone
from sqlalchemy import Float, ForeignKey, DateTime, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.infrastructure.database import Base
from app.domain.base import BaseEntity

class Prediction(Base, BaseEntity):
    __tablename__ = "predictions"

    greenhouse_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("greenhouses.id", ondelete="CASCADE"), nullable=False
    )
    yield_kg_per_m2: Mapped[float] = mapped_column(Float, nullable=False)
    model_version: Mapped[str] = mapped_column(String(50), nullable=False)
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
