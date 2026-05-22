import os
from pathlib import Path
from typing import Dict, Optional

import firebase_admin
from firebase_admin import credentials, messaging


class PushNotificationService:
    _initialized = False

    def __init__(self):
        self._initialize_firebase()

    def _initialize_firebase(self):
        if PushNotificationService._initialized:
            return

        service_account_path = Path(
            os.getenv(
                "FIREBASE_SERVICE_ACCOUNT_PATH",
                "app/secrets/firebase-service-account.json",
            )
        )

        if not service_account_path.exists():
            raise FileNotFoundError(
                f"Firebase service account file not found: {service_account_path}"
            )

        cred = credentials.Certificate(str(service_account_path))

        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)

        PushNotificationService._initialized = True

    async def send_to_token(
        self,
        token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None,
    ) -> str:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="greenhouse_alerts",
                    sound="default",
                ),
            ),
        )

        response = messaging.send(message)
        return response