# Phase 3: Kubernetes and Helm Runbook

**Status:** In progress. Core local deployment, development security controls,
database recovery, and isolated NetworkPolicy enforcement have been verified.
Remaining validation is listed at the end of this runbook; this does not claim
production readiness.

## Architecture

```text
Kind cluster: kind-kubemind (kubectl context: kind-kind-kubemind)
├── opssentinel
│   ├── Helm release: demostore (chart 0.1.1, revision 2)
│   ├── DemoStore API: 2 replicas
│   ├── PostgreSQL: 1 replica
│   ├── completed migration Job
│   └── demostore-postgres-pvc (2Gi)
└── opssentinel-dev
    ├── standalone dev workloads (no Helm release)
    ├── DemoStore API: 2 replicas, security-test image, UID/GID 10001
    ├── PostgreSQL: 1 replica, UID/GID 70
    ├── completed migration Job
    ├── demostore-postgres-pvc (2Gi)
    ├── ResourceQuota and LimitRange
    └── NetworkPolicy manifest prepared but not applied in this cluster

Separate disposable test cluster: opssentinel-netpol-test
├── Calico 3.33.0; both nodes Ready
└── netpol-test namespace: baseline, deny, and allow checks passed
```

Services are namespace-local ClusterIP services. The API connects to
`demostore-postgres:5432`. Database credentials are supplied through the
namespace-local `demostore-db-secret`; do not put credentials in Helm values.

## Current inventory and safety boundaries

- The `opssentinel` Helm release remains deployed at revision 2 and chart
  `0.1.1`. No security rollout or Helm upgrade was performed there.
- The source chart is now `0.1.2`; it has not been installed through Helm.
- `opssentinel-dev` has no Helm release. Its API and PostgreSQL Deployments
  have Helm-style labels but were updated by rendering individual templates
  and applying the standalone resources. Do not install or adopt a release
  over them until ownership is reviewed.
- Both application namespaces have a distinct Bound 2Gi PVC. The dev PVC is
  `pvc-3106d0e6-6fe6-4423-8c5c-490a5fad7cb3`; the `opssentinel` PVC is
  `pvc-038e6f5a-f763-4f86-8045-4ab3a16fa575`. Preserve both.
- A separate `demostore-postgres-pvc` also exists in `default`, left from an
  earlier namespace mistake. It was not inspected for deletion and must remain
  untouched.
- The `standard` StorageClass uses the `Delete` PV reclaim policy. PVC
  retention is essential.
- The separate `opssentinel-netpol-test` cluster is configured with Calico
  3.33.0. Its two nodes are Ready and all reported Tigera components are
  available. NetworkPolicy acceptance tests were run only in its `netpol-test`
  namespace; the cluster is retained for inspection.

Read-only status commands:

```bash
kubectl config current-context
helm list -A
kubectl get deployments,services,pods,pvc,jobs -n opssentinel
kubectl get deployments,services,pods,pvc,jobs -n opssentinel-dev
kubectl get pvc -A
```

## Deployment and Helm workflow

The adopted `opssentinel` release is Helm-managed. Use
`kubernetes/helm/demostore/values-local.yaml` for rendering and review its
diff before any Helm change. Do not apply overlapping Kustomize resources to
that namespace.

The dev workloads are not Helm-managed. `values-dev.yaml` is suitable for
future rendering, but an install or upgrade against the existing dev resources
requires an explicit ownership/adoption plan. Render without changing the
cluster:

```bash
helm lint kubernetes/helm/demostore \
  --values kubernetes/helm/demostore/values-dev.yaml
helm template demostore kubernetes/helm/demostore \
  --namespace opssentinel-dev \
  --values kubernetes/helm/demostore/values-dev.yaml \
  --set api.enabled=true
```

Before any deployment, inspect the exact rendered resource list and use
`kubectl diff` or an equivalent reviewed Helm diff. Preserve the existing
Secret and PVC. Helm rollback restores Kubernetes resources but does not roll
back database schema migrations; migrations must be forward-compatible and
database recovery must use a verified backup.

The production-style Helm release history currently contains revisions 1 and
2. No rollback test has been performed. Any production-style Helm upgrade or
rollback requires a separate explicit authorization.

For a dev-only Deployment rollback, inspect history first, then roll back only
the selected Deployment if its latest template fails:

```bash
kubectl rollout history deployment/demostore-api -n opssentinel-dev
kubectl rollout undo deployment/demostore-api -n opssentinel-dev
kubectl rollout status deployment/demostore-api -n opssentinel-dev
```

The PostgreSQL Deployment can also be reverted with `kubectl rollout undo`,
but first check the dev backup, PVC identity, and current database readiness.
Do not delete or recreate the PVC. For the production-style Helm release, the
reviewed rollback command is:

```bash
helm rollback demostore <reviewed-revision> --namespace opssentinel
```

Do not run a production rollback without explicit authorization. A Deployment
or Helm rollback does not reverse Alembic schema changes.

## Migration runbook

The API does not run Alembic migrations during startup. The migration Job runs
`alembic upgrade head` after waiting for PostgreSQL.

Inspect migration status and logs:

```bash
kubectl get jobs,pods -n opssentinel-dev
kubectl logs job/demostore-migrations -n opssentinel-dev
kubectl exec deployment/demostore-postgres -n opssentinel-dev -- \
  psql -U demostore -d demostore -Atc \
  'SELECT version_num FROM alembic_version'
```

The dev database reported revision `0001`; the `products`, `orders`, and
`alembic_version` tables exist. The existing migration Job is complete. Do not
delete or rerun a completed Job without a pending migration or a specific
reason.

## API security and validation

The API image creates UID/GID `10001`; its application files are readable by
that user, `/app` is not writable, and `/tmp` is writable. The dev API uses
`runAsNonRoot`, UID/GID `10001`, `RuntimeDefault` seccomp, disabled privilege
escalation, and dropped capabilities.

The dev PostgreSQL Deployment uses UID/GID `70`, `RuntimeDefault` seccomp,
disabled privilege escalation, and dropped capabilities. This was enabled
only after checking the live data directory (`70:0`, mode `700`), runtime
paths, a PostgreSQL 16 non-root smoke test, and a readable dev database backup.
The official entrypoint and storage behavior must be reassessed for any new
PVC: a fresh volume may need root-owned directory preparation.
The production-style API is still running the existing `latest` image and has
not received the dev-only security rollout.

The dev API and PostgreSQL use dedicated ServiceAccounts with token
automounting disabled on both the ServiceAccounts and pod templates. The token
file was verified absent in both running workloads. No Roles or RoleBindings
were created because neither workload needs Kubernetes API access; authorization
checks returned `no` for API `list pods`, API `get secrets`, and PostgreSQL
`list pods`.

The dev API has a PodDisruptionBudget with `minAvailable: 1`. Its Deployment
was scaled from two to three replicas and restored to two; the PDB's existence
and configuration were verified, but an eviction/drain behavior test was not
performed.

Verified dev endpoints:

```text
/health  HTTP 200
/ready   HTTP 200 (database connection true)
/metrics HTTP 200 (Prometheus exposition)
```

## Backup and recovery

Before database or storage changes, create a custom-format logical backup and
verify that `pg_restore --list` can read it. A dev backup verified during this
work is stored at:

```text
/home/parth/demostore-dev-security-20261031.dump
```

The archive was readable and was restored successfully into a temporary
PostgreSQL 16 container using `--network none`, with no persistent volume or
connection to either live database. The restored database contained
`products`, `orders`, and `alembic_version`; the migration revision was
`0001`. The `products` and `orders` tables each had zero rows at restore time.
The temporary container was removed after verification. An earlier backup also
exists at `/home/parth/demostore-backup-20261031.dump`; it was separately
checked for archive readability, not restore completeness.

Example backup flow (run from WSL; select a new filename and never overwrite
the only verified copy):

```bash
kubectl exec deployment/demostore-postgres -n opssentinel-dev -- \
  pg_dump -U demostore -d demostore -Fc \
  -f /tmp/demostore-backup.dump
kubectl cp -n opssentinel-dev \
  "$(kubectl get pod -n opssentinel-dev \
    -l app.kubernetes.io/name=demostore-postgres \
    -o jsonpath='{.items[0].metadata.name}'):/tmp/demostore-backup.dump" \
  "$HOME/demostore-backup.dump"
pg_restore --list "$HOME/demostore-backup.dump"
```

If `pg_restore` is not installed in WSL, use the PostgreSQL image as a
read-only archive inspection tool:

```bash
docker run --rm \
  -v "$HOME/demostore-backup.dump:/backup.dump:ro" \
  postgres:16-alpine pg_restore --list /backup.dump
```

For recovery, restore into an isolated PostgreSQL instance and a separate PVC
first; verify schema and application queries before considering a controlled
cutover. Never test restore by overwriting the live database or deleting its
PVC. The StorageClass reclaim policy is `Delete`.

## ResourceQuota and LimitRange

`kubernetes/overlays/dev/resource-controls.yaml` is applied in
`opssentinel-dev` only:

- requests capped at 2 CPU and 2Gi memory
- limits capped at 3 CPU and 3Gi memory
- 10 pods and 3 PVCs maximum
- default container request: 100m CPU / 128Mi
- default container limit: 500m CPU / 512Mi

At validation, usage was 300m CPU / 384Mi requests, 1500m CPU / 1536Mi
limits, 3 pods, and 1 PVC. The Kind node has 16 CPU and about 7.3Gi memory
allocatable; node/pod usage metrics were unavailable because metrics-server
is not installed. No quota was applied to `opssentinel`.

Check controls and usage:

```bash
kubectl get resourcequota,limitrange -n opssentinel-dev
kubectl describe resourcequota opssentinel-dev-quota -n opssentinel-dev
kubectl top nodes
kubectl top pods -n opssentinel-dev
```

## NetworkPolicy and CNI validation

`kubernetes/overlays/dev/network-policy.yaml` describes PostgreSQL ingress
only from DemoStore API pods on TCP 5432. It passed server-side dry-run
validation but is intentionally not applied to either application namespace.
The application cluster uses `kindnet`, which is not used to claim policy
enforcement.

Enforcement was tested in the separate `opssentinel-netpol-test` Kind cluster
with Calico 3.33.0 and a dedicated `netpol-test` namespace:

1. Client-to-server HTTP connectivity succeeded before a policy was applied.
2. `deny-server-ingress` blocked that traffic.
3. `allow-client` permitted traffic from the labeled client to TCP 80 again.

All three checks passed. This proves Kubernetes NetworkPolicy enforcement in
the disposable test cluster; it does not mean a policy is active in
`opssentinel` or `opssentinel-dev`. Keep the test cluster available until
final verification.

## Troubleshooting

```bash
kubectl get pods -n opssentinel-dev -o wide
kubectl describe pod -n opssentinel-dev <pod-name>
kubectl logs deployment/demostore-api -n opssentinel-dev --tail=100
kubectl logs deployment/demostore-postgres -n opssentinel-dev --tail=100
kubectl logs job/demostore-migrations -n opssentinel-dev
kubectl get events -n opssentinel-dev --sort-by=.lastTimestamp
```

If API readiness fails, check PostgreSQL readiness and the `demostore-db-secret`
key names without printing values. If a PVC is not Bound, check the StorageClass
and PVC events; do not delete/recreate the claim. If a future deployment fails
after a security-context change, compare the rendered Deployment with the
saved pre-change manifest and use a reviewed rollback plan.

## Remaining Phase 3 work

- Test resource-limit behavior under load.
- Test application-level unauthorized API requests; Kubernetes RBAC denial
  checks have passed, but they are not a substitute for application auth tests.
- Test PDB behavior during a controlled disruption.
- Test Helm rollback in an approved, non-production-style environment.
- Review dev ownership before installing a Helm release there.
- Keep the production-style `opssentinel` release unchanged unless a separate
  change is reviewed and explicitly authorized.
