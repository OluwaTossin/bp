# Blood Pressure Calculator - CI/CD Pipeline Project

[![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?logo=dotnet)](https://dotnet.microsoft.com/)
[![Tests](https://img.shields.io/badge/tests-62%20passing-brightgreen)](https://github.com/OluwaTossin/bp)
[![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/OluwaTossin/bp)
[![AWS](https://img.shields.io/badge/AWS-Elastic%20Beanstalk-FF9900?logo=amazon-aws)](https://aws.amazon.com/elasticbeanstalk/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)

A production-ready ASP.NET Core Razor Pages application for blood pressure classification with full CI/CD pipeline, infrastructure-as-code, and comprehensive testing.

## 📋 Project Overview

This project demonstrates enterprise-level DevOps practices including:

- ✅ **Automated Testing** - Unit tests (xUnit) + BDD tests (SpecFlow)
- ✅ **Infrastructure-as-Code** - Terraform for AWS resource management
- ✅ **CI/CD Pipeline** - GitHub Actions with automated quality gates
- ✅ **Blue-Green Deployment** - Zero-downtime deployments via CNAME swap
- ✅ **Cloud Monitoring** - CloudWatch logs, metrics, and alarms
- ✅ **Security Scanning** - Dependency vulnerability checks and OWASP ZAP baseline scans
- ✅ **Performance Testing** - k6 load testing with realistic user scenarios
- ✅ **Feature Branch Workflow** - Complete Git workflow with PR integration
- ✅ **Authorization Gates** - Manual approval required for production deployments

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Application │  │   Tests      │  │  Terraform   │     │
│  │     Code     │  │  (62 tests)  │  │     IaC      │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
    ┌────────────────┐
    │ GitHub Actions │ ◄─── CI/CD Pipeline
    │   Workflows    │
    └────────┬───────┘
             │
             ├──► Build & Test (CI)
             │
             ├──► Deploy to Staging (CD)
             │    └─► E2E Tests
             │    └─► Performance Tests
             │    └─► Security Scans
             │
             └──► Blue-Green Swap to Production
                  └─► AWS Elastic Beanstalk
```

## 🚀 Features

### Blood Pressure Classification
Calculates blood pressure category based on systolic and diastolic values:

| Category | Systolic (mmHg) | Diastolic (mmHg) | Description |
|----------|----------------|------------------|-------------|
| **Low** | < 90 | < 60 | Hypotension - May require medical attention |
| **Ideal** | 90-120 | 60-80 | Healthy blood pressure range |
| **Pre-High** | 121-140 | 81-90 | Prehypertension - Lifestyle changes recommended |
| **High** | > 140 | > 90 | Hypertension - Medical consultation advised |

### Input Validation
- Systolic range: 70-190 mmHg
- Diastolic range: 40-100 mmHg
- Systolic must be greater than Diastolic

## 📊 Project Status

### ✅ Phase 0: Foundation Setup (COMPLETE)
**Completed:** November 27, 2025

- [x] Repository setup and .NET 8.0 configuration
- [x] AWS IAM user created with appropriate policies
- [x] Terraform backend configured (S3 + DynamoDB)
- [x] Cost management documentation
- [x] Deployment automation scripts (`deploy.sh`, `destroy.sh`)

**Deliverables:**
- S3 Bucket: `bp-terraform-state-1764230215`
- DynamoDB Table: `bp-terraform-locks`
- IAM User: `bp-calculator-deploy`

---

### ✅ Phase 1: Application Logic & Testing (COMPLETE)
**Completed:** November 27, 2025

#### 1.1 Blood Pressure Classification Logic
- [x] Implemented classification algorithm with 4 categories
- [x] Added input validation (Systolic > Diastolic)
- [x] 100% line coverage on `BloodPressure.cs`
- [x] 100% branch coverage on core logic

#### 1.2 Unit Testing (xUnit)
- [x] Created test project: `BPCalculator.Tests`
- [x] Added 31 comprehensive unit tests
  - Category tests for all BP classifications
  - Boundary value analysis
  - Invalid input exception handling
  - Edge case coverage
- [x] Integrated Coverlet for code coverage
- [x] All tests passing: **31/31 ✓**

#### 1.3 BDD Testing (SpecFlow)
- [x] Added SpecFlow with Gherkin syntax
- [x] Created feature file with 13 scenarios + 1 scenario outline
- [x] Implemented step definitions with Given/When/Then
- [x] All BDD tests passing: **24/24 ✓**

**Test Results:**
```
Total Tests:  62 (36 unit + 26 BDD)
Passed:       62 ✓
Failed:       0
Skipped:      0
Duration:     101ms
Coverage:     100% (BloodPressure class)
```

**Deliverables:**
- `BPCalculator/BloodPressure.cs` - Core classification logic
- `BPCalculator.Tests/BloodPressureTests.cs` - 36 unit tests
- `BPCalculator.Tests/Features/BloodPressureClassification.feature` - BDD scenarios
- `BPCalculator.Tests/Features/BloodPressureClassificationSteps.cs` - Step definitions

---

### ✅ Phase 2: Telemetry & Observability (COMPLETE)
**Completed:** November 27, 2025

- [x] CloudWatch logging with structured logs
- [x] Custom metrics for BP calculation tracking
- [x] Logging middleware configuration
- [x] CloudWatch log group: `bp-calculator-logs`
- [x] Integration validated with 62/62 tests passing

---

### ✅ Phase 3: Terraform Infrastructure (COMPLETE)
**Completed:** November 27, 2025

- [x] Created Terraform directory structure (10 configuration files)
- [x] Defined AWS resources (EB, S3, IAM roles, CloudWatch, SNS)
- [x] Configured staging and production environments
- [x] Applied infrastructure with `terraform apply`
- [x] 16+ AWS resources deployed successfully

**Deployed Resources:**
- Elastic Beanstalk Application & Environment
- S3 buckets (artifacts)
- IAM roles and instance profiles
- CloudWatch log groups and alarms
- SNS topics for alerting
- Security groups and network configuration

---

### ✅ Phase 4: CI Pipeline (COMPLETE)
**Completed:** November 27, 2025

**GitHub Actions CI Pipeline - All Quality Gates Passing:**

- [x] Created `.github/workflows/ci.yml` with 4 parallel jobs
- [x] **build-and-test**: 62/62 tests passing (36 unit + 26 BDD)
- [x] **security-scan**: Zero vulnerabilities detected
- [x] **code-quality**: Code formatting compliance
- [x] **summary**: Aggregate quality gate enforcement
- [x] Code coverage: 100% on core BloodPressure.cs
- [x] Test reporting with automated GitHub check runs
- [x] Coverage reports (HTML + Markdown)
- [x] Triggers: Push/PR to main/develop, manual dispatch

---

### ✅ Phase 5: CD Pipeline with AWS Deployment (COMPLETE)
**Completed:** November 29, 2025

**Infrastructure Deployed & Application Running:**

- [x] Created `.github/workflows/cd.yml` for automated deployments
- [x] Deployed Terraform infrastructure to AWS (16+ resources)
- [x] **Elastic Beanstalk Environment**: bp-calculator-staging (t3.micro)
- [x] **Application URL**: http://bp-calculator-staging.eba-gb3zir6t.eu-west-1.elasticbeanstalk.com
- [x] **S3 Artifacts Bucket**: bp-calculator-eb-artifacts-staging
- [x] **CloudWatch Logging**: bp-calculator-logs
- [x] **CloudWatch Alarms**: CPU, Unhealthy hosts, 5xx errors
- [x] **Performance Testing**: k6 load tests (p95 < 500ms)
- [x] **Security Testing**: OWASP ZAP baseline scans
- [x] **Authorization Gates**: Manual approval for production
- [x] **Status**: Ready (Green health)
- [x] Application deployed and accessible (HTTP 200)
- [x] All CD pipeline jobs passing (8 jobs)

---

### ✅ Phase 6: New Feature (≤30 Lines) (COMPLETE)
**Completed:** November 27, 2025

- [x] User Story: BP category explanation text
- [x] Implementation: 23 lines (GetCategoryExplanation method + UI)
- [x] Feature branch: `feature/category-explanation`
- [x] Tests added: 7 new tests (5 unit + 2 BDD)
- [x] Pull Request #1: Created and merged
- [x] CI validation: All checks passed
- [x] CD deployment: Deployed to staging
- [x] Feature live: http://bp-calculator-staging.eba-gb3zir6t.eu-west-1.elasticbeanstalk.com

**Feature Details:**
- Added health guidance text for each BP category
- Integrated with existing UI using Bootstrap alerts
- Full test coverage maintained (62/62 tests passing)
- Demonstrated complete feature branch workflow

---

### ⏳ Phase 7: Evidence Collection (PENDING)

- [ ] Screenshots of all pipeline stages
- [ ] Terraform outputs
- [ ] Test results
- [ ] CloudWatch logs and metrics
- [ ] Deployment evidence

---

### ⏳ Phase 8: Report & Video (PENDING)

- [ ] Written report (15-20 pages)
- [ ] Video demonstration (10-15 minutes)
- [ ] Architecture diagrams
- [ ] Project reflection

---

## 🛠️ Technology Stack

| Category | Technologies |
|----------|-------------|
| **Application** | ASP.NET Core 8.0, Razor Pages, C# |
| **Testing** | xUnit, SpecFlow, Coverlet |
| **Performance Testing** | k6 (load testing, 50 concurrent users) |
| **Security Testing** | OWASP ZAP (baseline scan), dependency scanning |
| **Cloud Platform** | AWS (Elastic Beanstalk, S3, CloudWatch) |
| **Infrastructure** | Terraform, AWS CLI |
| **CI/CD** | GitHub Actions (8-stage pipeline) |
| **Monitoring** | CloudWatch Logs, CloudWatch Metrics, CloudWatch Alarms |

## 📦 Project Structure

```
bp/
├── BPCalculator/                    # Main application
│   ├── Pages/                       # Razor Pages
│   │   ├── Index.cshtml            # BP Calculator UI
│   │   └── Index.cshtml.cs         # Page model
│   ├── BloodPressure.cs            # Core BP logic (100% coverage)
│   ├── Program.cs                  # App entry point
│   └── Startup.cs                  # Configuration
│
├── BPCalculator.Tests/              # Test project
│   ├── BloodPressureTests.cs       # 31 unit tests
│   ├── Features/
│   │   ├── BloodPressureClassification.feature  # BDD scenarios
│   │   └── BloodPressureClassificationSteps.cs  # Step definitions
│   └── coverage/                    # Coverage reports
│
├── infra/                           # Terraform IaC (Phase 3)
│   ├── main.tf
│   ├── variables.tf
│   └── env/
│       ├── staging.tfvars
│       └── prod.tfvars
│
├── .github/workflows/               # CI/CD pipelines (Phase 4-5)
│   ├── ci.yml
│   └── cd.yml
│
├── tests/                           # Performance & security tests
│   ├── performance/
│   │   └── load-test.js            # k6 load testing script
│   └── security/
│       ├── zap-baseline.conf       # OWASP ZAP configuration
│       └── zap-scan.sh             # Security scan script
│
├── docs/                            # Documentation
│   └── GITHUB_ENVIRONMENTS_SETUP.md
│
├── deploy.sh                        # One-command deployment
├── destroy.sh                       # One-command teardown
├── bootstrap.sh                     # First-time AWS setup
├── DEPLOYMENT_GUIDE.md             # Deployment documentation
├── COST_MANAGEMENT.md              # AWS cost guide
├── EXECUTION_PLAN.md               # Phase tracking
└── README.md                        # This file
```

## 🚀 Quick Start

### Prerequisites
- .NET 8.0 SDK
- AWS CLI configured
- Terraform 1.0+
- Git

### Local Development

1. **Clone the repository:**
   ```bash
   git clone git@github.com:OluwaTossin/bp.git
   cd bp
   ```

2. **Run the application:**
   ```bash
   cd BPCalculator
   dotnet run
   ```
   Navigate to `http://localhost:5000`

3. **Run tests:**
   ```bash
   dotnet test
   ```

4. **Generate coverage report:**
   ```bash
   dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura
   ```

### Deployment

**Deploy to AWS:**
```bash
./deploy.sh staging    # Deploy to staging
./deploy.sh prod       # Deploy to production
./deploy.sh all        # Deploy both environments
```

**Destroy infrastructure:**
```bash
./destroy.sh all       # Destroy all resources
```

## 📈 Cost Estimation

**Estimated Monthly Cost:** $15-25 USD

| Service | Cost |
|---------|------|
| EC2 (t2.micro) | ~$8/month |
| S3 | <$0.10/month |
| DynamoDB | <$0.01/month |
| CloudWatch | ~$2.50/month |

See [COST_MANAGEMENT.md](./COST_MANAGEMENT.md) for detailed breakdown and optimization strategies.

## 🧪 Testing

### Test Categories

**Unit Tests (36 tests)**
- Blood pressure category classification
- Category explanation text
- Boundary value analysis
- Input validation
- Error handling

**BDD Tests (26 scenarios)**
- Gherkin-based behavior specification
- Scenario outlines with data tables
- Given/When/Then step definitions
- Category explanation validation

**Performance Tests (k6)**
- Load testing with 0→50 concurrent users
- Homepage and calculation endpoint tests
- Response time thresholds (p95 < 500ms)
- Error rate monitoring (< 1%)

**Security Tests (OWASP ZAP)**
- Baseline security scan
- XSS and injection vulnerability checks
- Security headers validation
- Cookie security assessment

**Test Execution:**
```bash
# Run unit and BDD tests
dotnet test

# Run with coverage
dotnet test /p:CollectCoverage=true

# Run performance tests
k6 run tests/performance/load-test.js

# Run security scan
./tests/security/zap-scan.sh http://localhost:5000
```

## 📚 Documentation

- [ASSIGNMENT.md](./ASSIGNMENT.md) - Original project requirements
- [EXECUTION_PLAN.md](./EXECUTION_PLAN.md) - Detailed phase-by-phase plan with checkboxes
- [COST_MANAGEMENT.md](./COST_MANAGEMENT.md) - AWS cost analysis and optimization

## 🤝 Contributing

This is an academic project for TU Dublin M.Sc. in Computing (DevOps). 

### Git Workflow
- **main** - Production-ready code
- **feature/** - Feature branches for new functionality
- Pull requests required for all changes to main

## 📄 License

This project is developed as part of academic coursework at TU Dublin.

## 👤 Author

**Oluwatosin**
- GitHub: [@OluwaTossin](https://github.com/OluwaTossin)
- Course: M.Sc. in Computing (DevOps)
- Institution: TU Dublin
- Module: CSD - Continuous Software Delivery

## 🎯 Project Goals

✅ **Technical Excellence:** Implement production-grade CI/CD pipeline  
✅ **DevOps Best Practices:** Infrastructure-as-Code, automated testing, monitoring  
✅ **Cloud Native:** AWS services with serverless architecture  
✅ **Quality Assurance:** >80% code coverage, automated security scans  
✅ **Zero-Downtime Deployments:** Blue-green strategy with CNAME swaps  

---

**Last Updated:** November 29, 2025  
**Current Phase:** Phase 7 - Evidence Collection  
**Test Status:** 62/62 passing ✓  
**Performance:** p95 < 500ms ✓  
**Security:** 0 high-risk vulnerabilities ✓  
**Coverage:** 100% (BloodPressure class)
