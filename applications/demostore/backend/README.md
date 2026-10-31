# DemoStore Backend

FastAPI-based demo ecommerce application used as the workload for OpsSentinel AI.

## Features

- Product CRUD endpoints
- Order creation and listing
- Health and readiness checks
- Prometheus metrics endpoint
- SQLAlchemy database layer with PostgreSQL and SQLite support
- Docker-ready configuration for local and cloud deployment

## Local run with WSL

Run these commands in a WSL terminal from the repository root:

```bash
docker compose up -d demostore-db
cd /mnt/c/Users/Parth/OneDrive/Desktop/OpsSentinel\ AI/applications/demostore/backend
python3 -m venv "$HOME/.venvs/opssentinel-demostore"
source "$HOME/.venvs/opssentinel-demostore/bin/activate"
python -m pip install -r requirements.txt
if [ ! -f .env ]; then cp .env.example .env; fi
alembic upgrade head
uvicorn app.main:app --reload --port 8001
```

If the Compose API service is already running on port 8001, stop it before
starting Uvicorn directly:

```bash
cd /mnt/c/Users/Parth/OneDrive/Desktop/OpsSentinel\ AI
docker compose stop demostore-api
```

Alternatively, run both services in containers from the repository root with
`docker compose up --build`.

The API also applies pending Alembic migrations during startup. The explicit
`alembic upgrade head` command is useful for applying migrations before launch.
The default local database URL points to PostgreSQL on `localhost:5432`.
Set `DATABASE_URL` to a SQLite URL when running tests without PostgreSQL.

## API docs

- Swagger UI: http://localhost:8001/docs
- ReDoc: http://localhost:8001/redoc
- Metrics: http://localhost:8001/metrics
