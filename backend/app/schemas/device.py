import uuid
from typing import Optional, Dict, Any
from pydantic import BaseModel, ConfigDict
from app.domain.device import DeviceStatus


class DeviceBase(BaseModel):
    name: str
    serial_number: str
    device_type: str
    status: DeviceStatus = DeviceStatus.INACTIVE
    firmware_version: Optional[str] = None


class DeviceCreate(DeviceBase):
    greenhouse_id: uuid.UUID


class DeviceUpdate(BaseModel):
    name: Optional[str] = None
    status: Optional[DeviceStatus] = None
    firmware_version: Optional[str] = None
    greenhouse_id: Optional[uuid.UUID] = None


class DeviceRead(DeviceBase):
    id: uuid.UUID
    greenhouse_id: uuid.UUID

    model_config = ConfigDict(from_attributes=True)


class DeviceCommandCreate(BaseModel):
    command: str
    payload: Dict[str, Any] = {}
