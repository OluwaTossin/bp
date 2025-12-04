#!/bin/bash

#######################################################
# Blood Pressure Calculator - Deployment Script
# 
# One-command deployment to AWS via Terraform
# Supports staging and production environments
#######################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}/infra"
APP_DIR="${SCRIPT_DIR}/BPCalculator"

# Default values
ENVIRONMENT=""
AUTO_APPROVE=""
SKIP_BUILD=""

#######################################################
# Functions
#######################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  BP Calculator - Deployment${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
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

usage() {
    cat << EOF
Usage: $0 <environment> [options]

Deploy Blood Pressure Calculator to AWS

ARGUMENTS:
    environment     Environment to deploy (staging|prod|all)

OPTIONS:
    --auto-approve  Skip confirmation prompts
    --skip-build    Skip application build step
    -h, --help      Show this help message

EXAMPLES:
    # Deploy to staging
    $0 staging

    # Deploy to production with auto-approval
    $0 prod --auto-approve

    # Deploy to both environments
    $0 all

    # Quick deploy (skip build)
    $0 staging --skip-build

ENVIRONMENTS:
    staging     Deploy to staging environment (auto-approve after tests)
    prod        Deploy to production environment (manual approval required)
    all         Deploy to both staging and production

PREREQUISITES:
    - AWS CLI configured with credentials
    - Terraform installed (>= 1.0)
    - .NET 8.0 SDK (if not skipping build)
    - S3 backend: bp-terraform-state-1764230215
    - DynamoDB table: bp-terraform-locks

NOTES:
    - Separate Terraform state files per environment
    - State files: bp-calculator/{staging|production}/terraform.tfstate
    - Both environments use t3.micro instances (free tier)
    - CloudWatch logs: bp-calculator-logs-{staging|prod}

EOF
}

check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install: https://aws.amazon.com/cli/"
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run: aws configure"
        exit 1
    fi

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install: https://www.terraform.io/downloads"
        exit 1
    fi

    # Check .NET SDK (if not skipping build)
    if [[ -z "$SKIP_BUILD" ]]; then
        if ! command -v dotnet &> /dev/null; then
            print_error ".NET SDK not found. Please install .NET 8.0 SDK"
            exit 1
        fi
    fi

    # Check infra directory exists
    if [[ ! -d "$INFRA_DIR" ]]; then
        print_error "Infrastructure directory not found: $INFRA_DIR"
        exit 1
    fi

    print_success "All prerequisites met"
}

build_application() {
    if [[ -n "$SKIP_BUILD" ]]; then
        print_warning "Skipping application build (--skip-build)"
        return
    fi

    print_info "Building application..."

    cd "$APP_DIR"

    # Restore dependencies
    dotnet restore

    # Build in Release mode
    dotnet build --configuration Release --no-restore

    # Run tests
    print_info "Running tests..."
    dotnet test --configuration Release --no-build --verbosity minimal

    cd "$SCRIPT_DIR"

    print_success "Application built and tested successfully"
}

deploy_infrastructure() {
    local env=$1
    local tfvars_file=""
    local state_env=""

    # Map environment names
    if [[ "$env" == "staging" ]]; then
        tfvars_file="env/staging.tfvars"
        state_env="staging"
    elif [[ "$env" == "prod" ]]; then
        tfvars_file="env/prod.tfvars"
        state_env="production"
    else
        print_error "Invalid environment: $env"
        exit 1
    fi

    print_info "Deploying infrastructure to: $env"
    
    cd "$INFRA_DIR"

    # Initialize Terraform with environment-specific state
    print_info "Initializing Terraform (state: bp-calculator/$state_env/terraform.tfstate)..."
    terraform init -reconfigure \
        -backend-config="key=bp-calculator/$state_env/terraform.tfstate"

    # Validate configuration
    print_info "Validating Terraform configuration..."
    terraform validate

    # Plan
    print_info "Planning infrastructure changes..."
    terraform plan -var-file="$tfvars_file" -out=tfplan

    # Confirm before apply (unless auto-approve)
    if [[ -z "$AUTO_APPROVE" ]]; then
        echo ""
        read -p "Apply infrastructure changes for $env? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            print_warning "Deployment cancelled by user"
            rm -f tfplan
            exit 0
        fi
    fi

    # Apply
    print_info "Applying infrastructure changes..."
    terraform apply tfplan

    rm -f tfplan

    # Get outputs
    print_info "Infrastructure outputs:"
    echo ""
    terraform output

    cd "$SCRIPT_DIR"

    print_success "Infrastructure deployed to $env"
}

deploy_application() {
    local env=$1
    local app_name=""
    local eb_env_name=""

    # Map environment names
    if [[ "$env" == "staging" ]]; then
        app_name="bp-calculator-staging"
        eb_env_name="bp-calculator-staging"
    elif [[ "$env" == "prod" ]]; then
        app_name="bp-calculator-prod"
        eb_env_name="bp-calculator-prod"
    else
        print_error "Invalid environment: $env"
        exit 1
    fi

    print_info "Deploying application to: $env"

    cd "$APP_DIR"

    # Publish application
    print_info "Publishing application..."
    dotnet publish --configuration Release --output ./publish

    # Create deployment package
    print_info "Creating deployment package..."
    VERSION_LABEL="v$(date +%Y%m%d-%H%M%S)-manual"
    cd publish
    zip -r "../${VERSION_LABEL}.zip" .
    cd ..

    # Get S3 bucket name from Terraform outputs
    cd "$INFRA_DIR"
    S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")
    cd "$SCRIPT_DIR"

    if [[ -z "$S3_BUCKET" ]]; then
        print_error "Could not get S3 bucket name from Terraform outputs"
        exit 1
    fi

    # Upload to S3
    print_info "Uploading to S3: $S3_BUCKET"
    aws s3 cp "$APP_DIR/${VERSION_LABEL}.zip" "s3://$S3_BUCKET/${VERSION_LABEL}.zip"

    # Create application version
    print_info "Creating Elastic Beanstalk application version..."
    aws elasticbeanstalk create-application-version \
        --application-name "$app_name" \
        --version-label "$VERSION_LABEL" \
        --source-bundle S3Bucket="$S3_BUCKET",S3Key="${VERSION_LABEL}.zip" \
        --description "Manual deployment - $(date '+%Y-%m-%d %H:%M:%S')"

    # Deploy to environment
    print_info "Deploying to Elastic Beanstalk environment: $eb_env_name"
    aws elasticbeanstalk update-environment \
        --application-name "$app_name" \
        --environment-name "$eb_env_name" \
        --version-label "$VERSION_LABEL"

    # Wait for deployment
    print_info "Waiting for deployment to complete (this may take 3-5 minutes)..."
    aws elasticbeanstalk wait environment-updated \
        --application-name "$app_name" \
        --environment-names "$eb_env_name"

    # Clean up
    rm -f "$APP_DIR/${VERSION_LABEL}.zip"
    rm -rf "$APP_DIR/publish"

    # Get environment URL
    ENV_URL=$(aws elasticbeanstalk describe-environments \
        --application-name "$app_name" \
        --environment-names "$eb_env_name" \
        --query 'Environments[0].CNAME' \
        --output text)

    cd "$SCRIPT_DIR"

    print_success "Application deployed to $env"
    print_success "Environment URL: http://$ENV_URL"
}

deploy_environment() {
    local env=$1

    echo ""
    print_info "=========================================="
    print_info "  Deploying to: $env"
    print_info "=========================================="
    echo ""

    # Deploy infrastructure
    deploy_infrastructure "$env"

    echo ""

    # Deploy application
    deploy_application "$env"

    echo ""
    print_success "✓ Deployment to $env complete!"
    echo ""
}

#######################################################
# Main Script
#######################################################

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        staging|prod|all)
            ENVIRONMENT=$1
            shift
            ;;
        --auto-approve)
            AUTO_APPROVE="true"
            shift
            ;;
        --skip-build)
            SKIP_BUILD="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate environment argument
if [[ -z "$ENVIRONMENT" ]]; then
    print_error "Environment argument required"
    usage
    exit 1
fi

# Main execution
print_header

check_prerequisites

build_application

# Deploy based on environment
case $ENVIRONMENT in
    staging)
        deploy_environment "staging"
        ;;
    prod)
        if [[ -z "$AUTO_APPROVE" ]]; then
            print_warning "Deploying to PRODUCTION environment"
            read -p "Are you sure you want to deploy to production? (yes/no): " confirm
            if [[ "$confirm" != "yes" ]]; then
                print_warning "Deployment cancelled"
                exit 0
            fi
        fi
        deploy_environment "prod"
        ;;
    all)
        deploy_environment "staging"
        echo ""
        print_info "Staging deployment complete. Proceeding to production..."
        sleep 2
        deploy_environment "prod"
        ;;
esac

echo ""
print_success "=========================================="
print_success "  Deployment Complete!"
print_success "=========================================="
echo ""

print_info "Next steps:"
print_info "1. Verify application health in AWS Console"
print_info "2. Check CloudWatch logs for any errors"
print_info "3. Test application functionality"
print_info "4. Monitor CloudWatch alarms"
echo ""

exit 0
