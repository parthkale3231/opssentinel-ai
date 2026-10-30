# Security Architecture

## Principles

1. Least-privilege IAM and Kubernetes RBAC.
2. AI is advisory — it cannot execute arbitrary commands.
3. Every remediation must pass policy validation.
4. High-risk actions require human approval.
5. All incident and remediation actions are audited.
6. No hardcoded credentials anywhere in the codebase.

## AWS Security

| Control | Implementation |
|---|---|
| IAM permissions | Least-privilege roles per workload |
| No hardcoded credentials | AWS environment variables / IRSA |
| Terraform state | Encrypted S3, restricted access |
| Network | Private subnets for EKS worker nodes |
| Audit | CloudTrail enabled |

## Kubernetes Security

| Control | Implementation |
|---|---|
| RBAC | Namespace-scoped roles, dedicated ServiceAccounts |
| NetworkPolicies | Restrict inter-namespace traffic |
| ResourceQuotas | Prevent resource exhaustion |
| Pod security | Non-root, read-only root filesystem where practical |
| Secrets | Kubernetes Secrets + AWS Secrets Manager |
| Admission | Kyverno policies block non-compliant pods |

## CI/CD Security

| Control | Implementation |
|---|---|
| Container scanning | Trivy (image + filesystem) |
| IaC scanning | Checkov |
| Code quality | SonarQube |
| Branch protection | Required checks before merge |
| Image tags | Immutable digests |
| Secret scanning | GitHub secret scanning enabled |

## AI Security

| Control | Implementation |
|---|---|
| No arbitrary execution | AI output is recommendations only |
| Schema validation | Every AI response validated against Pydantic schema |
| Policy gating | Policy engine must approve every action |
| Context limits | Evidence payload size bounded |
| Untrusted input | Logs and external content treated as untrusted |
| Audit | Every diagnosis and action decision is recorded |

## Remediation Policy Table

| Action | Risk | Approval Required |
|---|---|---|
| Restart approved deployment | Low | No |
| Scale approved deployment (within bounds) | Medium | Policy-dependent |
| Roll back deployment | High | Yes |
| Delete namespace | Critical | Always prohibited |
| Modify cluster IAM | Critical | Always prohibited |
| Unrestricted shell execution | Critical | Always prohibited |

## Security Scanning Commands

```powershell
# Image scan
trivy image opssentinel:latest

# Filesystem scan
trivy fs applications/opssentinel/backend/

# Terraform scan
checkov -d infrastructure/terraform/ --framework terraform

# Kubernetes manifest scan
trivy config kubernetes/
```

