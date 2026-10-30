# Testing Methodology

## Test Levels

### 1. Unit Tests

**Location:** `applications/*/backend/tests/unit/`

**Coverage:**
- Incident classification logic
- Alert payload validation
- Incident deduplication
- Policy evaluation rules
- AI response schema validation
- Remediation decision logic

**Run:**
```powershell
python -m pytest tests/unit/ -v --cov=app
```

### 2. Integration Tests

**Location:** `tests/integration/`

**Coverage:**
- Alertmanager → FastAPI webhook
- FastAPI → PostgreSQL persistence
- FastAPI → Prometheus query API
- Python controller → Kubernetes API
- Jenkins → ECR image push
- ArgoCD → Kubernetes reconciliation

**Run:**
```powershell
python -m pytest tests/integration/ -v
```

### 3. Kubernetes Tests

**Coverage:**
- Deployment health
- Service connectivity
- RBAC restrictions
- NetworkPolicy enforcement
- Resource limit enforcement
- HPA behavior

### 4. Chaos Tests

**Location:** `tests/chaos/`

**Scenarios:**
- Pod deletion (LitmusChaos PodDelete)
- CPU stress (LitmusChaos CPUHog)
- Memory stress
- Application latency injection
- Deployment failure

**Run:**
```powershell
kubectl apply -f tests/chaos/pod-failure.yaml -n demo-app
# Monitor OpsSentinel dashboard for incident detection
```

### 5. Performance Tests

**Location:** `tests/performance/`

**Tool:** k6

**Scenarios:**
- Baseline load (normal traffic)
- Ramp-up (increasing load)
- Spike test
- Stress test (find breaking point)

**Run:**
```powershell
k6 run tests/performance/baseline.js
```

**Targets:**
- P95 latency < 500ms under normal load
- Error rate < 1% under normal load

### 6. End-to-End Test

The primary acceptance scenario:

```
Inject pod failure
    → Prometheus detects (< 2 min)
    → Alertmanager routes to OpsSentinel webhook
    → Incident created and evidence collected
    → AI generates structured diagnosis
    → Policy engine evaluates action
    → Remediation executes (if authorized)
    → Recovery verification confirms health
    → Incident marked RESOLVED
    → Dashboard shows resolved state
```

## Security Tests

- [ ] Vulnerable dependency detected by Trivy → build blocked
- [ ] Unauthorized Kubernetes operation rejected by RBAC
- [ ] Invalid remediation request rejected by policy engine
- [ ] Pod failing security context rejected by Kyverno
- [ ] No secrets committed to Git

