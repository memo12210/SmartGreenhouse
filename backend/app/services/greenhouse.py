import uuid
from typing import List, Optional
from app.domain.greenhouse import Greenhouse
from app.repositories.greenhouse import GreenhouseRepository
from app.schemas.greenhouse import GreenhouseCreate, GreenhouseUpdate


class GreenhouseService:
    def __init__(self, greenhouse_repo: GreenhouseRepository):
        self.greenhouse_repo = greenhouse_repo

    async def create_greenhouse(self, owner_id: uuid.UUID, greenhouse_in: GreenhouseCreate) -> Greenhouse:
        greenhouse = Greenhouse(
            name=greenhouse_in.name,
            location=greenhouse_in.location,
            extra_metadata=greenhouse_in.extra_metadata,
            owner_id=owner_id
        )
        created = await self.greenhouse_repo.create(greenhouse)
        await self.greenhouse_repo.commit()
        return created

    async def get_greenhouse(self, greenhouse_id: uuid.UUID) -> Optional[Greenhouse]:
        return await self.greenhouse_repo.get(greenhouse_id)

    async def list_greenhouses(self, owner_id: uuid.UUID) -> List[Greenhouse]:
        return await self.greenhouse_repo.get_by_owner(owner_id)

    async def update_greenhouse(self, greenhouse_id: uuid.UUID, greenhouse_in: GreenhouseUpdate) -> Optional[Greenhouse]:
        db_obj = await self.greenhouse_repo.get(greenhouse_id)
        if not db_obj:
            return None
        updated = await self.greenhouse_repo.update(db_obj, greenhouse_in.model_dump(exclude_unset=True))
        await self.greenhouse_repo.commit()
        return updated

    async def delete_greenhouse(self, greenhouse_id: uuid.UUID):
        await self.greenhouse_repo.delete(greenhouse_id)
        await self.greenhouse_repo.commit()
