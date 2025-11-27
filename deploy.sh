#!/bin/bash

###############################################################################
# Blood Pressure Calculator - One-Command Deployment Script
# Usage: ./deploy.sh [staging|prod|all]
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
REGION="eu-west-1"
ENVIRONMENT=${1:-staging}

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

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check for required tools
    local tools=("dotnet" "aws" "terraform" "zip")
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            print_success "$tool is installed"
        else
            print_error "$tool is not installed"
            exit 1
        fi
    done
    
    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        print_success "AWS credentials configured"
    else
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    echo ""
}

build_application() {
    print_header "Building Application"
    
    # Restore dependencies
    print_info "Restoring dependencies..."
    dotnet restore
    
    # Build application
    print_info "Building application..."
    dotnet build --configuration Release --no-restore
    
    # Run tests
    print_info "Running tests..."
    dotnet test --configuration Release --no-build --verbosity normal
    
    # Publish application
    print_info "Publishing application..."
    dotnet publish -c Release -o publish/
    
    # Create deployment package
    print_info "Creating deployment package..."
    cd publish
    zip -r ../bp-app-$(git rev-parse --short HEAD).zip .
    cd ..
    
    print_success "Application built successfully"
    echo ""
}

deploy_infrastructure() {
    local env=$1
    print_header "Deploying Infrastructure: $env"
    
    cd infra
    
    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        print_info "Initializing Terraform..."
        terraform init
    fi
    
    # Plan infrastructure
    print_info "Planning infrastructure changes..."
    terraform plan -var-file="env/${env}.tfvars" -out="${env}.tfplan"
    
    # Apply infrastructure
    print_info "Applying infrastructure..."
    terraform apply "${env}.tfplan"
    
    # Save outputs
    terraform output -json > "../outputs/${env}-outputs.json"
    
    cd ..
    
    print_success "Infrastructure deployed: $env"
    echo ""
}

deploy_application() {
    local env=$1
    print_header "Deploying Application: $env"
    
    local version=$(git rev-parse --short HEAD)
    local bucket_name=$(cat outputs/${env}-outputs.json | jq -r '.app_bucket_name.value')
    local env_name="${APP_NAME}-${env}"
    
    # Upload to S3
    print_info "Uploading application to S3..."
    aws s3 cp "bp-app-${version}.zip" "s3://${bucket_name}/bp-app-${version}.zip"
    
    # Create application version
    print_info "Creating Elastic Beanstalk application version..."
    aws elasticbeanstalk create-application-version \
        --application-name "$APP_NAME" \
        --version-label "$version" \
        --source-bundle "S3Bucket=${bucket_name},S3Key=bp-app-${version}.zip" \
        --region "$REGION"
    
    # Deploy to environment
    print_info "Deploying to Elastic Beanstalk environment..."
    aws elasticbeanstalk update-environment \
        --environment-name "$env_name" \
        --version-label "$version" \
        --region "$REGION"
    
    # Wait for deployment
    print_info "Waiting for environment to be ready..."
    aws elasticbeanstalk wait environment-updated \
        --environment-names "$env_name" \
        --region "$REGION"
    
    # Get environment URL
    local url=$(aws elasticbeanstalk describe-environments \
        --environment-names "$env_name" \
        --region "$REGION" \
        --query "Environments[0].CNAME" \
        --output text)
    
    print_success "Application deployed: $env"
    print_info "URL: http://${url}"
    echo ""
}

run_health_check() {
    local env=$1
    print_header "Running Health Check: $env"
    
    local env_name="${APP_NAME}-${env}"
    local url=$(aws elasticbeanstalk describe-environments \
        --environment-names "$env_name" \
        --region "$REGION" \
        --query "Environments[0].CNAME" \
        --output text)
    
    print_info "Checking http://${url}"
    
    # Try to connect
    if curl -s -o /dev/null -w "%{http_code}" "http://${url}" | grep -q "200\|302"; then
        print_success "Health check passed"
    else
        print_error "Health check failed"
    fi
    
    echo ""
}

###############################################################################
# Main Deployment Logic
###############################################################################

main() {
    print_header "BP Calculator Deployment"
    echo -e "Environment: ${GREEN}${ENVIRONMENT}${NC}"
    echo -e "Region: ${BLUE}${REGION}${NC}"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Build application
    build_application
    
    # Create outputs directory
    mkdir -p outputs
    
    # Deploy based on environment parameter
    case $ENVIRONMENT in
        staging)
            deploy_infrastructure "staging"
            deploy_application "staging"
            run_health_check "staging"
            ;;
        prod|production)
            deploy_infrastructure "prod"
            deploy_application "prod"
            run_health_check "prod"
            ;;
        all)
            deploy_infrastructure "staging"
            deploy_application "staging"
            run_health_check "staging"
            
            deploy_infrastructure "prod"
            deploy_application "prod"
            run_health_check "prod"
            ;;
        *)
            print_error "Invalid environment: $ENVIRONMENT"
            echo "Usage: ./deploy.sh [staging|prod|all]"
            exit 1
            ;;
    esac
    
    print_header "Deployment Complete"
    print_success "All deployments completed successfully!"
    echo ""
    print_info "Next steps:"
    echo "  - Run E2E tests: npm test"
    echo "  - Check CloudWatch logs: aws logs tail /aws/elasticbeanstalk/${APP_NAME}-${ENVIRONMENT}"
    echo "  - Monitor metrics in AWS Console"
    echo ""
}

# Run main function
main
