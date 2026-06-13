import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1 import (
    auth,
    users,
    greenhouses,
    devices,
    telemetry,
    alerts,
    notifications,
    ml,
)
from app.infrastructure.mqtt import mqtt_service
from app.infrastructure.redis import redis_service
from app.workers.mqtt_worker import start_mqtt_worker
from app.workers.ml_prediction_worker import ml_prediction_worker
from app.workers.ml_training_worker import ml_training_worker
from app.services.discovery import discovery_service
from app.core.observability import setup_observability, start_metrics_server

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup. Each external dependency is connected independently so that one
    # outage (e.g. MQTT or Redis down) does not prevent the rest of the app —
    # and the background workers — from starting.
    start_metrics_server()

    try:
        await redis_service.connect()
    except Exception as e:
        logger.error(f"Failed to connect to Redis: {e}")

    try:
        await mqtt_service.connect()
    except Exception as e:
        logger.error(f"Failed to connect to MQTT broker: {e}")

    try:
        # Registers the telemetry subscription; safe to call even if MQTT is
        # currently down (it re-subscribes on reconnect).
        await start_mqtt_worker()
    except Exception as e:
        logger.error(f"Failed to start MQTT worker: {e}")

    # Background workers are independent of MQTT/Redis availability.
    discovery_service.start()
    ml_prediction_worker.start()
    ml_training_worker.start()

    yield

    # Shutdown: cancel background workers first, then close connections.
    await discovery_service.stop()
    await ml_prediction_worker.stop()
    await ml_training_worker.stop()
    await mqtt_service.disconnect()
    await redis_service.disconnect()


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
)

setup_observability(app)

# Set all CORS enabled origins
if settings.BACKEND_CORS_ORIGINS:
    origins = [str(origin) for origin in settings.BACKEND_CORS_ORIGINS]
    # A wildcard origin must not be combined with credentials: that effectively
    # lets any site make credentialed cross-origin requests. The API uses Bearer
    # tokens (not cookies), so credentials are only enabled for explicit origins.
    allow_all_origins = "*" in origins
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=not allow_all_origins,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(users.router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
app.include_router(
    greenhouses.router,
    prefix=f"{settings.API_V1_STR}/greenhouses",
    tags=["greenhouses"],
)
app.include_router(
    devices.router, prefix=f"{settings.API_V1_STR}/devices", tags=["devices"]
)
app.include_router(
    telemetry.router, prefix=f"{settings.API_V1_STR}/telemetry", tags=["telemetry"]
)
app.include_router(
    alerts.router, prefix=f"{settings.API_V1_STR}/alerts", tags=["alerts"]
)
app.include_router(
    notifications.router,
    prefix=f"{settings.API_V1_STR}/notifications",
    tags=["notifications"],
)
app.include_router(ml.router, prefix=f"{settings.API_V1_STR}/ml", tags=["ml"])


@app.get("/health")
async def health_check():
    return {"status": "ok"}
