import uuid
from datetime import datetime, timezone
from typing import List, Optional
from app.domain.device import Device, DeviceStatus, DeviceCommand
from app.repositories.device import DeviceRepository, DeviceCommandRepository
from app.schemas.device import DeviceCreate, DeviceUpdate, DeviceCommandCreate
from app.infrastructure.mqtt import mqtt_service


class DeviceService:
    def __init__(self, device_repo: DeviceRepository, command_repo: DeviceCommandRepository):
        self.device_repo = device_repo
        self.command_repo = command_repo

    async def register_device(self, device_in: DeviceCreate) -> Device:
        device = Device(
            name=device_in.name,
            serial_number=device_in.serial_number,
            device_type=device_in.device_type,
            status=device_in.status,
            firmware_version=device_in.firmware_version,
            greenhouse_id=device_in.greenhouse_id
        )
        created = await self.device_repo.create(device)
        await self.device_repo.commit()
        return created

    async def update_device_status(self, device_id: uuid.UUID, status: DeviceStatus):
        device = await self.device_repo.get(device_id)
        if device:
            await self.device_repo.update(device, {"status": status, "last_seen_at": datetime.now(timezone.utc)})
            await self.device_repo.commit()

    async def update_device(self, device_id: uuid.UUID, device_in: DeviceUpdate) -> Optional[Device]:
        db_obj = await self.device_repo.get(device_id)
        if not db_obj:
            return None
        updated = await self.device_repo.update(db_obj, device_in.model_dump(exclude_unset=True))
        await self.device_repo.commit()
        return updated

    async def delete_device(self, device_id: uuid.UUID):
        await self.device_repo.delete(device_id)
        await self.device_repo.commit()

    async def send_command(self, device_id: uuid.UUID, command_in: DeviceCommandCreate, user_id: uuid.UUID):
        device = await self.device_repo.get(device_id)
        if not device:
            raise ValueError("Device not found")

        command = DeviceCommand(
            device_id=device_id,
            command=command_in.command,
            payload=command_in.payload,
            issued_by=user_id,
            status="pending"
        )
        await self.command_repo.create(command)
        await self.command_repo.commit()

        # Publish to MQTT
        topic = f"greenhouse/{device.greenhouse_id}/device/{device.id}/commands"
        await mqtt_service.publish(topic, {"command_id": str(command.id), "command": command.command, "payload": command.payload})

        # Update command status to 'sent'
        await self.command_repo.update(command, {"status": "sent"})
        await self.command_repo.commit()
        return command
