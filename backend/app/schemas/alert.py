import uuid
from typing import Optional, Dict, Any
from pydantic import BaseModel, ConfigDict
from app.domain.alert import AlertSeverity


class AlertBase(BaseModel):
    alert_type: str
    severity: AlertSeverity = AlertSeverity.WARNING
    message: str
    value: Optional[float] = None
    extra_metadata: Dict[str, Any] = {}


class AlertCreate(AlertBase):
    device_id: uuid.UUID
    greenhouse_id: uuid.UUID


class AlertRead(AlertBase):
    id: uuid.UUID
    device_id: uuid.UUID
    greenhouse_id: uuid.UUID
    is_acknowledged: bool
    acknowledged_by: Optional[uuid.UUID] = None

    model_config = ConfigDict(from_attributes=True)
