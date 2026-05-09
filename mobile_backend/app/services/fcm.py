"""Thin wrapper around firebase-admin for FCM sending.

In dev or test, ``send`` becomes a logged no-op when ``FCM_PROJECT_ID`` and
``FCM_CREDENTIALS_PATH`` are not set.
"""

import logging
from typing import Any, Dict, Optional

from ..core.settings import get_settings

logger = logging.getLogger(__name__)


class FcmService:
    def __init__(self) -> None:
        self.settings = get_settings()
        self._initialized = False
        self._enabled = bool(self.settings.fcm_project_id and self.settings.fcm_credentials_path)

    def _ensure_init(self) -> None:
        if self._initialized or not self._enabled:
            return
        try:
            import firebase_admin  # type: ignore
            from firebase_admin import credentials  # type: ignore
        except Exception:
            logger.warning("firebase_admin not available; FCM disabled.")
            self._enabled = False
            return
        cred = credentials.Certificate(self.settings.fcm_credentials_path)
        firebase_admin.initialize_app(cred, {"projectId": self.settings.fcm_project_id})
        self._initialized = True

    def send_to_token(
        self,
        token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None,
    ) -> Optional[str]:
        if not self._enabled:
            logger.info("FCM (no-op): %s | %s", title, body)
            return None
        self._ensure_init()
        try:
            from firebase_admin import messaging  # type: ignore
        except Exception:
            return None
        msg = messaging.Message(
            token=token,
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
        )
        return messaging.send(msg)
