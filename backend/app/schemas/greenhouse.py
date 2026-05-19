import uuid
from typing import Optional, Dict, Any
from pydantic import BaseModel, ConfigDict


class GreenhouseBase(BaseModel):
    name: str
    location: Optional[str] = None
    extra_metadata: Dict[str, Any] = {}


class GreenhouseCreate(GreenhouseBase):
    pass


class GreenhouseUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    extra_metadata: Optional[Dict[str, Any]] = None


class GreenhouseRead(BaseModel):
    id: uuid.UUID
    name: str
    location: Optional[str] = None
    extra_metadata: Dict[str, Any]
    owner_id: uuid.UUID

    model_config = ConfigDict(from_attributes=True)
