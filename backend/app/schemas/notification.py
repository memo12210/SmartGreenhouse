import uuid
from typing import Optional
from pydantic import BaseModel, ConfigDict


class FcmTokenCreate(BaseModel):
    token: str
    platform: str = "android"
    device_name: Optional[str] = None


class FcmTokenRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    token: str
    platform: str
    device_name: Optional[str] = None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)