# Incident Response Guide

## Incident Lifecycle

```
DETECTED
    │
    ▼
ACKNOWLEDGED   ← Alertmanager webhook received
    │
    ▼
INVESTIGATING  ← Evidence collection started
    │
    ▼
DIAGNOSED      ← AI root cause analysis complete
    │
    ▼
AWAITING_APPROVAL  (if high-risk action required)
    │
    ▼
REMEDIATING    ← Kubernetes action executing
    │
    ▼
VERIFYING      ← Recovery verification running
    │
    ┌─────┴─────┐
    ▼           ▼
RESOLVED    ESCALATED
```

## Alert → Incident Flow

1. Prometheus fires alert rule.
2. Alertmanager routes alert to `POST /api/v1/webhooks/alerts`.
3. OpsSentinel validates payload.
4. Deduplication check — if incident already exists for this alert, update state.
5. New `Incident` record created in PostgreSQL with status `DETECTED`.
6. Evidence collector triggered asynchronously.
7. AI diagnosis engine called.
8. Policy engine evaluates recommended action.
9. Auto-approved actions execute immediately.
10. Approval-required actions wait for human input.

## Supported Incident Types

| Alert Name | Category | Default Action |
|---|---|---|
| PodCrashLooping | Pod Health | Diagnose + restart |
| PodNotReady | Pod Health | Diagnose + restore replicas |
| ContainerOOMKilled | Resource | Diagnose + recommend scaling |
| HighCPUUsage | Resource | Bounded scaling |
| HighMemoryUsage | Resource | Diagnose + alert |
| HighApplicationErrorRate | Application | Diagnose + investigate |
| HighAPIResponseLatency | Application | Diagnose |
| DeploymentUnavailable | Deployment | Restore replicas / approval rollback |
| PostgreSQLConnectionFailure | Database | Alert + escalate |

## Manual Actions

### Approve a remediation

```powershell
curl -X POST http://localhost:8000/api/v1/incidents/{id}/approve \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     -d '{"approved": true, "comment": "Approved by on-call engineer"}'
```

### Trigger diagnosis manually

```powershell
curl -X POST http://localhost:8000/api/v1/incidents/{id}/diagnose \
     -H "Authorization: Bearer <token>"
```

### Trigger remediation manually

```powershell
curl -X POST http://localhost:8000/api/v1/incidents/{id}/remediate \
     -H "Authorization: Bearer <token>"
```

## Evidence Types Collected

- Prometheus metrics (CPU, memory, error rate, latency)
- Kubernetes pod status and events
- Kubernetes deployment status
- Container logs (last 200 lines)
- Recent deployment history
- Application health endpoint response

