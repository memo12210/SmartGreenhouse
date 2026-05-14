from typing import List, Optional
from sqlalchemy.orm import Session
from uuid import UUID
from app.models.greenhouse import Greenhouse
from app.schemas.greenhouse import GreenhouseCreate, GreenhouseUpdate

def get_by_owner(db: Session, *, owner_id: UUID, greenhouse_id: UUID) -> Optional[Greenhouse]:
    return db.query(Greenhouse).filter(
        Greenhouse.id == greenhouse_id,
        Greenhouse.owner_id == owner_id
    ).first()

def get_multi_by_owner(
    db: Session, *, owner_id: UUID, skip: int = 0, limit: int = 100
) -> List[Greenhouse]:
    return db.query(Greenhouse).filter(
        Greenhouse.owner_id == owner_id
    ).offset(skip).limit(limit).all()

def create_with_owner(
    db: Session, *, obj_in: GreenhouseCreate, owner_id: UUID
) -> Greenhouse:
    db_obj = Greenhouse(
        name=obj_in.name,
        owner_id=owner_id
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def update(
    db: Session, *, db_obj: Greenhouse, obj_in: GreenhouseUpdate
) -> Greenhouse:
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

def remove(db: Session, *, id: UUID) -> Greenhouse:
    obj = db.query(Greenhouse).get(id)
    db.delete(obj)
    db.commit()
    return obj
