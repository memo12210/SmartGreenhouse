from typing import Optional
from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime

# Shared properties
class DeviceBase(BaseModel):
    mac_address: Optional[str] = None
    name: Optional[str] = None

# Properties to receive via API on creation
class DeviceCreate(DeviceBase):
    mac_address: str
    greenhouse_id: UUID

# Properties to receive via API on update
class DeviceUpdate(DeviceBase):
    pass

# Properties to return via API
class Device(DeviceBase):
    id: UUID
    mac_address: str
    greenhouse_id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
