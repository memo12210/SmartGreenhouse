from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1 import auth, users, greenhouses, devices, telemetry, alerts
from app.infrastructure.mqtt import mqtt_service
from app.infrastructure.redis import redis_service
from app.workers.mqtt_worker import start_mqtt_worker
from app.services.discovery import discovery_service

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await redis_service.connect()
    try:
        await mqtt_service.connect()
        await start_mqtt_worker()
        discovery_service.start()
    except Exception as e:
        # Don't fail startup if MQTT is down, but log it
        import logging
        logging.getLogger(__name__).error(f"Failed to connect to MQTT or start worker: {e}")
    yield
    # Shutdown
    await redis_service.disconnect()
    await mqtt_service.disconnect()

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan,
)

# Set all CORS enabled origins
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(users.router, prefix=f"{settings.API_V1_STR}/users", tags=["users"])
app.include_router(greenhouses.router, prefix=f"{settings.API_V1_STR}/greenhouses", tags=["greenhouses"])
app.include_router(devices.router, prefix=f"{settings.API_V1_STR}/devices", tags=["devices"])
app.include_router(telemetry.router, prefix=f"{settings.API_V1_STR}/telemetry", tags=["telemetry"])
app.include_router(alerts.router, prefix=f"{settings.API_V1_STR}/alerts", tags=["alerts"])


@app.get("/health")
async def health_check():
    return {"status": "ok"}
