# AWS Cost Management

## Strategy

**Primary rule:** Use local Kubernetes (kind) for all development. Create AWS resources only when needed.

## Estimated AWS Costs (ap-south-1)

| Resource | Cost (approx.) |
|---|---|
| EKS control plane | ~$0.10/hour |
| t3.medium worker node × 2 | ~$0.068/hour each |
| ECR storage | ~$0.10/GB/month |
| S3 Terraform state | Negligible |
| NAT Gateway | ~$0.045/hour + data transfer — **avoid if possible** |
| Load Balancer | ~$0.008/hour + LCU — **avoid if possible** |

**Estimated session cost (4-hour demo session):** ~$1.50–2.00 without NAT/LB.

## Cost Controls

1. **AWS Budget Alert** — Set \$20/month budget alert.
2. **One worker node initially** — Scale only if needed.
3. **No NAT Gateway** — Use VPC endpoints or direct internet access where needed.
4. **No always-on load balancer** — Use `kubectl port-forward` for local testing.
5. **ECR lifecycle policy** — Keep only last 5 images per repo.
6. **Destroy after testing** — Always run `terraform destroy` after a session.

## Lifecycle Commands

```powershell
# Check current running resources
aws ec2 describe-instances --region ap-south-1 --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,InstanceType,Tags]' --output table

# Check EKS clusters
aws eks list-clusters --region ap-south-1

# Check load balancers (cost risk)
aws elbv2 describe-load-balancers --region ap-south-1

# Check NAT gateways (cost risk)
aws ec2 describe-nat-gateways --region ap-south-1

# Destroy infrastructure
.\scripts\cleanup\destroy.ps1 -Environment dev
```

## Post-Destroy Checklist

- [ ] EKS cluster deleted
- [ ] Node group deleted
- [ ] Load balancers deleted
- [ ] NAT gateways deleted (if created)
- [ ] VPC and subnets deleted
- [ ] Security groups deleted
- [ ] IAM roles cleaned (optional — no cost)
- [ ] ECR images retained or cleaned
- [ ] S3 Terraform state retained (minimal cost)
- [ ] AWS Billing checked after 24 hours

