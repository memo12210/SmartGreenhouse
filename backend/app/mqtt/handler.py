import json
import logging
from fastapi_mqtt import FastMQTT, MQTTConfig
from app.core.config import settings
from app.database import SessionLocal
from app.models.device import Device
from app.models.telemetry import Telemetry

logger = logging.getLogger(__name__)

mqtt_config = MQTTConfig(
    host=settings.MQTT_BROKER_HOST,
    port=settings.MQTT_BROKER_PORT,
    keepalive=settings.MQTT_KEEPALIVE,
    username=settings.MQTT_USERNAME,
    password=settings.MQTT_PASSWORD
)

fast_mqtt = FastMQTT(config=mqtt_config)

@fast_mqtt.on_connect()
def connect(client, flags, rc, properties):
    logger.info("Connected to MQTT Broker")
    # Subscribe to telemetry for all users, greenhouses, and devices
    # Structure: gh/v1/+/+/+/telemetry
    client.subscribe("gh/v1/+/+/+/telemetry")

@fast_mqtt.subscribe("gh/v1/+/+/+/telemetry")
async def telemetry_message_handler(client, topic, payload, qos, properties):
    logger.info(f"Received message on topic: {topic}")

    try:
        # 1. Parse Topic to extract IDs
        # Topic format: gh/v1/<user_id>/<gh_id>/<device_mac>/telemetry
        parts = topic.split("/")
        if len(parts) < 6:
            logger.warning(f"Invalid topic structure: {topic}")
            return

        user_id = parts[2]
        gh_id = parts[3]
        device_mac = parts[4]

        # 2. Parse JSON Payload
        data = json.loads(payload.decode())

        # 3. Database Ingestion
        db = SessionLocal()
        try:
            # Validate device exists and is linked correctly (optional but recommended)
            device = db.query(Device).filter(Device.mac_address == device_mac).first()
            if not device:
                logger.error(f"Unregistered device attempted to send telemetry: {device_mac}")
                return

            # Map JSON fields to Telemetry model
            new_reading = Telemetry(
                device_id=device.id,
                temperature=data.get("temperature"),
                humidity=data.get("humidity"),
                light=data.get("light"),
                soil_moisture=data.get("soil_moisture")
            )

            db.add(new_reading)
            db.commit()
            logger.debug(f"Telemetry saved for device {device_mac}")

        finally:
            db.close()

    except Exception as e:
        logger.error(f"Error processing telemetry message: {str(e)}")

@fast_mqtt.on_disconnect()
def disconnect(client, packet, exc=None):
    logger.info("Disconnected from MQTT Broker")

@fast_mqtt.on_subscribe()
def subscribe(client, mid, qos, properties):
    logger.info("Subscribed to telemetry topics")

async def broadcast_discovery(user_id: str, mapping: dict):
    """
    Broadcast greenhouse mapping to devices for a specific user.
    Topic: greenhouses/
    Payload: {"user_id": "...", "mapping": {"gh_id": ["MAC1", "MAC2"]}}
    """
    payload = {
        "user_id": str(user_id),
        "mapping": mapping
    }
    logger.info(f"Broadcasting discovery for user {user_id}")
    # fast_mqtt.publish is synchronous
    fast_mqtt.publish("greenhouses/", json.dumps(payload), qos=1, retain=False)
