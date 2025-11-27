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

### Initialize Terraform

```bash
cd infra
terraform init
```

### Deploy Staging Environment

```bash
# Preview changes
terraform plan -var-file=env/staging.tfvars

# Apply changes
terraform apply -var-file=env/staging.tfvars
```

### Deploy Production Environment

```bash
# Preview changes
terraform plan -var-file=env/prod.tfvars

# Apply changes
terraform apply -var-file=env/prod.tfvars
```

### View Outputs

```bash
terraform output
```

### Destroy Environment

```bash
# Staging
terraform destroy -var-file=env/staging.tfvars

# Production
terraform destroy -var-file=env/prod.tfvars
```

## 🔧 Configuration Variables

### Required Variables

- `environment`: Environment name (staging or prod)

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | eu-west-1 | AWS region |
| `app_name` | bp-calculator | Application name |
| `instance_type` | t2.micro | EC2 instance type |
| `min_instances` | 1 | Minimum instances |
| `max_instances` | 2 | Maximum instances |
| `enable_cloudwatch_alarms` | true | Enable alarms |
| `health_check_path` | / | Health check endpoint |

## 📊 Outputs

After applying, you'll see:

- `environment_url`: Application URL
- `environment_cname`: CNAME for blue-green swaps
- `s3_bucket_name`: Artifact storage bucket
- `cloudwatch_log_group`: Log group name
- `sns_topic_arn`: Alarm notification topic

## 🔄 Blue-Green Deployment

The infrastructure supports blue-green deployments via CNAME swaps:

1. Deploy to staging environment
2. Test staging thoroughly
3. Swap CNAMEs between staging and production
4. Rollback by swapping CNAMEs back if needed

## 💰 Cost Estimation

### Staging (t2.micro)
- EC2: ~$8/month
- Load Balancer: ~$16/month
- S3: <$1/month
- CloudWatch: Free tier
- **Total: ~$25/month**

### Production (t2.small)
- EC2: ~$17/month
- Load Balancer: ~$16/month
- S3: <$1/month
- CloudWatch: ~$2/month
- **Total: ~$36/month**

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

### Apply Fails
- Check IAM permissions for creating resources
- Verify solution stack name: `aws elasticbeanstalk list-available-solution-stacks`
- Check VPC and subnet availability

### Environment Health Issues
- Check CloudWatch logs in AWS Console
- Verify application is publishing to correct port (5000)
- Check security group rules

## 🔗 Related Documentation

- [EXECUTION_PLAN.md](../EXECUTION_PLAN.md) - Full project plan
- [COST_MANAGEMENT.md](../COST_MANAGEMENT.md) - Cost optimization guide
- [deploy.sh](../deploy.sh) - Deployment automation script
- [destroy.sh](../destroy.sh) - Cleanup automation script
