from typing import List, Optional
from sqlalchemy.orm import Session
from uuid import UUID
from app.models.device import Device
from app.models.greenhouse import Greenhouse
from app.schemas.device import DeviceCreate, DeviceUpdate, DeviceClaim
from app.core.security import get_password_hash

def get_by_mac(db: Session, *, mac_address: str) -> Optional[Device]:
    return db.query(Device).filter(Device.mac_address == mac_address).first()

def claim_device(
    db: Session, *, obj_in: DeviceClaim
) -> Device:
    db_obj = Device(
        mac_address=obj_in.mac_address,
        name=obj_in.name,
        greenhouse_id=obj_in.greenhouse_id,
        hashed_secret=get_password_hash(obj_in.secret),
        is_active=True
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def get_by_owner(db: Session, *, owner_id: UUID, device_id: UUID) -> Optional[Device]:
    return db.query(Device).join(Greenhouse).filter(
        Device.id == device_id,
        Greenhouse.owner_id == owner_id
    ).first()

def get_multi_by_owner(
    db: Session, *, owner_id: UUID, skip: int = 0, limit: int = 100
) -> List[Device]:
    return db.query(Device).join(Greenhouse).filter(
        Greenhouse.owner_id == owner_id
    ).offset(skip).limit(limit).all()

def create_with_owner(
    db: Session, *, obj_in: DeviceCreate
) -> Device:
    db_obj = Device(
        mac_address=obj_in.mac_address,
        name=obj_in.name,
        greenhouse_id=obj_in.greenhouse_id
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def update(
    db: Session, *, db_obj: Device, obj_in: DeviceUpdate
) -> Device:
    if isinstance(obj_in, dict):
        update_data = obj_in
    else:
        update_data = obj_in.model_dump(exclude_unset=True)

    for field in update_data:
        setattr(db_obj, field, update_data[field])

    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def remove(db: Session, *, id: UUID) -> Device:
    obj = db.query(Device).get(id)
    db.delete(obj)
    db.commit()
    return obj
