# Troubleshooting Guide

## Local Kubernetes (kind)

### Pod stuck in Pending

```powershell
kubectl describe pod <pod-name> -n <namespace>
# Look for: Insufficient CPU/Memory, PVC not bound, image pull failure
```

### Image pull failure

```powershell
# Check image exists locally for kind
docker images | grep <image-name>

# Load image into kind cluster
kind load docker-image <image>:<tag> --name opssentinel
```

### Service not reachable

```powershell
kubectl get svc -n <namespace>
kubectl port-forward svc/<service-name> 8080:80 -n <namespace>
```

## Python / FastAPI

### Database connection error

```
sqlalchemy.exc.OperationalError: could not connect to server
```
- Check PostgreSQL is running: `docker ps | grep postgres`
- Verify `DATABASE_URL` in `.env`
- Check PostgreSQL port is mapped: `docker port <container>`

### Uvicorn import error

```powershell
# Ensure virtual environment is activated
.venv\Scripts\activate
pip install -r requirements.txt
```

## Terraform

### State lock error

```
Error locking state: Error acquiring the state lock
```
- Check if another Terraform process is running.
- If stale: `terraform force-unlock <lock-id>`

### Provider auth error

```
Error: No valid credential sources found
```
- Run `aws configure` and verify `aws sts get-caller-identity`

## ArgoCD

### Application out of sync

```powershell
kubectl get applications -n argocd
argocd app sync <app-name>
argocd app get <app-name>
```

### ArgoCD can't reach Git repo

- Check repository credentials in ArgoCD settings.
- Verify repository URL is correct.

## Prometheus

### No metrics appearing

```powershell
kubectl get servicemonitors -n monitoring
kubectl describe servicemonitor <name> -n monitoring
# Verify 'matchLabels' matches your service labels
```

### Alert not firing

```powershell
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 -n monitoring
# Check http://localhost:9093 for alert status
```

## OpsSentinel

### Webhook not receiving alerts

1. Verify Alertmanager config has the correct webhook URL.
2. Check OpsSentinel backend is running and accessible.
3. Check firewall / NetworkPolicy rules.
4. Test manually: `curl -X POST http://localhost:8000/api/v1/webhooks/alerts -d @tests/fixtures/test-alert.json`

### AI diagnosis not working

- Check `OPENAI_API_KEY` is set in `.env`
- Check LLM provider connectivity
- OpsSentinel falls back to rule-based diagnosis if AI is unavailable

