from fastapi import FastAPI
from app.core.config import settings
from app.api.endpoints import health, test_db, auth

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Include routers
app.include_router(health.router, prefix=settings.API_V1_STR, tags=["health"])
app.include_router(test_db.router, prefix=settings.API_V1_STR, tags=["test"])
app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["auth"])

@app.get("/")
def root():
    return {"message": "Welcome to the Smart Greenhouse Monitoring System API"}
