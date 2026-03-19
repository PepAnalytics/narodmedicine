from pathlib import Path
from typing import Any

from django.conf import settings


class PushConfigurationError(Exception):
    pass


def _get_firebase_app():  # noqa: ANN202
    try:
        import firebase_admin
        from firebase_admin import credentials
    except ImportError as exc:
        raise PushConfigurationError(
            "firebase-admin package is not installed.",
        ) from exc

    credentials_path = settings.FCM_CREDENTIALS_PATH
    if not credentials_path:
        raise PushConfigurationError("FCM_CREDENTIALS_PATH is not configured.")

    credential_file = Path(credentials_path)
    if not credential_file.exists():
        raise PushConfigurationError(
            f"FCM credentials file does not exist: {credential_file}",
        )

    try:
        return firebase_admin.get_app()
    except ValueError:
        credential = credentials.Certificate(str(credential_file))
        options: dict[str, str] = {}
        if settings.FCM_PROJECT_ID:
            options["projectId"] = settings.FCM_PROJECT_ID
        return firebase_admin.initialize_app(
            credential=credential,
            options=options or None,
        )


def send_push_notifications(
    *,
    tokens: list[str],
    title: str,
    body: str,
    data: dict[str, str] | None = None,
    dry_run: bool = False,
) -> list[dict[str, Any]]:
    if not tokens:
        return []

    app = _get_firebase_app()
    from firebase_admin import messaging

    payload_data = data or {}
    results: list[dict[str, Any]] = []

    for token in tokens:
        message = messaging.Message(
            token=token,
            notification=messaging.Notification(title=title, body=body),
            data=payload_data,
        )
        try:
            message_id = messaging.send(message, dry_run=dry_run, app=app)
        except Exception as exc:  # noqa: BLE001
            results.append(
                {
                    "token": token,
                    "status": "failed",
                    "error": str(exc),
                }
            )
            continue

        results.append(
            {
                "token": token,
                "status": "sent",
                "message_id": message_id,
            }
        )

    return results
