import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.domain.user import User
from app.domain.greenhouse import Greenhouse
from app.schemas.alert import (
    AlertRead,
    AlertRuleRead,
    AlertRuleCreate,
    AlertRuleUpdate,
)
from app.services.alert import AlertService, AlertRuleService
from app.repositories.alert import AlertRepository, AlertRuleRepository

router = APIRouter()


@router.get("/greenhouse/{greenhouse_id}", response_model=List[AlertRead])
async def list_greenhouse_alerts(
    greenhouse: Greenhouse = Depends(deps.get_greenhouse_or_404),
    db: AsyncSession = Depends(deps.get_db),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
):
    service = AlertService(AlertRepository(db))
    return await service.list_greenhouse_alerts(greenhouse.id, skip=skip, limit=limit)


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

    await deps.get_greenhouse_or_404(alert.greenhouse_id, db, current_user)

    service = AlertService(repo)
    updated = await service.acknowledge_alert(alert_id, current_user.id)

    if not updated:
        raise HTTPException(status_code=404, detail="Alert not found")

    return updated


@router.delete("/{alert_id}/dismiss")
async def dismiss_alert(
    alert_id: uuid.UUID,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    repo = AlertRepository(db)
    alert = await repo.get(alert_id)

    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")

    await deps.get_greenhouse_or_404(alert.greenhouse_id, db, current_user)

    service = AlertService(repo)
    deleted = await service.delete_alert(alert_id)

    if not deleted:
        raise HTTPException(status_code=404, detail="Alert not found")

    return {"status": "success"}


@router.get("/rules/device/{device_id}", response_model=List[AlertRuleRead])
async def list_device_rules(
    device_id: uuid.UUID,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    await deps.get_device_or_404(device_id, db, current_user)

    service = AlertRuleService(AlertRuleRepository(db))
    return await service.get_device_rules(device_id)


@router.post("/rules", response_model=AlertRuleRead)
async def create_alert_rule(
    rule_in: AlertRuleCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    await deps.get_device_or_404(rule_in.device_id, db, current_user)

    service = AlertRuleService(AlertRuleRepository(db))
    return await service.create_rule(rule_in)


@router.patch("/rules/{rule_id}", response_model=AlertRuleRead)
async def update_alert_rule(
    rule_id: uuid.UUID,
    rule_in: AlertRuleUpdate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    repo = AlertRuleRepository(db)
    rule = await repo.get(rule_id)

    if not rule:
        raise HTTPException(status_code=404, detail="Alert rule not found")

    await deps.get_device_or_404(rule.device_id, db, current_user)

    service = AlertRuleService(repo)
    updated = await service.update_rule(rule_id, rule_in)

    if not updated:
        raise HTTPException(status_code=404, detail="Alert rule not found")

    return updated


@router.delete("/rules/{rule_id}")
async def delete_alert_rule(
    rule_id: uuid.UUID,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    repo = AlertRuleRepository(db)
    rule = await repo.get(rule_id)

    if not rule:
        raise HTTPException(status_code=404, detail="Alert rule not found")

    await deps.get_device_or_404(rule.device_id, db, current_user)

    service = AlertRuleService(repo)
    deleted = await service.delete_rule(rule_id)

    if not deleted:
        raise HTTPException(status_code=404, detail="Alert rule not found")

    return {"status": "success"}