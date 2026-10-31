# OpsSentinel AI — System Architecture

**Project:** Autonomous Cloud Infrastructure Reliability & Self-Healing Platform  
**Architecture Version:** 1.0  
**Cloud Provider:** AWS  
**Primary Region:** `ap-south-1` (Mumbai)  
**Deployment Strategy:** Local-first development, AWS deployment for final validation  
**Architecture Style:** Cloud-native, event-driven, modular microservices

---

# 1. Architecture Overview

## 1.1 Purpose

OpsSentinel AI is an intelligent infrastructure reliability platform designed to detect, diagnose, and safely remediate infrastructure incidents in Kubernetes environments.

The platform integrates observability, incident management, AI-assisted root cause analysis, policy-controlled remediation, and recovery verification.

## 1.2 Core Capabilities

- Infrastructure and application monitoring.
- Kubernetes workload health monitoring.
- Automated incident detection.
- Alert deduplication and severity classification.
- Metrics, logs, events and deployment evidence collection.
- AI-assisted root cause analysis.
- Policy-based remediation recommendations.
- Controlled Kubernetes self-healing.
- Human approval for sensitive operations.
- Automated recovery verification.
- Incident history and audit logging.
- Web-based operational dashboard.

## 1.3 Architecture Principles

1. **Security first:** Least-privilege IAM and Kubernetes RBAC.
2. **AI is advisory:** AI cannot execute arbitrary shell commands.
3. **Policy-controlled actions:** Every remediation must pass validation.
4. **Human oversight:** High-risk actions require approval.
5. **Observable by design:** Every service exposes health and operational metrics.
6. **Fault isolation:** Failure of the AI component must not stop monitoring.
7. **Cost awareness:** Local development before AWS deployment.
8. **Auditability:** Every incident and remediation action is recorded.

---

# 2. High-Level System Architecture

```text
                       OPERATIONS TEAM
                              |
                              v
                    React Web Dashboard
                              |
                              v
                       FastAPI Backend
                              |
                +-------------+-------------+
                |             |             |
                v             v             v
          Incident API    Dashboard API   Auth API
                |
                v
       INCIDENT MANAGEMENT ENGINE
                |
       +--------+---------+
       |        |         |
       v        v         v
    Incident  Evidence  PostgreSQL
    Manager   Collector  Database
       |        |
       |        +----------------------+
       |                               |
       v                               v
  AI DIAGNOSIS ENGINE          OBSERVABILITY STACK
       |                       Prometheus / Loki
       |                       Kubernetes Events
       v                       Deployment History
  ROOT CAUSE ANALYSIS
       |
       v
  POLICY VALIDATION ENGINE
       |
       +-----------------------------+
       |                             |
       v                             v
  Human Approval              Auto-approved
       |                             |
       +-------------+---------------+
                     |
                     v
              REMEDIATION ENGINE
                     |
                     v
              Kubernetes API
                     |
                     v
             RECOVERY VERIFICATION
                     |
              +------+------+
              |             |
              v             v
           SUCCESS        FAILURE
              |             |
              v             v
          Close Incident  Escalate Incident
              |
              v
         Audit Database
```

---

# 3. Infrastructure Architecture — AWS

## 3.1 AWS Services

| AWS Service | Purpose |
|---|---|
| VPC | Isolated networking |
| Public Subnets | Internet-facing components when required |
| Private Subnets | Kubernetes workloads |
| EKS | Managed Kubernetes control plane |
| EC2 | Kubernetes worker nodes |
| ECR | Container image registry |
| IAM | Identity and access management |
| S3 | Terraform state storage |
| CloudWatch | AWS infrastructure logs and metrics |
| Route 53 | DNS management, if required |
| ACM | TLS certificates, if required |

## 3.2 AWS Infrastructure Layout

```text
                         AWS ACCOUNT
                              |
                              v
                       VPC - ap-south-1
                              |
               +--------------+--------------+
               |                             |
               v                             v
         Public Subnets                 Private Subnets
               |                             |
         Internet Gateway                    |
               |                             |
        Optional Ingress                     |
                                             |
                                      Amazon EKS
                                             |
                                  +----------+----------+
                                  |                     |
                                  v                     v
                             Worker Node 1         Worker Node 2
                                  |                     |
                                  +----------+----------+
                                             |
                                      Kubernetes Pods
```

## 3.3 Infrastructure Provisioning

Terraform manages:

- VPC and subnet configuration.
- Internet Gateway and route tables.
- Security groups.
- IAM roles and policies.
- EKS cluster.
- Managed node groups.
- ECR repositories.
- S3 backend for Terraform state.

**Important:** EKS has ongoing control-plane and worker-node costs. Use `kind` for local development and create EKS only for a controlled final deployment.

Avoid deploying NAT Gateways and load balancers unless required. They can increase costs.

---

# 4. Kubernetes Architecture

## 4.1 Namespace Strategy

| Namespace | Components |
|---|---|
| `opssentinel` | FastAPI, incident engine, AI engine |
| `monitoring` | Prometheus, Grafana, Alertmanager |
| `logging` | Loki and log collectors |
| `argocd` | ArgoCD |
| `demo-app` | DemoStore application |
| `security` | Security scanning and policy components |

## 4.2 Workload Architecture

```text
                   KUBERNETES CLUSTER
                           |
        +------------------+------------------+
        |                  |                  |
        v                  v                  v
    OPSENTINEL          MONITORING          DEMOSTORE
        |                  |                  |
    FastAPI             Prometheus          Frontend
    Incident API        Grafana             Backend API
    AI Engine           Alertmanager        PostgreSQL
    Remediation         Loki
        |
        v
    Kubernetes API
```

## 4.3 Kubernetes Resource Strategy

Use the following resources:

- Deployments for stateless services.
- StatefulSets only when stateful workloads require them.
- Services for internal service communication.
- ConfigMaps for non-sensitive configuration.
- Secrets for credentials and tokens.
- ServiceAccounts for workload identity.
- Roles and RoleBindings for namespace-level permissions.
- NetworkPolicies for traffic restrictions.
- HorizontalPodAutoscalers for selected workloads.
- PodDisruptionBudgets for availability-sensitive workloads.
- Ingress for external HTTP access.

---

# 5. Application Architecture

OpsSentinel consists of the following logical services.

## 5.1 Frontend Service

**Technology:** React + Vite + Tailwind CSS

Responsibilities:

- Dashboard overview.
- Incident management interface.
- Kubernetes workload status.
- Root cause analysis display.
- Remediation approval.
- Recovery status.
- Audit history.
- Security and system settings.

## 5.2 Backend API

**Technology:** Python + FastAPI

Responsibilities:

- API routing.
- Authentication and authorization.
- Incident APIs.
- Dashboard data APIs.
- Remediation approval APIs.
- Database integration.
- Service-to-service communication.

## 5.3 Incident Management Engine

Responsibilities:

- Receive Alertmanager webhooks.
- Validate incoming alerts.
- Deduplicate repeated alerts.
- Generate incident IDs.
- Classify incident severity.
- Track incident lifecycle.
- Trigger evidence collection.
- Coordinate diagnosis and remediation.

Incident lifecycle:

```text
DETECTED
   |
   v
ACKNOWLEDGED
   |
   v
INVESTIGATING
   |
   v
DIAGNOSED
   |
   v
AWAITING_APPROVAL (if required)
   |
   v
REMEDIATING
   |
   v
VERIFYING
   |
   +----------+
   |          |
   v          v
RESOLVED   ESCALATED
```

## 5.4 Evidence Collector

Collects operational evidence from:

- Prometheus.
- Loki.
- Kubernetes API.
- Kubernetes Events.
- Deployment history.
- Application health endpoints.

The collector should use bounded time ranges, request timeouts and payload limits.

## 5.5 AI Diagnosis Engine

**Technology:** Python, LLM integration, retrieval and structured outputs.

Responsibilities:

- Analyze incident evidence.
- Identify possible root causes.
- Correlate metrics, logs and Kubernetes events.
- Review recent deployment changes.
- Generate remediation recommendations.
- Assign a confidence score.
- Explain the evidence supporting its conclusions.

Example structured response:

```json
{
  "incident_id": "INC-1001",
  "probable_root_cause": "Memory pressure",
  "confidence": 0.92,
  "evidence": [
    "Container memory usage exceeded configured threshold",
    "Kubernetes reported OOMKilled"
  ],
  "recommended_action": {
    "type": "RESTART_DEPLOYMENT",
    "namespace": "demo-app",
    "workload": "backend"
  },
  "requires_approval": false
}
```

The AI response is untrusted input. Validate it against a strict schema and the policy engine before any action.

## 5.6 Policy Validation Engine

Responsibilities:

- Verify allowed remediation types.
- Validate namespace and workload scope.
- Check action risk level.
- Enforce rate limits.
- Enforce maximum retry attempts.
- Require human approval for high-risk operations.
- Reject invalid or unsupported actions.

Example policy:

| Action | Risk | Approval |
|---|---|---|
| Restart approved deployment | Low | Not required |
| Scale approved deployment | Medium | Policy-dependent |
| Roll back deployment | High | Required |
| Delete namespace | Critical | Always prohibited |
| Modify cluster IAM | Critical | Always prohibited |

## 5.7 Remediation Engine

Responsibilities:

- Execute approved Kubernetes actions.
- Communicate with the Kubernetes API.
- Enforce execution timeouts.
- Record action results.
- Prevent duplicate executions.
- Trigger recovery verification.

Initial supported actions:

1. Restart an approved Deployment.
2. Scale an approved Deployment within configured limits.
3. Roll back a Deployment with explicit approval.

Do not allow unrestricted shell commands or unrestricted Kubernetes access.

---

# 6. Observability Architecture

## 6.1 Components

| Component | Responsibility |
|---|---|
| Prometheus | Metrics collection |
| Grafana | Monitoring dashboards |
| Alertmanager | Alert routing |
| Loki | Log aggregation |
| OpenTelemetry | Distributed tracing and telemetry |
| Exporters | Infrastructure and Kubernetes metrics |

## 6.2 Monitoring Flow

```text
       APPLICATION + KUBERNETES
                  |
                  v
             PROMETHEUS
                  |
          +-------+-------+
          |               |
          v               v
       GRAFANA       ALERTMANAGER
                          |
                          v
                   FASTAPI WEBHOOK
                          |
                          v
                  INCIDENT ENGINE
```

## 6.3 Initial Alert Rules

- PodCrashLooping.
- PodNotReady.
- ContainerOOMKilled.
- HighCPUUsage.
- HighMemoryUsage.
- HighApplicationErrorRate.
- HighAPIResponseLatency.
- DeploymentUnavailable.
- PostgreSQLConnectionFailure.

Every alert should include useful labels such as namespace, workload, severity and alert name.

---

# 7. CI/CD and GitOps Architecture

## 7.1 CI Pipeline

**Tools:** GitHub Actions or Jenkins, SonarQube, Trivy, Docker, ECR.

```text
Developer Push
      |
      v
GitHub Repository
      |
      v
CI Pipeline
      |
      +----> Unit Tests
      |
      +----> Code Quality Scan
      |
      +----> Dependency Scan
      |
      +----> Docker Build
      |
      +----> Container Scan
      |
      v
Container Registry (ECR)
      |
      v
Update Deployment Manifest
      |
      v
GitOps Repository
```

## 7.2 GitOps Deployment

**Tool:** ArgoCD

```text
Git Repository
      |
      v
ArgoCD
      |
      v
Kubernetes Cluster
      |
      v
Desired State Reconciliation
```

ArgoCD continuously reconciles the Kubernetes cluster with the desired state stored in Git.

CI should publish immutable image tags and update deployment manifests. ArgoCD should handle deployment synchronization.

---

# 8. Database Architecture

**Database:** PostgreSQL

## 8.1 Core Tables

### incidents

| Field | Type |
|---|---|
| id | UUID |
| title | VARCHAR |
| severity | VARCHAR |
| status | VARCHAR |
| source | VARCHAR |
| namespace | VARCHAR |
| workload | VARCHAR |
| created_at | TIMESTAMP |
| resolved_at | TIMESTAMP |

### incident_evidence

| Field | Type |
|---|---|
| id | UUID |
| incident_id | UUID |
| evidence_type | VARCHAR |
| content | JSONB |
| collected_at | TIMESTAMP |

### diagnoses

| Field | Type |
|---|---|
| id | UUID |
| incident_id | UUID |
| root_cause | TEXT |
| confidence | FLOAT |
| recommendation | JSONB |
| created_at | TIMESTAMP |

### remediation_actions

| Field | Type |
|---|---|
| id | UUID |
| incident_id | UUID |
| action_type | VARCHAR |
| target | JSONB |
| approval_status | VARCHAR |
| execution_status | VARCHAR |
| executed_at | TIMESTAMP |

### audit_logs

| Field | Type |
|---|---|
| id | UUID |
| actor | VARCHAR |
| action | VARCHAR |
| resource | VARCHAR |
| result | VARCHAR |
| timestamp | TIMESTAMP |

Use database migrations, foreign keys, indexes and appropriate retention policies. Never store credentials or unrestricted raw secrets in incident evidence.

---

# 9. API Architecture

Base path: `/api/v1`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/health` | Health check |
| GET | `/incidents` | List incidents |
| GET | `/incidents/{id}` | Incident details |
| POST | `/webhooks/alerts` | Receive monitoring alerts |
| GET | `/incidents/{id}/evidence` | Retrieve evidence |
| GET | `/incidents/{id}/diagnosis` | Retrieve diagnosis |
| POST | `/incidents/{id}/diagnose` | Trigger diagnosis |
| POST | `/incidents/{id}/approve` | Approve remediation |
| POST | `/incidents/{id}/remediate` | Request remediation |
| GET | `/remediations` | List remediation history |
| GET | `/audit-logs` | Retrieve audit records |
| GET | `/metrics` | Application metrics |

All protected endpoints require authentication and authorization. Webhook endpoints must validate their source and payload.

---

# 10. Security Architecture

## 10.1 AWS Security

- IAM roles with least privilege.
- No hardcoded AWS credentials.
- Use workload identity where supported.
- Encrypt sensitive storage.
- Restrict security group ingress.
- Store Terraform state securely.
- Enable appropriate AWS audit logging.

## 10.2 Kubernetes Security

- Dedicated ServiceAccounts.
- Namespace-scoped RBAC.
- No default ServiceAccount permissions for application workloads.
- Read-only access for evidence collection where possible.
- Separate remediation permissions.
- NetworkPolicies.
- Resource requests and limits.
- Non-root containers.
- Read-only root filesystem where practical.

## 10.3 CI/CD Security

- Trivy container and dependency scanning.
- SonarQube static analysis.
- Checkov Terraform scanning.
- Secret scanning.
- Image signing and verification.
- Protected deployment branches.
- Immutable image tags.

## 10.4 AI Security

- AI cannot directly execute commands.
- AI output must pass schema validation.
- Every action must pass policy validation.
- Limit context and evidence payload sizes.
- Treat logs and external content as untrusted input.
- Do not expose secrets to the LLM.
- Record diagnosis and action decisions for audit.

---

# 11. Failure Handling and Recovery

| Failure | Expected Behavior |
|---|---|
| Prometheus unavailable | Mark monitoring data as unavailable; do not fabricate evidence |
| AI provider unavailable | Continue incident management and provide rule-based fallback |
| Database unavailable | Retry bounded operations and alert operators |
| Kubernetes API unavailable | Queue or reject remediation safely |
| Remediation fails | Record failure and escalate |
| Recovery verification fails | Keep incident open |
| Duplicate alert | Deduplicate against existing incident |
| Invalid AI recommendation | Reject action |
| Approval timeout | Do not execute high-risk action |

A failure in the AI component must never disable monitoring or prevent manual incident handling.

---

# 12. Incident Scenarios for Demonstration

The following scenarios will prove the platform's core functionality.

| Scenario | Trigger | Expected Response |
|---|---|---|
| Pod CrashLoop | Invalid application configuration | Detect, collect evidence and diagnose |
| High CPU | Controlled CPU stress | Detect and recommend scaling |
| Memory Pressure | Controlled memory stress | Detect OOM events and diagnose |
| Application Failure | HTTP 5xx errors | Correlate application logs and metrics |
| Deployment Failure | Broken deployment | Identify rollout failure |
| Database Failure | Controlled DB connection interruption | Detect and escalate |
| Recovery Test | Restore healthy workload | Verify recovery and resolve incident |

Run destructive tests only in an isolated development namespace.

---

# 13. Reliability Metrics

The platform will measure:

| Metric | Description |
|---|---|
| MTTD | Mean Time to Detect |
| MTTA | Mean Time to Acknowledge |
| MTTR | Mean Time to Resolve |
| Recovery Success Rate | Successful recovery actions / attempted actions |
| False Positive Rate | Incorrect incidents / total incidents |
| Remediation Success Rate | Successful remediation / executed remediation |
| Incident Volume | Total incidents over a period |
| AI Diagnosis Accuracy | Diagnoses matching verified root causes |

Capture baseline values before enabling automated remediation. Report actual measured results rather than assumed improvements.

---

# 14. Deployment Architecture

## Development

```text
Windows PowerShell
       |
       v
Docker Desktop
       |
       v
kind Kubernetes Cluster
       |
       +----> DemoStore
       +----> OpsSentinel
       +----> Prometheus
       +----> Grafana
       +----> Loki
       +----> ArgoCD
       +----> PostgreSQL
```

## AWS Showcase

```text
GitHub
  |
  v
CI Pipeline
  |
  v
Amazon ECR
  |
  v
GitOps Repository
  |
  v
ArgoCD
  |
  v
Amazon EKS
  |
  +----> OpsSentinel
  +----> DemoStore
  +----> Observability Stack
```

Local development is the default. AWS resources should be created only when required for infrastructure validation and the final demonstration.

---

# 15. Repository Architecture

```text
opssentinel-ai/
│
├── README.md
├── PLAN.md
├── TASKS.md
├── ARCHITECTURE.md
├── CONTRIBUTING.md
├── LICENSE
├── .gitignore
│
├── applications/
│   ├── demostore/
│   │   ├── frontend/
│   │   ├── backend/
│   │   └── database/
│   │
│   └── opssentinel/
│       ├── frontend/
│       └── backend/
│           ├── api/
│           ├── incident_engine/
│           ├── evidence_collector/
│           ├── ai_engine/
│           ├── policy_engine/
│           ├── remediation_engine/
│           ├── database/
│           └── tests/
│
├── infrastructure/
│   ├── terraform/
│   │   ├── modules/
│   │   └── environments/
│   │       ├── dev/
│   │       └── showcase/
│   │
│   └── ansible/
│
├── kubernetes/
│   ├── base/
│   ├── overlays/
│   └── helm/
│
├── gitops/
│   ├── applications/
│   └── environments/
│
├── observability/
│   ├── prometheus/
│   ├── alertmanager/
│   ├── grafana/
│   ├── loki/
│   └── opentelemetry/
│
├── ci-cd/
│   ├── Jenkinsfile
│   └── github-actions/
│
├── security/
│   ├── policies/
│   ├── rbac/
│   └── scans/
│
├── scripts/
│   ├── setup/
│   ├── deploy/
│   ├── test/
│   └── cleanup/
│
├── tests/
│   ├── integration/
│   ├── e2e/
│   ├── chaos/
│   └── performance/
│
└── docs/
    ├── diagrams/
    ├── api/
    ├── runbooks/
    ├── screenshots/
    └── incident-scenarios/
```

---

# 16. Architecture Decision Records

Important design decisions should be documented in `docs/adr/`.

| ADR | Decision |
|---|---|
| ADR-001 | Use FastAPI for backend services |
| ADR-002 | Use PostgreSQL for incident persistence |
| ADR-003 | Use Prometheus and Grafana for observability |
| ADR-004 | Use ArgoCD for GitOps deployment |
| ADR-005 | AI provides recommendations, not unrestricted execution |
| ADR-006 | Enforce policy validation before remediation |
| ADR-007 | Use local Kubernetes for development and EKS for showcase |
| ADR-008 | Require human approval for high-risk actions |

---

# 17. Definition of Done

The architecture is considered implemented when:

- [ ] Terraform provisions the required AWS infrastructure.
- [ ] DemoStore runs in Kubernetes.
- [ ] CI builds and scans container images.
- [ ] ArgoCD deploys application changes.
- [ ] Prometheus collects metrics.
- [ ] Alertmanager delivers alerts to OpsSentinel.
- [ ] Incident engine creates and tracks incidents.
- [ ] Evidence collector retrieves relevant operational evidence.
- [ ] AI generates structured diagnoses.
- [ ] Policy engine validates remediation proposals.
- [ ] Remediation engine executes permitted actions.
- [ ] Recovery verification determines incident outcome.
- [ ] PostgreSQL stores incident and audit history.
- [ ] Dashboard displays the complete incident lifecycle.
- [ ] Security, integration and end-to-end tests pass.
- [ ] AWS resources can be cleaned up reliably.

---

**Final Architecture Goal:** Build a demonstrable, secure, observable and policy-controlled autonomous infrastructure reliability platform that showcases practical DevOps, Cloud, Kubernetes, DevSecOps, SRE and AI integration skills.