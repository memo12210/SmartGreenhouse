import uuid
import pytest
from app.domain.alert import AlertSeverity, Alert, AlertRule
from app.repositories.alert import AlertRepository, AlertRuleRepository
from app.services.alert import AlertService, AlertEngineService
from app.domain.telemetry import Telemetry
from app.schemas.alert import AlertCreate, AlertRuleCreate

@pytest.mark.asyncio
async def test_alert_engine_logic(db_session):
    # Setup: Create a test rule
    device_id = uuid.uuid4()
    greenhouse_id = uuid.uuid4()

    alert_repo = AlertRepository(db_session)
    rule_repo = AlertRuleRepository(db_session)
    alert_service = AlertService(alert_repo)
    engine = AlertEngineService(alert_service, rule_repo, alert_repo)

    # Create rule: humidity > 80
    rule_in = AlertRuleCreate(
        device_id=device_id,
        field="humidity",
        operator=">",
        threshold=80.0,
        severity=AlertSeverity.CRITICAL,
        message_template="High Humidity Alert!"
    )
    rule = AlertRule(
        id=uuid.uuid4(),
        device_id=rule_in.device_id,
        field=rule_in.field,
        operator=rule_in.operator,
        threshold=rule_in.threshold,
        severity=rule_in.severity,
        message_template=rule_in.message_template
    )
    db_session.add(rule)
    await db_session.flush()

    # Test case 1: Telemetry below threshold (75)
    telemetry_low = Telemetry(
        device_id=device_id,
        humidity=75.0,
        temperature=25.0
    )
    await engine.evaluate_telemetry(telemetry_low, greenhouse_id)

    alerts = await alert_repo.get_by_greenhouse(greenhouse_id)
    assert len(alerts) == 0

    # Test case 2: Telemetry above threshold (85)
    telemetry_high = Telemetry(
        device_id=device_id,
        humidity=85.0,
        temperature=25.0
    )
    await engine.evaluate_telemetry(telemetry_high, greenhouse_id)

    alerts = await alert_repo.get_by_greenhouse(greenhouse_id)
    assert len(alerts) == 1
    assert alerts[0].value == 85.0
    assert alerts[0].message == "High Humidity Alert!"
    assert alerts[0].alert_type == "humidity_>_80.0"

    # Test case 3: Deduplication (another telemetry above threshold)
    await engine.evaluate_telemetry(telemetry_high, greenhouse_id)
    alerts_after = await alert_repo.get_by_greenhouse(greenhouse_id)
    assert len(alerts_after) == 1 # Still 1 because first is unacknowledged

    # Test case 4: Acknowledge and then another alert
    await alert_service.acknowledge_alert(alerts[0].id, uuid.uuid4())
    await engine.evaluate_telemetry(telemetry_high, greenhouse_id)
    alerts_final = await alert_repo.get_by_greenhouse(greenhouse_id)
    assert len(alerts_final) == 2
