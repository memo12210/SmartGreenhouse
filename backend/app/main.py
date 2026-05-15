from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.core.config import settings
from app.api.endpoints import health, test_db, auth, greenhouses, devices
from app.mqtt.handler import fast_mqtt

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Connect to MQTT
    await fast_mqtt.mqtt_startup()
    yield
    # Shutdown: Disconnect from MQTT
    await fast_mqtt.mqtt_shutdown()

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan
)

# Include routers
app.include_router(health.router, prefix=settings.API_V1_STR, tags=["health"])
app.include_router(test_db.router, prefix=settings.API_V1_STR, tags=["test"])
app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(greenhouses.router, prefix=f"{settings.API_V1_STR}/greenhouses", tags=["greenhouses"])
app.include_router(devices.router, prefix=f"{settings.API_V1_STR}/devices", tags=["devices"])

@app.get("/")
def root():
    return {"message": "Welcome to the Smart Greenhouse Monitoring System API"}
