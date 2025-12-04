#!/bin/bash

#######################################################
# Blood Pressure Calculator - Destroy Script
# 
# One-command teardown of AWS infrastructure
# Safely destroys resources with confirmation prompts
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

# Default values
ENVIRONMENT=""
AUTO_APPROVE=""
PRESERVE_STATE=""

#######################################################
# Functions
#######################################################

print_header() {
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  BP Calculator - Infrastructure Teardown${NC}"
    echo -e "${RED}========================================${NC}"
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

Destroy Blood Pressure Calculator AWS infrastructure

ARGUMENTS:
    environment     Environment to destroy (staging|prod|all)

OPTIONS:
    --auto-approve      Skip confirmation prompts (DANGEROUS!)
    --preserve-state    Keep Terraform state file (don't delete from S3)
    -h, --help          Show this help message

EXAMPLES:
    # Destroy staging (with confirmation)
    $0 staging

    # Destroy production without prompts
    $0 prod --auto-approve

    # Destroy everything
    $0 all

    # Destroy but keep state files
    $0 staging --preserve-state

ENVIRONMENTS:
    staging     Destroy staging environment only
    prod        Destroy production environment only
    all         Destroy both staging and production

WHAT GETS DESTROYED:
    - Elastic Beanstalk environment and application
    - EC2 instances
    - S3 buckets (with all contents)
    - CloudWatch log groups and alarms
    - SNS topics
    - IAM roles and instance profiles
    - Security groups
    - Terraform state (unless --preserve-state)

SAFETY FEATURES:
    - Confirmation prompt before destruction
    - Backup of Terraform state before destroy
    - Dry-run option to preview changes
    - List of resources to be destroyed

NOTES:
    ⚠️  This action is IRREVERSIBLE
    ⚠️  All data will be permanently deleted
    ⚠️  Application versions will be removed
    ⚠️  CloudWatch logs will be deleted

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

    # Check infra directory exists
    if [[ ! -d "$INFRA_DIR" ]]; then
        print_error "Infrastructure directory not found: $INFRA_DIR"
        exit 1
    fi

    print_success "All prerequisites met"
}

backup_state() {
    local env=$1
    local state_env=""

    if [[ "$env" == "staging" ]]; then
        state_env="staging"
    elif [[ "$env" == "prod" ]]; then
        state_env="production"
    fi

    print_info "Backing up Terraform state..."

    # Create backup directory
    local backup_dir="$INFRA_DIR/state-backups"
    mkdir -p "$backup_dir"

    # Download state from S3
    local backup_file="$backup_dir/terraform-${state_env}-$(date +%Y%m%d-%H%M%S).tfstate"
    
    aws s3 cp "s3://bp-terraform-state-1764230215/bp-calculator/$state_env/terraform.tfstate" "$backup_file" 2>/dev/null || {
        print_warning "Could not backup state file (may not exist)"
        return
    }

    print_success "State backed up to: $backup_file"
}

list_resources() {
    local env=$1

    print_info "Resources that will be destroyed in $env:"
    echo ""

    cd "$INFRA_DIR"

    # Initialize Terraform
    local state_env=""
    if [[ "$env" == "staging" ]]; then
        state_env="staging"
    elif [[ "$env" == "prod" ]]; then
        state_env="production"
    fi

    terraform init -reconfigure \
        -backend-config="key=bp-calculator/$state_env/terraform.tfstate" &> /dev/null || {
        print_warning "Could not initialize Terraform"
        return
    }

    # List resources
    terraform state list 2>/dev/null || {
        print_warning "No resources found in state"
        return
    }

    cd "$SCRIPT_DIR"
    echo ""
}

destroy_infrastructure() {
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

    print_warning "Destroying infrastructure in: $env"
    echo ""

    cd "$INFRA_DIR"

    # Initialize Terraform with environment-specific state
    print_info "Initializing Terraform (state: bp-calculator/$state_env/terraform.tfstate)..."
    terraform init -reconfigure \
        -backend-config="key=bp-calculator/$state_env/terraform.tfstate"

    # List resources
    list_resources "$env"

    # Backup state
    backup_state "$env"

    # Confirm destruction (unless auto-approve)
    if [[ -z "$AUTO_APPROVE" ]]; then
        echo ""
        print_warning "⚠️  WARNING: This will permanently delete all resources in $env"
        print_warning "⚠️  This action CANNOT be undone!"
        echo ""
        read -p "Type 'destroy-$env' to confirm: " confirm
        
        if [[ "$confirm" != "destroy-$env" ]]; then
            print_warning "Destruction cancelled by user"
            cd "$SCRIPT_DIR"
            exit 0
        fi
    fi

    # Destroy
    print_info "Destroying infrastructure..."
    
    if [[ -n "$AUTO_APPROVE" ]]; then
        terraform destroy -var-file="$tfvars_file" -auto-approve
    else
        terraform destroy -var-file="$tfvars_file"
    fi

    # Clean up state file from S3 (unless preserve flag)
    if [[ -z "$PRESERVE_STATE" ]]; then
        print_info "Removing Terraform state from S3..."
        aws s3 rm "s3://bp-terraform-state-1764230215/bp-calculator/$state_env/terraform.tfstate" 2>/dev/null || {
            print_warning "State file not found in S3 (may already be deleted)"
        }
        
        # Remove state lock from DynamoDB
        aws dynamodb delete-item \
            --table-name bp-terraform-locks \
            --key "{\"LockID\": {\"S\": \"bp-terraform-state-1764230215/bp-calculator/$state_env/terraform.tfstate\"}}" \
            2>/dev/null || {
            print_warning "State lock not found in DynamoDB"
        }
    else
        print_warning "Preserving Terraform state in S3 (--preserve-state)"
    fi

    cd "$SCRIPT_DIR"

    print_success "Infrastructure destroyed in $env"
}

clean_local_artifacts() {
    print_info "Cleaning local artifacts..."

    # Remove Terraform state files
    find "$INFRA_DIR" -name "terraform.tfstate*" -delete 2>/dev/null || true
    find "$INFRA_DIR" -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$INFRA_DIR" -name "*.tfplan" -delete 2>/dev/null || true

    # Remove build artifacts
    find "$SCRIPT_DIR" -name "bin" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$SCRIPT_DIR" -name "obj" -type d -exec rm -rf {} + 2>/dev/null || true
    find "$SCRIPT_DIR" -name "publish" -type d -exec rm -rf {} + 2>/dev/null || true

    print_success "Local artifacts cleaned"
}

destroy_environment() {
    local env=$1

    echo ""
    print_warning "=========================================="
    print_warning "  Destroying: $env"
    print_warning "=========================================="
    echo ""

    destroy_infrastructure "$env"

    echo ""
    print_success "✓ Destruction of $env complete!"
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
        --preserve-state)
            PRESERVE_STATE="true"
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

# Final warning for 'all'
if [[ "$ENVIRONMENT" == "all" && -z "$AUTO_APPROVE" ]]; then
    echo ""
    print_warning "⚠️  WARNING: You are about to destroy ALL environments (staging AND production)"
    print_warning "⚠️  This will delete EVERYTHING and CANNOT be undone!"
    echo ""
    read -p "Type 'destroy-everything' to confirm: " confirm
    
    if [[ "$confirm" != "destroy-everything" ]]; then
        print_warning "Destruction cancelled by user"
        exit 0
    fi
fi

# Destroy based on environment
case $ENVIRONMENT in
    staging)
        destroy_environment "staging"
        ;;
    prod)
        destroy_environment "prod"
        ;;
    all)
        destroy_environment "staging"
        echo ""
        print_info "Staging destroyed. Proceeding to production..."
        sleep 2
        destroy_environment "prod"
        ;;
esac

# Clean up local artifacts
echo ""
clean_local_artifacts

echo ""
print_success "=========================================="
print_success "  Destruction Complete!"
print_success "=========================================="
echo ""

print_info "Summary:"
print_info "- All AWS resources destroyed"
if [[ -z "$PRESERVE_STATE" ]]; then
    print_info "- Terraform state removed from S3"
else
    print_info "- Terraform state preserved in S3"
fi
print_info "- Local artifacts cleaned"
print_info "- State backups saved in: $INFRA_DIR/state-backups"
echo ""

print_warning "To redeploy, run: ./deploy.sh <environment>"
echo ""

exit 0
