# ADR-005: AI Provides Recommendations, Not Unrestricted Execution

**Date:** 2026-10-30  
**Status:** Accepted

## Decision

The AI/LLM component provides structured remediation recommendations only. It cannot directly execute Kubernetes API calls, shell commands, or any infrastructure operations.

## Rationale

- LLM outputs are untrusted and must be schema-validated before any action.
- Unrestricted AI execution is a critical security risk in a production-adjacent system.
- The policy engine provides a controlled, auditable execution boundary.
- Human operators must retain override capability.
- This allows AI fallback (rule-based diagnosis) without disabling remediation.

## Implementation

1. AI outputs a `DiagnosisResult` Pydantic model.
2. The model is validated against a strict schema.
3. The `recommended_action` field is passed to the Policy Engine.
4. The Policy Engine evaluates the action against the allowlist and risk rules.
5. Only if approved does the Remediation Engine execute the action.

## Constraint

AI can never call `kubectl`, `subprocess`, `os.system`, or any Kubernetes API directly.

