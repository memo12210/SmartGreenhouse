import uuid
from typing import List, Optional
from app.domain.alert import Alert
from app.repositories.alert import AlertRepository
from app.schemas.alert import AlertCreate


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
