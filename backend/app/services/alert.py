import uuid
import operator
from typing import List, Optional, Dict, Any
from app.domain.alert import Alert, AlertRule
from app.repositories.alert import AlertRepository, AlertRuleRepository
from app.schemas.alert import AlertCreate, AlertRuleCreate, AlertRuleUpdate
from app.domain.telemetry import Telemetry


class AlertService:
    def __init__(self, alert_repo: AlertRepository):
        self.alert_repo = alert_repo

    async def create_alert(self, alert_in: AlertCreate) -> Alert:
        alert = Alert(
            device_id=alert_in.device_id,
            greenhouse_id=alert_in.greenhouse_id,
            alert_type=alert_in.alert_type,
            severity=alert_in.severity,
            message=alert_in.message,
            value=alert_in.value,
            extra_metadata=alert_in.extra_metadata
        )
        created = await self.alert_repo.create(alert)
        await self.alert_repo.commit()
        return created

    async def acknowledge_alert(self, alert_id: uuid.UUID, user_id: uuid.UUID) -> Optional[Alert]:
        alert = await self.alert_repo.get(alert_id)
        if not alert:
            return None
        updated = await self.alert_repo.update(alert, {
            "is_acknowledged": True,
            "acknowledged_by": user_id
        })
        await self.alert_repo.commit()
        return updated

    async def list_greenhouse_alerts(self, greenhouse_id: uuid.UUID) -> List[Alert]:
        return await self.alert_repo.get_by_greenhouse(greenhouse_id)


class AlertRuleService:
    def __init__(self, rule_repo: AlertRuleRepository):
        self.rule_repo = rule_repo

    async def create_rule(self, rule_in: AlertRuleCreate) -> AlertRule:
        rule = AlertRule(
            device_id=rule_in.device_id,
            field=rule_in.field,
            operator=rule_in.operator,
            threshold=rule_in.threshold,
            severity=rule_in.severity,
            is_enabled=rule_in.is_enabled,
            message_template=rule_in.message_template
        )
        created = await self.rule_repo.create(rule)
        await self.rule_repo.commit()
        return created

    async def update_rule(self, rule_id: uuid.UUID, rule_in: AlertRuleUpdate) -> Optional[AlertRule]:
        rule = await self.rule_repo.get(rule_id)
        if not rule:
            return None
        update_data = rule_in.model_dump(exclude_unset=True)
        updated = await self.rule_repo.update(rule, update_data)
        await self.rule_repo.commit()
        return updated

    async def delete_rule(self, rule_id: uuid.UUID) -> bool:
        deleted = await self.rule_repo.delete(rule_id)
        if deleted:
            await self.rule_repo.commit()
            return True
        return False

    async def get_device_rules(self, device_id: uuid.UUID) -> List[AlertRule]:
        return await self.rule_repo.get_by_device(device_id)


class AlertEngineService:
    OPERATORS = {
        ">": operator.gt,
        "<": operator.lt,
        ">=": operator.ge,
        "<=": operator.le,
        "==": operator.eq,
        "!=": operator.ne,
    }

    def __init__(self, alert_service: AlertService, rule_repo: AlertRuleRepository, alert_repo: AlertRepository):
        self.alert_service = alert_service
        self.rule_repo = rule_repo
        self.alert_repo = alert_repo

    async def evaluate_telemetry(self, telemetry: Telemetry, greenhouse_id: uuid.UUID):
        rules = await self.rule_repo.get_enabled_by_device(telemetry.device_id)

        for rule in rules:
            val = getattr(telemetry, rule.field, None)
            if val is None:
                continue

            op_func = self.OPERATORS.get(rule.operator)
            if not op_func:
                continue

            if op_func(val, rule.threshold):
                # Rule matched! Check if an unacknowledged alert already exists
                alert_type = f"{rule.field}_{rule.operator}_{rule.threshold}"
                existing = await self.alert_repo.get_unacknowledged_by_device_and_type(
                    telemetry.device_id, alert_type
                )

                if not existing:
                    message = rule.message_template or f"{rule.field} is {rule.operator} {rule.threshold} (current: {val})"
                    alert_in = AlertCreate(
                        device_id=telemetry.device_id,
                        greenhouse_id=greenhouse_id,
                        alert_type=alert_type,
                        severity=rule.severity,
                        message=message,
                        value=val,
                        extra_metadata={"rule_id": str(rule.id)}
                    )
                    await self.alert_service.create_alert(alert_in)
