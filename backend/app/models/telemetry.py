import uuid
from sqlalchemy import Column, Float, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class Telemetry(Base):
    __tablename__ = "telemetry"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    temperature = Column(Float, nullable=True)
    humidity = Column(Float, nullable=True)
    light = Column(Float, nullable=True)
    soil_moisture = Column(Float, nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id", ondelete="CASCADE"), nullable=False)

    # Relationships
    device = relationship("Device", back_populates="telemetry_data")
