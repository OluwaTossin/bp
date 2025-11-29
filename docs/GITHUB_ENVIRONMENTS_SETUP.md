# GitHub Environments Setup Guide

This guide explains how to configure GitHub Environments for proper authorization gates in the CI/CD pipeline.

## Overview

The CD pipeline uses GitHub Environments to implement authorization gates:
- **staging**: Auto-deploys on push to main (no approval needed)
- **production-approval**: Requires manual approval before production deployment
- **production**: Deploys to production after approval

## Setup Instructions

### 1. Navigate to Repository Settings

1. Go to your repository: https://github.com/OluwaTossin/bp
2. Click **Settings** tab
3. Click **Environments** in the left sidebar

### 2. Create Staging Environment

1. Click **New environment**
2. Name: `staging`
3. Click **Configure environment**
4. **Deployment branches**: Select "Selected branches" → Add rule: `main`
5. Leave **Environment protection rules** empty (no approval needed)
6. Click **Save protection rules**

### 3. Create Production Approval Environment

1. Click **New environment**
2. Name: `production-approval`
3. Click **Configure environment**
4. **Environment protection rules**:
   - ✅ Check **Required reviewers**
   - Add reviewers (your GitHub username or team)
   - Set wait timer: 0 minutes (optional)
5. **Deployment branches**: Select "Selected branches" → Add rule: `main`
6. Click **Save protection rules**

### 4. Create Production Environment

1. Click **New environment**
2. Name: `production`
3. Click **Configure environment**
4. **Environment protection rules**:
   - ✅ Check **Required reviewers** (optional - already gated by production-approval)
   - Add reviewers if desired
5. **Deployment branches**: Select "Selected branches" → Add rule: `main`
6. Add **Environment secrets** (if different from staging):
   - `AWS_ACCESS_KEY_ID` (if using different AWS account)
   - `AWS_SECRET_ACCESS_KEY` (if using different AWS account)
7. Click **Save protection rules**

## Environment Variables

### Repository Secrets (Already Configured)
These apply to all environments:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_ACCOUNT_ID`

### Environment-Specific Secrets (Optional)
If production uses different AWS credentials:
1. Go to Environment → **Environment secrets**
2. Add production-specific secrets that override repository secrets

## How Authorization Gates Work

### Automatic Deployment (Staging)
```
Push to main → CI passes → CD deploys to staging → Tests run
```

### Manual Approval (Production)
```
Manual workflow dispatch with environment=production
  ↓
Smoke tests pass
  ↓
Performance tests pass
  ↓
Security tests pass
  ↓
[APPROVAL REQUIRED] ← GitHub sends notification
  ↓
Reviewer approves in GitHub UI
  ↓
Deploy to production
```

## Triggering Production Deployment

### Via GitHub UI (Recommended)
1. Go to **Actions** tab
2. Select **CD - Deploy to AWS** workflow
3. Click **Run workflow**
4. Select branch: `main`
5. Select environment: `production`
6. Click **Run workflow**
7. Wait for tests to complete
8. Approve deployment when prompted

### Via GitHub CLI
```bash
gh workflow run cd.yml \
  --ref main \
  --field environment=production
```

## Approval Process

### For Reviewers

When production deployment needs approval:

1. **Email notification** from GitHub
2. Go to repository → **Actions**
3. Find the running workflow
4. Click on the workflow run
5. See **Review deployments** button
6. Review changes:
   - Check smoke test results
   - Check performance test results
   - Check security scan results
7. Click **Approve and deploy** or **Reject**
8. Add comment (optional)

### Approval Checklist

Before approving production deployment:

- [ ] All CI tests passed (62 tests)
- [ ] Staging deployment successful
- [ ] Smoke tests passed
- [ ] Performance tests passed (< 500ms p95)
- [ ] Security scan passed (no high-risk vulnerabilities)
- [ ] No critical bugs reported in staging
- [ ] Stakeholders notified of deployment

## Bypass Emergency Deployments

In case of emergency (with proper authorization):

### Option 1: Temporary approval bypass
1. Settings → Environments → production-approval
2. Temporarily remove required reviewers
3. Run deployment
4. Re-enable reviewers immediately after

### Option 2: Use staging as production
1. Update DNS/load balancer to point to staging
2. Quick fix in place
3. Follow proper process for permanent fix

## Best Practices

1. **Test in staging first**: Always deploy to staging before production
2. **Review test results**: Check all test results before approving
3. **Document approvals**: Add comments explaining approval decision
4. **Monitor post-deployment**: Watch CloudWatch logs after production deployment
5. **Have rollback plan**: Know how to quickly rollback if issues arise

## Rollback Process

If production deployment causes issues:

```bash
# List available versions
aws elasticbeanstalk describe-application-versions \
  --application-name bp-calculator \
  --query 'ApplicationVersions[*].[VersionLabel,DateCreated]' \
  --output table

# Rollback to previous version
aws elasticbeanstalk update-environment \
  --environment-name bp-calculator-prod \
  --version-label <previous-version-label>
```

## Troubleshooting

### Approval not showing up
- Check that you're added as a required reviewer
- Check email for GitHub notification
- Refresh Actions page

### Can't approve deployment
- Verify you have write access to repository
- Check that you're in the required reviewers list
- Try different browser/clear cache

### Environment not found error
- Verify environment names match exactly: `staging`, `production-approval`, `production`
- Check that environments are created in repository settings
- Verify branch protection rules allow deployments from `main`

## Security Considerations

1. **Limit approvers**: Only give approval rights to trusted team members
2. **Audit trail**: GitHub logs all approvals and who approved
3. **Separate credentials**: Consider using different AWS accounts for staging/production
4. **Secrets rotation**: Regularly rotate AWS credentials
5. **Least privilege**: Give environments minimum required AWS permissions

---

**Last Updated**: November 29, 2025
