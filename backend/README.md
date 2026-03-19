# Folk Medicine Backend (Sprint 2)

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

5. Загрузите стартовые данные Sprint 1:

```bash
docker compose exec backend python manage.py load_initial_data
```

Для полной перезагрузки данных:

```bash
docker compose exec backend python manage.py load_initial_data --reset
```

## URL

- Django Admin: `http://localhost:8000/admin/`
- Swagger UI: `http://localhost:8000/swagger/`
- OpenAPI JSON: `http://localhost:8000/swagger.json`

## Переменные окружения (`.env`)

- `DEBUG` — режим отладки (`True`/`False`)
- `DJANGO_SECRET_KEY` — секретный ключ Django
- `ALLOWED_HOSTS` — список хостов через запятую
- `POSTGRES_DB` — имя БД Postgres
- `POSTGRES_USER` — пользователь БД
- `POSTGRES_PASSWORD` — пароль БД
- `POSTGRES_HOST` — хост Postgres (для docker-compose: `db`)
- `POSTGRES_PORT` — порт Postgres (обычно `5432`)
- `DATABASE_URL` — DSN строка подключения к БД
- `REDIS_URL` — URL подключения к Redis

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

## API (Sprint 2)

- `GET /api/symptoms/` (поддерживает нечёткий поиск: `?q=...`)
- `POST /api/search/`
- `GET /api/diseases/{id}/`
- `GET /api/remedies/`
- `GET /api/remedies/{id}/`
- `POST /api/remedies/{id}/rate/`
- `POST /api/favorites/`
- `GET /api/favorites/`
- `DELETE /api/favorites/{remedy_id}/`
- `POST /api/history/`
- `GET /api/history/`
- `GET /api/sync/`

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
curl "http://localhost:8000/api/diseases/1/?evidence_level=A,B"
```

```bash
curl "http://localhost:8000/api/remedies/?evidence_level=A&disease_id=1"
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
curl http://localhost:8000/api/favorites/ -H "X-User-Id: some-uuid"
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

## Инициализационный датасет

Команда `load_initial_data` создаёт:

- 50 болезней
- 100 симптомов
- 100 ингредиентов
- 200 методов лечения (по 4 на каждую болезнь)
- связи болезнь-симптом с весами `weight`
