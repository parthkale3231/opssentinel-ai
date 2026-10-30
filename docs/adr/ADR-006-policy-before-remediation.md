# ADR-006: Enforce Policy Validation Before Remediation

**Date:** 2026-10-30  
**Status:** Accepted

## Decision

Every remediation action, whether AI-generated or manually requested, must pass through the Policy Validation Engine before execution.

## Rationale

- Prevents runaway remediation loops.
- Enforces scope restrictions (permitted namespaces and workloads only).
- Enforces rate limits and retry limits.
- Ensures sensitive operations require human approval.
- Provides a complete audit trail of all decisions.

## Policy Schema

```yaml
allowed_actions:
  - RESTART_DEPLOYMENT
  - SCALE_DEPLOYMENT
  - ROLLBACK_DEPLOYMENT  # requires approval

allowed_namespaces:
  - demo-app

max_retries_per_incident: 3
max_scale_replicas: 5
approval_required_for:
  - ROLLBACK_DEPLOYMENT
  - any severity=critical

rate_limit:
  max_actions_per_hour: 10
```

