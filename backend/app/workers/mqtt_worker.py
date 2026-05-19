import logging
import asyncio
import uuid
from app.infrastructure.mqtt import mqtt_service
from app.infrastructure.database import SessionLocal
from app.repositories.telemetry import TelemetryRepository
from app.services.telemetry import TelemetryService
from app.schemas.telemetry import TelemetryCreate
from app.domain.device import DeviceStatus
from app.repositories.device import DeviceRepository, DeviceCommandRepository
from app.services.device import DeviceService
from app.repositories.alert import AlertRepository, AlertRuleRepository
from app.services.alert import AlertService, AlertEngineService

logger = logging.getLogger(__name__)

async def process_telemetry(topic: str, data: dict):
    # topic: greenhouse/{greenhouse_id}/device/{device_id}/telemetry
    parts = topic.split("/")
    if len(parts) < 4:
        return

    greenhouse_id = parts[1]
    device_id = parts[3]
    try:
        async with SessionLocal() as db:
            alert_repo = AlertRepository(db)
            alert_rule_repo = AlertRuleRepository(db)
            alert_service = AlertService(alert_repo)
            alert_engine = AlertEngineService(alert_service, alert_rule_repo, alert_repo)

            telemetry_repo = TelemetryRepository(db)
            telemetry_service = TelemetryService(telemetry_repo, alert_engine)

            telemetry_in = TelemetryCreate(
                device_id=device_id,
                **data
            )
            await telemetry_service.ingest_telemetry(telemetry_in, greenhouse_id=uuid.UUID(greenhouse_id))

            # Also update device status/last seen
            device_repo = DeviceRepository(db)
            device_service = DeviceService(device_repo, DeviceCommandRepository(db))
            await device_service.update_device_status(device_id, DeviceStatus.ONLINE)

            await db.commit()
            logger.debug(f"Ingested telemetry and evaluated alerts for device {device_id}")
    except Exception as e:
        logger.error(f"Error processing telemetry for device {device_id}: {e}")

async def start_mqtt_worker():
    # Subscribe to all device telemetry
    await mqtt_service.subscribe("greenhouse/+/device/+/telemetry", process_telemetry)
    logger.info("MQTT Worker started and subscribed to telemetry topics")
