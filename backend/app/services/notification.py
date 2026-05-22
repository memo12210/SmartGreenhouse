from app.domain.fcm_token import FcmToken
from app.repositories.fcm_token import FcmTokenRepository
from app.schemas.notification import FcmTokenCreate


class NotificationTokenService:
    def __init__(self, token_repo: FcmTokenRepository):
        self.token_repo = token_repo

    async def register_token(
        self,
        user_id,
        token_in: FcmTokenCreate,
    ) -> FcmToken:
        existing = await self.token_repo.get_by_token(token_in.token)

        if existing:
            updated = await self.token_repo.update(
                existing,
                {
                    "user_id": user_id,
                    "platform": token_in.platform,
                    "device_name": token_in.device_name,
                    "is_active": True,
                },
            )
            await self.token_repo.commit()
            return updated

        token = FcmToken(
            user_id=user_id,
            token=token_in.token,
            platform=token_in.platform,
            device_name=token_in.device_name,
            is_active=True,
        )

        created = await self.token_repo.create(token)
        await self.token_repo.commit()
        return created