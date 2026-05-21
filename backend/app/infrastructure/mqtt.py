import asyncio
import uuid
import json
import logging
from typing import Optional, Callable, Dict, Any
from gmqtt import Client as MQTTClient
from gmqtt.mqtt.constants import MQTTv50
from app.core.config import settings

logger = logging.getLogger(__name__)

class MQTTService:
    def __init__(self):
        self.client: Optional[MQTTClient] = None
        self.connected = False
        self.subscriptions: Dict[str, Callable[[str, Any], asyncio.Future]] = {}

    def _on_connect(self, client, flags, rc, properties):
        logger.info("Connected to MQTT Broker")
        self.connected = True
        # Resubscribe to topics on reconnect
        for topic in self.subscriptions:
            self.client.subscribe(topic)

    def _on_message(self, client, topic, payload, qos, properties):
        logger.info(f"Received MQTT message on {topic}")
        # Check for wildcard matches
        for sub_topic, callback in self.subscriptions.items():
            if self._topic_matches(sub_topic, topic):
                try:
                    data = json.loads(payload.decode())
                    asyncio.create_task(callback(topic, data))
                except Exception as e:
                    logger.error(f"Error processing MQTT message on {topic}: {e}")

    def _topic_matches(self, sub_topic: str, actual_topic: str) -> bool:
        # Simple MQTT wildcard matching logic (+ and #)
        import re
        pattern = sub_topic.replace("+", "[^/]+").replace("#", ".*")
        return re.fullmatch(pattern, actual_topic) is not None

    def _on_disconnect(self, client, packet, exc=None):
        logger.warning("Disconnected from MQTT Broker")
        self.connected = False

    async def connect(self):
        client_id = f"{settings.MQTT_CLIENT_ID}_{uuid.uuid4().hex[:8]}"
        self.client = MQTTClient(client_id)

        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message
        self.client.on_disconnect = self._on_disconnect

        if settings.MQTT_USER and settings.MQTT_PASSWORD:
            self.client.set_auth_credentials(settings.MQTT_USER, settings.MQTT_PASSWORD)

        try:
            await self.client.connect(settings.MQTT_HOST, settings.MQTT_PORT, keepalive=60)
        except Exception as e:
            logger.error(f"Failed to connect to MQTT Broker: {e}")
            raise

    async def disconnect(self):
        if self.client:
            await self.client.disconnect()

    async def subscribe(self, topic: str, callback: Callable[[str, Any], asyncio.Future]):
        self.subscriptions[topic] = callback
        if self.connected:
            self.client.subscribe(topic)

    async def publish(self, topic: str, payload: Any, qos: int = 1, retain: bool = False):
        if not self.connected:
            logger.error(f"Cannot publish to {topic}, MQTT not connected")
            return

        message = json.dumps(payload)
        self.client.publish(topic, message, qos=qos, retain=retain)

mqtt_service = MQTTService()
