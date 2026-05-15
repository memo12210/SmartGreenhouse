from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID

from app.api import deps
from app.crud import crud_greenhouse, crud_device
from app.schemas import greenhouse as greenhouse_schema
from app.models.user import User
from app.mqtt.handler import broadcast_discovery

router = APIRouter()

@router.get("/", response_model=List[greenhouse_schema.Greenhouse])
def read_greenhouses(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Retrieve greenhouses owned by the current user.
    """
    greenhouses = crud_greenhouse.get_multi_by_owner(
        db, owner_id=current_user.id, skip=skip, limit=limit
    )
    return greenhouses

@router.post("/", response_model=greenhouse_schema.Greenhouse)
async def create_greenhouse(
    *,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    greenhouse_in: greenhouse_schema.GreenhouseCreate,
) -> Any:
    """
    Create a new greenhouse for the current user.
    """
    greenhouse = crud_greenhouse.create_with_owner(
        db, obj_in=greenhouse_in, owner_id=current_user.id
    )

    # Broadcast discovery after creating greenhouse
    mapping = crud_device.get_greenhouse_device_map_by_owner(db, owner_id=current_user.id)
    await broadcast_discovery(user_id=current_user.id, mapping=mapping)

    return greenhouse

@router.put("/{id}", response_model=greenhouse_schema.Greenhouse)
def update_greenhouse(
    *,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    id: UUID,
    greenhouse_in: greenhouse_schema.GreenhouseUpdate,
) -> Any:
    """
    Update a greenhouse.
    """
    greenhouse = crud_greenhouse.get_by_owner(
        db, owner_id=current_user.id, greenhouse_id=id
    )
    if not greenhouse:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Greenhouse not found or you don't have permission to access it",
        )
    greenhouse = crud_greenhouse.update(db, db_obj=greenhouse, obj_in=greenhouse_in)
    return greenhouse

@router.delete("/{id}", response_model=greenhouse_schema.Greenhouse)
def delete_greenhouse(
    *,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    id: UUID,
) -> Any:
    """
    Delete a greenhouse.
    """
    greenhouse = crud_greenhouse.get_by_owner(
        db, owner_id=current_user.id, greenhouse_id=id
    )
    if not greenhouse:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Greenhouse not found or you don't have permission to access it",
        )
    greenhouse = crud_greenhouse.remove(db, id=id)
    return greenhouse
