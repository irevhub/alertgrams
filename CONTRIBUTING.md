# Contributing to AlertGrams

Thank you for your interest in contributing to AlertGrams! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Types of Contributions

We welcome various types of contributions:

- **Bug Reports** - Help us identify and fix issues
- **Feature Requests** - Suggest new functionality
- **Code Contributions** - Submit bug fixes and new features
- **Documentation** - Improve or add documentation
- **Testing** - Test on different platforms and report results
- **Examples** - Share real-world usage examples

## 🐛 Reporting Bugs

### Before Reporting
1. **Search existing issues** to avoid duplicates
2. **Test with latest version** to ensure the bug still exists
3. **Verify system requirements** are met
4. **Try troubleshooting steps** in documentation

### Bug Report Template
```markdown
**Bug Description**
A clear description of what the bug is.

**Environment**
- OS: [e.g., Ubuntu 20.04, Alpine Linux 3.14]
- Shell: [e.g., bash, dash, busybox sh]
- AlertGrams Version: [e.g., 1.0.0]
- HTTP Client: [e.g., curl 7.68.0, wget 1.20.3]

**Steps to Reproduce**
1. Go to '...'
2. Run command '...'
3. See error

**Expected Behavior**
What you expected to happen.

**Actual Behavior**
What actually happened.

**Error Output**
```
Paste any error messages here
```

**Additional Context**
Any other context about the problem.
```

## 💡 Suggesting Features

### Feature Request Guidelines
- **Check existing requests** first
- **Explain the use case** - why is this needed?
- **Provide examples** of how it would be used
- **Consider alternatives** - are there existing ways to achieve this?
- **Keep POSIX compliance** in mind

### Feature Request Template
```markdown
**Feature Summary**
Brief description of the feature.

**Use Case**
Describe the problem this feature would solve.

**Proposed Solution**
How you think this should work.

**Alternatives Considered**
Other ways to solve this problem.

**Additional Context**
Any other relevant information.
```

## 🔧 Code Contributions

### Development Setup

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone https://github.com/yourusername/alertgrams.git
   cd alertgrams
   ```
3. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Coding Standards

#### Shell Script Guidelines
- **POSIX Compliance**: Use only POSIX-compatible features
- **Shebang**: Always use `#!/bin/sh`
- **Safety**: Use `set -eu` for error handling
- **Quoting**: Always quote variables: `"$var"`
- **Testing**: Use `[ ]` instead of `[[ ]]`
- **Functions**: Define functions before use

#### Code Style
```bash
#!/bin/sh
set -eu

# Function names: lowercase with underscores
send_alert() {
    local message="$1"
    local level="${2:-INFO}"
    
    # Variable names: lower_snake_case for locals, UPPER_CASE for exports
    api_url="https://api.telegram.org/bot${TELEGRAM_API_KEY}/sendMessage"
    
    # Always quote variables
    if [ -n "$message" ]; then
        printf "Sending: %s\n" "$message"
    fi
}
```

#### Documentation Standards
- **Comment functions** with purpose and parameters
- **Explain complex logic** with inline comments
- **Use meaningful variable names**
- **Include usage examples** in script headers

#### Testing Requirements
- **Test on multiple platforms** (Debian, Alpine, BusyBox)
- **Verify POSIX compliance** with `shellcheck`
- **Test error conditions** and edge cases
- **Ensure backward compatibility**

### Pull Request Process

1. **Update documentation** if needed
2. **Add/update tests** for your changes
3. **Run linting tools**:
   ```bash
   # Check POSIX compliance
   shellcheck alert.sh install.sh
   
   # Test syntax
   sh -n alert.sh install.sh
   ```
4. **Test on multiple platforms** if possible
5. **Commit with descriptive messages**:
   ```bash
   git commit -m "feat: add support for custom emoji configuration"
   git commit -m "fix: handle empty log file path correctly"
   git commit -m "docs: update installation guide for Alpine Linux"
   ```

### Commit Message Format

Use conventional commits format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```bash
feat: add support for message templates
fix: resolve permission issues on Alpine Linux
docs: improve troubleshooting section
refactor: simplify configuration validation
test: add integration tests for BusyBox
chore: update GitHub Actions workflow
```

## 📖 Documentation Contributions

### Documentation Standards
- **Clear and concise** writing
- **Step-by-step instructions** for complex procedures
- **Code examples** with expected output
- **Cross-references** to related sections
- **Keep up-to-date** with code changes

### Documentation Structure
```
README.md        - Project overview and quick start
INSTALL.md       - Detailed installation guide
SECURITY.md      - Security guidelines
DOCUMENTATION.md - Documentation index
CONTRIBUTING.md  - This file
```

## 🧪 Testing

### Manual Testing
Test your changes on different platforms:

```bash
# Test installation
./install.sh --check-only

# Test configuration
./install.sh --config-only

# Test functionality
./alert.sh "INFO" "Test message"

# Test error handling
./alert.sh "" ""  # Should show error
```

### Platform Testing
Priority platforms for testing:
1. **Ubuntu/Debian** (most common)
2. **Alpine Linux** (minimal environment)
3. **BusyBox** (embedded systems)
4. **macOS** (BSD-style utilities)

### Automated Testing
We use GitHub Actions for:
- **Shellcheck** linting
- **Syntax validation**
- **Multi-platform testing**
- **Security scanning**

## 🏷️ Release Process

### Version Numbering
We use [Semantic Versioning](https://semver.org/):
- **Major** (1.0.0): Breaking changes
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.1.1): Bug fixes, backward compatible

### Release Checklist
- [ ] Update version numbers
- [ ] Update CHANGELOG.md
- [ ] Test on all supported platforms
- [ ] Update documentation
- [ ] Create release notes
- [ ] Tag release
- [ ] Update GitHub release

## 🌟 Recognition

Contributors are recognized in:
- **GitHub contributors** list
- **CHANGELOG.md** for significant contributions
- **README.md** acknowledgments

## 📋 Code of Conduct

### Our Standards
- **Be respectful** and inclusive
- **Welcome newcomers** and help them learn
- **Focus on constructive feedback**
- **Respect different opinions** and experiences
- **Show empathy** towards other community members

### Unacceptable Behavior
- Harassment or discrimination
- Trolling or insulting comments
- Personal attacks
- Publishing private information
- Spam or off-topic content

## 📞 Getting Help

### Development Questions
- **GitHub Discussions** for general questions
- **GitHub Issues** for specific problems
- **Code review comments** for implementation details

### Resources
- [POSIX Shell Specification](https://pubs.opengroup.org/onlinepubs/9699919799/)
- [ShellCheck](https://www.shellcheck.net/) for linting
- [Telegram Bot API](https://core.telegram.org/bots/api)

## 🎯 Project Goals

Keep these in mind when contributing:

### Core Principles
1. **POSIX Compliance** - Works everywhere
2. **Zero Dependencies** - Uses only system tools
3. **Security First** - Secure by default
4. **Simplicity** - Easy to understand and use
5. **Reliability** - Works consistently

### Non-Goals
- Complex message formatting (keep it simple)
- Multiple backends (Telegram only)
- GUI interfaces (command-line only)
- Heavy dependencies (shell script only)

## 🚀 Quick Contribution Workflow

```bash
# 1. Fork and clone
git clone https://github.com/yourusername/alertgrams.git
cd alertgrams

# 2. Create feature branch
git checkout -b feature/my-improvement

# 3. Make changes
# Edit files...

# 4. Test changes
./install.sh --check-only
shellcheck *.sh

# 5. Commit changes
git add .
git commit -m "feat: improve error handling"

# 6. Push and create PR
git push origin feature/my-improvement
# Create pull request on GitHub
```

## 🙏 Thank You

Every contribution, no matter how small, helps make AlertGrams better for everyone. We appreciate your time and effort!

---

**Happy contributing!** 🎉