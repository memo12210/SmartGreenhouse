from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID

from app.api import deps
from app.crud import crud_device, crud_greenhouse, crud_telemetry
from app.schemas import device as device_schema
from app.schemas import telemetry as telemetry_schema
from app.models.user import User
from app.mqtt.handler import broadcast_discovery

router = APIRouter()

@router.get("/", response_model=List[device_schema.Device])
def read_devices(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    skip: int = 0,
    limit: int = 100,
) -> Any:
    """
    Retrieve devices owned by the current user (across all their greenhouses).
    """
    devices = crud_device.get_multi_by_owner(
        db, owner_id=current_user.id, skip=skip, limit=limit
    )
    return devices

@router.post("/", response_model=device_schema.Device)
async def create_device(
    *,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    device_in: device_schema.DeviceCreate,
) -> Any:
    """
    Create a new device in a greenhouse owned by the current user.
    """
    # Verify the user owns the greenhouse
    gh = crud_greenhouse.get_by_owner(
        db, owner_id=current_user.id, greenhouse_id=device_in.greenhouse_id
    )
    if not gh:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Greenhouse not found or you don't have permission to add devices to it",
        )

    # Check if MAC address is already registered
    existing_device = crud_device.get_by_mac(db, mac_address=device_in.mac_address)
    if existing_device:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A device with this MAC address is already registered in the system",
        )

    device = crud_device.create_with_owner(db, obj_in=device_in)

    # Broadcast discovery after creating device
    mapping = crud_device.get_greenhouse_device_map_by_owner(db, owner_id=current_user.id)
    await broadcast_discovery(user_id=current_user.id, mapping=mapping)

    return device

@router.post("/claim", response_model=device_schema.Device)
async def claim_device(
    *,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    device_in: device_schema.DeviceClaim,
) -> Any:
    """
    Claim a physical device using its MAC address and secret.
    """
    # Verify greenhouse ownership
    gh = crud_greenhouse.get_by_owner(
        db, owner_id=current_user.id, greenhouse_id=device_in.greenhouse_id
    )
    if not gh:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Greenhouse not found or you don't have permission to add devices to it",
        )

    # Check if MAC address is already registered
    existing_device = crud_device.get_by_mac(db, mac_address=device_in.mac_address)
    if existing_device:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This device has already been claimed",
        )

    device = crud_device.claim_device(db, obj_in=device_in)

    # Broadcast discovery after claiming device
    mapping = crud_device.get_greenhouse_device_map_by_owner(db, owner_id=current_user.id)
    await broadcast_discovery(user_id=current_user.id, mapping=mapping)

    return device

@router.get("/{id}", response_model=device_schema.Device)
def read_device(
    *,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    id: UUID,
) -> Any:
    """
    Get a specific device by ID (ownership verified).
    """
    device = crud_device.get_by_owner(db, owner_id=current_user.id, device_id=id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found or you don't have permission to access it",
        )
    return device

@router.put("/{id}", response_model=device_schema.Device)
def update_device(
    *,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    id: UUID,
    device_in: device_schema.DeviceUpdate,
) -> Any:
    """
    Update a device.
    """
    device = crud_device.get_by_owner(db, owner_id=current_user.id, device_id=id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found or you don't have permission to access it",
        )
    device = crud_device.update(db, db_obj=device, obj_in=device_in)
    return device

@router.delete("/{id}", response_model=device_schema.Device)
def delete_device(
    *,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    id: UUID,
) -> Any:
    """
    Delete a device.
    """
    device = crud_device.get_by_owner(db, owner_id=current_user.id, device_id=id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found or you don't have permission to access it",
        )
    device = crud_device.remove(db, id=id)
    return device

@router.get("/{id}/telemetry/latest", response_model=telemetry_schema.Telemetry)
def read_latest_telemetry(
    *,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    id: UUID,
) -> Any:
    """
    Get the latest telemetry for a specific device (ownership verified).
    """
    device = crud_device.get_by_owner(db, owner_id=current_user.id, device_id=id)
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found or you don't have permission to access it",
        )

    telemetry = crud_telemetry.get_latest_by_device(db, device_id=id)
    if not telemetry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No telemetry found for this device",
        )
    return telemetry
