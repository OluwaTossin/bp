# CD Pipeline - Continuous Deployment

This workflow automates the deployment of the Blood Pressure Calculator to AWS Elastic Beanstalk with comprehensive testing and zero-downtime blue-green deployment.

## Workflow Overview

### Triggers
- **Automatic**: Push to `main` branch (deploys to staging after CI passes)
- **Manual**: `workflow_dispatch` with environment selection (staging/production)
- **Paths-ignore**: Documentation-only changes don't trigger deployments

### Jobs (7-Stage Pipeline)

#### 1. Build and Package
- Checkout code
- Setup .NET 8.0
- Restore dependencies and build
- Run all tests (62 tests must pass)
- Publish application for deployment
- Create ZIP deployment package
- Upload as artifact

**Outputs:**
- `version-label`: Timestamped version (e.g., `v20251204-143022-c3171b2`)
- `artifact-key`: S3 key for deployment package

**Duration:** ~2 minutes

---

#### 2. Deploy Infrastructure
- Configure AWS credentials
- Initialize Terraform with S3 backend (environment-specific state)
- Plan infrastructure changes
- Apply Terraform (creates/updates AWS resources)
- Output environment details (name, URL, S3 bucket, application-name)

**Resources Created:**
- Elastic Beanstalk application and environment
- IAM service role and EC2 instance profile
- S3 bucket for artifacts (environment-specific)
- CloudWatch log groups and alarms (environment-specific)
- SNS topic for notifications

**Key Configuration:**
- Separate Terraform state files: `bp-calculator/{staging|production}/terraform.tfstate`
- Dynamic outputs: application-name, environment-name, s3-bucket

**Duration:** ~4-5 minutes (first run), ~30 seconds (subsequent)

---

#### 3. Deploy Application
- Download deployment package from artifacts
- Upload to environment-specific S3 bucket
- Create EB application version (using dynamic application-name)
- Deploy to environment with rolling updates (blue-green)
- Wait for deployment to complete
- Report deployment URL

**Environment Configurations:**
- **Staging**: t3.micro, 1-2 instances, auto-deploy on push to main
- **Production**: t3.micro, 1-4 instances, manual trigger with approval

**Blue-Green Deployment via EB Rolling Updates:**
1. New instances launched with new application version
2. Health checks validate new instances
3. Traffic gradually switches from old to new instances
4. Old instances terminated after successful migration
5. Zero downtime maintained throughout

**Duration:** ~3-4 minutes

---

#### 4. Smoke Tests
- Test home page accessibility (HTTP 200)
- Verify application content ("Blood Pressure Calculator")
- Test BP calculation endpoint
- Validate response structure
- Check CloudWatch logs generation

**Quality Gates:**
- Home page must return HTTP 200
- Page must contain expected content
- Application must respond to calculation requests
- CloudWatch logs should be generating

**Duration:** ~30 seconds

---

#### 5. Performance Tests (k6)
- Install k6 load testing tool
- Execute load test script (`tests/performance/load-test.js`)
- Simulate realistic user scenarios:
  - Ramp up: 0 → 10 users over 30s
  - Steady: 10 users for 1 minute
  - Peak: 10 → 50 users over 30s
  - Sustained: 50 users for 2 minutes
  - Ramp down: 50 → 0 users over 30s
- Custom metrics: errorRate, pageLoadTime, calculationTime

**Quality Gates:**
- p95 response time < 500ms
- p99 response time < 1000ms
- Error rate < 1%
- All HTTP requests return 200-299 status codes

**Expected Results:**
- p95: ~300ms
- p99: ~450ms
- Error rate: 0%

**Duration:** ~5 minutes

---

#### 6. Security Tests (OWASP ZAP)
- Pull OWASP ZAP Docker image
- Run baseline security scan
- Check for common vulnerabilities:
  - XSS (Cross-Site Scripting)
  - SQL Injection
  - CSRF (Cross-Site Request Forgery)
  - Security headers
  - Cookie security
- Generate HTML report

**Quality Gates:**
- No high-risk vulnerabilities
- No medium-risk vulnerabilities (configurable)
- Security headers properly configured

**Configuration:** `tests/security/zap-baseline.conf`

**Duration:** ~1-2 minutes

---

#### 7. Approve Production (Manual Gate)
- **Only triggered for production deployments**
- Requires manual approval in GitHub UI
- Shows deployment summary:
  - Environment URL
  - Application version
  - Test results (smoke, performance, security)
  - Blue-green deployment confirmation
- Review staging deployment before approving production

**Environment:** `production-approval`

**Notes:**
- Approval happens AFTER deployment to production (confirms working deployment)
- Can be configured to require approval BEFORE deployment if needed
- Multiple approvers can be configured in GitHub Environments settings

---

## Deployment Strategy

### Automatic Staging Deployment

**Trigger:** Push to `main` branch (after CI passes)

```bash
git push origin main
```

**Workflow:**
1. CI pipeline runs (unit tests, BDD tests, code analysis, security scan)
2. If CI passes, CD pipeline automatically triggers
3. Builds and packages application
4. Deploys infrastructure (if changes detected)
5. Deploys application to staging with rolling updates
6. Runs smoke tests
7. Runs performance tests (k6)
8. Runs security tests (OWASP ZAP)
9. Reports deployment status

**URL:** http://bp-calculator-staging.eba-i4p69s48.eu-west-1.elasticbeanstalk.com

---

### Manual Production Deployment

**Trigger:** Workflow dispatch (manual with approval)

**Steps:**
1. Go to **Actions** → **CD - Deploy to AWS**
2. Click **Run workflow**
3. Select environment: **production**
4. Click **Run workflow**
5. Pipeline executes:
   - Build and package
   - Deploy infrastructure
   - Deploy application (blue-green)
   - Smoke tests
   - Performance tests
   - Security tests
6. Manual approval gate appears in GitHub UI
7. Review test results and staging deployment
8. Approve in GitHub Environments
9. Pipeline completes, reports production URL

**URL:** http://bp-calculator-prod.eba-3mgpqk3d.eu-west-1.elasticbeanstalk.com

---

## Blue-Green Deployment (Zero Downtime)

### Implementation via Elastic Beanstalk Rolling Updates

The pipeline uses Elastic Beanstalk's rolling deployment policy to achieve zero-downtime blue-green deployments:

**Configuration:**
```hcl
deployment_policy = "Rolling"
rolling_update_enabled = true
rolling_update_type = "Health"
```

**Process:**
1. **New Version Created**: Application version uploaded to S3 and registered with EB
2. **New Instances Launched** (Green): EB launches new EC2 instances with new version
3. **Health Checks**: New instances undergo health checks (HTTP 200 on `/`)
4. **Traffic Switch**: Once healthy, traffic gradually switches from old (Blue) to new (Green)
5. **Old Instances Terminated** (Blue): After successful migration, old instances shut down
6. **Completion**: Only new version remains, zero downtime achieved

**Benefits:**
- No user-facing downtime
- Automatic rollback if health checks fail
- Gradual traffic migration reduces risk
- Old version kept as EB application version for manual rollback

**Rollback Capability:**
- Automatic: If health checks fail, EB doesn't promote new version
- Manual: Deploy previous application version via AWS Console or workflow

---

## Environment Variables

**Required in GitHub Secrets:**
- `AWS_ACCESS_KEY_ID` - IAM user access key
- `AWS_SECRET_ACCESS_KEY` - IAM user secret key

**Configured in Workflow:**
- `AWS_REGION`: eu-west-1
- `DOTNET_VERSION`: 8.0.x
- `TF_VERSION`: 1.0.0

**Dynamic (from Terraform Outputs):**
- `APPLICATION_NAME`: `bp-calculator-{staging|prod}`
- `ENVIRONMENT_NAME`: `bp-calculator-{staging|prod}`
- `S3_BUCKET`: `bp-calculator-eb-artifacts-{staging|prod}`

---

## Infrastructure Configuration

### Separate State Files

Each environment has its own Terraform state file to prevent resource conflicts:

**Staging:**
```bash
key=bp-calculator/staging/terraform.tfstate
```

**Production:**
```bash
key=bp-calculator/production/terraform.tfstate
```

**S3 Backend:** `bp-terraform-state-1764230215`
**DynamoDB Lock Table:** `bp-terraform-locks`

### Instance Types

Both environments use **t3.micro** (free tier eligible in eu-west-1):
- Staging: 1-2 instances
- Production: 1-4 instances

**Why t3.micro?**
- Free tier eligible in eu-west-1 region
- Sufficient for .NET 8 application
- Cost-effective (~$0/month under free tier)

### Environment-Specific Resources

Each environment has isolated resources:
- S3 bucket: `bp-calculator-eb-artifacts-{env}`
- CloudWatch log group: `bp-calculator-logs-{env}`
- IAM service role: `bp-calculator-eb-service-role-{env}`
- IAM instance profile: `bp-calculator-ec2-instance-profile-{env}`

---

## Monitoring Deployments

### GitHub Actions UI
- **Real-time Progress**: View deployment status for all 7 jobs
- **Deployment Summary**: URLs, test results, version labels
- **Logs**: Detailed execution logs for each job
- **Approval Gate**: Manual approval interface for production

### AWS Console
- **Elastic Beanstalk**: Environment health, events, logs
- **S3**: Deployment artifacts and versions
- **CloudWatch Logs**: Application logs (structured JSON)
- **CloudWatch Metrics**: Request count, latency, errors
- **CloudWatch Alarms**: CPU usage, unhealthy hosts, 5xx errors

### Environment URLs
- **Staging**: http://bp-calculator-staging.eba-i4p69s48.eu-west-1.elasticbeanstalk.com
- **Production**: http://bp-calculator-prod.eba-3mgpqk3d.eu-west-1.elasticbeanstalk.com

---

## Rollback Procedure

### Via GitHub Actions (Recommended)
1. Go to previous successful deployment workflow run
2. Click **Re-run all jobs**
3. System deploys the older application version
4. Zero-downtime rollback via EB rolling updates

### Via AWS Console
1. Go to **Elastic Beanstalk** → **Application Versions**
2. Select previous working version
3. Click **Deploy** → Select environment
4. EB performs rolling deployment to old version

### Via Terraform
```bash
cd infra
terraform init -backend-config="key=bp-calculator/staging/terraform.tfstate"
terraform apply -var-file=env/staging.tfvars
# Deploys infrastructure as defined in code (not application version)
```

---

## Cost Considerations

**Monthly Estimates:**
- **EC2 (t3.micro × 2)**: ~$0/month (free tier eligible for first 750 hours)
- **S3 Storage**: <$0.10/month (minimal storage for artifacts)
- **Data Transfer**: ~$1-2/month (varies with usage)
- **CloudWatch Logs**: ~$0.50/month (7-day retention)
- **CloudWatch Alarms**: Free (under 10 alarms)

**Total Estimated Cost:** $2-5/month under free tier, $15-25/month after

**Optimization Tips:**
- Use free tier eligible instance types (t3.micro)
- Set short log retention periods (7 days)
- Delete old application versions periodically
- Monitor usage via AWS Cost Explorer

---

## Troubleshooting

### Issue: Deployment Timeout
**Problem:** Environment stuck launching for 20+ minutes
- **Cause**: Instance type not free tier eligible in region
- **Solution**: Use t3.micro in eu-west-1 (not t2.micro/t2.small)
- **File**: Update `infra/env/prod.tfvars` with `instance_type = "t3.micro"`

### Issue: Application Version Not Found
**Problem:** "No Application Version named 'vXXXX' found"
- **Cause**: Hardcoded application name not matching environment
- **Solution**: Use dynamic name: `${{ needs.deploy-infrastructure.outputs.application-name }}`
- **Commit**: Fixed in c3171b2

### Issue: Terraform State Conflicts
**Problem:** Deploying to production destroys staging
- **Cause**: Both environments sharing same state file
- **Solution**: Separate state files per environment
- **Config**: `-backend-config="key=bp-calculator/${ENV}/terraform.tfstate"`

### Issue: CloudWatch Log Group Already Exists
**Problem:** "ResourceAlreadyExistsException"
- **Cause**: Log group name hardcoded without environment suffix
- **Solution**: Use `${var.app_name}-logs-${var.environment}`
- **File**: `infra/main.tf` line 315

### Issue: Health Check Fails
1. Wait 2-3 minutes for application startup
2. Check EB environment health in AWS Console
3. Review CloudWatch logs for application errors
4. Verify security groups allow HTTP traffic on port 80

### Issue: Performance Tests Fail
- **Check**: Response times may vary with instance warmup
- **Solution**: Re-run workflow after instances stabilize
- **Thresholds**: p95 < 500ms, p99 < 1000ms

### Issue: Security Scan Fails
- **Check**: OWASP ZAP may report false positives
- **Solution**: Review HTML report, configure exceptions in `zap-baseline.conf`
- **Config**: `-J` flag allows informational alerts

---

## Security Notes

- **Deployment Packages**: Stored in private S3 buckets (not public)
- **IAM Roles**: Follow principle of least privilege
- **Secrets**: Stored in GitHub Secrets (AES-256 encrypted)
- **Resources**: Tagged for accountability and cost tracking
- **Logs**: Retained for 7 days, structured JSON format
- **HTTPS**: Not configured (HTTP only for free tier demo)

---

## Next Steps

After successful deployment:
1. ✅ Access application via environment URLs
2. ✅ Test BP calculations for all categories
3. ✅ Verify CloudWatch logs show structured logging
4. ✅ Test CloudWatch alarms (manually trigger if needed)
5. ⏳ Document deployment evidence for Phase 7
6. ⏳ Collect screenshots for report (Phase 8)

---

**Pipeline Status:** All 7 jobs passing ✓  
**Staging:** Live and healthy ✓  
**Production:** Live and healthy ✓  
**Zero Downtime:** Confirmed via EB rolling updates ✓  
**Last Updated:** December 4, 2025
