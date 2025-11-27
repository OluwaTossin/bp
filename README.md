# Blood Pressure Calculator - CI/CD Pipeline Project

[![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?logo=dotnet)](https://dotnet.microsoft.com/)
[![Tests](https://img.shields.io/badge/tests-55%20passing-brightgreen)](https://github.com/OluwaTossin/bp)
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
- ✅ **Security Scanning** - Dependency vulnerability checks and OWASP ZAP

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Application │  │   Tests      │  │  Terraform   │     │
│  │     Code     │  │  (55 tests)  │  │     IaC      │     │
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
Total Tests:  55 (31 unit + 24 BDD)
Passed:       55 ✓
Failed:       0
Skipped:      0
Duration:     99ms
Coverage:     100% (BloodPressure class)
```

**Deliverables:**
- `BPCalculator/BloodPressure.cs` - Core classification logic
- `BPCalculator.Tests/BloodPressureTests.cs` - 31 unit tests
- `BPCalculator.Tests/Features/BloodPressureClassification.feature` - BDD scenarios
- `BPCalculator.Tests/Features/BloodPressureClassificationSteps.cs` - Step definitions

---

### 🔄 Phase 2: Telemetry & Observability (IN PROGRESS)
**Status:** Not Started

- [ ] CloudWatch logging with structured logs
- [ ] Custom metrics for BP calculation tracking
- [ ] AWS X-Ray integration (optional)
- [ ] Logging middleware configuration

---

### ⏳ Phase 3: Terraform Infrastructure (PENDING)

- [ ] Create Terraform directory structure
- [ ] Define AWS resources (EB, S3, IAM roles)
- [ ] Configure staging and production environments
- [ ] Apply infrastructure with `terraform apply`

---

### ⏳ Phase 4: CI Pipeline (PENDING)

- [ ] Create `.github/workflows/ci.yml`
- [ ] Automated build and test on PR/push
- [ ] Code coverage reporting
- [ ] Static code analysis
- [ ] Security vulnerability scanning

---

### ⏳ Phase 5: CD Pipeline with Blue-Green Deployment (PENDING)

- [ ] Create `.github/workflows/cd.yml`
- [ ] Deploy to staging environment
- [ ] E2E tests on staging
- [ ] Performance testing with k6
- [ ] Security testing with OWASP ZAP
- [ ] Manual approval gate
- [ ] Blue-green CNAME swap to production

---

### ⏳ Phase 6: New Feature (≤30 Lines) (PENDING)

- [ ] User Story: Category explanation text
- [ ] Implementation with tests
- [ ] Feature branch workflow demonstration
- [ ] Pull request with CI checks

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
| **Testing** | xUnit, SpecFlow, Coverlet, Playwright, k6, OWASP ZAP |
| **Cloud Platform** | AWS (Elastic Beanstalk, S3, CloudWatch, X-Ray) |
| **Infrastructure** | Terraform, AWS CLI |
| **CI/CD** | GitHub Actions |
| **Monitoring** | CloudWatch Logs, CloudWatch Metrics, X-Ray |

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
├── deploy.sh                        # One-command deployment
├── destroy.sh                       # One-command teardown
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

**Unit Tests (31 tests)**
- Blood pressure category classification
- Boundary value analysis
- Input validation
- Error handling

**BDD Tests (24 scenarios)**
- Gherkin-based behavior specification
- Scenario outlines with data tables
- Given/When/Then step definitions

**Test Execution:**
```bash
# Run all tests
dotnet test

# Run with coverage
dotnet test /p:CollectCoverage=true

# Run only unit tests
dotnet test --filter "FullyQualifiedName~BloodPressureTests"

# Run only BDD tests
dotnet test --filter "FullyQualifiedName~BloodPressureClassificationFeature"
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

**Last Updated:** November 27, 2025  
**Current Phase:** Phase 2 - Telemetry & Observability  
**Test Status:** 55/55 passing ✓  
**Coverage:** 100% (BloodPressure class)
