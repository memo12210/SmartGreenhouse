from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.domain.user import User
from app.repositories.fcm_token import FcmTokenRepository
from app.schemas.notification import FcmTokenCreate, FcmTokenRead
from app.services.notification import NotificationTokenService
from app.services.push_notification import PushNotificationService

router = APIRouter()


@router.post("/fcm-token", response_model=FcmTokenRead)
async def register_fcm_token(
    token_in: FcmTokenCreate,
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    service = NotificationTokenService(FcmTokenRepository(db))

    return await service.register_token(
        user_id=current_user.id,
        token_in=token_in,
    )


@router.post("/test")
async def send_test_notification(
    current_user: User = Depends(deps.get_current_user),
    db: AsyncSession = Depends(deps.get_db),
):
    token_repo = FcmTokenRepository(db)
    tokens = await token_repo.get_active_by_user(current_user.id)

    if not tokens:
        return {
            "status": "error",
            "message": "No active FCM token found for current user.",
        }

    push_service = PushNotificationService()

    results = []
    success_count = 0
    failure_count = 0

    for token in tokens:
        try:
            firebase_response = await push_service.send_to_token(
                token=token.token,
                title="Smart Greenhouse Test",
                body="Push notification system is working successfully.",
                data={
                    "type": "test_notification",
                    "user_id": str(current_user.id),
                },
            )

            success_count += 1

            results.append(
                {
                    "token_id": str(token.id),
                    "status": "success",
                    "firebase_response": firebase_response,
                }
            )

        except Exception as error:
            failure_count += 1

            results.append(
                {
                    "token_id": str(token.id),
                    "status": "failed",
                    "error": str(error),
                }
            )

    return {
        "status": "completed",
        "success_count": success_count,
        "failure_count": failure_count,
        "results": results,
    }