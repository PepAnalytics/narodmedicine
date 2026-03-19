from pathlib import Path

import environ

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(
    DEBUG=(bool, False),
)
environ.Env.read_env(BASE_DIR.parent / ".env")

SECRET_KEY = env("DJANGO_SECRET_KEY", default="django-insecure-change-me")
DEBUG = env("DEBUG")
SERVICE_NAME = env("SERVICE_NAME", default="folk-medicine-backend")
APP_VERSION = env("APP_VERSION", default="1.0.0")

ALLOWED_HOSTS = env.list(
    "ALLOWED_HOSTS",
    default=["localhost", "127.0.0.1", "testserver"],
)
CSRF_TRUSTED_ORIGINS = env.list("CSRF_TRUSTED_ORIGINS", default=[])

CORS_ALLOW_ALL_ORIGINS = env.bool("CORS_ALLOW_ALL_ORIGINS", default=False)
CORS_ALLOWED_ORIGINS = env.list("CORS_ALLOWED_ORIGINS", default=[])
CORS_ALLOWED_ORIGIN_REGEXES = env.list("CORS_ALLOWED_ORIGIN_REGEXES", default=[])
CORS_ALLOW_CREDENTIALS = env.bool("CORS_ALLOW_CREDENTIALS", default=False)
CORS_ALLOW_METHODS = env.list(
    "CORS_ALLOW_METHODS",
    default=["DELETE", "GET", "OPTIONS", "PATCH", "POST", "PUT"],
)
CORS_ALLOW_HEADERS = env.list(
    "CORS_ALLOW_HEADERS",
    default=[
        "Accept",
        "Accept-Language",
        "Authorization",
        "Content-Language",
        "Content-Type",
        "Origin",
        "User-Agent",
        "X-Requested-With",
        "X-User-Id",
    ],
)
CORS_EXPOSE_HEADERS = env.list(
    "CORS_EXPOSE_HEADERS",
    default=["Content-Type", "X-User-Id"],
)


# Application definition

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "drf_yasg",
    "core",
    "api",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "folk_medicine.middleware.SimpleCORSMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "folk_medicine.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "folk_medicine.wsgi.application"


DATABASES = {
    "default": env.db(
        "DATABASE_URL",
        default="postgres://postgres:postgres@db:5432/folk_medicine",
    )
}
DATABASES["default"]["CONN_MAX_AGE"] = env.int("DATABASE_CONN_MAX_AGE", default=60)
DATABASES["default"]["CONN_HEALTH_CHECKS"] = env.bool(
    "DATABASE_CONN_HEALTH_CHECKS",
    default=True,
)

CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": env("REDIS_URL", default="redis://redis:6379/1"),
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": (
            "django.contrib.auth.password_validation."
            "UserAttributeSimilarityValidator"
        ),
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


LANGUAGE_CODE = "ru-ru"

TIME_ZONE = "UTC"

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/4.2/howto/static-files/

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

SECURE_SSL_REDIRECT = env.bool("SECURE_SSL_REDIRECT", default=not DEBUG)
SESSION_COOKIE_SECURE = env.bool("SESSION_COOKIE_SECURE", default=not DEBUG)
CSRF_COOKIE_SECURE = env.bool("CSRF_COOKIE_SECURE", default=not DEBUG)
SECURE_HSTS_SECONDS = env.int(
    "SECURE_HSTS_SECONDS",
    default=31_536_000 if not DEBUG else 0,
)
SECURE_HSTS_INCLUDE_SUBDOMAINS = env.bool(
    "SECURE_HSTS_INCLUDE_SUBDOMAINS",
    default=not DEBUG,
)
SECURE_HSTS_PRELOAD = env.bool("SECURE_HSTS_PRELOAD", default=not DEBUG)
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = env(
    "SECURE_REFERRER_POLICY",
    default="strict-origin-when-cross-origin",
)
USE_X_FORWARDED_HOST = env.bool("USE_X_FORWARDED_HOST", default=True)
if env.bool("ENABLE_PROXY_SSL_HEADER", default=True):
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
X_FRAME_OPTIONS = env("X_FRAME_OPTIONS", default="DENY")

REST_FRAMEWORK = {
    "DEFAULT_SCHEMA_CLASS": "rest_framework.schemas.openapi.AutoSchema",
    "EXCEPTION_HANDLER": "api.exceptions.custom_exception_handler",
}

SWAGGER_SETTINGS = {
    "USE_SESSION_AUTH": False,
    "SECURITY_DEFINITIONS": {},
}

FCM_CREDENTIALS_PATH = env("FCM_CREDENTIALS_PATH", default="")
FCM_PROJECT_ID = env("FCM_PROJECT_ID", default="")
CATALOG_CACHE_TTL = env.int("CATALOG_CACHE_TTL", default=3600)
LEGAL_CACHE_TTL = env.int("LEGAL_CACHE_TTL", default=3600)
POPULAR_DISEASES_LIMIT = env.int("POPULAR_DISEASES_LIMIT", default=10)

LOG_LEVEL = env("LOG_LEVEL", default="INFO").upper()
DJANGO_LOG_LEVEL = env("DJANGO_LOG_LEVEL", default=LOG_LEVEL).upper()
LOG_FILE = env("LOG_FILE", default="")

_log_handlers = {
    "console": {
        "class": "logging.StreamHandler",
        "formatter": "verbose",
        "level": LOG_LEVEL,
    }
}
if LOG_FILE:
    log_file_path = Path(LOG_FILE).expanduser()
    log_file_path.parent.mkdir(parents=True, exist_ok=True)
    _log_handlers["file"] = {
        "class": "logging.handlers.RotatingFileHandler",
        "filename": str(log_file_path),
        "maxBytes": 10 * 1024 * 1024,
        "backupCount": 5,
        "formatter": "verbose",
        "level": LOG_LEVEL,
    }

_default_log_handlers = list(_log_handlers)

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": (
                "[{asctime}] {levelname} {name} "
                "(pid={process:d} thread={thread:d}): {message}"
            ),
            "style": "{",
        }
    },
    "handlers": _log_handlers,
    "root": {
        "handlers": _default_log_handlers,
        "level": LOG_LEVEL,
    },
    "loggers": {
        "django": {
            "handlers": _default_log_handlers,
            "level": DJANGO_LOG_LEVEL,
            "propagate": False,
        },
        "django.request": {
            "handlers": _default_log_handlers,
            "level": DJANGO_LOG_LEVEL,
            "propagate": False,
        },
        "django.server": {
            "handlers": _default_log_handlers,
            "level": DJANGO_LOG_LEVEL,
            "propagate": False,
        },
        "api": {
            "handlers": _default_log_handlers,
            "level": LOG_LEVEL,
            "propagate": False,
        },
        "core": {
            "handlers": _default_log_handlers,
            "level": LOG_LEVEL,
            "propagate": False,
        },
    },
}
