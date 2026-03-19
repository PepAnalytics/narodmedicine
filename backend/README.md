# Folk Medicine Backend (Release 1.0 Prep)

Бэкенд MVP для мобильного справочника по народной медицине.

## Стек

- Python 3.12
- Django 4.2.x
- Django REST Framework
- PostgreSQL 14
- Redis
- Docker + docker-compose
- drf-yasg (Swagger/OpenAPI)
- black + flake8 + pre-commit
- Gunicorn + Nginx (production profile)

## Структура

```text
backend/
  folk_medicine/   # Django project
  core/            # модели и админка
  api/             # API эндпоинты
```

## Быстрый старт (Docker)

1. Создайте файл `.env` в корне проекта:

```bash
cp .env.example .env
```

2. Поднимите проект:

```bash
docker compose up --build
```

3. Примените миграции (если не применились автоматически):

```bash
docker compose exec backend python manage.py migrate
```

4. Создайте суперпользователя:

```bash
docker compose exec backend python manage.py createsuperuser
```

5. Загрузите стартовые данные и расширенный региональный каталог:

```bash
docker compose exec backend python manage.py load_initial_data
```

Для полной перезагрузки данных:

```bash
docker compose exec backend python manage.py load_initial_data --reset
```

Отдельный импорт только регионального контента:

```bash
docker compose exec backend python manage.py load_regional_content
```

```bash
docker compose exec backend python manage.py load_regional_content --reset
```

## URL

- Django Admin: `http://localhost:8000/admin/`
- Swagger UI: `http://localhost:8000/swagger/`
- OpenAPI JSON: `http://localhost:8000/swagger.json`
- Liveness: `http://localhost:8000/api/health/`
- Readiness: `http://localhost:8000/api/health/ready/`

## Переменные окружения (`.env`)

- `DEBUG` — режим отладки (`True`/`False`)
- `DJANGO_SECRET_KEY` — секретный ключ Django
- `ALLOWED_HOSTS` — список хостов через запятую
- `SERVICE_NAME` — имя сервиса для health/logging
- `APP_VERSION` — версия текущего релиза
- `CSRF_TRUSTED_ORIGINS` — доверенные origin-ы для CSRF
- `POSTGRES_DB` — имя БД Postgres
- `POSTGRES_USER` — пользователь БД
- `POSTGRES_PASSWORD` — пароль БД
- `POSTGRES_HOST` — хост Postgres (для docker-compose: `db`)
- `POSTGRES_PORT` — порт Postgres (обычно `5432`)
- `DATABASE_URL` — DSN строка подключения к БД
- `DATABASE_CONN_MAX_AGE` — время жизни соединений БД
- `DATABASE_CONN_HEALTH_CHECKS` — health-check соединений Django DB pool
- `REDIS_URL` — URL подключения к Redis
- `CORS_ALLOW_ALL_ORIGINS` — включить wildcard CORS (не рекомендуется для production)
- `CORS_ALLOWED_ORIGINS` — список разрешённых origin-ов через запятую
- `CORS_ALLOWED_ORIGIN_REGEXES` — regex-список origin-ов
- `CORS_ALLOW_CREDENTIALS` — нужно ли разрешать credentials
- `SECURE_SSL_REDIRECT` — принудительный HTTPS redirect
- `SESSION_COOKIE_SECURE` — secure-cookie для сессий
- `CSRF_COOKIE_SECURE` — secure-cookie для CSRF
- `SECURE_HSTS_SECONDS` — HSTS max-age
- `SECURE_HSTS_INCLUDE_SUBDOMAINS` — HSTS для поддоменов
- `SECURE_HSTS_PRELOAD` — HSTS preload
- `USE_X_FORWARDED_HOST` — доверять proxy host headers
- `ENABLE_PROXY_SSL_HEADER` — учитывать `X-Forwarded-Proto`
- `SECURE_REFERRER_POLICY` — referrer policy
- `X_FRAME_OPTIONS` — защита от clickjacking
- `FCM_CREDENTIALS_PATH` — путь до Firebase service account JSON
- `FCM_PROJECT_ID` — ID Firebase проекта (опционально)
- `CATALOG_CACHE_TTL` — TTL для каталогов, поиска, `/sync/`, популярных болезней
- `LEGAL_CACHE_TTL` — TTL для юридических документов
- `POPULAR_DISEASES_LIMIT` — лимит по умолчанию для `/api/diseases/popular/`
- `LOG_LEVEL` — общий уровень логирования
- `DJANGO_LOG_LEVEL` — уровень Django-логов
- `LOG_FILE` — путь до файла логов (опционально, иначе stdout/stderr)
- `COLLECTSTATIC` — запуск `collectstatic` при старте контейнера
- `GUNICORN_*` — tuning Gunicorn workers/threads/timeouts

## Production запуск

1. Создайте production env:

```bash
cp .env.prod.example .env
```

2. Укажите production домены и секреты:

- `ALLOWED_HOSTS=api.example.com`
- `CSRF_TRUSTED_ORIGINS=https://api.example.com`
- `CORS_ALLOWED_ORIGINS=https://app.example.com`
- `DJANGO_SECRET_KEY=<real-secret>`
- используйте длинный случайный ключ `DJANGO_SECRET_KEY` длиной 50+ символов
- `POSTGRES_PASSWORD=<real-password>`
- `FCM_CREDENTIALS_PATH=/run/secrets/firebase-service-account.json`

3. Положите TLS сертификаты в `deploy/certs/`:

- `deploy/certs/fullchain.pem`
- `deploy/certs/privkey.pem`

4. Поднимите production профиль:

```bash
docker compose -f docker-compose.prod.yml up --build -d
```

5. Проверьте readiness:

```bash
curl -i https://api.example.com/api/health/ready/
```

Production профиль использует:

- Gunicorn для Django app server
- Nginx для HTTPS termination и раздачи `/static/`
- Redis для кеша
- PostgreSQL 14

## Мониторинг и логирование

- Логи backend и nginx доступны через `docker compose -f docker-compose.prod.yml logs -f backend nginx`
- Liveness probe: `/api/health/`
- Readiness probe: `/api/health/ready/`
- Ошибки API продолжают возвращаться в едином формате
- Логирование по умолчанию идёт в stdout/stderr; при необходимости можно задать `LOG_FILE`

## Нагрузочное тестирование

Для минимального smoke-load теста ключевых endpoint-ов есть скрипт:

```bash
python backend/scripts/load_test.py --base-url http://127.0.0.1:8000 --requests 200 --concurrency 50
```

Скрипт проверяет:

- `POST /api/search/`
- `GET /api/diseases/popular/`
- `GET /api/diseases/{id}/`

Перед запуском убедитесь, что:

- backend доступен по `--base-url`
- стартовые данные загружены (`load_initial_data`)

## Линтинг и pre-commit

Установить dev-зависимости:

```bash
pip install -r backend/requirements-dev.txt
```

Установить pre-commit hooks:

```bash
pre-commit install
```

Запуск проверок вручную:

```bash
black --config backend/pyproject.toml backend
flake8 --config backend/.flake8 backend
```

## API (Sprint 4)

- `GET /api/symptoms/` (поддерживает нечёткий поиск: `?q=...`)
- `GET /api/health/`
- `GET /api/health/ready/`
- `POST /api/search/` (поддерживает фильтр `?region=arab`)
- `GET /api/diseases/popular/`
- `GET /api/diseases/{id}/` (поддерживает `?evidence_level=A,B` и `?region=arab`)
- `GET /api/remedies/` (поддерживает `?evidence_level=A&disease_id=1&region=arab`)
- `GET /api/remedies/{id}/`
- `POST /api/remedies/{id}/rate/`
- `POST /api/favorites/`
- `GET /api/favorites/` (пагинация: `?page=1&page_size=20`)
- `DELETE /api/favorites/{remedy_id}/`
- `POST /api/history/`
- `GET /api/history/`
- `GET /api/sync/`
- `GET /api/legal/terms/`
- `GET /api/legal/privacy/`
- `POST /api/legal/consents/`
- `POST /api/analytics/`
- `POST /api/push/subscribe/`
- `POST /api/push/unsubscribe/`
- `POST /api/push/notify/`

Единый формат ошибок:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Validation error.",
    "details": {
      "user_id": "Provide user_id in body, query, or X-User-Id."
    }
  }
}
```

Примеры:

```bash
curl http://localhost:8000/api/symptoms/
```

```bash
curl "http://localhost:8000/api/symptoms/?q=голов"
```

```bash
curl -X POST http://localhost:8000/api/search/ \
  -H "Content-Type: application/json" \
  -d '{"symptoms":["головная боль","тошнота"]}'
```

```bash
curl -X POST "http://localhost:8000/api/search/?region=arab" \
  -H "Content-Type: application/json" \
  -d '{"symptoms":["головная боль","тошнота"]}'
```

```bash
curl "http://localhost:8000/api/diseases/popular/?limit=5"
```

```bash
curl "http://localhost:8000/api/diseases/1/?evidence_level=A,B&region=arab"
```

```bash
curl "http://localhost:8000/api/remedies/?evidence_level=A&disease_id=1&region=arab"
```

```bash
curl http://localhost:8000/api/remedies/1/
```

```bash
curl -X POST http://localhost:8000/api/remedies/1/rate/ \
  -H "Content-Type: application/json" \
  -d '{"user_id":"some-uuid","is_like":true,"comment":"Помогло"}'
```

```bash
curl -X POST http://localhost:8000/api/favorites/ \
  -H "X-User-Id: some-uuid" \
  -H "Content-Type: application/json" \
  -d '{"remedy_id": 1}'
```

```bash
curl "http://localhost:8000/api/favorites/?page=1&page_size=20" \
  -H "X-User-Id: some-uuid"
```

```bash
curl -X DELETE http://localhost:8000/api/favorites/1/ -H "X-User-Id: some-uuid"
```

```bash
curl -X POST http://localhost:8000/api/history/ \
  -H "X-User-Id: some-uuid" \
  -H "Content-Type: application/json" \
  -d '{"remedy_id": 1}'
```

```bash
curl "http://localhost:8000/api/history/?page=1&page_size=20" \
  -H "X-User-Id: some-uuid"
```

```bash
curl -i http://localhost:8000/api/sync/
```

```bash
curl http://localhost:8000/api/legal/terms/
```

```bash
curl http://localhost:8000/api/legal/privacy/
```

```bash
curl -X POST http://localhost:8000/api/legal/consents/ \
  -H "X-User-Id: some-uuid" \
  -H "Content-Type: application/json" \
  -d '{"document_type":"terms_of_service","version":"1.0"}'
```

```bash
curl -X POST http://localhost:8000/api/analytics/ \
  -H "X-User-Id: some-uuid" \
  -H "Content-Type: application/json" \
  -d '{"event_type":"screen_view","metadata":{"screen":"search_results"}}'
```

```bash
curl -X POST http://localhost:8000/api/push/subscribe/ \
  -H "X-User-Id: some-uuid" \
  -H "Content-Type: application/json" \
  -d '{"fcm_token":"token-value","platform":"android"}'
```

```bash
curl -X POST http://localhost:8000/api/push/unsubscribe/ \
  -H "X-User-Id: some-uuid" \
  -H "Content-Type: application/json" \
  -d '{"fcm_token":"token-value"}'
```

```bash
curl -X POST http://localhost:8000/api/push/notify/ \
  -H "X-User-Id: some-uuid" \
  -H "Content-Type: application/json" \
  -d '{"title":"Напоминание","body":"Пора проверить избранные методы","dry_run":true}'
```

## Инициализационный датасет

Команда `load_initial_data` создаёт:

- 50 болезней
- 100 симптомов
- 100 ингредиентов
- 200 базовых методов лечения (по 4 на каждую болезнь)
- 180 региональных методов лечения (по 30 на каждый регион: arab, persian, caucasian, turkic, chinese, indian)
- 12 структурированных источников по регионам
- стартовые версии `TermsOfService` и `PrivacyPolicy`
- связи болезнь-симптом с весами `weight`

## Sprint 4

- `Remedy` расширен полями `region`, `cultural_context`, `source_record`
- `Ingredient` поддерживает `alternative_names` через `JSONField`
- Добавлены модели `Source`, `TermsOfService`, `PrivacyPolicy`, `UserConsent`, `AnalyticsEvent`
- Redis-кеширование используется для `/api/symptoms/`, `/api/search/`, `/api/diseases/popular/`, `/api/sync/`, а также актуальных юридических документов
- Инвалидация кеша выполняется автоматически через сигналы при изменениях из админки и доменных событий

## Sprint 5 Prep

- `POST /api/search/` дополнительно возвращает `short_description` и alias `matched_symptoms` для UI-карточек, сохраняя исходное поле `symptoms`
- `GET /api/diseases/popular/` дополнительно возвращает `short_description` и `remedies_count`, а поле `description` уже нормализовано под короткий карточный текст

## Release 1.0 Prep

- Добавлены production-safe security settings для HTTPS, HSTS, secure cookies и proxy headers
- Добавлен встроенный CORS middleware с настройкой через env
- Добавлены health endpoints `/api/health/` и `/api/health/ready/`
- Добавлены production-артефакты: `docker-compose.prod.yml`, `backend/gunicorn.conf.py`, `deploy/nginx/default.conf`, `.env.prod.example`
- Добавлен скрипт `backend/scripts/load_test.py` для минимального нагрузочного smoke-теста
