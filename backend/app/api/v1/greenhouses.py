import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.domain.user import User
from app.domain.greenhouse import Greenhouse
from app.schemas.greenhouse import GreenhouseRead, GreenhouseCreate, GreenhouseUpdate
from app.services.greenhouse import GreenhouseService
from app.repositories.greenhouse import GreenhouseRepository

router = APIRouter()


@router.post("/", response_model=GreenhouseRead)
async def create_greenhouse(
    greenhouse_in: GreenhouseCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    service = GreenhouseService(GreenhouseRepository(db))
    return await service.create_greenhouse(current_user.id, greenhouse_in)


@router.get("/", response_model=List[GreenhouseRead])
async def list_greenhouses(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    service = GreenhouseService(GreenhouseRepository(db))
    return await service.list_greenhouses(current_user.id)


@router.get("/{greenhouse_id}", response_model=GreenhouseRead)
async def get_greenhouse(
    greenhouse: Greenhouse = Depends(deps.get_greenhouse_or_404),
):
    return greenhouse


@router.patch("/{greenhouse_id}", response_model=GreenhouseRead)
async def update_greenhouse(
    greenhouse_in: GreenhouseUpdate,
    greenhouse: Greenhouse = Depends(deps.get_greenhouse_or_404),
    db: AsyncSession = Depends(deps.get_db),
):
    service = GreenhouseService(GreenhouseRepository(db))
    return await service.update_greenhouse(greenhouse.id, greenhouse_in)


@router.delete("/{greenhouse_id}", status_code=204)
async def delete_greenhouse(
    greenhouse: Greenhouse = Depends(deps.get_greenhouse_or_404),
    db: AsyncSession = Depends(deps.get_db),
):
    service = GreenhouseService(GreenhouseRepository(db))
    await service.delete_greenhouse(greenhouse.id)
