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

The API does not apply migrations during startup. Run
`alembic upgrade head` before launching it to apply pending schema changes.
The default local database URL points to PostgreSQL on `localhost:5432`.
Set `DATABASE_URL` to a SQLite URL when running tests without PostgreSQL.

## Kubernetes deployment

The commands below describe a fresh Kustomize deployment. The existing local
`opssentinel` resources are now managed by the Helm release `demostore`; do not
apply the overlapping Kustomize manifests to that namespace.

Ensure the namespace and PostgreSQL resources are deployed first. Then run the
one-shot migration Job and apply the API overlay only after it completes:

```bash
kubectl apply -f kubernetes/base/demostore/namespace.yaml
kubectl apply -f kubernetes/base/demostore/postgres-secret.yaml
kubectl apply -f kubernetes/base/demostore/postgres-pvc.yaml
kubectl apply -f kubernetes/base/demostore/postgres-deployment.yaml
kubectl apply -f kubernetes/base/demostore/postgres-service.yaml
kubectl rollout status deployment/demostore-postgres \
  -n opssentinel --timeout=180s
kubectl apply -k kubernetes/overlays/local/migration
kubectl wait --for=condition=complete job/demostore-migrations \
  -n opssentinel --timeout=10m
kubectl apply -k kubernetes/overlays/local
kubectl rollout status deployment/demostore-api \
  -n opssentinel --timeout=180s
```

The migration Job and API use the same DemoStore image. Rebuild and load or
publish the updated image before deploying code or migration changes. A
completed Job is not rerun by `kubectl apply`; delete
`job/demostore-migrations` in `opssentinel` before applying the migration
overlay again for a later release.

## Helm chart

The chart is in `kubernetes/helm/demostore`. Lint and render its staged local
configuration without changing the cluster:

```bash
helm lint kubernetes/helm/demostore -f kubernetes/helm/demostore/values-local.yaml
helm template demostore kubernetes/helm/demostore \
  --namespace opssentinel \
  -f kubernetes/helm/demostore/values-local.yaml
```

The installed release manages the API and PostgreSQL Deployments and Services,
the API ConfigMap, and the PostgreSQL PVC. It references the existing
`demostore-db-secret` and has its migration hook disabled for this adopted
release. Use Helm for changes to these resources; do not reapply Kustomize
manifests to the same namespace. The PVC has Helm's `keep` policy, but protect
PostgreSQL data with verified backups as well.

`values-dev.yaml` targets `opssentinel-dev`, uses its namespace-local database
Secret, and opts into the PostgreSQL non-root security context validated for
the existing development PVC. The development workloads currently exist but
are not managed by a Helm release. Do not run `helm install` or `helm upgrade`
against that namespace until resource ownership and adoption have been reviewed.
The existing `opssentinel` release is separate and remains Helm-managed.

Render the dev configuration for review without changing the cluster:

```bash
helm lint kubernetes/helm/demostore \
  -f kubernetes/helm/demostore/values-dev.yaml
helm template demostore kubernetes/helm/demostore \
  --namespace opssentinel-dev \
  -f kubernetes/helm/demostore/values-dev.yaml \
  --set api.enabled=true
```

The chart's migration hook runs `alembic upgrade head` on install and before
upgrade. Review the rendered hook and database backup before any future Helm
operation. The current dev migration Job is a completed standalone Job; it is
not evidence of an installed dev Helm release.

Dev namespace controls are in
`kubernetes/overlays/dev/resource-controls.yaml`. The prepared PostgreSQL
NetworkPolicy is in `kubernetes/overlays/dev/network-policy.yaml`, but it is
not applied because the cluster's kindnet CNI does not enforce NetworkPolicies.
Do not treat that policy as network isolation.

See [the Phase 3 Kubernetes runbook](../../../docs/kubernetes-phase3.md) for
current namespace inventory, safe backup and rollback guidance, and remaining
validation work.

`values-local.yaml` contains a local-development password. Do not use it in
production. Set `postgres.auth.existingSecret` to a separately managed Secret
with `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` keys for
production deployments.

## API docs

- Swagger UI: http://localhost:8001/docs
- ReDoc: http://localhost:8001/redoc
- Metrics: http://localhost:8001/metrics
