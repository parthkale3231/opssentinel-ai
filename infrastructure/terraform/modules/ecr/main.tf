locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Lifecycle policy: keep only the N most recent images
  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Retain only the ${var.image_retention_count} most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.image_retention_count
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ─── DemoStore ECR Repository ─────────────────────────────────────────────────
resource "aws_ecr_repository" "demostore" {
  name                 = "${local.name_prefix}/demostore"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${local.name_prefix}-demostore-ecr"
    Service = "demostore"
  }
}

resource "aws_ecr_lifecycle_policy" "demostore" {
  repository = aws_ecr_repository.demostore.name
  policy     = local.lifecycle_policy
}

# ─── OpsSentinel ECR Repository ───────────────────────────────────────────────
resource "aws_ecr_repository" "opssentinel" {
  name                 = "${local.name_prefix}/opssentinel"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${local.name_prefix}-opssentinel-ecr"
    Service = "opssentinel"
  }
}

resource "aws_ecr_lifecycle_policy" "opssentinel" {
  repository = aws_ecr_repository.opssentinel.name
  policy     = local.lifecycle_policy
}

# ─── OpsSentinel Frontend ECR Repository ─────────────────────────────────────
resource "aws_ecr_repository" "opssentinel_frontend" {
  name                 = "${local.name_prefix}/opssentinel-frontend"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${local.name_prefix}-opssentinel-frontend-ecr"
    Service = "opssentinel-frontend"
  }
}

resource "aws_ecr_lifecycle_policy" "opssentinel_frontend" {
  repository = aws_ecr_repository.opssentinel_frontend.name
  policy     = local.lifecycle_policy
}

