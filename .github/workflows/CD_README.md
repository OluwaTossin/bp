# CD Pipeline - Continuous Deployment

This workflow automates the deployment of the Blood Pressure Calculator to AWS Elastic Beanstalk.

## Workflow Overview

### Triggers
- **Automatic**: Push to `main` branch (after CI passes)
- **Manual**: `workflow_dispatch` with environment selection (staging/production)

### Jobs

#### 1. Build and Package
- Checkout code
- Setup .NET 8.0
- Restore dependencies and build
- Run all tests (55 tests must pass)
- Publish application for deployment
- Create ZIP deployment package
- Upload as artifact

**Outputs:**
- `version-label`: Timestamped version (e.g., `v20251127-143022-a1b2c3d`)
- `artifact-key`: S3 key for deployment package

#### 2. Deploy Infrastructure
- Configure AWS credentials
- Initialize Terraform with S3 backend
- Plan infrastructure changes
- Apply Terraform (creates/updates AWS resources)
- Output environment details (name, URL, S3 bucket)

**Resources Created:**
- Elastic Beanstalk application and environment
- IAM roles and instance profiles
- S3 bucket for artifacts
- CloudWatch log groups and alarms
- SNS topic for notifications

#### 3. Deploy to Staging
- Download deployment package
- Upload to S3
- Create EB application version
- Deploy to staging environment
- Wait for deployment to complete
- Perform basic health check

**Environment:** `staging`
**Instance Type:** t2.micro
**Auto-scaling:** 1-2 instances

#### 4. Smoke Tests
- Test home page accessibility (HTTP 200)
- Verify application content
- Test application responsiveness
- Check CloudWatch logs generation

**Quality Gates:**
- Home page must return HTTP 200
- Page must contain "Blood Pressure" content
- Application must respond to requests
- CloudWatch logs should be generating

#### 5. Approve Production (Manual)
- **Only triggered for production deployments**
- Requires manual approval in GitHub UI
- Review staging deployment before proceeding

**Environment:** `production-approval`

#### 6. Deploy to Production
- **Only runs after manual approval**
- Download deployment package
- Upload to S3
- Create EB application version
- Deploy to production environment
- Wait for deployment
- Report production URL

**Environment:** `production`
**Instance Type:** t2.small
**Auto-scaling:** 1-4 instances

## Blue-Green Deployment Strategy

The pipeline implements a simplified blue-green deployment:

1. **Green Environment (Staging)**: Always receives deployments first
2. **Smoke Tests**: Automated validation on staging
3. **Manual Approval**: Required gate for production
4. **Blue Environment (Production)**: Deployed only after approval
5. **Zero Downtime**: EB handles rolling deployments

### Future Enhancement: Full Blue-Green
For full blue-green with instant rollback:
- Deploy to separate "green" production environment
- Run extensive tests on green
- Swap CNAME to promote green → production
- Keep old "blue" environment for instant rollback

## Usage

### Automatic Deployment to Staging
```bash
# Push to main triggers automatic deployment
git push origin main
```

### Manual Deployment
1. Go to Actions → CD - Deploy to AWS
2. Click "Run workflow"
3. Select environment (staging or production)
4. Click "Run workflow"

### For Production Deployment
1. Trigger manual workflow with "production"
2. Review staging deployment
3. Approve in GitHub UI at the manual approval step
4. Production deployment proceeds automatically

## Environment Variables

Required in repository secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Configured in workflow:
- `AWS_REGION`: eu-west-1
- `APPLICATION_NAME`: bp-calculator
- `DOTNET_VERSION`: 8.0.x

## Monitoring Deployments

### GitHub Actions UI
- View real-time deployment progress
- See deployment summaries with URLs
- Check health check results
- Review CloudWatch log status

### AWS Console
- **Elastic Beanstalk**: Environment health and logs
- **S3**: Deployment artifacts
- **CloudWatch**: Application logs and metrics
- **CloudWatch Alarms**: Health, 5xx errors, CPU usage

### Environment URLs
- **Staging**: Auto-generated (e.g., `bp-calculator-staging.eu-west-1.elasticbeanstalk.com`)
- **Production**: Auto-generated (e.g., `bp-calculator-production.eu-west-1.elasticbeanstalk.com`)

## Rollback Procedure

### Via GitHub Actions
1. Go to previous successful deployment
2. Re-run that workflow
3. System deploys the older version

### Via AWS Console
1. Go to Elastic Beanstalk → Application Versions
2. Select previous version
3. Click "Deploy" → Select environment
4. EB performs rolling deployment

### Via Terraform
```bash
cd infra
terraform apply -var-file=env/staging.tfvars
# Deploys the infrastructure as defined in code
```

## Cost Considerations

- **t2.micro (staging)**: ~$8-10/month
- **t2.small (production)**: ~$16-20/month
- **S3**: <$1/month (minimal storage)
- **Data transfer**: Varies with usage
- **Total estimate**: $15-25/month

## Troubleshooting

### Deployment Fails
1. Check GitHub Actions logs for specific error
2. Review AWS Elastic Beanstalk environment logs
3. Check CloudWatch logs for application errors
4. Verify IAM permissions are correct

### Health Check Fails
1. Wait 2-3 minutes for application startup
2. Check EB environment health in AWS Console
3. Review application logs in CloudWatch
4. Verify security groups allow HTTP traffic

### Terraform Apply Fails
1. Check Terraform state lock in DynamoDB
2. Verify AWS credentials have required permissions
3. Review specific resource error in logs
4. Check for resource naming conflicts

## Security Notes

- Deployment packages are stored in private S3 bucket
- IAM roles follow principle of least privilege
- Secrets are stored in GitHub Secrets (encrypted)
- All resources are tagged for accountability
- CloudWatch logs retention: 7 days

## Next Steps

After successful deployment:
1. Access application via environment URL
2. Test BP calculations for all categories
3. Verify CloudWatch logs show structured logging
4. Test CloudWatch alarms by simulating errors
5. Document deployment evidence for Phase 7
