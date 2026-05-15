from typing import Optional
from sqlalchemy.orm import Session
from uuid import UUID
from app.models.telemetry import Telemetry

def get_latest_by_device(db: Session, *, device_id: UUID) -> Optional[Telemetry]:
    return db.query(Telemetry).filter(
        Telemetry.device_id == device_id
    ).order_by(Telemetry.timestamp.desc()).first()
