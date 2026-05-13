import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class Device(Base):
    __tablename__ = "devices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    mac_address = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=True)
    greenhouse_id = Column(UUID(as_uuid=True), ForeignKey("greenhouses.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    greenhouse = relationship("Greenhouse", back_populates="devices")
    telemetry_data = relationship("Telemetry", back_populates="device", cascade="all, delete-orphan")
