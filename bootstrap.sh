#!/bin/bash

###############################################################################
# Blood Pressure Calculator - Bootstrap Script
# Purpose: One-time setup for Terraform backend and AWS prerequisites
# Usage: ./bootstrap.sh
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="bp-calculator"
REGION="${AWS_REGION:-eu-west-1}"
ACCOUNT_ID=""

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check for required tools
    local tools=("aws" "terraform" "jq")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            print_success "$tool is installed"
        else
            print_error "$tool is not installed"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        print_info "Installation instructions:"
        echo "  - AWS CLI: https://aws.amazon.com/cli/"
        echo "  - Terraform: https://www.terraform.io/downloads"
        echo "  - jq: sudo apt-get install jq (Linux) or brew install jq (Mac)"
        exit 1
    fi
    
    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        print_success "AWS credentials configured (Account: $ACCOUNT_ID)"
    else
        print_error "AWS credentials not configured"
        echo ""
        print_info "Configure AWS credentials:"
        echo "  aws configure"
        echo "  OR set environment variables:"
        echo "    export AWS_ACCESS_KEY_ID=<your-key>"
        echo "    export AWS_SECRET_ACCESS_KEY=<your-secret>"
        exit 1
    fi
    
    echo ""
}

create_terraform_backend() {
    print_header "Creating Terraform Backend"
    
    # Generate unique suffix using timestamp
    local unique_suffix=$(date +%s)
    local bucket_name="${APP_NAME}-tfstate-${unique_suffix}"
    local table_name="${APP_NAME}-locks"
    
    # Check if bucket already exists
    if aws s3 ls "s3://${bucket_name}" 2>/dev/null; then
        print_info "S3 bucket already exists: ${bucket_name}"
    else
        print_info "Creating S3 bucket: ${bucket_name}"
        aws s3 mb "s3://${bucket_name}" --region "$REGION"
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "${bucket_name}" \
            --versioning-configuration Status=Enabled \
            --region "$REGION"
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "${bucket_name}" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }]
            }' \
            --region "$REGION"
        
        # Block public access
        aws s3api put-public-access-block \
            --bucket "${bucket_name}" \
            --public-access-block-configuration \
                "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
            --region "$REGION"
        
        print_success "S3 bucket created and configured: ${bucket_name}"
    fi
    
    # Check if DynamoDB table already exists
    if aws dynamodb describe-table --table-name "${table_name}" --region "$REGION" &>/dev/null; then
        print_info "DynamoDB table already exists: ${table_name}"
    else
        print_info "Creating DynamoDB table: ${table_name}"
        aws dynamodb create-table \
            --table-name "${table_name}" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "$REGION" \
            --tags Key=Project,Value=bp-calculator Key=ManagedBy,Value=bootstrap
        
        # Wait for table to be active
        print_info "Waiting for DynamoDB table to be active..."
        aws dynamodb wait table-exists --table-name "${table_name}" --region "$REGION"
        
        print_success "DynamoDB table created: ${table_name}"
    fi
    
    # Save backend configuration
    cat > infra/backend-config.tfvars <<EOF
bucket         = "${bucket_name}"
key            = "bp-calculator/terraform.tfstate"
region         = "${REGION}"
dynamodb_table = "${table_name}"
encrypt        = true
EOF
    
    print_success "Backend configuration saved to infra/backend-config.tfvars"
    
    # Save to .env file for scripts to use
    cat > .env <<EOF
# Terraform Backend Configuration
TF_STATE_BUCKET=${bucket_name}
TF_STATE_TABLE=${table_name}
AWS_REGION=${REGION}
AWS_ACCOUNT_ID=${ACCOUNT_ID}
APP_NAME=${APP_NAME}
EOF
    
    print_success "Environment variables saved to .env"
    echo ""
}

setup_terraform_backend() {
    print_header "Configuring Terraform Backend"
    
    if [ ! -f "infra/backend-config.tfvars" ]; then
        print_error "Backend configuration not found. Run create_terraform_backend first."
        exit 1
    fi
    
    cd infra
    
    # Create backend configuration in main.tf if not exists
    if ! grep -q "backend \"s3\"" backend.tf 2>/dev/null; then
        print_info "Creating backend.tf"
        cat > backend.tf <<'EOF'
terraform {
  backend "s3" {
    # Configuration loaded from backend-config.tfvars
    # Run: terraform init -backend-config=backend-config.tfvars
  }
}
EOF
        print_success "backend.tf created"
    else
        print_info "Backend configuration already exists in backend.tf"
    fi
    
    # Initialize Terraform with backend
    print_info "Initializing Terraform with backend..."
    terraform init -backend-config=backend-config.tfvars -reconfigure
    
    cd ..
    
    print_success "Terraform backend configured"
    echo ""
}

create_environment_configs() {
    print_header "Creating Environment Configuration Files"
    
    mkdir -p infra/env
    
    # Create staging.tfvars if not exists
    if [ ! -f "infra/env/staging.tfvars" ]; then
        print_info "Creating staging.tfvars"
        cat > infra/env/staging.tfvars <<EOF
# Staging Environment Configuration
environment = "staging"
region      = "${REGION}"

# Instance Configuration
instance_type = "t3.micro"  # Free tier eligible

# Application Configuration
app_name = "${APP_NAME}"

# Monitoring
enable_monitoring = true
log_retention_days = 7

# Tags
tags = {
  Environment = "staging"
  Project     = "bp-calculator"
  ManagedBy   = "terraform"
  CostCenter  = "development"
}
EOF
        print_success "staging.tfvars created"
    else
        print_info "staging.tfvars already exists"
    fi
    
    # Create prod.tfvars if not exists
    if [ ! -f "infra/env/prod.tfvars" ]; then
        print_info "Creating prod.tfvars"
        cat > infra/env/prod.tfvars <<EOF
# Production Environment Configuration
environment = "prod"
region      = "${REGION}"

# Instance Configuration
instance_type = "t3.small"  # Production sizing

# Application Configuration
app_name = "${APP_NAME}"

# Monitoring
enable_monitoring = true
log_retention_days = 30

# Tags
tags = {
  Environment = "production"
  Project     = "bp-calculator"
  ManagedBy   = "terraform"
  CostCenter  = "production"
}
EOF
        print_success "prod.tfvars created"
    else
        print_info "prod.tfvars already exists"
    fi
    
    echo ""
}

create_github_secrets_guide() {
    print_header "GitHub Secrets Configuration"
    
    print_info "To enable CI/CD, add these secrets to your GitHub repository:"
    echo ""
    echo "Repository Settings > Secrets and variables > Actions > New repository secret"
    echo ""
    echo "Required secrets:"
    echo "  AWS_ACCESS_KEY_ID     = <your-aws-access-key>"
    echo "  AWS_SECRET_ACCESS_KEY = <your-aws-secret-key>"
    echo "  AWS_REGION            = ${REGION}"
    echo "  AWS_ACCOUNT_ID        = ${ACCOUNT_ID}"
    echo ""
    
    if [ -f ".env" ]; then
        print_info "These values are also saved in .env file (DO NOT commit this file!)"
    fi
    
    echo ""
}

verify_setup() {
    print_header "Verifying Setup"
    
    local all_good=true
    
    # Check backend config
    if [ -f "infra/backend-config.tfvars" ]; then
        print_success "Backend configuration exists"
    else
        print_error "Backend configuration missing"
        all_good=false
    fi
    
    # Check environment configs
    if [ -f "infra/env/staging.tfvars" ]; then
        print_success "Staging configuration exists"
    else
        print_error "Staging configuration missing"
        all_good=false
    fi
    
    if [ -f "infra/env/prod.tfvars" ]; then
        print_success "Production configuration exists"
    else
        print_error "Production configuration missing"
        all_good=false
    fi
    
    # Check Terraform
    if [ -d "infra/.terraform" ]; then
        print_success "Terraform initialized"
    else
        print_warning "Terraform not initialized (will be done on first deploy)"
    fi
    
    # Check .env
    if [ -f ".env" ]; then
        print_success ".env file created"
    else
        print_warning ".env file missing"
    fi
    
    echo ""
    
    if [ "$all_good" = true ]; then
        print_success "All checks passed!"
    else
        print_warning "Some checks failed. Review the output above."
    fi
    
    echo ""
}

###############################################################################
# Main Bootstrap Logic
###############################################################################

main() {
    print_header "BP Calculator Bootstrap"
    echo "This script will set up your AWS environment for deployment"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Create Terraform backend
    create_terraform_backend
    
    # Setup Terraform
    setup_terraform_backend
    
    # Create environment configs
    create_environment_configs
    
    # Verify setup
    verify_setup
    
    # Show GitHub secrets guide
    create_github_secrets_guide
    
    print_header "Bootstrap Complete!"
    print_success "Your environment is ready for deployment"
    echo ""
    print_info "Next steps:"
    echo "  1. Review the generated configuration files in infra/env/"
    echo "  2. Update GitHub secrets (see output above)"
    echo "  3. Run deployment: ./deploy.sh staging"
    echo ""
    print_warning "Important: Add .env to .gitignore to avoid committing secrets!"
    echo ""
}

# Run main function
main
