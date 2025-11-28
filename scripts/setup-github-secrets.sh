#!/bin/bash

# =============================================================================
# GITHUB SECRETS SETUP SCRIPT
# =============================================================================

set -e

echo "🔐 Setting up GitHub Secrets for CI/CD Pipeline"
echo "=============================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it first:"
    echo "   https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo "🔑 Please authenticate with GitHub CLI:"
    gh auth login
fi

# Get Terraform outputs
echo "📋 Retrieving AWS credentials from Terraform..."
cd ../terraform

AWS_ACCESS_KEY_ID=$(terraform output -raw github_actions_access_key_id)
AWS_SECRET_ACCESS_KEY=$(terraform output -raw github_actions_secret_access_key)
AWS_REGION=$(terraform output -raw aws_region)
AWS_ACCOUNT_ID=$(terraform output -raw aws_account_id)

# Set GitHub secrets
echo "🚀 Setting GitHub repository secrets..."

gh secret set AWS_ACCESS_KEY_ID --body "$AWS_ACCESS_KEY_ID"
gh secret set AWS_SECRET_ACCESS_KEY --body "$AWS_SECRET_ACCESS_KEY"
gh secret set AWS_REGION --body "$AWS_REGION"
gh secret set AWS_ACCOUNT_ID --body "$AWS_ACCOUNT_ID"

echo "✅ GitHub secrets configured successfully!"
echo ""
echo "📝 Configured secrets:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo "   - AWS_REGION: $AWS_REGION"
echo "   - AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
echo ""
echo "🎯 Your GitHub Actions pipeline is now ready!"