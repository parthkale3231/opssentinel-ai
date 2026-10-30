.DEFAULT_GOAL := help

BASE := c:\Users\Parth\OneDrive\Desktop\OpsSentinel AI
DEMOSTORE := $(BASE)\applications\demostore\backend
OPSSENTINEL := $(BASE)\applications\opssentinel\backend
FRONTEND := $(BASE)\applications\opssentinel\frontend
TF_DEV := $(BASE)\infrastructure\terraform\environments\dev

.PHONY: help bootstrap cluster-up cluster-down \
        demostore-dev opssentinel-dev frontend-dev \
        test-demostore test-opssentinel \
        tf-init tf-validate tf-plan tf-apply tf-destroy \
        docker-build-demostore docker-build-opssentinel \
        scan-demostore scan-opssentinel \
        monitoring-install monitoring-uninstall \
        argocd-install clean

help:  ## Show this help
	@echo.
	@echo OpsSentinel AI — Developer Commands
	@echo =====================================
	@echo.
	@echo   make bootstrap           Check all required tools
	@echo   make cluster-up          Create kind Kubernetes cluster
	@echo   make cluster-down        Delete kind cluster
	@echo   make demostore-dev       Run DemoStore locally (port 8001)
	@echo   make opssentinel-dev     Run OpsSentinel backend locally (port 8000)
	@echo   make frontend-dev        Run React dashboard locally
	@echo   make test-demostore      Run DemoStore unit tests
	@echo   make test-opssentinel    Run OpsSentinel unit tests
	@echo   make tf-init             Terraform init (dev env)
	@echo   make tf-validate         Terraform validate (dev env)
	@echo   make tf-plan             Terraform plan (dev env)
	@echo   make tf-apply            Terraform apply (dev env)
	@echo   make tf-destroy          Terraform destroy (dev env)
	@echo   make docker-build-demostore   Build DemoStore image
	@echo   make docker-build-opssentinel Build OpsSentinel image
	@echo   make scan-demostore      Trivy scan DemoStore image
	@echo   make scan-opssentinel    Trivy scan OpsSentinel image
	@echo   make monitoring-install  Install Prometheus stack via Helm
	@echo   make argocd-install      Install ArgoCD via Helm
	@echo   make clean               Remove build artifacts
	@echo.

bootstrap:  ## Verify all required development tools
	powershell -ExecutionPolicy Bypass -File scripts/setup/bootstrap.ps1

cluster-up:  ## Create kind Kubernetes cluster
	kind create cluster --name opssentinel --config kubernetes/overlays/local/kind-config.yaml

cluster-down:  ## Delete kind cluster
	kind delete cluster --name opssentinel

demostore-dev:  ## Run DemoStore FastAPI app locally
	cd $(DEMOSTORE) && uvicorn app.main:app --reload --port 8001

opssentinel-dev:  ## Run OpsSentinel FastAPI app locally
	cd $(OPSSENTINEL) && uvicorn app.main:app --reload --port 8000

frontend-dev:  ## Run React frontend dev server
	cd $(FRONTEND) && npm run dev

test-demostore:  ## Run DemoStore tests
	cd $(DEMOSTORE) && python -m pytest tests/ -v

test-opssentinel:  ## Run OpsSentinel tests
	cd $(OPSSENTINEL) && python -m pytest tests/ -v

tf-init:  ## Terraform init
	cd $(TF_DEV) && terraform init

tf-validate:  ## Terraform validate
	cd $(TF_DEV) && terraform validate

tf-plan:  ## Terraform plan
	cd $(TF_DEV) && terraform plan -out=tfplan

tf-apply:  ## Terraform apply (requires confirmation)
	cd $(TF_DEV) && terraform apply tfplan

tf-destroy:  ## Terraform destroy
	cd $(TF_DEV) && terraform destroy

docker-build-demostore:  ## Build DemoStore Docker image
	docker build -t demostore:latest $(DEMOSTORE)

docker-build-opssentinel:  ## Build OpsSentinel Docker image
	docker build -t opssentinel:latest $(OPSSENTINEL)

scan-demostore:  ## Scan DemoStore image with Trivy
	trivy image demostore:latest

scan-opssentinel:  ## Scan OpsSentinel image with Trivy
	trivy image opssentinel:latest

monitoring-install:  ## Install kube-prometheus-stack
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
		-n monitoring --create-namespace \
		-f observability/prometheus/values.yaml

monitoring-uninstall:  ## Remove monitoring stack
	helm uninstall monitoring -n monitoring

argocd-install:  ## Install ArgoCD
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update
	helm upgrade --install argocd argo/argo-cd \
		-n argocd --create-namespace

clean:  ## Remove build artifacts
	find . -type d -name __pycache__ -exec rm -rf {} + 2>nul || true
	find . -type d -name .pytest_cache -exec rm -rf {} + 2>nul || true
	find . -type f -name "*.pyc" -delete 2>nul || true

