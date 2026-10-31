# OpsSentinel AI

> **Autonomous Cloud Infrastructure Reliability & Self-Healing Platform**

[![Python](https://img.shields.io/badge/Python-3.11%20%7C%203.12-blue?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110-green?logo=fastapi)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react)](https://react.dev)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS%201.36-326CE5?logo=kubernetes)](https://kubernetes.io)
[![Terraform](https://img.shields.io/badge/IaC-Terraform%201.7%2B-7B42BC?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/Cloud-AWS%20(ap--south--1)-FF9900?logo=amazonaws)](https://aws.amazon.com)
[![Security](https://img.shields.io/badge/Security-Checkov%20%7C%20Trivy-red)](security/scans/checkov.yaml)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## Overview

OpsSentinel AI is an intelligent infrastructure reliability platform designed to **monitor cloud-native workloads**, **detect infrastructure anomalies**, **investigate incidents**, and **execute predefined recovery procedures** — combining AI-assisted root cause analysis with strict policy-controlled self-healing.

### Core Self-Healing Workflow

```text
Infrastructure Failure (CrashLoopBackOff / OOMKilled / Latency Spike)
        │
        ▼
Prometheus Detects → Alertmanager Routes → OpsSentinel Receives
        │
        ▼
Evidence Collection (Prometheus metrics + Pod logs + Kubernetes events)
        │
        ▼
AI Diagnosis Engine (LLM + Domain-Specific RAG Knowledge Base)
        │
        ▼
Policy Validation Engine (OPA / Kyverno / Remediation Safeguards)
        │
   ┌────┴──────────────────────────┐
   ▼                               ▼
Auto-Approved                 Requires Approval
(e.g., restart, scale, rollback) (e.g., node drain, config change)
   │                               │
   └───────────────┬───────────────┘
                   │
                   ▼
Kubernetes Remediation (Automated via Kubernetes API / ArgoCD)
                   │
                   ▼
Recovery Verification → Incident Resolved → Grafana & Dashboard Updated
```

---

## Technology Stack

| Layer | Technology | Details / Version |
|---|---|---|
| **Cloud Provider** | AWS (`ap-south-1`) | Minimal-cost architecture with single-NAT option |
| **Infrastructure as Code** | Terraform | v1.7+ / v1.16+ with modular DAG architecture |
| **Container Orchestration** | Amazon EKS / kind | Kubernetes 1.36 on Amazon Linux 2023 (`AL2023_x86_64_STANDARD`) |
| **Container Registry** | Amazon ECR | 3 private repositories with scan-on-push & lifecycle rules |
| **CI / Build** | Jenkins + GitHub Actions | Automated linting, static analysis, image builds |
| **CD / GitOps** | ArgoCD | Declarative sync with automated rollbacks |
| **Backend API** | Python + FastAPI | Async REST API with OpenAPI documentation |
| **Frontend UI** | React 18 + Vite + Tailwind | Responsive 9-view incident management dashboard |
| **Database** | PostgreSQL | Relational incident and audit trail store |
| **Observability** | Prometheus + Grafana + Loki | Custom alert rules, dashboards, log aggregation |
| **Tracing** | OpenTelemetry | Distributed tracing for latency and request tracking |
| **AI Diagnosis** | LLM + RAG | Structured incident root-cause analysis (Advisory-only) |
| **Security & Compliance** | Checkov + Trivy + Kyverno | Static IaC scanning, container vulnerability scanning, admission control |
| **Chaos Engineering** | LitmusChaos | Controlled failure injection (CPU, pod kill, network latency) |
| **Load Testing** | k6 | Performance and stress testing under failure scenarios |

---

## Phase 2: DemoStore Application

Phase 2 is complete. DemoStore is a FastAPI ecommerce workload with PostgreSQL
persistence, SQLAlchemy models, and Alembic migrations. It provides product and
order APIs, health and readiness checks, and Prometheus-compatible request
metrics. Docker Compose runs the API with PostgreSQL for local development.

### Run DemoStore with Docker Compose

From the repository root in WSL or another environment with Docker Compose:

```bash
docker compose up -d --build
docker compose ps
```

The API is available at [http://localhost:8001](http://localhost:8001), with
interactive API documentation at [http://localhost:8001/docs](http://localhost:8001/docs).
The Compose setup waits for PostgreSQL to become healthy, and the API applies
pending database migrations when it starts.

Useful endpoints:

| Endpoint | Purpose |
|---|---|
| `GET /health` | Liveness check |
| `GET /ready` | Readiness check, including PostgreSQL connectivity |
| `GET /metrics` | Prometheus metrics |
| `/api/products/` | Product CRUD |
| `/api/orders/` | Create and list orders |

Run the backend tests inside the API container:

```bash
docker exec opssentinel-demostore-api pytest -v
```

See [the DemoStore backend README](applications/demostore/backend/README.md)
for WSL virtual environment setup and additional local run instructions.

---

## Project Structure

```text
OpsSentinel AI/
├── applications/
│   ├── demostore/                 # Sample microservice for incident simulation
│   │   └── backend/               # FastAPI app, SQLAlchemy models, Alembic migrations, tests
│   └── opssentinel/               # Core reliability platform
│       ├── backend/               # Incident engine, AI analysis, policy validator
│       └── frontend/              # React 18 dashboard
├── infrastructure/
│   └── terraform/
│       ├── environments/
│       │   ├── dev/               # Development environment configuration
│       │   └── showcase/          # Production-like showcase environment
│       └── modules/
│           ├── vpc/               # VPC, 2-AZ subnets, NAT GW, S3 Gateway Endpoint
│           ├── iam/               # EKS cluster & worker node IAM roles
│           ├── eks/               # EKS 1.36 cluster, AL2023 nodes, OIDC provider
│           ├── irsa/              # Workload IRSA role & scoped Secrets Manager policy
│           └── ecr/               # ECR repos (demostore, opssentinel, frontend)
├── kubernetes/                    # Manifests, overlays, and Helm charts
├── gitops/                        # ArgoCD application and project CRDs
├── observability/                 # Prometheus rules, Alertmanager configs, Grafana dashboards
├── ci-cd/                         # Jenkinsfile and GitHub Actions workflows
├── security/
│   ├── policies/                  # Kyverno admission control policies
│   ├── rbac/                      # Kubernetes ClusterRoles & RoleBindings
│   └── scans/                     # Checkov IaC security scanning configurations
├── tests/                         # Integration, end-to-end, chaos, and performance tests
├── scripts/
│   ├── setup/                     # Cluster bootstrap, backend creation, validation scripts
│   ├── deploy/                    # Guided infrastructure deployment with safety checks
│   └── cleanup/                   # Infrastructure destruction scripts
└── docs/                          # Comprehensive technical documentation & ADRs
```

---

## Phase 1: AWS Infrastructure Architecture

The platform's cloud foundation is built with production-grade Terraform modules designed for cost efficiency, least-privilege security, and maintainability:

```text
[modules/vpc] (VPC, 2-AZ Subnets, Single/Multi NAT GW, S3 Gateway Endpoint, Cluster SG)
       │
       ├─────────────────────────────────┐
       ▼                                 ▼
[modules/iam] (Cluster & Node Roles)   [modules/ecr] (Repositories with Scan-on-Push)
       │                                 │
       └────────────────┬────────────────┘
                        ▼
                 [modules/eks] (EKS 1.36, AL2023, AccessConfig, OIDC Provider)
                        │
                        ▼ (oidc_provider_arn, oidc_provider_url)
                 [modules/irsa] (OpsSentinel Workload IRSA, Scoped Secrets Policy)
```

### Key Architectural Highlights

- **Standard Support Kubernetes**: Amazon EKS v1.36 (supported through August 2027) with Amazon Linux 2023 (`AL2023_x86_64_STANDARD`) worker nodes.
- **EKS Access Management**: Configured with `API_AND_CONFIG_MAP` authentication mode, disabling automatic cluster creator bootstrap in favor of explicit `aws_eks_access_entry` bindings.
- **Secure Default API Endpoint**: Public API server access is disabled by default; enabled only when an explicit CIDR list is supplied via `dev.auto.tfvars`.
- **Cyclic-Free Dependency Graph**: Workload IRSA is separated from cluster/node IAM, guaranteeing a clean single-pass DAG (`vpc/iam -> eks -> irsa`).
- **Strict Input Validation**: Enforced via `lifecycle { precondition { ... } }` blocks on `aws_vpc.main`, aborting plans if subnets mismatch availability zones or CIDRs collide.
- **Cost-Optimized Egress**: Configurable `single_nat_gateway = true` for dev (~$0.045/hr vs ~$0.11/hr for full VPC interface endpoints), with free S3 Gateway Endpoints.
- **Encrypted Remote State**: S3 backend bootstrapped with AES-256 server-side encryption, versioning enabled, public access blocked, and HTTPS-only transport policy.

---

## Quick Start

### Prerequisites

- **WSL2** (Ubuntu 22.04 / 24.04) or **Linux / macOS**
- [Terraform](https://developer.hashicorp.com/terraform/install) v1.7+ (tested on v1.16.0)
- [AWS CLI v2](https://aws.amazon.com/cli/) configured (`aws configure`)
- [Docker Desktop](https://www.docker.com/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) v1.30+
- [Python](https://python.org) 3.11+ / 3.12+
- [Node.js](https://nodejs.org/) v20+
- [Checkov](https://www.checkov.io/) (`pip install checkov`)

### 1. Terraform Infrastructure Validation (Local / WSL)

Run from the repository root:

```bash
# Check HCL formatting across all Terraform modules:
terraform fmt -check -recursive infrastructure/terraform

# Initialize and validate the development environment:
cd infrastructure/terraform/environments/dev
terraform init -backend=false -reconfigure
terraform validate

# Initialize and validate the showcase environment:
cd ../showcase
terraform init -backend=false -reconfigure
terraform validate

# Run static security scanning with Checkov:
cd ../../../../
checkov -d infrastructure/terraform \
  --framework terraform \
  --config-file security/scans/checkov.yaml
```

Or run the all-in-one script:

```bash
bash scripts/setup/validate-phase1.sh
```

### 2. Configure Local Public IP for Dev Access

To allow your workstation's `kubectl` to reach the EKS API server during development:

```bash
cd infrastructure/terraform/environments/dev
cp dev.auto.tfvars.example dev.auto.tfvars

# Get your current public IP:
MY_IP=$(curl -s https://checkip.amazonaws.com)

# Add your IP to dev.auto.tfvars:
echo "cluster_public_access_cidrs = [\"${MY_IP}/32\"]" > dev.auto.tfvars
```

> **Note:** `*.auto.tfvars` is ignored by `.gitignore` to prevent committing IP addresses or local secrets.

### 3. Local Cluster Development (kind)

For rapid local iteration without AWS charges:

```powershell
# Create local kind cluster:
kind create cluster --name opssentinel

# Verify cluster connectivity:
kubectl cluster-info --context kind-opssentinel
```

---

## Documentation

| Document | Description |
|---|---|
| [PLAN.md](PLAN.md) | Complete 12-phase project master plan |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Detailed system architecture, data models, and specifications |
| [TASKS.md](TASKS.md) | Granular task tracker, acceptance criteria, and phase status |
| [docs/setup.md](docs/setup.md) | Local development environment setup guide |
| [docs/deployment.md](docs/deployment.md) | AWS deployment runbook and checklist |
| [docs/security.md](docs/security.md) | Security architecture, IRSA, RBAC, and threat models |
| [docs/cost-management.md](docs/cost-management.md) | AWS cost tracking, budgets, and teardown schedules |
| [docs/incident-response.md](docs/incident-response.md) | Incident states, AI advisory workflow, and recovery runbooks |
| [docs/testing.md](docs/testing.md) | Testing strategy: unit, integration, chaos, and performance |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common failure modes and debugging procedures |

---

## Development Status

| Phase | Description | Status | Details |
|:---:|---|:---:|---|
| **0** | **Project Initialization** |  Completed | Repository structure, CI/CD foundation, docs, ADRs, scripts |
| **1** | **AWS Infrastructure & Terraform** |  Completed | 5 modules, dev & showcase envs, EKS 1.36, AL2023, Checkov validated |
| **2** | **DemoStore Application** | ✅ Completed | FastAPI product/order APIs, PostgreSQL, Alembic migrations, health checks, Prometheus metrics, Docker Compose; 8 tests passing |
| **3** | **Kubernetes & Helm** | ⬜ Not Started | Production manifests, Helm charts, ResourceQuotas, NetworkPolicies |
| **4** | **CI/CD & GitOps** | ⬜ Not Started | Jenkins multibranch pipeline, ArgoCD Application CRDs |
| **5** | **Monitoring & Observability** | ⬜ Not Started | Prometheus rules, Alertmanager routing, Grafana dashboards |
| **6** | **Incident Management Engine** | ⬜ Not Started | FastAPI engine, PostgreSQL schema, webhook receiver, audit logs |
| **7** | **AI Diagnosis & Self-Healing** | ⬜ Not Started | LLM prompt engineering, RAG pipeline, policy validation guardrails |
| **8** | **DevSecOps & Chaos Engineering** | ⬜ Not Started | Kyverno admission control, LitmusChaos experiments, k6 performance tests |
| **9** | **React Frontend Dashboard** | ⬜ Not Started | 9 responsive views, live incident telemetry, human approval controls |
| **10** | **AWS Deployment & Validation** | ⬜ Not Started | Cloud deployment, end-to-end chaos drills, cost verification |
| **11** | **Documentation & Portfolio** | ⬜ Not Started | Architecture diagrams, incident runbooks, demonstration video, showcase writeup |

---

## Engineering Standards

- **Local-First Verification**: Every microservice and policy is developed and tested against local `kind` clusters before cloud deployment.
- **Fail-Safe Self-Healing**: Automated remediation is strictly gated by safety policies and rate limits. Critical mutations mandate human-in-the-loop approval.
- **Security-First IaC**: Zero hardcoded credentials, state storage encrypted at rest and in transit, private-first subnets, and automated static policy checks.

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
