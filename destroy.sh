#!/bin/bash

###############################################################################
# Blood Pressure Calculator - One-Command Teardown Script
# Usage: ./destroy.sh [staging|prod|all] [--auto-approve]
###############################################################################

set -e  # Exit on error

# Load environment configuration if exists
if [ -f ".env" ]; then
    source .env
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="${APP_NAME:-bp-calculator}"
REGION="${AWS_REGION:-eu-west-1}"
ENVIRONMENT=${1:-staging}
AUTO_APPROVE=false

# Check for auto-approve flag
if [[ "$*" == *"--auto-approve"* ]]; then
    AUTO_APPROVE=true
fi

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  $1${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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

confirm_destroy() {
    local env=$1
    
    if [ "$AUTO_APPROVE" = true ]; then
        return 0
    fi
    
    echo ""
    print_warning "You are about to destroy the ${env} environment!"
    print_warning "This will delete:"
    echo "  - Elastic Beanstalk environments"
    echo "  - Application versions"
    echo "  - S3 bucket contents"
    echo "  - CloudWatch logs and metrics"
    echo "  - All associated AWS resources"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        print_info "Destruction cancelled"
        exit 0
    fi
}

backup_terraform_state() {
    print_header "Backing Up Terraform State"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="backups/terraform-state-${timestamp}"
    
    mkdir -p "$backup_dir"
    
    if [ -d "infra/.terraform" ]; then
        cp -r infra/.terraform "$backup_dir/"
        print_success "Terraform state backed up to $backup_dir"
    else
        print_info "No Terraform state found to backup"
    fi
    
    echo ""
}

terminate_environment() {
    local env=$1
    print_header "Terminating Elastic Beanstalk Environment: $env"
    
    local env_name="${APP_NAME}-${env}"
    
    # Check if environment exists
    if aws elasticbeanstalk describe-environments \
        --environment-names "$env_name" \
        --region "$REGION" \
        --query "Environments[0].EnvironmentName" \
        --output text 2>/dev/null | grep -q "$env_name"; then
        
        print_info "Terminating environment: $env_name"
        aws elasticbeanstalk terminate-environment \
            --environment-name "$env_name" \
            --region "$REGION"
        
        print_info "Waiting for environment termination..."
        aws elasticbeanstalk wait environment-terminated \
            --environment-names "$env_name" \
            --region "$REGION" || true
        
        print_success "Environment terminated: $env_name"
    else
        print_info "Environment does not exist: $env_name"
    fi
    
    echo ""
}

delete_application_versions() {
    print_header "Deleting Application Versions"
    
    # Get all versions
    local versions=$(aws elasticbeanstalk describe-application-versions \
        --application-name "$APP_NAME" \
        --region "$REGION" \
        --query "ApplicationVersions[*].VersionLabel" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$versions" ]; then
        for version in $versions; do
            print_info "Deleting version: $version"
            aws elasticbeanstalk delete-application-version \
                --application-name "$APP_NAME" \
                --version-label "$version" \
                --delete-source-bundle \
                --region "$REGION" || true
        done
        print_success "Application versions deleted"
    else
        print_info "No application versions found"
    fi
    
    echo ""
}

empty_s3_buckets() {
    local env=$1
    print_header "Emptying S3 Buckets: $env"
    
    # Try to get bucket name from Terraform outputs
    if [ -f "outputs/${env}-outputs.json" ]; then
        local bucket_name=$(cat outputs/${env}-outputs.json | jq -r '.app_bucket_name.value' 2>/dev/null || echo "")
        
        if [ -n "$bucket_name" ] && [ "$bucket_name" != "null" ]; then
            print_info "Emptying bucket: $bucket_name"
            aws s3 rm "s3://${bucket_name}" --recursive || true
            print_success "Bucket emptied: $bucket_name"
        else
            print_info "No bucket found in Terraform outputs"
        fi
    else
        print_info "No Terraform outputs found for $env"
    fi
    
    echo ""
}

destroy_infrastructure() {
    local env=$1
    print_header "Destroying Infrastructure: $env"
    
    cd infra
    
    # Destroy with Terraform
    print_info "Running terraform destroy..."
    if [ "$AUTO_APPROVE" = true ]; then
        terraform destroy -var-file="env/${env}.tfvars" -auto-approve
    else
        terraform destroy -var-file="env/${env}.tfvars"
    fi
    
    cd ..
    
    print_success "Infrastructure destroyed: $env"
    echo ""
}

delete_cloudwatch_logs() {
    local env=$1
    print_header "Deleting CloudWatch Logs: $env"
    
    local log_group="/aws/elasticbeanstalk/${APP_NAME}-${env}"
    
    if aws logs describe-log-groups \
        --log-group-name-prefix "$log_group" \
        --region "$REGION" 2>/dev/null | grep -q "$log_group"; then
        
        print_info "Deleting log group: $log_group"
        aws logs delete-log-group \
            --log-group-name "$log_group" \
            --region "$REGION" || true
        print_success "Log group deleted"
    else
        print_info "No log groups found for $env"
    fi
    
    echo ""
}

cleanup_local_files() {
    print_header "Cleaning Up Local Files"
    
    # Remove build artifacts
    if [ -d "publish" ]; then
        rm -rf publish
        print_success "Removed publish directory"
    fi
    
    # Remove deployment packages
    rm -f bp-app-*.zip
    print_success "Removed deployment packages"
    
    # Remove Terraform plans
    rm -f infra/*.tfplan
    print_success "Removed Terraform plans"
    
    echo ""
}

destroy_terraform_backend() {
    print_header "Destroying Terraform Backend (S3 & DynamoDB)"
    
    print_warning "This will delete the Terraform state backend!"
    
    if [ "$AUTO_APPROVE" = false ]; then
        read -p "Delete Terraform backend? (yes/no): " confirmation
        if [ "$confirmation" != "yes" ]; then
            print_info "Backend deletion skipped"
            return
        fi
    fi
    
    # Get backend configuration from .env or backend-config.tfvars
    local state_bucket="${TF_STATE_BUCKET}"
    local lock_table="${TF_STATE_TABLE}"
    
    if [ -z "$state_bucket" ] && [ -f "infra/backend-config.tfvars" ]; then
        print_info "Reading backend configuration from backend-config.tfvars"
        state_bucket=$(grep '^bucket' infra/backend-config.tfvars | cut -d'=' -f2 | tr -d ' "')
        lock_table=$(grep '^dynamodb_table' infra/backend-config.tfvars | cut -d'=' -f2 | tr -d ' "')
    fi
    
    if [ -z "$state_bucket" ] || [ -z "$lock_table" ]; then
        print_error "Could not determine backend configuration"
        print_info "Manually delete these resources:"
        echo "  - S3 bucket: ${APP_NAME}-tfstate-*"
        echo "  - DynamoDB table: ${APP_NAME}-locks"
        return
    fi
    
    print_info "Deleting S3 bucket: $state_bucket"
    if aws s3 ls "s3://${state_bucket}" &>/dev/null; then
        aws s3 rb "s3://${state_bucket}" --force --region "$REGION" || print_warning "Failed to delete S3 bucket"
        print_success "S3 bucket deleted"
    else
        print_info "S3 bucket does not exist: $state_bucket"
    fi
    
    print_info "Deleting DynamoDB table: $lock_table"
    if aws dynamodb describe-table --table-name "$lock_table" --region "$REGION" &>/dev/null; then
        aws dynamodb delete-table --table-name "$lock_table" --region "$REGION" || print_warning "Failed to delete DynamoDB table"
        print_success "DynamoDB table deleted"
    else
        print_info "DynamoDB table does not exist: $lock_table"
    fi
    
    # Clean up local files
    if [ -f "infra/backend-config.tfvars" ]; then
        rm infra/backend-config.tfvars
        print_success "Removed backend-config.tfvars"
    fi
    
    if [ -f ".env" ]; then
        rm .env
        print_success "Removed .env file"
    fi
    
    echo ""
}

###############################################################################
# Main Destruction Logic
###############################################################################

main() {
    print_header "BP Calculator Teardown"
    echo -e "Environment: ${RED}${ENVIRONMENT}${NC}"
    echo -e "Region: ${BLUE}${REGION}${NC}"
    echo ""
    
    # Backup Terraform state first
    backup_terraform_state
    
    # Destroy based on environment parameter
    case $ENVIRONMENT in
        staging)
            confirm_destroy "staging"
            terminate_environment "staging"
            empty_s3_buckets "staging"
            destroy_infrastructure "staging"
            delete_cloudwatch_logs "staging"
            ;;
        prod|production)
            confirm_destroy "production"
            terminate_environment "prod"
            empty_s3_buckets "prod"
            destroy_infrastructure "prod"
            delete_cloudwatch_logs "prod"
            ;;
        all)
            confirm_destroy "all environments"
            
            # Terminate environments first
            terminate_environment "staging"
            terminate_environment "prod"
            
            # Delete application versions
            delete_application_versions
            
            # Empty S3 buckets
            empty_s3_buckets "staging"
            empty_s3_buckets "prod"
            
            # Destroy infrastructure
            destroy_infrastructure "staging"
            destroy_infrastructure "prod"
            
            # Delete CloudWatch logs
            delete_cloudwatch_logs "staging"
            delete_cloudwatch_logs "prod"
            
            # Optional: Destroy backend
            destroy_terraform_backend
            ;;
        *)
            print_error "Invalid environment: $ENVIRONMENT"
            echo "Usage: ./destroy.sh [staging|prod|all] [--auto-approve]"
            exit 1
            ;;
    esac
    
    # Cleanup local files
    cleanup_local_files
    
    # Clean up Terraform state
    if [ -d "infra/.terraform" ]; then
        print_info "Removing Terraform state"
        rm -rf infra/.terraform
        rm -f infra/.terraform.lock.hcl
        print_success "Terraform state removed"
    fi
    
    print_header "Teardown Complete"
    print_success "All resources have been destroyed!"
    echo ""
    print_info "Next steps:"
    echo "  - Verify in AWS Console that all resources are deleted"
    echo "  - Check for any remaining S3 buckets"
    echo "  - Review AWS billing to confirm no charges"
    echo ""
}

# Run main function
main
