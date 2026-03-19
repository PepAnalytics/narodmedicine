from django.apps import AppConfig


class CoreConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "core"

    def ready(self) -> None:
        # Import signals after app loading to avoid side effects at import time.
        import core.signals  # noqa: F401
