# ADR-001: Use FastAPI for Backend Services

**Date:** 2026-10-30  
**Status:** Accepted

## Decision

Use Python FastAPI for all backend services (DemoStore and OpsSentinel).

## Rationale

- Native async support for high-throughput webhook processing.
- Automatic OpenAPI documentation generation.
- Pydantic schema validation for all inputs and AI outputs.
- Strong Python ecosystem for Kubernetes and Prometheus clients.
- Fast development velocity for a solo engineering project.

## Alternatives Considered

- Flask: synchronous, less suitable for webhook processing.
- Go/Gin: faster but longer development time.
- Node.js/Express: less mature ML/AI ecosystem.

