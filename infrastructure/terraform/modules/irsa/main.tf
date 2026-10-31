locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ─── OpsSentinel Service Account Role (IRSA) ──────────────────────────────────
# This role is assumed by the opssentinel ServiceAccount in Kubernetes via WebIdentity
resource "aws_iam_role" "opssentinel_sa" {
  name = "${local.name_prefix}-opssentinel-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:opssentinel:opssentinel-sa"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name = "${local.name_prefix}-opssentinel-sa-role"
  }
}

# Tightly-scoped Secrets Manager policy
resource "aws_iam_policy" "opssentinel_secrets" {
  name        = "${local.name_prefix}-opssentinel-secrets-policy"
  description = "Allows OpsSentinel pods to read their secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowOpsSentinelSecretRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${local.name_prefix}/opssentinel/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "opssentinel_secrets" {
  role       = aws_iam_role.opssentinel_sa.name
  policy_arn = aws_iam_policy.opssentinel_secrets.arn
}

