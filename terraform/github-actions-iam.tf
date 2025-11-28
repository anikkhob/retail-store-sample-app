# =============================================================================
# GITHUB ACTIONS IAM USER AND PERMISSIONS
# =============================================================================

# ECR repositories for the retail store application
locals {
  ecr_repositories = [
    "retail-store-ui",
    "retail-store-catalog", 
    "retail-store-cart",
    "retail-store-orders",
    "retail-store-checkout"
  ]
}

# IAM User for GitHub Actions
resource "aws_iam_user" "github_actions" {
  name = "github-actions-retail-store"
  path = "/ci-cd/"

  tags = {
    Name        = "GitHub Actions User"
    Environment = var.environment
    Purpose     = "CI/CD Pipeline"
  }
}

# Access Keys for GitHub Actions User
resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# =============================================================================
# ECR PERMISSIONS POLICY
# =============================================================================

resource "aws_iam_policy" "github_actions_ecr" {
  name        = "GitHubActions-ECR-Policy"
  description = "Minimal ECR permissions for GitHub Actions"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          for repo in local.ecr_repositories : 
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${repo}"
        ]
      }
    ]
  })
}

# =============================================================================
# EKS PERMISSIONS POLICY (for ArgoCD sync)
# =============================================================================

resource "aws_iam_policy" "github_actions_eks" {
  name        = "GitHubActions-EKS-Policy"
  description = "Minimal EKS permissions for GitHub Actions"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = module.retail_app_eks.cluster_arn
      }
    ]
  })
}

# =============================================================================
# POLICY ATTACHMENTS
# =============================================================================

resource "aws_iam_user_policy_attachment" "github_actions_ecr" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

resource "aws_iam_user_policy_attachment" "github_actions_eks" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.github_actions_eks.arn
}

# =============================================================================
# OUTPUTS FOR GITHUB SECRETS
# =============================================================================

output "github_actions_access_key_id" {
  description = "Access Key ID for GitHub Actions"
  value       = aws_iam_access_key.github_actions.id
  sensitive   = true
}

output "github_actions_secret_access_key" {
  description = "Secret Access Key for GitHub Actions"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}

output "github_secrets_setup" {
  description = "GitHub Secrets to configure"
  value = {
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.github_actions.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.github_actions.secret
    AWS_REGION           = data.aws_region.current.name
    AWS_ACCOUNT_ID       = data.aws_caller_identity.current.account_id
  }
  sensitive = true
}