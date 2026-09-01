import uuid
import math
import operator
import logging
from typing import List, Optional


def _float_eq(a: float, b: float) -> bool:
    # Direct float equality is unreliable for sensor values; compare with a small
    # tolerance so a rule like "value == 25.0" behaves intuitively.
    return math.isclose(a, b, rel_tol=1e-9, abs_tol=1e-9)


def _float_ne(a: float, b: float) -> bool:
    return not _float_eq(a, b)

from app.domain.alert import Alert, AlertRule
from app.domain.telemetry import Telemetry
from app.repositories.alert import AlertRepository, AlertRuleRepository
from app.repositories.greenhouse import GreenhouseRepository
from app.repositories.fcm_token import FcmTokenRepository
from app.schemas.alert import AlertCreate, AlertRuleCreate, AlertRuleUpdate
from app.services.push_notification import PushNotificationService

logger = logging.getLogger(__name__)


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
            extra_metadata=alert_in.extra_metadata,
        )

        created = await self.alert_repo.create(alert)
        await self.alert_repo.commit()
        return created

    async def acknowledge_alert(
        self,
        alert_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> Optional[Alert]:
        alert = await self.alert_repo.get(alert_id)

        if not alert:
            return None

        updated = await self.alert_repo.update(
            alert,
            {
                "is_acknowledged": True,
                "acknowledged_by": user_id,
            },
        )

        await self.alert_repo.commit()
        return updated

    async def list_greenhouse_alerts(
        self,
        greenhouse_id: uuid.UUID,
        skip: int = 0,
        limit: int = 100,
    ) -> List[Alert]:
        return await self.alert_repo.get_by_greenhouse(greenhouse_id, skip=skip, limit=limit)

    async def delete_alert(self, alert_id: uuid.UUID) -> bool:
        deleted = await self.alert_repo.delete(alert_id)

        if deleted:
            await self.alert_repo.commit()
            return True

        return False


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
            message_template=rule_in.message_template,
        )

        created = await self.rule_repo.create(rule)
        await self.rule_repo.commit()
        return created

    async def update_rule(
        self,
        rule_id: uuid.UUID,
        rule_in: AlertRuleUpdate,
    ) -> Optional[AlertRule]:
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
        "==": _float_eq,
        "!=": _float_ne,
    }

    def __init__(
        self,
        alert_service: AlertService,
        rule_repo: AlertRuleRepository,
        alert_repo: AlertRepository,
    ):
        self.alert_service = alert_service
        self.rule_repo = rule_repo
        self.alert_repo = alert_repo

    async def evaluate_telemetry(
        self,
        telemetry: Telemetry,
        greenhouse_id: uuid.UUID,
    ):
        rules = await self.rule_repo.get_enabled_by_device(telemetry.device_id)

        for rule in rules:
            val = getattr(telemetry, rule.field, None)

            if val is None:
                continue

            op_func = self.OPERATORS.get(rule.operator)

            if not op_func:
                continue

            if op_func(val, rule.threshold):
                alert_type = f"{rule.field}_{rule.operator}_{rule.threshold}"

                existing = await self.alert_repo.get_unacknowledged_by_device_and_type(
                    telemetry.device_id,
                    alert_type,
                )

                if existing:
                    continue

                message = (
                    rule.message_template
                    or f"{rule.field} is {rule.operator} {rule.threshold} "
                    f"(current: {val})"
                )

                alert_in = AlertCreate(
                    device_id=telemetry.device_id,
                    greenhouse_id=greenhouse_id,
                    alert_type=alert_type,
                    severity=rule.severity,
                    message=message,
                    value=val,
                    extra_metadata={
                        "rule_id": str(rule.id),
                        "field": rule.field,
                        "operator": rule.operator,
                        "threshold": rule.threshold,
                        "current_value": val,
                    },
                )

                created_alert = await self.alert_service.create_alert(alert_in)

                await self._send_alert_push_notification(
                    alert=created_alert,
                    rule=rule,
                    current_value=val,
                )

    async def _send_alert_push_notification(
        self,
        alert: Alert,
        rule: AlertRule,
        current_value: float,
    ) -> None:
        try:
            session = self.alert_repo.session

            greenhouse_repo = GreenhouseRepository(session)
            fcm_token_repo = FcmTokenRepository(session)

            greenhouse = await greenhouse_repo.get(alert.greenhouse_id)

            if not greenhouse:
                logger.warning(
                    "Greenhouse not found while sending alert notification. "
                    "greenhouse_id=%s",
                    alert.greenhouse_id,
                )
                return

            tokens = await fcm_token_repo.get_active_by_user(greenhouse.owner_id)

            if not tokens:
                logger.info(
                    "No active FCM token found for greenhouse owner. owner_id=%s",
                    greenhouse.owner_id,
                )
                return

            push_service = PushNotificationService()

            title = self._build_notification_title(alert.severity)
            body = alert.message

            for token in tokens:
                try:
                    await push_service.send_to_token(
                        token=token.token,
                        title=title,
                        body=body,
                        data={
                            "type": "greenhouse_alert",
                            "alert_id": str(alert.id),
                            "greenhouse_id": str(alert.greenhouse_id),
                            "device_id": str(alert.device_id),
                            "alert_type": alert.alert_type,
                            "severity": str(alert.severity),
                            "field": rule.field,
                            "operator": rule.operator,
                            "threshold": str(rule.threshold),
                            "current_value": str(current_value),
                        },
                    )

                    logger.info(
                        "Alert push notification sent successfully. alert_id=%s token_id=%s",
                        alert.id,
                        token.id,
                    )

                except Exception as token_error:
                    logger.error(
                        "Failed to send alert push notification. alert_id=%s token_id=%s error=%s",
                        alert.id,
                        token.id,
                        token_error,
                    )

        except Exception as error:
            logger.error(
                "Unexpected error while sending alert push notification. alert_id=%s error=%s",
                alert.id,
                error,
            )

    def _build_notification_title(self, severity: str) -> str:
        severity_text = str(severity).lower()

        if severity_text == "critical":
            return "Critical Greenhouse Alert"

        if severity_text == "warning":
            return "Greenhouse Warning"

        return "Greenhouse Notification"

    async def delete_alert(self, alert_id: uuid.UUID) -> bool:
        deleted = await self.alert_repo.delete(alert_id)

        if deleted:
            await self.alert_repo.commit()
            return True

        return False