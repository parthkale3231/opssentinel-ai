# Local Development Setup

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Docker Desktop | Latest | https://www.docker.com/products/docker-desktop |
| Git | Latest | https://git-scm.com |
| Python | 3.11+ | https://python.org |
| Node.js | 20+ | https://nodejs.org |
| kind | Latest | https://kind.sigs.k8s.io |
| kubectl | 1.29+ | https://kubernetes.io/docs/tasks/tools |
| Helm | 3.14+ | https://helm.sh |
| Terraform | 1.7+ | https://developer.hashicorp.com/terraform |
| AWS CLI | v2 | https://aws.amazon.com/cli |
| Trivy | Latest | https://aquasecurity.github.io/trivy |
| Checkov | Latest | `pip install checkov` |

## Quick Setup

```powershell
# 1. Verify all tools
.\scripts\setup\bootstrap.ps1

# 2. Create local Kubernetes cluster
kind create cluster --name opssentinel

# 3. Install monitoring stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace

# 4. Set up Python environments
cd applications/demostore/backend && python -m venv .venv && .venv\Scripts\activate && pip install -r requirements.txt
cd applications/opssentinel/backend && python -m venv .venv && .venv\Scripts\activate && pip install -r requirements.txt

# 5. Set up frontend
cd applications/opssentinel/frontend && npm install
```

## Environment Variables

Copy `.env.example` to `.env` in each service directory and fill in values.

**DemoStore backend (`applications/demostore/backend/.env`):**
```
DATABASE_URL=postgresql://demostore:password@localhost:5432/demostore
LOG_LEVEL=INFO
ENVIRONMENT=local
```

**OpsSentinel backend (`applications/opssentinel/backend/.env`):**
```
DATABASE_URL=postgresql://opssentinel:password@localhost:5432/opssentinel
PROMETHEUS_URL=http://localhost:9090
KUBERNETES_IN_CLUSTER=false
LLM_PROVIDER=openai
OPENAI_API_KEY=your-key-here
LOG_LEVEL=INFO
ENVIRONMENT=local
```

## Running Services

```powershell
# Terminal 1: DemoStore
cd applications/demostore/backend
.venv\Scripts\activate
uvicorn app.main:app --reload --port 8001

# Terminal 2: OpsSentinel backend
cd applications/opssentinel/backend
.venv\Scripts\activate
uvicorn app.main:app --reload --port 8000

# Terminal 3: React frontend
cd applications/opssentinel/frontend
npm run dev
```

## Running Tests

```powershell
# DemoStore tests
cd applications/demostore/backend && python -m pytest tests/ -v

# OpsSentinel tests
cd applications/opssentinel/backend && python -m pytest tests/ -v
```

