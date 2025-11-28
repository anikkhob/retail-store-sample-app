# GitHub Actions IAM Security Guide

## Overview

This document outlines the minimal IAM permissions required for GitHub Actions to build, push Docker images, and manage the retail store application following AWS security best practices.

## IAM User: `github-actions-retail-store`

### Security Best Practices Applied

✅ **Principle of Least Privilege**: Only essential permissions granted  
✅ **Resource-Specific Permissions**: Limited to specific ECR repositories and EKS cluster  
✅ **No Administrative Access**: No broad AWS permissions  
✅ **Separate CI/CD User**: Dedicated user for automation  
✅ **Path-Based Organization**: User placed in `/ci-cd/` path for easy identification  

## Required Permissions

### 1. ECR Permissions (Image Build & Push)

```json
{
  "Effect": "Allow",
  "Action": [
    "ecr:GetAuthorizationToken"
  ],
  "Resource": "*"
}
```
**Purpose**: Authenticate with ECR to push/pull images

```json
{
  "Effect": "Allow",
  "Action": [
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer", 
    "ecr:BatchGetImage",
    "ecr:InitiateLayerUpload",
    "ecr:UploadLayerPart",
    "ecr:CompleteLayerUpload",
    "ecr:PutImage"
  ],
  "Resource": [
    "arn:aws:ecr:REGION:ACCOUNT:repository/retail-store-ui",
    "arn:aws:ecr:REGION:ACCOUNT:repository/retail-store-catalog",
    "arn:aws:ecr:REGION:ACCOUNT:repository/retail-store-cart",
    "arn:aws:ecr:REGION:ACCOUNT:repository/retail-store-orders",
    "arn:aws:ecr:REGION:ACCOUNT:repository/retail-store-checkout"
  ]
}
```
**Purpose**: Build and push Docker images to specific ECR repositories

### 2. EKS Permissions (Cluster Access)

```json
{
  "Effect": "Allow",
  "Action": [
    "eks:DescribeCluster"
  ],
  "Resource": "arn:aws:eks:REGION:ACCOUNT:cluster/retail-store"
}
```
**Purpose**: Allow ArgoCD to sync applications (minimal cluster access)

## What's NOT Included (Security Boundaries)

❌ **No EC2 Permissions**: Cannot create/modify instances  
❌ **No IAM Permissions**: Cannot create/modify users or roles  
❌ **No VPC Permissions**: Cannot modify network infrastructure  
❌ **No S3 Permissions**: No access to storage buckets  
❌ **No Lambda Permissions**: No serverless function access  
❌ **No RDS Permissions**: No database access  

## Setup Instructions

### 1. Deploy IAM Resources
```bash
cd terraform/
terraform apply -target=aws_iam_user.github_actions
terraform apply -target=aws_iam_policy.github_actions_ecr
terraform apply -target=aws_iam_policy.github_actions_eks
```

### 2. Configure GitHub Secrets (Automated)
```bash
# Install GitHub CLI if not already installed
brew install gh  # macOS
# or
sudo apt install gh  # Ubuntu

# Run the setup script
./scripts/setup-github-secrets.sh
```

### 3. Manual GitHub Secrets Setup
If you prefer manual setup:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add these secrets:

| Secret Name | Value | Source |
|-------------|-------|---------|
| `AWS_ACCESS_KEY_ID` | Access Key ID | `terraform output github_actions_access_key_id` |
| `AWS_SECRET_ACCESS_KEY` | Secret Access Key | `terraform output github_actions_secret_access_key` |
| `AWS_REGION` | AWS Region | `terraform output aws_region` |
| `AWS_ACCOUNT_ID` | AWS Account ID | `terraform output aws_account_id` |

## Security Monitoring

### Recommended CloudTrail Events to Monitor

- `ecr:GetAuthorizationToken`
- `ecr:PutImage`
- `eks:DescribeCluster`

### Access Key Rotation

Rotate access keys every 90 days:

```bash
# Generate new access key
terraform apply -replace=aws_iam_access_key.github_actions

# Update GitHub secrets
./scripts/setup-github-secrets.sh

# Delete old access key (after verifying new one works)
```

## Troubleshooting

### Common Permission Errors

**Error**: `AccessDenied: User is not authorized to perform ecr:GetAuthorizationToken`
**Solution**: Ensure ECR policy is attached to the user

**Error**: `AccessDenied: User is not authorized to perform ecr:PutImage`
**Solution**: Verify repository ARNs match your actual ECR repositories

**Error**: `AccessDenied: User is not authorized to perform eks:DescribeCluster`
**Solution**: Check EKS cluster ARN in the policy matches your cluster

### Verification Commands

```bash
# Test ECR access
aws ecr get-login-password --region us-west-2

# Test EKS access  
aws eks describe-cluster --name retail-store --region us-west-2

# List user policies
aws iam list-attached-user-policies --user-name github-actions-retail-store
```

## Compliance Notes

- **SOC 2**: Minimal permissions support access control requirements
- **ISO 27001**: Follows principle of least privilege
- **PCI DSS**: No access to sensitive data systems
- **GDPR**: No access to personal data storage

This configuration ensures your CI/CD pipeline has exactly the permissions it needs, nothing more.