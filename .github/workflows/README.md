# GitHub Actions CI/CD Workflows

This directory contains GitHub Actions workflows for automated CI/CD pipelines.

## 📁 Workflows

### ci.yml - Continuous Integration
**Triggers:**
- Push to `main` or `develop` branches
- Pull requests targeting `main` or `develop`
- Manual workflow dispatch

**Jobs:**

1. **build-and-test**
   - Checkout code
   - Setup .NET 8.0
   - Restore NuGet packages
   - Build solution in Release mode
   - Run all tests (31 unit + 24 BDD = 55 total)
   - Generate code coverage report
   - Validate coverage meets 80% threshold
   - Upload test results and coverage artifacts
   - Comment coverage on pull requests

2. **security-scan**
   - Scan for vulnerable NuGet packages
   - Check transitive dependencies
   - Fail if high/critical vulnerabilities found
   - Upload vulnerability report

3. **code-quality**
   - Run `dotnet format` to check code formatting
   - Check for build warnings
   - Enforce code quality standards

4. **summary**
   - Aggregate results from all jobs
   - Fail if build/test or security scans fail
   - Warn on code quality issues

**Quality Gates:**
- ✅ All 62 tests must pass (36 unit + 26 BDD)
- ✅ Code coverage ≥ 80% (100% on BloodPressure.cs)
- ✅ No high/critical security vulnerabilities
- ⚠️ No build warnings (warning only)
- ⚠️ Code formatting follows .NET conventions (warning only)

**Artifacts:**
- Test results (.trx files)
- Coverage report (HTML + Markdown)
- Vulnerability scan report

### cd.yml - Continuous Deployment
**Triggers:**
- Push to `main` branch (automatic staging deployment)
- Manual workflow dispatch with environment selection
- Paths-ignore: Documentation files (*.md, docs/**)

**Jobs (7-Stage Pipeline):**

1. **build-package**
   - Build .NET 8.0 application
   - Run all 62 tests (36 unit + 26 BDD)
   - Create deployment package (.zip)
   - Upload as artifact

2. **deploy-infrastructure**
   - Initialize Terraform with environment-specific state
   - Apply infrastructure changes
   - Output: environment-name, application-name, s3-bucket

3. **deploy-application**
   - Upload package to S3
   - Create EB application version
   - Deploy with rolling updates (blue-green)
   - Wait for deployment completion

4. **smoke-tests**
   - Validate HTTP 200 on home page
   - Test BP calculation endpoint
   - Check CloudWatch logs

5. **performance-tests**
   - k6 load testing (0→50 concurrent users)
   - Quality gates: p95<500ms, error rate<1%
   - Custom metrics: pageLoadTime, calculationTime

6. **security-tests**
   - OWASP ZAP baseline scan
   - Check for XSS, injection, CSRF vulnerabilities
   - Fail on high-risk vulnerabilities

7. **approve-production**
   - Manual approval gate (GitHub Environments)
   - Only for production deployments
   - Shows deployment summary before approval

**Quality Gates:**
- ✅ All 62 tests must pass
- ✅ Infrastructure deployment successful
- ✅ Smoke tests pass (HTTP 200)
- ✅ Performance: p95 < 500ms
- ✅ Security: 0 high-risk vulnerabilities
- ✅ Manual approval for production

**Artifacts:**
- Deployment package (.zip)
- Performance test results
- Security scan report

**Live Environments:**
- Staging: http://bp-calculator-staging.eba-i4p69s48.eu-west-1.elasticbeanstalk.com
- Production: http://bp-calculator-prod.eba-3mgpqk3d.eu-west-1.elasticbeanstalk.com

See [CD_README.md](./CD_README.md) for detailed documentation.

## 🚀 Usage

### Automatic Triggers
Workflows run automatically on:
- Every commit to `main` or `develop`
- Every pull request to these branches

### Manual Trigger
```bash
# Via GitHub UI: Actions → CI - Build and Test → Run workflow
# Or via GitHub CLI:
gh workflow run ci.yml
```

### Local Testing
Before pushing, test locally:
```bash
# Restore and build
dotnet restore
dotnet build --configuration Release

# Run tests
dotnet test --verbosity normal

# Check coverage
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura

# Check for vulnerabilities
dotnet list package --vulnerable --include-transitive

# Check code formatting
dotnet format --verify-no-changes
```

## 📊 Viewing Results

### In GitHub Actions UI
1. Go to repository → Actions tab
2. Click on a workflow run
3. View job details, logs, and artifacts

### Pull Request Comments
CI automatically comments on PRs with:
- Test results summary
- Code coverage percentage
- Link to detailed coverage report

### Artifacts
Download from workflow run page:
- `test-results`: Test execution results
- `coverage-report`: HTML coverage report
- `vulnerability-report`: Security scan results

## 🔧 Configuration

### Environment Variables (ci.yml)
- `DOTNET_VERSION`: .NET SDK version (8.0.x)
- `SOLUTION_PATH`: Path to .sln file
- `TEST_PROJECT_PATH`: Path to test project
- `COVERAGE_THRESHOLD`: Minimum coverage % (80)

### Modifying Workflows
Edit `.github/workflows/ci.yml` and commit changes. Workflows update automatically.

## 🐛 Troubleshooting

### CI Fails on Tests
- Check test output in workflow logs
- Run tests locally: `dotnet test --verbosity normal`
- Verify all 62 tests pass locally (36 unit + 26 BDD)

### Coverage Below Threshold
- Check which files have low coverage
- Add more unit tests for uncovered code
- View detailed report in coverage-report artifact

### Security Vulnerabilities Detected
- Review vulnerability-report artifact
- Update affected packages: `dotnet add package <PackageName> --version <SafeVersion>`
- Check transitive dependencies: `dotnet list package --include-transitive`

### Code Quality Issues
- Run `dotnet format` locally to fix formatting
- Review build warnings: `dotnet build`
- Fix warnings before committing

## 📝 Best Practices

1. **Always run tests locally** before pushing
2. **Keep coverage above 80%** for all new code
3. **Address security vulnerabilities** immediately
4. **Fix build warnings** to maintain code quality
5. **Review CI results** before merging PRs

## 🔗 Related Documentation

- [EXECUTION_PLAN.md](../../EXECUTION_PLAN.md) - Project execution plan
- [README.md](../../README.md) - Project overview
- [infra/README.md](../../infra/README.md) - Infrastructure documentation
