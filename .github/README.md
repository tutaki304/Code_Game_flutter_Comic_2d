# .github Configuration

Thư mục này chứa cấu hình GitHub để đảm bảo code quality và tuân thủ Clean Architecture cho Memory Match Game.

## 📁 Structure

```
.github/
├── workflows/                 # GitHub Actions workflows
│   ├── flutter_ci.yml         # Main CI/CD pipeline
│   └── architecture_check.yml # Architecture compliance check
├── ISSUE_TEMPLATE/             # Issue templates
│   ├── bug_report.yml         # Bug report template
│   └── feature_request.yml    # Feature request template
├── scripts/                   # Helper scripts
│   └── check_structure.sh     # Project structure validation
├── pull_request_template.md   # PR template
├── CONTRIBUTING.md            # Contribution guidelines
├── CODE_QUALITY_GUIDELINES.md # Code quality standards
├── SECURITY.md                # Security policy
└── README.md                  # This file
```

## 🚀 Workflows

### Flutter CI/CD (`flutter_ci.yml`)

-   **Triggers**: Push to main/develop branches, PRs
-   **Jobs**:
    -   Code quality check (format, analyze, test)
    -   Project structure validation
    -   Android APK build
    -   iOS build (no codesign)
-   **Features**:
    -   Code coverage reporting
    -   Artifact uploads
    -   Multi-platform builds

### Architecture Check (`architecture_check.yml`)

-   **Triggers**: PRs affecting lib/ or test/
-   **Validations**:
    -   Clean Architecture compliance
    -   Domain layer purity (no Flutter imports)
    -   File naming conventions
    -   Forbidden patterns check
    -   Test organization

## 📋 Templates

### Pull Request Template

Đảm bảo PRs contain:

-   ✅ Change description
-   ✅ Architecture compliance checklist
-   ✅ Testing information
-   ✅ Code quality verification
-   ✅ Device testing status
-   ✅ Screenshots/GIFs

### Issue Templates

-   **Bug Report**: Structured bug reporting với device info, reproduction steps
-   **Feature Request**: Detailed feature proposals với user stories, acceptance criteria

## 🛠️ Scripts

### Structure Check (`check_structure.sh`)

Validates project structure:

-   Required directories (core/, data/, domain/, presentation/, services/)
-   File naming conventions (snake_case)
-   Clean architecture violations
-   Forbidden patterns (print statements, hardcoded strings)

## 📚 Documentation

### Contributing Guidelines (`CONTRIBUTING.md`)

-   Development workflow
-   Architecture overview
-   Testing requirements
-   Code review process
-   Security guidelines

### Code Quality Guidelines (`CODE_QUALITY_GUIDELINES.md`)

-   Architecture rules
-   Coding standards
-   Performance guidelines
-   Security best practices
-   Development tools

### Security Policy (`SECURITY.md`)

-   Vulnerability reporting process
-   Security best practices
-   Incident response procedures
-   Contact information

## 🔧 Usage

### For Developers

1. **Before coding**: Đọc `CONTRIBUTING.md` và `CODE_QUALITY_GUIDELINES.md`
2. **Creating PR**: Sử dụng PR template, đảm bảo pass tất cả checks
3. **Reporting bugs**: Sử dụng bug report template
4. **Requesting features**: Sử dụng feature request template

### For Maintainers

1. **Code review**: Follow checklist trong PR template
2. **Architecture validation**: Workflows tự động check compliance
3. **Security issues**: Follow process trong `SECURITY.md`
4. **Release management**: Use workflows cho automated building

## ⚙️ Configuration

### Required Secrets

Để workflows hoạt động properly, cần setup secrets sau trong GitHub repository:

```
CODECOV_TOKEN          # For coverage reporting (optional)
ANDROID_KEYSTORE       # For Android signing (production)
ANDROID_KEY_ALIAS      # For Android signing (production)
ANDROID_KEY_PASSWORD   # For Android signing (production)
```

### Branch Protection Rules

Recommended settings:

-   Require PR reviews: ✅
-   Require status checks: ✅
-   Require branches to be up to date: ✅
-   Include administrators: ✅
-   Allow force pushes: ❌
-   Allow deletions: ❌

### Required Status Checks

-   `code_quality` job từ Flutter CI
-   `architecture_check` job từ Architecture Check

## 🎯 Benefits

### Code Quality

-   ✅ Automated code formatting và linting
-   ✅ Architecture compliance checking
-   ✅ Test coverage monitoring
-   ✅ Security vulnerability scanning

### Development Experience

-   ✅ Clear contribution guidelines
-   ✅ Structured issue reporting
-   ✅ Comprehensive PR templates
-   ✅ Automated builds và testing

### Project Maintenance

-   ✅ Consistent code quality
-   ✅ Clear documentation
-   ✅ Security-first approach
-   ✅ Scalable architecture

## 🔄 Maintenance

### Regular Updates

-   Update Flutter version trong workflows
-   Review và update lint rules
-   Update dependency versions
-   Refresh documentation

### Monitoring

-   Check workflow success rates
-   Monitor code quality metrics
-   Review security scan results
-   Track contributor feedback

---

## 📞 Support

Nếu có questions về GitHub configuration:

1. Check existing documentation
2. Create issue với `question` label
3. Contact maintainers

**Last Updated**: December 2024
