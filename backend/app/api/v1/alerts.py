import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.domain.user import User
from app.domain.greenhouse import Greenhouse
from app.schemas.alert import AlertRead, AlertCreate
from app.services.alert import AlertService
from app.repositories.alert import AlertRepository

router = APIRouter()


@router.get("/greenhouse/{greenhouse_id}", response_model=List[AlertRead])
async def list_greenhouse_alerts(
    greenhouse: Greenhouse = Depends(deps.get_greenhouse_or_404),
    db: AsyncSession = Depends(deps.get_db),
):
    service = AlertService(AlertRepository(db))
    return await service.list_greenhouse_alerts(greenhouse.id)


@router.post("/{alert_id}/acknowledge", response_model=AlertRead)
async def acknowledge_alert(
    alert_id: uuid.UUID,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    repo = AlertRepository(db)
    alert = await repo.get(alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")

    # Verify ownership via greenhouse
    await deps.get_greenhouse_or_404(alert.greenhouse_id, db, current_user)

    service = AlertService(repo)
    return await service.acknowledge_alert(alert_id, current_user.id)
