#!/bin/bash

#######################################################
# Blood Pressure Calculator - Bootstrap Script
# 
# First-time setup for AWS infrastructure
# Creates Terraform backend (S3 + DynamoDB)
#######################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="eu-west-1"
S3_BUCKET_PREFIX="bp-terraform-state"
DYNAMODB_TABLE="bp-terraform-locks"

#######################################################
# Functions
#######################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  BP Calculator - Bootstrap${NC}"
    echo -e "${BLUE}  First-Time AWS Setup${NC}"
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
Usage: $0 [options]

Bootstrap AWS infrastructure for Blood Pressure Calculator

OPTIONS:
    --region <region>   AWS region (default: eu-west-1)
    --bucket <name>     S3 bucket name (default: auto-generated)
    --skip-checks       Skip prerequisite checks
    -h, --help          Show this help message

EXAMPLES:
    # Bootstrap with defaults
    $0

    # Bootstrap in a different region
    $0 --region us-east-1

    # Use specific bucket name
    $0 --bucket my-terraform-state-bucket

WHAT THIS SCRIPT DOES:
    1. Checks prerequisites (AWS CLI, credentials)
    2. Creates S3 bucket for Terraform state
    3. Enables S3 bucket versioning
    4. Creates DynamoDB table for state locking
    5. Configures bucket lifecycle rules
    6. Displays configuration for Terraform backend

PREREQUISITES:
    - AWS CLI installed and configured
    - AWS credentials with appropriate permissions:
      * s3:CreateBucket, s3:PutBucketVersioning
      * dynamodb:CreateTable
      * iam:GetUser (to verify credentials)

NOTES:
    ⚠️  Run this script ONLY ONCE per AWS account
    ⚠️  If resources already exist, script will skip creation
    ⚠️  Bucket names must be globally unique across AWS

EOF
}

check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install: https://aws.amazon.com/cli/"
        exit 1
    fi

    print_success "AWS CLI found: $(aws --version | head -n 1)"

    # Check AWS credentials
    print_info "Checking AWS credentials..."
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run: aws configure"
        exit 1
    fi

    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_USER=$(aws sts get-caller-identity --query Arn --output text | cut -d'/' -f2)

    print_success "Authenticated as: $AWS_USER"
    print_success "AWS Account: $AWS_ACCOUNT_ID"

    # Check Terraform (optional, just for info)
    if command -v terraform &> /dev/null; then
        print_success "Terraform found: $(terraform version | head -n 1)"
    else
        print_warning "Terraform not found (install later: https://www.terraform.io/downloads)"
    fi

    echo ""
}

generate_bucket_name() {
    # Generate unique bucket name with timestamp
    local timestamp=$(date +%s)
    echo "${S3_BUCKET_PREFIX}-${timestamp}"
}

create_s3_bucket() {
    local bucket_name=$1

    print_info "Creating S3 bucket: $bucket_name"

    # Check if bucket already exists
    if aws s3 ls "s3://$bucket_name" &> /dev/null; then
        print_warning "S3 bucket already exists: $bucket_name"
        return 0
    fi

    # Create bucket (eu-west-1 requires LocationConstraint)
    if [[ "$AWS_REGION" == "us-east-1" ]]; then
        aws s3 mb "s3://$bucket_name" --region "$AWS_REGION"
    else
        aws s3 mb "s3://$bucket_name" --region "$AWS_REGION" --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi

    print_success "S3 bucket created: $bucket_name"

    # Enable versioning
    print_info "Enabling versioning on S3 bucket..."
    aws s3api put-bucket-versioning \
        --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled

    print_success "Versioning enabled"

    # Add lifecycle policy (optional - delete old versions after 90 days)
    print_info "Adding lifecycle policy..."
    cat > /tmp/lifecycle.json << 'LIFECYCLE'
{
    "Rules": [
        {
            "Id": "DeleteOldVersions",
            "Status": "Enabled",
            "NoncurrentVersionExpiration": {
                "NoncurrentDays": 90
            }
        }
    ]
}
LIFECYCLE

    aws s3api put-bucket-lifecycle-configuration \
        --bucket "$bucket_name" \
        --lifecycle-configuration file:///tmp/lifecycle.json

    rm -f /tmp/lifecycle.json

    print_success "Lifecycle policy configured (delete old versions after 90 days)"

    # Block public access (security best practice)
    print_info "Configuring bucket security..."
    aws s3api put-public-access-block \
        --bucket "$bucket_name" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

    print_success "Public access blocked (secure)"
}

create_dynamodb_table() {
    local table_name=$1

    print_info "Creating DynamoDB table: $table_name"

    # Check if table already exists
    if aws dynamodb describe-table --table-name "$table_name" --region "$AWS_REGION" &> /dev/null; then
        print_warning "DynamoDB table already exists: $table_name"
        return 0
    fi

    # Create table
    aws dynamodb create-table \
        --table-name "$table_name" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" \
        --tags Key=Project,Value=bp-calculator Key=ManagedBy,Value=Terraform

    print_success "DynamoDB table created: $table_name"

    # Wait for table to be active
    print_info "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "$table_name" --region "$AWS_REGION"

    print_success "Table is active"
}

display_backend_config() {
    local bucket_name=$1
    local table_name=$2

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Bootstrap Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    print_info "Terraform Backend Configuration:"
    echo ""
    cat << BACKEND
terraform {
  backend "s3" {
    bucket         = "$bucket_name"
    key            = "bp-calculator/\${var.environment}/terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "$table_name"
    encrypt        = true
  }
}
BACKEND

    echo ""
    print_info "This configuration is already in: infra/backend.tf"
    echo ""

    print_info "GitHub Secrets to configure:"
    echo ""
    echo "  AWS_ACCESS_KEY_ID: <your-access-key>"
    echo "  AWS_SECRET_ACCESS_KEY: <your-secret-key>"
    echo "  AWS_REGION: $AWS_REGION"
    echo ""

    print_info "Next Steps:"
    echo "  1. Add AWS credentials to GitHub Secrets"
    echo "  2. Initialize Terraform: cd infra && terraform init"
    echo "  3. Deploy infrastructure: ./deploy.sh staging"
    echo ""
}

#######################################################
# Main Script
#######################################################

# Default values
SKIP_CHECKS=""
CUSTOM_BUCKET=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --bucket)
            CUSTOM_BUCKET="$2"
            shift 2
            ;;
        --skip-checks)
            SKIP_CHECKS="true"
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

# Main execution
print_header

if [[ -z "$SKIP_CHECKS" ]]; then
    check_prerequisites
fi

# Generate or use custom bucket name
if [[ -n "$CUSTOM_BUCKET" ]]; then
    S3_BUCKET="$CUSTOM_BUCKET"
else
    S3_BUCKET=$(generate_bucket_name)
fi

print_info "Configuration:"
print_info "  AWS Region: $AWS_REGION"
print_info "  S3 Bucket: $S3_BUCKET"
print_info "  DynamoDB Table: $DYNAMODB_TABLE"
echo ""

read -p "Proceed with bootstrap? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    print_warning "Bootstrap cancelled"
    exit 0
fi

echo ""

# Create resources
create_s3_bucket "$S3_BUCKET"
echo ""
create_dynamodb_table "$DYNAMODB_TABLE"

# Display configuration
display_backend_config "$S3_BUCKET" "$DYNAMODB_TABLE"

print_success "Bootstrap complete! AWS infrastructure ready for Terraform."
echo ""

exit 0
