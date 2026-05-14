from typing import Optional
from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime

# Shared properties
class GreenhouseBase(BaseModel):
    name: Optional[str] = None

# Properties to receive via API on creation
class GreenhouseCreate(GreenhouseBase):
    name: str

# Properties to receive via API on update
class GreenhouseUpdate(GreenhouseBase):
    pass

# Properties to return via API
class Greenhouse(GreenhouseBase):
    id: UUID
    name: str
    owner_id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
