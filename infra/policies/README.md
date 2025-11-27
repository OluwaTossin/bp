# IAM Policy for CI/CD Deployment

## Problem

The GitHub Actions CI/CD pipeline fails with DynamoDB access errors when Terraform tries to acquire state locks:

```
Error: Error acquiring the state lock
AccessDeniedException: User: arn:aws:iam::455921291596:user/bp-calculator-deploy 
is not authorized to perform: dynamodb:PutItem on resource: 
arn:aws:dynamodb:eu-west-1:455921291596:table/bp-terraform-locks
```

## Solution

The IAM user `bp-calculator-deploy` needs permissions for:
1. **DynamoDB** - State locking (PutItem, GetItem, DeleteItem)
2. **S3** - State storage (GetObject, PutObject)
3. **Elastic Beanstalk** - Application deployment
4. **EC2, IAM, CloudWatch, SNS** - Supporting services

## How to Apply the Policy

### Option 1: Using AWS Console (Recommended)

1. **Go to IAM Console**:
   - Navigate to: https://console.aws.amazon.com/iam/
   - Click **Users** → Find `bp-calculator-deploy`

2. **Create Custom Policy**:
   - Click **Add permissions** → **Attach policies directly**
   - Click **Create policy**
   - Switch to **JSON** tab
   - Copy the entire contents of `deploy-user-policy.json`
   - Paste into the JSON editor
   - Click **Next: Tags** (skip tags)
   - Click **Next: Review**
   - Name: `BPCalculatorDeployPolicy`
   - Description: `Full deployment permissions for BP Calculator CI/CD pipeline`
   - Click **Create policy**

3. **Attach Policy to User**:
   - Go back to Users → `bp-calculator-deploy`
   - Click **Add permissions** → **Attach policies directly**
   - Search for: `BPCalculatorDeployPolicy`
   - Select the policy
   - Click **Add permissions**

### Option 2: Using AWS CLI

```bash
# Create the policy
aws iam create-policy \
  --policy-name BPCalculatorDeployPolicy \
  --policy-document file://infra/policies/deploy-user-policy.json \
  --description "Full deployment permissions for BP Calculator CI/CD pipeline"

# Get the policy ARN (replace POLICY_ARN with output from above)
POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`BPCalculatorDeployPolicy`].Arn' --output text)

# Attach policy to user
aws iam attach-user-policy \
  --user-name bp-calculator-deploy \
  --policy-arn $POLICY_ARN
```

### Option 3: Quick Fix (Managed Policies - Less Secure)

If you need a quick fix for testing, attach these AWS managed policies:

```bash
aws iam attach-user-policy \
  --user-name bp-calculator-deploy \
  --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkFullAccess

aws iam attach-user-policy \
  --user-name bp-calculator-deploy \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-user-policy \
  --user-name bp-calculator-deploy \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess
```

**Note**: This grants broader permissions than needed. Use Option 1 or 2 for production.

## Verification

After applying the policy, verify permissions:

```bash
# Check attached policies
aws iam list-attached-user-policies --user-name bp-calculator-deploy

# Test DynamoDB access
aws dynamodb describe-table --table-name bp-terraform-locks --region eu-west-1

# Test S3 access
aws s3 ls s3://bp-terraform-state-1764230215
```

## Re-run CI/CD Pipeline

Once the policy is applied:

1. **Commit the policy files** (for documentation):
   ```bash
   git add infra/policies/
   git commit -m "docs: Add IAM policy for deployment user"
   git push origin feature/category-explanation
   ```

2. **Re-run the failed workflow**:
   - Go to: https://github.com/OluwaTossin/bp/actions
   - Find the failed workflow run
   - Click **Re-run all jobs**

3. **Or push a small change**:
   ```bash
   # Trigger the workflow again
   git commit --allow-empty -m "chore: Trigger CI after IAM policy update"
   git push origin feature/category-explanation
   ```

## Permissions Explained

| Service | Permissions | Why Needed |
|---------|-------------|------------|
| **DynamoDB** | PutItem, GetItem, DeleteItem | Terraform state locking to prevent concurrent modifications |
| **S3** | GetObject, PutObject, ListBucket | Terraform state storage and application artifact uploads |
| **Elastic Beanstalk** | Full access | Deploy and manage application environments |
| **EC2** | Describe actions | Query instance types, VPCs, subnets for EB |
| **IAM** | GetRole, PassRole | Read EB service roles and pass them to resources |
| **CloudWatch** | Full access | Create log groups, put metrics, configure alarms |
| **SNS** | Full access | Create topics for CloudWatch alarm notifications |

## Security Notes

- ✅ Policy follows **least privilege** principle
- ✅ DynamoDB access limited to specific table
- ✅ S3 access limited to terraform state and artifact buckets
- ✅ IAM actions are read-only (GetRole, ListRoles) except PassRole
- ⚠️ EC2/EB require wildcard resources (AWS limitation for describe actions)

## Troubleshooting

### Still getting access denied?

1. **Wait 30-60 seconds** for IAM policy propagation
2. **Check policy JSON** for syntax errors
3. **Verify correct region** (eu-west-1)
4. **Check GitHub Secrets** match the correct IAM user:
   ```bash
   aws sts get-caller-identity
   ```

### Need to verify current permissions?

```bash
# Simulate DynamoDB access
aws dynamodb put-item \
  --table-name bp-terraform-locks \
  --item '{"LockID":{"S":"test"}}' \
  --region eu-west-1 \
  --dry-run
```
