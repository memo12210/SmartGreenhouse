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


class AlertRuleBase(BaseModel):
    field: str
    operator: str
    threshold: float
    severity: AlertSeverity = AlertSeverity.WARNING
    is_enabled: bool = True
    message_template: Optional[str] = None


class AlertRuleCreate(AlertRuleBase):
    device_id: uuid.UUID


class AlertRuleUpdate(BaseModel):
    field: Optional[str] = None
    operator: Optional[str] = None
    threshold: Optional[float] = None
    severity: Optional[AlertSeverity] = None
    is_enabled: Optional[bool] = None
    message_template: Optional[str] = None


class AlertRuleRead(AlertRuleBase):
    id: uuid.UUID
    device_id: uuid.UUID

    model_config = ConfigDict(from_attributes=True)
