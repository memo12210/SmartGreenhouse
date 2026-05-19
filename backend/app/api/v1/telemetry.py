import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.domain.user import User
from app.domain.device import Device
from app.schemas.telemetry import TelemetryRead, TelemetryCreate
from app.services.telemetry import TelemetryService
from app.repositories.telemetry import TelemetryRepository

router = APIRouter()


@router.get("/{device_id}", response_model=List[TelemetryRead])
async def get_telemetry(
    start_time: Optional[datetime] = None,
    end_time: Optional[datetime] = None,
    limit: int = Query(100, le=1000),
    device: Device = Depends(deps.get_device_or_404),
    db: AsyncSession = Depends(deps.get_db),
):
    service = TelemetryService(TelemetryRepository(db))
    return await service.get_device_telemetry(device.id, start_time, end_time, limit)


@router.post("/", response_model=TelemetryRead)
async def ingest_telemetry(
    telemetry_in: TelemetryCreate,
    db: AsyncSession = Depends(deps.get_db),
):
    # This could be used for REST-based telemetry ingestion from some devices
    # We need to find the greenhouse_id to evaluate alerts
    from app.repositories.device import DeviceRepository
    device_repo = DeviceRepository(db)
    device = await device_repo.get(telemetry_in.device_id)
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    from app.repositories.alert import AlertRepository, AlertRuleRepository
    from app.services.alert import AlertService, AlertEngineService

    alert_repo = AlertRepository(db)
    alert_rule_repo = AlertRuleRepository(db)
    alert_service = AlertService(alert_repo)
    alert_engine = AlertEngineService(alert_service, alert_rule_repo, alert_repo)

    service = TelemetryService(TelemetryRepository(db), alert_engine)
    result = await service.ingest_telemetry(telemetry_in, greenhouse_id=device.greenhouse_id)
    await db.commit()
    return result
