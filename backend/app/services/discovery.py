import logging
import asyncio
from app.infrastructure.mqtt import mqtt_service
from app.repositories.device import DeviceRepository
from app.infrastructure.database import SessionLocal

logger = logging.getLogger(__name__)

class DiscoveryService:
    def __init__(self):
        self._task = None

    async def broadcast_discovery(self):
        """
        Periodically broadcast the mapping of Serial Numbers (MACs) to Greenhouse and Device IDs.
        Format: {"mapping": {"<GH_ID>": {"<MAC1>": "<DEV_ID1>", "<MAC2>": "<DEV_ID2>"}}}
        """
        while True:
            try:
                async with SessionLocal() as db:
                    repo = DeviceRepository(db)
                    # Fetch devices (limit to 1000 for scalability)
                    devices = await repo.get_multi(limit=1000)

                    # Group device information by greenhouse_id
                    mapping = {}
                    for dev in devices:
                        gh_id = str(dev.greenhouse_id)
                        if gh_id not in mapping:
                            mapping[gh_id] = {}

                        # Map MAC (serial_number) to the internal Device UUID
                        mapping[gh_id][dev.serial_number] = str(dev.id)

                    payload = {
                        "mapping": mapping
                    }

                    await mqtt_service.publish("greenhouse/mapping", payload, retain=True)
                    logger.debug("Broadcasted device discovery mapping")
            except Exception as e:
                logger.error(f"Error in discovery broadcast: {e}")

            await asyncio.sleep(60)  # Broadcast every 60 seconds

    def start(self):
        if self._task is None:
            self._task = asyncio.create_task(self.broadcast_discovery())
            logger.info("Backend Discovery Service started")

discovery_service = DiscoveryService()
