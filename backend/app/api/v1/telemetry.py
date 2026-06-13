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
from app.core.observability import TELEMETRY_INGESTED

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
    current_user: User = Depends(deps.get_current_user),
):
    # REST-based telemetry ingestion. Requires authentication and ownership of
    # the target device so that arbitrary callers cannot inject sensor data for
    # devices they do not own (data injection / unsafe automation).
    from app.repositories.device import DeviceRepository
    from app.repositories.greenhouse import GreenhouseRepository

    device_repo = DeviceRepository(db)
    device = await device_repo.get(telemetry_in.device_id)
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    greenhouse_repo = GreenhouseRepository(db)
    greenhouse = await greenhouse_repo.get(device.greenhouse_id)
    if not greenhouse or greenhouse.owner_id != current_user.id:
        # Do not leak existence of devices the caller does not own.
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

    TELEMETRY_INGESTED.labels(device_type=device.device_type).inc()
    return result
