import uuid
from typing import Optional, List
from sqlalchemy import select
from app.domain.device import Device, DeviceCommand
from app.repositories.base import BaseRepository


class DeviceRepository(BaseRepository[Device]):
    def __init__(self, session):
        super().__init__(Device, session)

    async def get_by_serial(self, serial_number: str) -> Optional[Device]:
        query = select(Device).where(Device.serial_number == serial_number)
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def get_by_greenhouse(self, greenhouse_id: uuid.UUID) -> List[Device]:
        query = select(Device).where(Device.greenhouse_id == greenhouse_id)
        result = await self.session.execute(query)
        return list(result.scalars().all())


class DeviceCommandRepository(BaseRepository[DeviceCommand]):
    def __init__(self, session):
        super().__init__(DeviceCommand, session)

    async def get_pending_commands(self, device_id: uuid.UUID) -> List[DeviceCommand]:
        query = select(DeviceCommand).where(
            DeviceCommand.device_id == device_id,
            DeviceCommand.status == "pending"
        )
        result = await self.session.execute(query)
        return list(result.scalars().all())
