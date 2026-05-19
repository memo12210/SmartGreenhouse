import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.domain.user import User
from app.domain.greenhouse import Greenhouse
from app.schemas.alert import AlertRead, AlertCreate, AlertRuleRead, AlertRuleCreate, AlertRuleUpdate
from app.services.alert import AlertService, AlertRuleService
from app.repositories.alert import AlertRepository, AlertRuleRepository

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


# Alert Rule Endpoints

@router.get("/rules/device/{device_id}", response_model=List[AlertRuleRead])
async def list_device_rules(
    device_id: uuid.UUID,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    # Verify device ownership
    await deps.get_device_or_404(device_id, db, current_user)

    service = AlertRuleService(AlertRuleRepository(db))
    return await service.get_device_rules(device_id)


@router.post("/rules", response_model=AlertRuleRead)
async def create_alert_rule(
    rule_in: AlertRuleCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    # Verify device ownership
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

    # Verify device ownership
    await deps.get_device_or_404(rule.device_id, db, current_user)

    service = AlertRuleService(repo)
    updated = await service.update_rule(rule_id, rule_in)
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

    # Verify device ownership
    await deps.get_device_or_404(rule.device_id, db, current_user)

    service = AlertRuleService(repo)
    await service.delete_rule(rule_id)
    return {"status": "success"}
