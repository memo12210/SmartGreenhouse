from typing import Optional
from redis.asyncio import Redis, from_url
from app.core.config import settings

class RedisService:
    def __init__(self):
        self.client: Optional[Redis] = None

    async def connect(self):
        self.client = from_url(str(settings.REDIS_URL), decode_responses=True)

    async def disconnect(self):
        if self.client:
            await self.client.close()

    async def get(self, key: str) -> Optional[str]:
        return await self.client.get(key)

    async def set(self, key: str, value: str, expire: Optional[int] = None):
        await self.client.set(key, value, ex=expire)

    async def delete(self, key: str):
        await self.client.delete(key)

redis_service = RedisService()
