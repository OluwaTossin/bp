# Blood Pressure Calculator - AWS Cost Management Guide

## 📊 Overview

This document provides cost estimates, optimization strategies, and cleanup procedures for the Blood Pressure Calculator CI/CD infrastructure on AWS.

**Project Duration:** Development phase (est. 2-4 weeks)  
**Target Budget:** Stay within AWS Free Tier where possible  
**Estimated Monthly Cost:** $10-20 USD (if minimized properly)

---

## 💰 Cost Breakdown by Service

### 1. AWS Elastic Beanstalk

**Service:** Application hosting platform  
**Resources:**
- **Staging Environment:** t2.micro EC2 instance
- **Production Environment:** t2.small EC2 instance

**Cost Estimates:**
- **t2.micro:** $0.0116/hour = ~$8.41/month (750 hours free tier eligible)
- **t2.small:** $0.023/hour = ~$16.79/month (NOT free tier eligible)
- **Load Balancer (if enabled):** $0.0225/hour + data processed charges

**Optimization:**
- ✅ Use t2.micro for both staging and production during development
- ✅ Disable load balancer for single-instance deployments
- ✅ Stop environments when not actively testing (use `./destroy.sh staging`)
- ⚠️ Production t2.small will incur charges even with free tier

**Free Tier:**
- 750 hours/month of t2.micro (covers 1 instance running 24/7)

---

### 2. Amazon S3

**Service:** Object storage for deployment artifacts and Terraform state

**Resources:**
- Application deployment packages (.zip files)
- Terraform state files
- Terraform state versions (with versioning enabled)

**Cost Estimates:**
- **Storage:** $0.023/GB/month
- **PUT Requests:** $0.005 per 1,000 requests
- **GET Requests:** $0.0004 per 1,000 requests

**Typical Usage:**
- ~50MB deployment artifacts = $0.001/month
- ~1KB Terraform state = negligible
- ~100 requests/month = $0.001/month
- **Total S3 Cost:** <$0.10/month

**Optimization:**
- ✅ Delete old deployment artifacts after successful deployments
- ✅ Lifecycle policy to expire old versions after 30 days
- ✅ Clean up failed/incomplete multipart uploads

**Free Tier:**
- 5GB storage
- 20,000 GET requests
- 2,000 PUT requests
- **Project usage well within free tier limits**

---

### 3. Amazon DynamoDB

**Service:** Terraform state locking

**Resources:**
- Table: `bp-terraform-locks`
- Billing Mode: PAY_PER_REQUEST

**Cost Estimates:**
- **Read Requests:** $0.25 per million requests
- **Write Requests:** $1.25 per million requests
- **Storage:** $0.25/GB/month

**Typical Usage:**
- ~100 read/write requests per Terraform apply/destroy
- ~10 Terraform operations/month = 1,000 requests
- Storage: <1KB
- **Total DynamoDB Cost:** <$0.01/month

**Optimization:**
- ✅ PAY_PER_REQUEST mode is optimal for low-frequency access
- ✅ No charges when table is idle

**Free Tier:**
- 25GB storage
- 2.5 million read requests/month
- **Project usage well within free tier limits**

---

### 4. Amazon CloudWatch

**Service:** Logging, metrics, and monitoring

**Resources:**
- Application logs from Elastic Beanstalk
- Custom metrics (if implemented)
- CloudWatch Alarms

**Cost Estimates:**
- **Logs Ingestion:** $0.50/GB ingested
- **Logs Storage:** $0.03/GB/month
- **Custom Metrics:** $0.30 per metric/month
- **Alarms:** $0.10 per alarm/month (first 10 free)
- **API Requests:** $0.01 per 1,000 requests

**Typical Usage:**
- ~100MB logs/day = 3GB/month ingestion = $1.50/month
- ~500MB log storage = $0.015/month
- 3 custom metrics = $0.90/month
- 5 alarms = $0 (within free tier)
- **Total CloudWatch Cost:** ~$2.50/month

**Optimization:**
- ✅ Set log retention to 7 days for development: `aws logs put-retention-policy --log-group-name <name> --retention-in-days 7`
- ✅ Filter verbose logs (DEBUG level) in production
- ✅ Delete log groups after project completion
- ✅ Limit custom metrics to essential KPIs only

**Free Tier:**
- 5GB logs ingestion
- 5GB logs storage
- 10 alarms
- 10 custom metrics
- 1 million API requests

---

### 5. AWS X-Ray (Optional)

**Service:** Distributed tracing for request flow analysis

**Cost Estimates:**
- **Traces Recorded:** $5.00 per 1 million traces
- **Traces Retrieved:** $0.50 per 1 million traces
- **Traces Scanned:** $0.50 per 1 million traces

**Typical Usage (if enabled):**
- ~10,000 requests/month = 10,000 traces
- **Total X-Ray Cost:** <$0.10/month

**Optimization:**
- ✅ Enable sampling (e.g., 10% of requests)
- ✅ Disable in staging environment
- ⚠️ Consider skipping X-Ray for this project (optional feature)

**Free Tier:**
- 100,000 traces recorded/month
- 1 million traces retrieved/month
- 1 million traces scanned/month
- **Project usage within free tier**

---

### 6. Data Transfer

**Service:** Network data transfer (in/out of AWS)

**Cost Estimates:**
- **Data IN:** Free
- **Data OUT to Internet:** 
  - First 1GB/month: Free
  - Next 9.999TB: $0.09/GB

**Typical Usage:**
- Application responses: ~10MB/day = 300MB/month
- **Total Data Transfer Cost:** $0 (within 1GB free tier)

---

### 7. GitHub Actions

**Service:** CI/CD workflow execution

**Resources:**
- Linux runners for build, test, and deployment

**Cost Estimates:**
- **Free for public repositories:** Unlimited minutes
- **Private repositories:** 2,000 minutes/month free, then $0.008/minute

**Typical Usage:**
- CI pipeline: ~5 minutes per run
- CD pipeline: ~10 minutes per deployment
- ~20 CI runs/week = 100 runs/month = 500 minutes
- ~10 CD runs/month = 100 minutes
- **Total: 600 minutes/month**

**Optimization:**
- ✅ If repository is public: $0 cost
- ✅ If private: 600 minutes within 2,000 free tier minutes = $0
- ✅ Cache dependencies to reduce build time
- ✅ Fail fast on test failures

**Free Tier (GitHub):**
- Public repos: Unlimited
- Private repos: 2,000 minutes/month

---

## 📈 Total Estimated Monthly Cost

| Scenario | Cost Estimate |
|----------|---------------|
| **Minimal (t2.micro only, staging off when not testing)** | $4-8/month |
| **Development (t2.micro staging + t2.small prod, both running)** | $15-20/month |
| **Optimized (t2.micro both, 8 hours/day usage)** | $2-5/month |
| **Maximum (all services, 24/7 uptime)** | $25-30/month |

### Recommended Approach for This Project:
**Target: $5-10/month**
- Use t2.micro for both staging and production
- Run staging only during active development (8 hours/day)
- Keep production running 24/7 for demos
- Set 7-day log retention
- Disable X-Ray (optional feature)

---

## ⚠️ Cost Monitoring & Alerts

### Setting Up Billing Alerts

1. **Enable Billing Alerts:**
   ```bash
   aws ce put-billing-preferences --enable-billing-alerts
   ```

2. **Create SNS Topic for Alerts:**
   ```bash
   aws sns create-topic --name bp-billing-alerts --region us-east-1
   aws sns subscribe --topic-arn arn:aws:sns:us-east-1:<account-id>:bp-billing-alerts \
     --protocol email --notification-endpoint your-email@example.com
   ```
   *(Confirm subscription via email)*

3. **Create Billing Alarm (Budget: $10/month):**
   ```bash
   aws cloudwatch put-metric-alarm \
     --alarm-name bp-billing-alarm-10usd \
     --alarm-description "Alert when costs exceed $10" \
     --metric-name EstimatedCharges \
     --namespace AWS/Billing \
     --statistic Maximum \
     --period 21600 \
     --evaluation-periods 1 \
     --threshold 10 \
     --comparison-operator GreaterThanThreshold \
     --dimensions Name=Currency,Value=USD \
     --alarm-actions arn:aws:sns:us-east-1:<account-id>:bp-billing-alerts \
     --region us-east-1
   ```

4. **Create Budget (Optional - More Granular):**
   - Navigate to [AWS Budgets Console](https://console.aws.amazon.com/billing/home#/budgets)
   - Create budget: $15/month
   - Set alerts at 80% ($12) and 100% ($15)

### Cost Tracking Commands

**Check Current Month-to-Date Costs:**
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d 'first day of this month' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=SERVICE
```

**Check EC2 Instance Hours This Month:**
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d 'first day of this month' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics UsageQuantity \
  --filter file://ec2-filter.json
```

---

## 🗑️ Cleanup & Teardown Plan

### Complete Teardown (After Project Submission)

**Option 1: Automated Teardown (Recommended)**
```bash
# Destroy all resources with confirmation prompts
./destroy.sh all

# Or skip prompts (use with caution!)
./destroy.sh all --auto-approve
```

**Option 2: Manual Teardown**

1. **Terminate Elastic Beanstalk Environments:**
   ```bash
   aws elasticbeanstalk terminate-environment --environment-name bp-calculator-staging
   aws elasticbeanstalk terminate-environment --environment-name bp-calculator-prod
   # Wait 5-10 minutes for termination
   ```

2. **Delete Elastic Beanstalk Application:**
   ```bash
   aws elasticbeanstalk delete-application --application-name bp-calculator --terminate-env-by-force
   ```

3. **Destroy Terraform-Managed Resources:**
   ```bash
   cd infra
   terraform destroy -var-file=env/staging.tfvars
   terraform destroy -var-file=env/prod.tfvars
   ```

4. **Delete Deployment Artifacts:**
   ```bash
   # List bucket contents
   aws s3 ls s3://bp-terraform-state-1764230215
   
   # Empty bucket (required before deletion)
   aws s3 rm s3://bp-terraform-state-1764230215 --recursive
   
   # Delete bucket
   aws s3 rb s3://bp-terraform-state-1764230215
   ```

5. **Delete DynamoDB Table:**
   ```bash
   aws dynamodb delete-table --table-name bp-terraform-locks --region eu-west-1
   ```

6. **Delete CloudWatch Log Groups:**
   ```bash
   # List log groups
   aws logs describe-log-groups --log-group-name-prefix /aws/elasticbeanstalk/bp-calculator
   
   # Delete each log group
   aws logs delete-log-group --log-group-name /aws/elasticbeanstalk/bp-calculator-staging
   aws logs delete-log-group --log-group-name /aws/elasticbeanstalk/bp-calculator-prod
   ```

7. **Delete CloudWatch Alarms:**
   ```bash
   aws cloudwatch delete-alarms --alarm-names \
     bp-calculator-staging-unhealthy-hosts \
     bp-calculator-prod-unhealthy-hosts \
     bp-calculator-staging-5xx-errors \
     bp-calculator-prod-5xx-errors
   ```

8. **Delete IAM Roles (if created by Terraform):**
   ```bash
   # Detach policies first
   aws iam detach-role-policy --role-name bp-calculator-ec2-role --policy-arn <policy-arn>
   
   # Delete role
   aws iam delete-role --role-name bp-calculator-ec2-role
   ```

9. **Delete IAM User (Optional - for CI/CD):**
   ```bash
   # Delete access keys first
   aws iam delete-access-key --user-name bp-calculator-deploy --access-key-id AKIAWUJYG2FGKR6VNPAV
   
   # Detach policies
   aws iam detach-user-policy --user-name bp-calculator-deploy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
   aws iam detach-user-policy --user-name bp-calculator-deploy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess
   aws iam detach-user-policy --user-name bp-calculator-deploy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
   aws iam detach-user-policy --user-name bp-calculator-deploy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess-AWSElasticBeanstalk
   
   # Delete user
   aws iam delete-user --user-name bp-calculator-deploy
   ```

10. **Verify No Resources Remain:**
    ```bash
    # Check for any running EC2 instances
    aws ec2 describe-instances --filters "Name=tag:Project,Values=bp-calculator" --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'
    
    # Check for S3 buckets
    aws s3 ls | grep bp-
    
    # Check for CloudWatch log groups
    aws logs describe-log-groups | grep bp-calculator
    
    # Final cost check
    aws ce get-cost-and-usage \
      --time-period Start=$(date -u +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
      --granularity DAILY \
      --metrics UnblendedCost
    ```

---

## 💡 Cost Optimization Best Practices

### During Development

1. **Stop Resources When Not in Use:**
   - Terminate staging environment overnight: `./destroy.sh staging`
   - Redeploy in the morning: `./deploy.sh staging`
   - Savings: ~$5-8/month

2. **Use Smallest Instances:**
   - t2.micro has sufficient resources for this application
   - Swap t2.small → t2.micro in `infra/env/prod.tfvars`
   - Savings: ~$8/month

3. **Short Log Retention:**
   ```bash
   aws logs put-retention-policy --log-group-name /aws/elasticbeanstalk/bp-calculator-staging --retention-in-days 3
   ```
   - Savings: ~$1-2/month

4. **Disable X-Ray:**
   - Comment out X-Ray middleware in Program.cs
   - Savings: Negligible, but simplifies setup

5. **Single-Instance Deployment:**
   - Disable load balancer in Elastic Beanstalk configuration
   - Use single EC2 instance instead of auto-scaling group
   - Savings: ~$15-20/month

### Monitoring Cost Trends

**Weekly Check (Recommended):**
```bash
# Quick cost summary for last 7 days
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '7 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics UnblendedCost \
  --output table
```

---

## 📅 Project Timeline & Cost Projection

| Phase | Duration | Expected Cost | Notes |
|-------|----------|---------------|-------|
| Phase 0: Foundation | 1-2 days | $0-1 | S3 + DynamoDB within free tier |
| Phase 1: App Logic | 2-3 days | $1-2 | Local testing, minimal AWS usage |
| Phase 2: Telemetry | 1 day | $0.50 | CloudWatch logs setup |
| Phase 3: Terraform | 2-3 days | $2-4 | Create staging + prod environments |
| Phase 4: CI Pipeline | 1-2 days | $0 | GitHub Actions within free tier |
| Phase 5: CD Pipeline | 2-3 days | $3-5 | Frequent deployments for testing |
| Phase 6: New Feature | 1 day | $1-2 | Feature branch workflow testing |
| Phase 7: Evidence | 1 day | $1 | Keep environments running for screenshots |
| Phase 8: Report/Video | 2-3 days | $2-3 | Environments running for demo |
| **TOTAL** | **2-3 weeks** | **$15-25** | Full project lifecycle |

### Post-Submission
- **Day 1 After Submission:** Keep environments running for instructor review
- **Week 1 After Submission:** Destroy all resources
- **Final Cost:** Monitor for 2-3 days after teardown to catch any residual charges

---

## 🎯 Summary

**Estimated Total Project Cost:** $15-25 USD  
**Recommended Budget:** $30 USD (safety margin)  
**Teardown Time:** 10-15 minutes (automated with `./destroy.sh all`)

**Key Takeaways:**
- ✅ Most services stay within AWS Free Tier limits
- ✅ Primary cost driver: EC2 instances (t2.micro = ~$8/month)
- ✅ Automated teardown script prevents lingering resources
- ✅ Billing alarms provide early warning if costs spike
- ✅ Complete cleanup after submission prevents ongoing charges

**Action Items:**
- [ ] Set up billing alarm for $10 threshold
- [ ] Review costs weekly during development
- [ ] Destroy staging environment when not actively testing
- [ ] Execute `./destroy.sh all` within 1 week of project submission

---

**Last Updated:** 2025-11-27  
**Terraform Backend Resources:**
- S3 Bucket: `bp-terraform-state-1764230215`
- DynamoDB Table: `bp-terraform-locks`
