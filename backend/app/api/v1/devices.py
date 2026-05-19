import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.domain.user import User
from app.domain.device import Device
from app.domain.greenhouse import Greenhouse
from app.schemas.device import DeviceRead, DeviceCreate, DeviceUpdate, DeviceCommandCreate
from app.services.device import DeviceService
from app.repositories.device import DeviceRepository, DeviceCommandRepository
from app.repositories.greenhouse import GreenhouseRepository

router = APIRouter()


@router.post("/", response_model=DeviceRead)
async def register_device(
    device_in: DeviceCreate,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
):
    # Verify greenhouse ownership
    await deps.get_greenhouse_or_404(device_in.greenhouse_id, db, current_user)

    service = DeviceService(DeviceRepository(db), DeviceCommandRepository(db))
    return await service.register_device(device_in)


@router.get("/{device_id}", response_model=DeviceRead)
async def get_device(
    device: Device = Depends(deps.get_device_or_404),
):
    return device


@router.get("/greenhouse/{greenhouse_id}", response_model=List[DeviceRead])
async def list_greenhouse_devices(
    greenhouse: Greenhouse = Depends(deps.get_greenhouse_or_404),
    db: AsyncSession = Depends(deps.get_db),
):
    repo = DeviceRepository(db)
    return await repo.get_by_greenhouse(greenhouse.id)


@router.patch("/{device_id}", response_model=DeviceRead)
async def update_device(
    device_in: DeviceUpdate,
    device: Device = Depends(deps.get_device_or_404),
    db: AsyncSession = Depends(deps.get_db),
):
    service = DeviceService(DeviceRepository(db), DeviceCommandRepository(db))
    return await service.update_device(device.id, device_in)


@router.delete("/{device_id}", status_code=204)
async def delete_device(
    device: Device = Depends(deps.get_device_or_404),
    db: AsyncSession = Depends(deps.get_db),
):
    service = DeviceService(DeviceRepository(db), DeviceCommandRepository(db))
    await service.delete_device(device.id)


@router.post("/{device_id}/commands")
async def send_device_command(
    command_in: DeviceCommandCreate,
    device: Device = Depends(deps.get_device_or_404),
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
):
    service = DeviceService(DeviceRepository(db), DeviceCommandRepository(db))
    try:
        return await service.send_command(device.id, command_in, current_user.id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
