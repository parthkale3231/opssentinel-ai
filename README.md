# OpsSentinel AI

> **Autonomous Cloud Infrastructure Reliability & Self-Healing Platform**

[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110-green?logo=fastapi)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react)](https://react.dev)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?logo=kubernetes)](https://kubernetes.io)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazonaws)](https://aws.amazon.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## Overview

OpsSentinel AI is an intelligent infrastructure reliability platform designed to **monitor cloud-native workloads**, **detect infrastructure anomalies**, **investigate incidents**, and **execute predefined recovery procedures** — all with AI-assisted root cause analysis and policy-controlled self-healing.

### Core Workflow

```
Infrastructure Failure
        │
        ▼
Prometheus Detects → Alertmanager Routes → OpsSentinel Receives
        │
        ▼
Evidence Collection (metrics + logs + k8s events)
        │
        ▼
AI Diagnosis Engine (LLM + RAG)
        │
        ▼
Policy Validation Engine
        │
   ┌────┴────┐
   │         │
   ▼         ▼
Auto-       Requires
approved    Human
   │        Approval
   └────┬───┘
        │
        ▼
Kubernetes Remediation
        │
        ▼
Recovery Verification → Incident Resolved → Dashboard Updated
```

---

## Technology Stack

| Layer | Technology |
|---|---|
| Cloud | AWS (ap-south-1) |
| Infrastructure as Code | Terraform |
| Container Orchestration | Kubernetes (kind / Amazon EKS) |
| Container Registry | Amazon ECR |
| CI | Jenkins |
| CD / GitOps | ArgoCD |
| Backend | Python + FastAPI |
| Frontend | React + Vite + Tailwind CSS |
| Database | PostgreSQL |
| Metrics | Prometheus + Grafana |
| Logging | Loki |
| Tracing | OpenTelemetry |
| AI | LLM + RAG |
| Security | Trivy + Checkov + Kyverno |
| Chaos Engineering | LitmusChaos |
| Load Testing | k6 |

---

## Project Structure

```
opssentinel-ai/
├── applications/
│   ├── demostore/          # Sample app for incident generation
│   └── opssentinel/        # Core platform (backend + frontend)
├── infrastructure/
│   └── terraform/          # AWS infrastructure modules
├── kubernetes/             # Manifests, overlays, Helm charts
├── gitops/                 # ArgoCD application definitions
├── observability/          # Prometheus, Grafana, Alertmanager, Loki
├── ci-cd/                  # Jenkinsfile + GitHub Actions
├── security/               # Kyverno, RBAC, scan configs
├── tests/                  # Integration, e2e, chaos, performance
├── scripts/                # Bootstrap, deploy, cleanup scripts
└── docs/                   # Full documentation suite
```

---

## Quick Start (Local Development)

### Prerequisites

- Docker Desktop
- [kind](https://kind.sigs.k8s.io/) — local Kubernetes
- kubectl
- Python 3.11+
- Node.js 20+
- Helm 3
- Terraform 1.7+
- AWS CLI v2

### 1. Create local Kubernetes cluster

```powershell
kind create cluster --name opssentinel
kubectl cluster-info --context kind-opssentinel
```

### 2. Deploy monitoring stack

```powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

### 3. Start DemoStore (local)

```powershell
cd applications/demostore/backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001
```

### 4. Start OpsSentinel backend (local)

```powershell
cd applications/opssentinel/backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### 5. Start OpsSentinel frontend

```powershell
cd applications/opssentinel/frontend
npm install
npm run dev
```

---

## AWS Deployment

See [docs/deployment.md](docs/deployment.md) for the full AWS deployment guide.

**Quick summary:**
1. Configure AWS CLI and IAM permissions.
2. Create S3 bucket for Terraform state.
3. `cd infrastructure/terraform/environments/dev && terraform init && terraform apply`
4. Push images to ECR via Jenkins pipeline.
5. ArgoCD deploys to EKS automatically.

---

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for full system design.

---

## Documentation

| Document | Description |
|---|---|
| [PLAN.md](PLAN.md) | Complete project plan |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture |
| [TASKS.md](TASKS.md) | Development task tracker |
| [docs/setup.md](docs/setup.md) | Local setup guide |
| [docs/deployment.md](docs/deployment.md) | AWS deployment guide |
| [docs/security.md](docs/security.md) | Security architecture |
| [docs/testing.md](docs/testing.md) | Testing methodology |
| [docs/incident-response.md](docs/incident-response.md) | Incident lifecycle |
| [docs/cost-management.md](docs/cost-management.md) | AWS cost controls |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common issues |

---

## Development Status

| Phase | Description | Status |
|---|---|---|
| 0 | Project Initialization | 🟡 In Progress |
| 1 | AWS Infrastructure & Terraform | ⬜ Not Started |
| 2 | DemoStore Application | ⬜ Not Started |
| 3 | Kubernetes & Helm | ⬜ Not Started |
| 4 | CI/CD & GitOps | ⬜ Not Started |
| 5 | Monitoring & Observability | ⬜ Not Started |
| 6 | Incident Management Engine | ⬜ Not Started |
| 7 | AI Diagnosis & Self-Healing | ⬜ Not Started |
| 8 | DevSecOps & Chaos Engineering | ⬜ Not Started |
| 9 | React Frontend Dashboard | ⬜ Not Started |
| 10 | AWS Deployment & Validation | ⬜ Not Started |
| 11 | Documentation & Portfolio | ⬜ Not Started |

---

## License

MIT — see [LICENSE](LICENSE)

---

> **Engineering Philosophy:** Build → Test → Secure → Deploy → Monitor → Break → Recover → Measure → Document

