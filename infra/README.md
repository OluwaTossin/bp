# Blood Pressure Calculator - Terraform Infrastructure

This directory contains Terraform configuration for deploying the Blood Pressure Calculator to AWS Elastic Beanstalk.

## 📁 Directory Structure

```
infra/
├── backend.tf          # S3 backend configuration for Terraform state
├── providers.tf        # AWS provider configuration
├── variables.tf        # Input variables
├── main.tf            # Main infrastructure resources
├── outputs.tf         # Output values
├── env/
│   ├── staging.tfvars # Staging environment configuration
│   └── prod.tfvars    # Production environment configuration
└── README.md          # This file
```

## 🏗️ Infrastructure Components

### Resources Created:

1. **S3 Bucket**: For Elastic Beanstalk application versions
2. **Elastic Beanstalk Application**: Container for environments
3. **Elastic Beanstalk Environment**: Running application instance
4. **IAM Roles**:
   - Service role for Elastic Beanstalk
   - Instance profile for EC2 instances
5. **CloudWatch**:
   - Log group for application logs
   - Alarms for health, errors, and CPU
   - SNS topic for alarm notifications
6. **VPC**: Uses default VPC with public subnets

## 🚀 Usage

### Prerequisites

1. **AWS CLI configured** with credentials
2. **Terraform installed** (version >= 1.0)
3. **Backend resources created**:
   - S3 bucket: `bp-terraform-state-1764230215`
   - DynamoDB table: `bp-terraform-locks`

### Automated Deployment (Recommended)

Infrastructure deployment is fully automated via GitHub Actions CI/CD pipeline.

**Staging:**
```bash
# Automatic deployment on push to main
git push origin main
```

**Production:**
1. Go to **Actions** → **CD - Deploy to AWS**
2. Click **Run workflow**
3. Select environment: **production**
4. Approve when prompted after tests pass

### Manual Deployment (For Development/Testing)

**Initialize Terraform with Environment-Specific State:**

```bash
cd infra

# Staging
terraform init -reconfigure \
  -backend-config="key=bp-calculator/staging/terraform.tfstate"

# Production
terraform init -reconfigure \
  -backend-config="key=bp-calculator/production/terraform.tfstate"
```

**Deploy Staging Environment:**

```bash
# Preview changes
terraform plan -var-file=env/staging.tfvars

# Apply changes
terraform apply -var-file=env/staging.tfvars
```

**Deploy Production Environment:**

```bash
# Preview changes
terraform plan -var-file=env/prod.tfvars

# Apply changes
terraform apply -var-file=env/prod.tfvars
```

**View Outputs:**

```bash
terraform output
```

**Destroy Environment:**

```bash
# Staging
terraform destroy -var-file=env/staging.tfvars

# Production
terraform destroy -var-file=env/prod.tfvars
```

**Important Notes:**
- Always specify the correct backend state file when initializing
- Use `-reconfigure` flag when switching between environments
- Separate state files prevent resource conflicts between environments

## 🔧 Configuration Variables

### Required Variables

- `environment`: Environment name (staging or prod)

### Optional Variables

| Variable | Default | Staging | Production | Description |
|----------|---------|---------|------------|-------------|
| `aws_region` | eu-west-1 | eu-west-1 | eu-west-1 | AWS region |
| `app_name` | bp-calculator | bp-calculator | bp-calculator | Application name |
| `instance_type` | t3.micro | t3.micro | t3.micro | EC2 instance type (free tier) |
| `min_instances` | 1 | 1 | 1 | Minimum instances |
| `max_instances` | 2 | 2 | 4 | Maximum instances |
| `enable_cloudwatch_alarms` | true | true | true | Enable alarms |
| `health_check_path` | / | / | / | Health check endpoint |

**Key Configuration Notes:**
- **Instance Type**: Both environments use `t3.micro` (free tier eligible in eu-west-1)
- **State Files**: Separate per environment to prevent conflicts
  - Staging: `bp-calculator/staging/terraform.tfstate`
  - Production: `bp-calculator/production/terraform.tfstate`
- **Resource Names**: Include environment suffix (e.g., `bp-calculator-logs-staging`)

## 📊 Outputs

After applying, you'll see:

- `environment_url`: Application URL
- `environment_name`: Environment name
- `environment_cname`: CNAME for the environment
- `s3_bucket_name`: Artifact storage bucket
- `application_name`: EB application name (dynamic)
- `cloudwatch_log_group`: Log group name
- `sns_topic_arn`: Alarm notification topic

**Live Environments:**
- **Staging**: http://bp-calculator-staging.eba-i4p69s48.eu-west-1.elasticbeanstalk.com
- **Production**: http://bp-calculator-prod.eba-3mgpqk3d.eu-west-1.elasticbeanstalk.com

## 🔄 Blue-Green Deployment

The infrastructure supports zero-downtime deployments via Elastic Beanstalk rolling updates:

**Process:**
1. New application version created and uploaded to S3
2. New EC2 instances launched with new version
3. Health checks validate new instances (HTTP 200 on `/`)
4. Traffic gradually switches from old to new instances
5. Old instances terminated after successful migration

**Benefits:**
- Zero downtime during deployments
- Automatic rollback if health checks fail
- Old application versions preserved for manual rollback

**Rollback Options:**
- Automatic: EB doesn't promote unhealthy versions
- Manual: Deploy previous application version via AWS Console or workflow

## 💰 Cost Estimation

### Both Environments (t3.micro, free tier eligible)

**Under Free Tier (First 12 months):**
- EC2 (t3.micro × 750 hours/month): $0
- S3 Storage: <$0.10/month
- Data Transfer: <$1/month (first 1 GB free)
- CloudWatch Logs: <$0.50/month
- CloudWatch Alarms: Free (under 10 alarms)
- **Total: ~$2/month**

**After Free Tier:**
- EC2 (t3.micro per environment): ~$7.50/month
- S3 Storage: <$0.10/month
- Data Transfer: ~$1-2/month
- CloudWatch: ~$1/month
- **Total per environment: ~$10/month**
- **Both environments: ~$20/month**

**Cost Optimization:**
- Use t3.micro instances (free tier eligible)
- Short log retention (7 days)
- Delete old application versions periodically
- Monitor usage via AWS Cost Explorer

## 🔒 Security Features

- S3 buckets are private with versioning enabled
- IAM roles follow least-privilege principle
- CloudWatch logs retained for 7 days
- Enhanced health reporting enabled
- Public IP addresses for instances (required for default VPC)

## 📝 Notes

- Default VPC is used for simplicity
- Solution stack: `.NET 8` on Amazon Linux 2023
- Health check on root path `/`
- Logs stream to CloudWatch automatically
- Alarms notify via SNS topic

## 🐛 Troubleshooting

### Terraform Init Fails
- Verify AWS credentials: `aws sts get-caller-identity`
- Check S3 bucket exists: `aws s3 ls s3://bp-terraform-state-1764230215`
- Check DynamoDB table: `aws dynamodb describe-table --table-name bp-terraform-locks`
- Ensure correct backend state key for environment

### Apply Fails
- Check IAM permissions for creating resources
- Verify solution stack name: `aws elasticbeanstalk list-available-solution-stacks | grep ".NET"`
- Check VPC and subnet availability
- Ensure instance type is available in region (use t3.micro in eu-west-1)

### CloudWatch Log Group Already Exists
- **Problem**: "ResourceAlreadyExistsException"
- **Cause**: Log group name not environment-specific
- **Solution**: Ensure `main.tf` uses `${var.app_name}-logs-${var.environment}` (line 315)

### Terraform State Conflicts
- **Problem**: Deploying to production destroys staging
- **Cause**: Both environments sharing same state file
- **Solution**: Always specify environment-specific backend config:
  ```bash
  terraform init -reconfigure \
    -backend-config="key=bp-calculator/${ENV}/terraform.tfstate"
  ```

### Instance Type Not Available
- **Problem**: "The specified instance type is not eligible for Free Tier"
- **Solution**: Use `t3.micro` in eu-west-1 (not t2.micro or t2.small)
- **File**: Update `infra/env/prod.tfvars` with `instance_type = "t3.micro"`

### Environment Health Issues
- Check CloudWatch logs: `aws logs tail /aws/elasticbeanstalk/bp-calculator-staging --follow`
- Verify application listens on port 5000 (EB expects port 5000 for .NET apps)
- Check security group rules allow HTTP traffic

## 🔗 Related Documentation

- [EXECUTION_PLAN.md](../EXECUTION_PLAN.md) - Full project plan with troubleshooting
- [COST_MANAGEMENT.md](../COST_MANAGEMENT.md) - Cost optimization guide
- [.github/workflows/CD_README.md](../.github/workflows/CD_README.md) - CD pipeline documentation
- [deploy.sh](../deploy.sh) - One-command deployment script
- [destroy.sh](../destroy.sh) - Infrastructure teardown script
- [README.md](../README.md) - Project overview

**Last Updated**: December 4, 2025
