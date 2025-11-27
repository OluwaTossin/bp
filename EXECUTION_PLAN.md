# Blood Pressure Calculator – Full CI/CD + Terraform Execution Plan

**AWS + Elastic Beanstalk + GitHub Actions + Terraform**

---

## 📋 Overview

This document outlines the complete execution plan for delivering the Blood Pressure Calculator project using:

- ✅ AWS Elastic Beanstalk
- ✅ Terraform (Infrastructure-as-Code)
- ✅ GitHub Actions (CI + CD)
- ✅ CloudWatch Telemetry
- ✅ Unit & BDD Testing
- ✅ Blue–Green Deployments
- ✅ Feature Branch Workflow

The plan consists of **eight clear phases**, each with actionable steps. Following these phases ensures full coverage of all assignment requirements.

---

## 🎯 Phase Progress Tracker

- [x] **Phase 0:** Foundation Setup
- [x] **Phase 1:** Application Logic & Testing
- [x] **Phase 2:** Telemetry & Observability
- [x] **Phase 3:** Terraform (Infrastructure-as-Code)
- [ ] **Phase 4:** CI Pipeline (GitHub Actions)
- [ ] **Phase 5:** CD Pipeline with Blue–Green Deployment
- [ ] **Phase 6:** New Feature (≤ 30 Lines) + Feature Branch Workflow
- [ ] **Phase 7:** Evidence Collection
- [ ] **Phase 8:** Report & Video Preparation

---

## PHASE 0 — FOUNDATION SETUP

### Status: ✅ COMPLETE (November 27, 2025)

### 0.1. Fork and Inspect Repository
- [x] Fork https://github.com/gclynch/bp to your GitHub account
- [x] Clone locally: `git clone <your-fork-url>`
- [x] Open in Visual Studio or VS Code
- [x] Confirm the application runs with `dotnet run`
- [x] Browse to `http://localhost:5000` and verify the UI loads

### 0.2. AWS Credentials for CI/CD
- [x] Create an IAM user/role with permissions for:
  - Elastic Beanstalk (full access)
  - S3 (read/write)
  - CloudWatch Logs & Metrics (read/write)
  - CloudWatch X-Ray (optional)
  - IAM (for Terraform-managed roles)
- [x] Store credentials in **GitHub Secrets**:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION=eu-west-1`

### 0.3. Terraform Backend Setup
- [x] Manually create S3 bucket for Terraform state:
  ```bash
  aws s3 mb s3://bp-terraform-state-<unique-id> --region eu-west-1
  aws s3api put-bucket-versioning --bucket bp-terraform-state-<unique-id> --versioning-configuration Status=Enabled
  ```
- [x] Create DynamoDB table for state locking:
  ```bash
  aws dynamodb create-table \
    --table-name bp-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region eu-west-1
  ```

### 0.4. Cost Management & Cleanup Plan
- [x] Review AWS Free Tier limits
- [x] Estimate costs:
  - Elastic Beanstalk (t2.micro): ~$0.02/hour
  - S3 storage: ~$0.023/GB
  - CloudWatch: Free tier covers most usage
- [x] Document teardown plan: `./destroy.sh` after submission
- [x] Set up AWS Billing Alerts (optional but recommended)

### 0.5. Create Deployment Automation Scripts
- [x] Create `deploy.sh` for one-command deployment
- [x] Create `destroy.sh` for one-command teardown
- [x] Make scripts executable: `chmod +x deploy.sh destroy.sh`
- [x] Test scripts in dry-run mode

---

## PHASE 1 — APPLICATION LOGIC & TESTING

### Status: ✅ COMPLETE (November 27, 2025)

### 1.1. Implement Blood Pressure Classification
- [x] Follow the assignment chart:
  - Systolic: 70–190
  - Diastolic: 40–100
  - Systolic > Diastolic
  - Categories: **Low**, **Ideal**, **Pre-High**, **High**
- [x] Update the calculation logic in the application
- [x] Bind the category result to the Razor view
- [x] Include range validation:
  - Reject if systolic ≤ diastolic
  - Reject if values out of range
- [x] Add appropriate error handling and user feedback

### 1.2. Unit Testing (≥80% coverage)
- [x] Create test project: `dotnet new xunit -n BpCalculator.Tests`
- [x] Add tests for each category:
  - **Low:** S=90, D=60
  - **Ideal:** S=115, D=75
  - **Pre-High:** S=130, D=85
  - **High:** S=150, D=95
- [x] Add boundary value tests:
  - Low/Ideal boundary: S=90, D=60 vs S=91, D=60
  - Ideal/Pre-High boundary: S=120, D=80 vs S=121, D=80
  - Pre-High/High boundary: S=140, D=90 vs S=141, D=90
- [x] Add invalid input tests:
  - S=D (equal values)
  - S<D (invalid relationship)
  - Out of range values
- [x] Generate coverage report:
  ```bash
  dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura
  ```
- [x] Verify coverage ≥80% (achieved 100% on BloodPressure.cs)

### 1.3. BDD Testing (SpecFlow)
- [x] Add SpecFlow NuGet packages:
  ```bash
  dotnet add package SpecFlow
  dotnet add package SpecFlow.xUnit
  dotnet add package SpecFlow.Tools.MsBuild.Generation
  ```
- [x] Create `Features/BloodPressureClassification.feature`:
  ```gherkin
  Feature: Blood Pressure Classification
    As a healthcare professional
    I want to calculate blood pressure categories
    So that I can assess patient health

  Scenario: Ideal blood pressure
    Given systolic pressure is 115
    And diastolic pressure is 75
    When I calculate the category
    Then the result should be "Ideal"

  Scenario: High blood pressure
    Given systolic pressure is 150
    And diastolic pressure is 95
    When I calculate the category
    Then the result should be "High"

  Scenario: Pre-High blood pressure
    Given systolic pressure is 130
    And diastolic pressure is 85
    When I calculate the category
    Then the result should be "Pre-High"

  Scenario: Low blood pressure
    Given systolic pressure is 85
    And diastolic pressure is 55
    When I calculate the category
    Then the result should be "Low"
  ```
- [x] Implement C# step definitions calling your classification logic
- [x] Run BDD tests: `dotnet test`
- [x] All 55 tests passing (31 unit + 24 BDD)

---

## PHASE 2 — TELEMETRY & OBSERVABILITY

### Status: ✅ COMPLETE (November 27, 2025)

### 2.1. CloudWatch Logging
- [x] ASP.NET logs automatically appear in CloudWatch when running on Elastic Beanstalk
- [x] Add structured logging to Program.cs:
  ```csharp
  builder.Logging.AddConsole();
  builder.Logging.AddAWSProvider();
  ```
- [x] Add informational logs in calculation logic:
  ```csharp
  logger.LogInformation("BP calculated: Systolic={systolic}, Diastolic={diastolic}, Category={category}", 
    systolic, diastolic, category);
  ```
- [x] Add error logs for validation failures:
  ```csharp
  logger.LogWarning("Invalid BP input: Systolic={systolic}, Diastolic={diastolic}", systolic, diastolic);
  ```

### 2.2. Optional: Custom CloudWatch Metrics
- [x] Install AWS SDK: `dotnet add package AWSSDK.CloudWatch`
- [ ] Push custom metrics:
  - Metric: `BpCalculationCount`
  - Dimension: `Category=High/Ideal/PreHigh/Low`
- [ ] Track calculation frequency by category

### 2.3. Optional: AWS X-Ray Tracing
- [ ] Install X-Ray SDK: `dotnet add package AWSXRayRecorder.Handlers.AspNetCore`
- [ ] Add X-Ray middleware in Program.cs:
  ```csharp
  app.UseXRay("BpCalculator");
  ```
- [ ] Add subsegments around classification logic for detailed tracing

---

## PHASE 3 — TERRAFORM (INFRASTRUCTURE-AS-CODE)

### Status: ✅ COMPLETE (November 27, 2025)

### 3.1. Directory Structure
- [x] Create Terraform directory structure:
  ```
  infra/
    main.tf
    variables.tf
    outputs.tf
    providers.tf
    backend.tf
    env/
      staging.tfvars
      prod.tfvars
    README.md
  ```

### 3.2. Terraform Configuration Files

#### backend.tf
- [x] Configure remote state:
  ```hcl
  terraform {
    backend "s3" {
      bucket         = "bp-terraform-state-1764230215"
      key            = "bp-calculator/terraform.tfstate"
      region         = "eu-west-1"
      dynamodb_table = "bp-terraform-locks"
      encrypt        = true
    }
  }
  ```

#### providers.tf
- [x] Configure AWS provider:
  ```hcl
  terraform {
    required_version = ">= 1.0"
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
  }

  provider "aws" {
    region = var.aws_region
  }
  ```

#### main.tf
- [x] S3 bucket for EB application bundles
- [x] Elastic Beanstalk application resource
- [x] IAM roles:
  - Service role for EB
  - Instance profile for EC2 instances
- [x] Elastic Beanstalk environments (staging/prod configurable via tfvars)
- [x] CloudWatch alarms:
  - Unhealthy host count > 0
  - 5xx error rate > 5%
  - High CPU utilization (>80%)

#### variables.tf
- [x] Define variables:
  - `aws_region`
  - `app_name`
  - `environment` (staging/prod)
  - `instance_type` (default: t2.micro)
  - `solution_stack_name` (.NET 8 on Amazon Linux 2023)
  - `min_instances`, `max_instances`
  - `health_check_path`
  - `enable_cloudwatch_alarms`

#### outputs.tf
- [x] Output environment CNAMEs
- [x] Output S3 bucket name
- [x] Output CloudWatch log groups
- [x] Output IAM roles and instance profiles

### 3.3. Environment-Specific Variables

#### env/staging.tfvars
- [x] Create staging configuration:
  ```hcl
  environment   = "staging"
  instance_type = "t2.micro"
  min_instances = 1
  max_instances = 2
  ```

#### env/prod.tfvars
- [x] Create production configuration:
  ```hcl
  environment   = "prod"
  instance_type = "t2.small"
  min_instances = 1
  max_instances = 4
  ```

### 3.4. Terraform Initialization and Validation
- [x] Initialize Terraform:
  ```bash
  cd infra
  terraform init
  ```
- [x] Validate configuration:
  ```bash
  terraform validate
  ```
- [x] Plan staging:
  ```bash
  terraform plan -var-file="env/staging.tfvars" -out=staging.tfplan
  ```
- [ ] Apply staging (deferred until Phase 5 CD pipeline):
  ```bash
  terraform apply staging.tfplan
  ```
- [ ] Plan and apply production (deferred until Phase 5)

### 3.5. Blue-Green Deployment Architecture

**Strategy:** Staging as Green, Production as Blue
- **BLUE** = `bp-calculator-prod` (current production environment)
- **GREEN** = `bp-calculator-staging` (new version being validated)
- **Promotion:** After validation passes, CNAME swap promotes GREEN to production
- **Rollback:** CNAME swap back or redeploy previous version

**Infrastructure Ready For:**
- Separate staging and production environments
- CNAME swapping for zero-downtime deployments
- CloudWatch monitoring with SNS alarms
- Automatic log streaming to CloudWatch

---

## PHASE 4 — CI PIPELINE (GITHUB ACTIONS)

### Status: ⬜ Not Started

### 4.1. Create CI Workflow
- [ ] Create `.github/workflows/ci.yml`

### 4.2. CI Pipeline Components

#### Trigger Configuration
- [ ] Trigger on:
  - Pull requests to `main` or `develop`
  - Push to `main` or `develop`

#### Build Jobs
- [ ] **Restore & Build**
  ```bash
  dotnet restore
  dotnet build --configuration Release --no-restore
  ```

- [ ] **Unit Tests**
  ```bash
  dotnet test --no-build --verbosity normal
  ```

- [ ] **BDD Tests**
  ```bash
  dotnet test --filter "Category=BDD" --no-build
  ```

- [ ] **Code Coverage**
  ```bash
  dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura /p:Threshold=80
  ```

- [ ] **Static Code Analysis**
  - Option 1: SonarCloud integration
  - Option 2: `dotnet format --verify-no-changes`
  - Option 3: Roslyn analyzers

- [ ] **Dependency Vulnerability Scan**
  ```bash
  dotnet list package --vulnerable --include-transitive
  ```

- [ ] **Security Scan** (Choose one or more)
  - Snyk: `snyk test`
  - GitHub Dependabot (enable in repo settings)
  - Trivy: `trivy fs .`

### 4.3. CI Quality Gates
- [ ] All tests must pass
- [ ] Code coverage ≥80%
- [ ] No high/critical vulnerabilities
- [ ] No code formatting issues

---

## PHASE 5 — CD PIPELINE WITH BLUE–GREEN DEPLOYMENT

### Status: ⬜ Not Started

### 5.1. Create CD Workflow
- [ ] Create `.github/workflows/cd.yml`
- [ ] Trigger on:
  - Release tag creation (e.g., `v1.0.0`)
  - OR push to `main` branch (after CI passes)

### 5.2. Build & Package Application
- [ ] Publish release build:
  ```bash
  dotnet publish -c Release -o publish/
  ```
- [ ] Create deployment package:
  ```bash
  cd publish
  zip -r ../bp-app-$GITHUB_SHA.zip .
  ```

### 5.3. Upload Artifact to S3
- [ ] Upload to S3 bucket:
  ```bash
  aws s3 cp bp-app-$GITHUB_SHA.zip s3://<bucket-name>/
  ```

### 5.4. Create EB Application Version
- [ ] Create application version:
  ```bash
  aws elasticbeanstalk create-application-version \
    --application-name bp-calculator \
    --version-label $GITHUB_SHA \
    --source-bundle S3Bucket="<bucket-name>",S3Key="bp-app-$GITHUB_SHA.zip"
  ```

### 5.5. Deploy to STAGING
- [ ] Deploy to staging environment:
  ```bash
  aws elasticbeanstalk update-environment \
    --environment-name bp-calculator-staging \
    --version-label $GITHUB_SHA
  ```
- [ ] Wait for environment to be ready:
  ```bash
  aws elasticbeanstalk wait environment-updated \
    --environment-names bp-calculator-staging
  ```

### 5.6. Automated Tests on STAGING

#### E2E Tests (Playwright/Selenium)
- [ ] Install test framework
- [ ] Test scenarios:
  - Page loads successfully
  - Form accepts valid input
  - Correct category displayed for:
    - Low BP: S=85, D=55 → "Low"
    - Ideal BP: S=115, D=75 → "Ideal"
    - Pre-High BP: S=130, D=85 → "Pre-High"
    - High BP: S=150, D=95 → "High"
  - Error handling for invalid input
- [ ] Execute against staging URL

#### Performance Tests (k6)
- [ ] Create k6 test script:
  ```javascript
  import http from 'k6/http';
  import { check, sleep } from 'k6';

  export let options = {
    stages: [
      { duration: '10s', target: 10 },
      { duration: '20s', target: 50 },
      { duration: '10s', target: 0 },
    ],
    thresholds: {
      http_req_duration: ['p(95)<500'],
      http_req_failed: ['rate<0.01'],
      http_reqs: ['rate>50'],
    },
  };

  export default function () {
    let res = http.post('http://<staging-url>/calculate', {
      systolic: 120,
      diastolic: 80,
    });
    check(res, { 'status is 200': (r) => r.status === 200 });
    sleep(1);
  }
  ```
- [ ] Run: `k6 run performance-test.js`
- [ ] Fail pipeline if thresholds not met

#### Security Tests (OWASP ZAP)
- [ ] Run ZAP baseline scan:
  ```bash
  docker run -t owasp/zap2docker-stable zap-baseline.py \
    -t http://<staging-url> \
    -r zap-report.html
  ```
- [ ] Review report for HIGH severity issues
- [ ] Fail pipeline if critical vulnerabilities found

#### Telemetry Gate
- [ ] Query CloudWatch metrics for last 5 minutes:
  ```bash
  aws cloudwatch get-metric-statistics \
    --namespace AWS/ElasticBeanstalk \
    --metric-name ApplicationRequests5xx \
    --dimensions Name=EnvironmentName,Value=bp-calculator-staging \
    --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum
  ```
- [ ] Fail if:
  - 5xx errors > 0
  - Average response time > 2000ms

### 5.7. Manual Approval Gate
- [ ] Configure GitHub Environment protection:
  - Go to Settings → Environments → Create `production`
  - Enable "Required reviewers"
  - Add yourself as required reviewer
- [ ] Pipeline pauses for approval before production deployment
- [ ] Review staging metrics and test results
- [ ] Approve deployment to production

### 5.8. Blue–Green Promotion (CNAME Swap)
- [ ] Execute CNAME swap:
  ```bash
  aws elasticbeanstalk swap-environment-cnames \
    --source-environment-name bp-calculator-staging \
    --destination-environment-name bp-calculator-prod
  ```
- [ ] Wait for swap to complete
- [ ] Verify production URL serves new version
- [ ] Monitor CloudWatch for any errors

### 5.9. Rollback Strategy
- [ ] **Option 1: CNAME Swap Back**
  ```bash
  aws elasticbeanstalk swap-environment-cnames \
    --source-environment-name bp-calculator-prod \
    --destination-environment-name bp-calculator-staging
  ```
- [ ] **Option 2: Redeploy Previous Version**
  ```bash
  aws elasticbeanstalk update-environment \
    --environment-name bp-calculator-staging \
    --version-label <previous-sha>
  # Then swap again after validation
  ```

---

## PHASE 6 — NEW FEATURE (≤ 30 LINES) + FEATURE BRANCH WORKFLOW

### Status: ⬜ Not Started

### 6.1. User Story: Category Explanation Text

**User Story:**
```
AS A patient using the BP calculator
I WANT to see an explanation of my blood pressure category
SO THAT I understand what my reading means and what action to take
```

**Acceptance Criteria:**
- Given I submit valid BP values
- When the category is calculated
- Then I see a clear explanation below the category
- And the explanation is appropriate for the category (Low/Ideal/Pre-High/High)

### 6.2. Implementation (≤30 lines)

- [ ] Create feature branch:
  ```bash
  git checkout -b feature/category-explanation
  ```

- [ ] Add explanation method:
  ```csharp
  public static string GetCategoryExplanation(BpCategory category)
  {
      return category switch
      {
          BpCategory.Low => 
              "Your blood pressure is low. If you experience dizziness, weakness, or fatigue, please consult a healthcare provider.",
          
          BpCategory.Ideal => 
              "Your blood pressure is ideal and healthy. Keep maintaining your current lifestyle with regular exercise and a balanced diet.",
          
          BpCategory.PreHigh => 
              "Your blood pressure is pre-high (prehypertension). Consider lifestyle changes such as reducing salt intake, exercising regularly, and managing stress.",
          
          BpCategory.High => 
              "Your blood pressure is high. Please consult a healthcare provider for proper evaluation and treatment. Monitor your BP regularly.",
          
          _ => 
              "Unable to determine category. Please ensure valid input values."
      };
  }
  ```

- [ ] Update Razor page to display explanation
- [ ] Add CSS styling for explanation text

### 6.3. Tests for New Feature

#### Unit Tests
- [ ] Test explanation for Low category
- [ ] Test explanation for Ideal category
- [ ] Test explanation for Pre-High category
- [ ] Test explanation for High category
- [ ] Test explanation is not null/empty

#### BDD Test
- [ ] Add scenario to `.feature` file:
  ```gherkin
  Scenario: Display explanation for Ideal blood pressure
    Given systolic pressure is 115
    And diastolic pressure is 75
    When I calculate the category
    Then the result should be "Ideal"
    And the explanation should contain "ideal and healthy"
  ```
- [ ] Implement step definition

### 6.4. Git Feature Branch Workflow
- [ ] Create feature branch: `git checkout -b feature/category-explanation`
- [ ] Implement feature with tests
- [ ] Commit changes:
  ```bash
  git add .
  git commit -m "feat: Add BP category explanation text"
  ```
- [ ] Push to remote:
  ```bash
  git push origin feature/category-explanation
  ```
- [ ] Open Pull Request to `main`
- [ ] CI pipeline runs automatically
- [ ] Wait for tests to pass
- [ ] Request code review (if applicable)
- [ ] Merge PR after approval
- [ ] Delete feature branch
- [ ] CD pipeline deploys to staging → production

---

## PHASE 7 — EVIDENCE COLLECTION

### Status: ⬜ Not Started

### 7.1. Terraform Evidence
- [ ] Screenshot: `terraform plan` output
- [ ] Screenshot: `terraform apply` completion
- [ ] Screenshot: AWS Elastic Beanstalk console showing both environments
- [ ] Screenshot: Terraform state in S3 bucket

### 7.2. CI Pipeline Evidence
- [ ] Screenshot: GitHub Actions CI workflow successful run
- [ ] Screenshot: Unit test results (all passing)
- [ ] Screenshot: BDD test results (all passing)
- [ ] Screenshot: Code coverage report (≥80%)
- [ ] Screenshot: Static analysis results
- [ ] Screenshot: Dependency vulnerability scan results

### 7.3. CD Pipeline Evidence
- [ ] Screenshot: GitHub Actions CD workflow successful run
- [ ] Screenshot: Deployment to staging environment
- [ ] Screenshot: E2E test results on staging
- [ ] Screenshot: Performance test results (k6 output)
- [ ] Screenshot: Security scan results (OWASP ZAP)
- [ ] Screenshot: Manual approval gate
- [ ] Screenshot: Blue-green CNAME swap execution
- [ ] Screenshot: Production environment after deployment

### 7.4. Telemetry Evidence
- [ ] Screenshot: CloudWatch log streams
- [ ] Screenshot: CloudWatch metrics dashboard
- [ ] Screenshot: Custom metrics (if implemented)
- [ ] Screenshot: X-Ray traces (if implemented)
- [ ] Screenshot: Telemetry gate validation

### 7.5. Application Evidence
- [ ] Screenshot: Application running on staging URL
- [ ] Screenshot: Application running on production URL
- [ ] Screenshot: BP calculation with Low category
- [ ] Screenshot: BP calculation with Ideal category
- [ ] Screenshot: BP calculation with Pre-High category
- [ ] Screenshot: BP calculation with High category
- [ ] Screenshot: New feature (explanation text) displayed
- [ ] Screenshot: Error handling for invalid input

### 7.6. Feature Branch Workflow Evidence
- [ ] Screenshot: Feature branch in GitHub
- [ ] Screenshot: Pull Request with CI checks
- [ ] Screenshot: Code review comments (if applicable)
- [ ] Screenshot: Merge commit
- [ ] Screenshot: Branch deletion after merge

---

## PHASE 8 — REPORT & VIDEO PREPARATION

### Status: ⬜ Not Started

### 8.1. Written Report Structure

- [ ] **1. Introduction** (1 page)
  - Project overview
  - Technologies used
  - Architecture diagram

- [ ] **2. Application Implementation** (2-3 pages)
  - BP classification logic
  - Code structure
  - Validation and error handling
  - Code quality improvements

- [ ] **3. Testing Strategy** (2-3 pages)
  - Unit testing approach
  - BDD testing with SpecFlow
  - Test coverage analysis
  - Test results

- [ ] **4. Infrastructure-as-Code (Terraform)** (2-3 pages)
  - Terraform structure
  - AWS resources created
  - Environment configuration
  - State management

- [ ] **5. CI Pipeline** (2-3 pages)
  - GitHub Actions workflow
  - Build and test automation
  - Code analysis tools
  - Security scanning
  - Quality gates

- [ ] **6. CD Pipeline** (3-4 pages)
  - Deployment workflow
  - Environment promotion strategy
  - Automated testing in staging
  - Performance testing
  - Security testing
  - Telemetry gates

- [ ] **7. Blue–Green Deployment** (2 pages)
  - Deployment strategy explanation
  - CNAME swap process
  - Zero-downtime deployment
  - Rollback procedure

- [ ] **8. Branching Workflow** (1-2 pages)
  - Git Feature Branch workflow
  - Pull request process
  - Code review integration
  - CI/CD integration with branches

- [ ] **9. Telemetry & Monitoring** (2 pages)
  - CloudWatch logging
  - Metrics tracking
  - X-Ray tracing (if used)
  - Alerting configuration

- [ ] **10. New Feature** (2 pages)
  - **User Story:**
    - AS A patient using the BP calculator
    - I WANT to see an explanation of my blood pressure category
    - SO THAT I understand what my reading means and what action to take
  - Feature implementation
  - Tests added
  - Demonstration

- [ ] **11. Reflection** (1-2 pages)
  - Challenges faced
  - Solutions implemented
  - Lessons learned
  - Future improvements

### 8.2. Video Structure (10–15 minutes)

- [ ] **Introduction** (1 min)
  - Project overview
  - Architecture overview

- [ ] **Application Demo** (2 min)
  - Logic walkthrough
  - BP calculations for each category
  - New feature demonstration
  - Error handling

- [ ] **Testing** (2 min)
  - Unit test execution
  - BDD test execution
  - Coverage report
  - Test results

- [ ] **Terraform Infrastructure** (2 min)
  - Terraform files overview
  - `terraform plan` execution
  - AWS resources created
  - Staging and production environments

- [ ] **CI Pipeline** (2 min)
  - GitHub Actions workflow
  - Build process
  - Test execution
  - Security scanning
  - Quality gates

- [ ] **CD Pipeline Execution** (3 min)
  - Deployment trigger
  - Staging deployment
  - Automated tests on staging
  - Manual approval gate
  - Blue-green promotion (CNAME swap)
  - Production verification

- [ ] **Telemetry & Monitoring** (1 min)
  - CloudWatch logs
  - Metrics dashboard
  - X-Ray traces (if used)

- [ ] **Summary** (1 min)
  - Key achievements
  - Full CI/CD pipeline demonstration
  - All requirements met

---

## 📊 Requirements Mapping

| Requirement | Phase | Status |
|-------------|-------|--------|
| Complete BP logic | Phase 1.1 | ⬜ |
| Add telemetry | Phase 2 | ⬜ |
| Unit tests (≥80%) | Phase 1.2 | ⬜ |
| BDD testing | Phase 1.3 | ⬜ |
| Code analysis | Phase 4 | ⬜ |
| Security - dependencies | Phase 4 | ⬜ |
| Release management | Phase 5 | ⬜ |
| Blue/green deployment | Phase 5 | ⬜ |
| E2E testing | Phase 5.6 | ⬜ |
| Performance testing | Phase 5.6 | ⬜ |
| Security - pen testing | Phase 5.6 | ⬜ |
| Telemetry monitoring | Phase 2, 5.6 | ⬜ |
| Authorization gates | Phase 5.7 | ⬜ |
| New feature (≤30 lines) | Phase 6 | ⬜ |
| Feature branch workflow | Phase 6.4 | ⬜ |
| Video demo | Phase 8.2 | ⬜ |
| Report | Phase 8.1 | ⬜ |

---

## 🎯 Success Criteria

- ✅ All phases completed
- ✅ All tests passing (unit, BDD, E2E)
- ✅ Code coverage ≥80%
- ✅ Infrastructure deployed via Terraform
- ✅ CI pipeline fully automated
- ✅ CD pipeline with blue-green deployment
- ✅ New feature implemented and tested
- ✅ Evidence collected for all phases
- ✅ Report completed
- ✅ Video demo recorded

---

## 📝 Notes

- Commit after each phase completion
- Test thoroughly before moving to next phase
- Document any issues encountered
- Keep all evidence organized
- Review assignment requirements regularly

---

## 🚀 Deployment Automation Scripts

### One-Command Deployment: `./deploy.sh`

**Purpose:** Deploy entire infrastructure and application with a single command

**Usage:**
```bash
# Deploy to staging
./deploy.sh staging

# Deploy to production
./deploy.sh prod

# Deploy both environments
./deploy.sh all
```

### One-Command Teardown: `./destroy.sh`

**Purpose:** Destroy all AWS resources and clean up with a single command

**Usage:**
```bash
# Destroy staging environment
./destroy.sh staging

# Destroy production environment
./destroy.sh prod

# Destroy everything (including S3 buckets and state)
./destroy.sh all

# Destroy with auto-approval (no prompts)
./destroy.sh all --auto-approve
```

**Safety Features:**
- Confirmation prompts before destruction
- Backup of Terraform state before destroy
- Option to preserve S3 buckets with application artifacts
- Dry-run mode to preview what will be destroyed
