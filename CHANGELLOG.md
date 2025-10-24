# Changelog

All notable changes to AlertGrams will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Complete AlertGrams Telegram Alert Service** - Initial implementation of portable POSIX shell-based alert system
- **Core alert script (`alert.sh`)** - Main alert sender with emoji support, multiple alert levels, and Markdown formatting
- **Enhanced installation system (`install.sh`)** - Comprehensive setup script with interactive and silent modes
- **System-wide installation support** - Install to `/usr/local/bin` and `/etc/alertgrams` with proper permissions
- **Systemd service integration** - Automatic service creation and management for production deployments
- **Service user creation** - Dedicated user account for secure service operation
- **Configuration validation** - Real-time validation of Telegram bot tokens and chat IDs with format checking
- **Backup functionality** - Automatic backup of existing configurations during updates
- **Multiple installation modes**:
  - Interactive installation with step-by-step guidance
  - Silent installation for automation
  - Configuration-only setup
  - System-wide deployment
  - Service setup with systemd integration
- **Comprehensive command-line options**:
  - `--help` - Complete usage documentation
  - `--show-config` - Display current configuration status
  - `--check-config` - Validate configuration without changes
  - `--configure` - Interactive configuration setup
  - `--test-only` - Test existing configuration
  - `--system` - System-wide installation
  - `--service` - Systemd service setup
  - `--silent` - Automated installation mode
- **Enhanced user experience**:
  - Color-coded output for better readability
  - Progress indicators and status messages
  - Clear error messages with troubleshooting guidance
  - Step-by-step credential setup with BotFather and userinfobot instructions
- **Security features**:
  - Secure file permissions (755 for scripts, 600 for configurations)
  - API key masking in display output
  - Service user isolation for production deployments
- **Cross-platform compatibility** - Support for Debian, Ubuntu, Alpine, BusyBox, OpenWRT, Raspberry Pi OS, CentOS/RHEL, and macOS
- **Comprehensive documentation**:
  - `README.md` - Project overview and quick start guide
  - `INSTALL.md` - Detailed installation instructions and troubleshooting
  - `SECURITY.md` - Security guidelines and best practices
  - `DOCUMENTATION.md` - Documentation navigation hub
  - `CONTRIBUTING.md` - Development and contribution guidelines
  - `.gitignore` - Proper exclusions for sensitive files

### Enhanced
- **Installation script reliability** - Fixed Windows line ending compatibility issues
- **Configuration flow improvements** - Clear separation between mandatory and optional settings
- **Input validation** - Enhanced format checking for Telegram credentials
- **Error handling** - Comprehensive error messages and recovery guidance
- **Output management** - Proper separation of user interaction and configuration file generation
- **Optional settings handling** - User-friendly flow with clear choices for default values

### Fixed
- **Configuration file corruption** - Resolved issue where prompts and validation messages were mixed into `.env` file content
- **Windows line endings compatibility** - Added automatic handling of `\r\n` line endings in configuration files
- **Input/output separation** - Fixed stdout/stderr redirection to prevent prompt contamination in configuration values
- **Color code handling** - Prevented ANSI color codes from being saved in configuration files
- **Validation logic** - Corrected placeholder value detection for proper configuration status reporting

### Security
- **Token protection** - Implemented secure storage and display of API credentials
- **File permissions** - Automatic setting of appropriate permissions for all files
- **Service isolation** - Created dedicated service user for production deployments
- **Configuration backup** - Secure backup of sensitive configuration files
- **Input sanitization** - Proper validation and sanitization of user inputs

### Technical Improvements
- **POSIX compliance** - 100% portable shell script implementation using `/bin/sh`
- **Dependency management** - Smart detection and fallback for HTTP clients (curl/wget)
- **Error codes** - Proper exit codes for different failure scenarios
- **Logging support** - Optional file logging with configurable paths
- **URL encoding** - Safe message transmission with proper encoding
- **Message truncation** - Automatic handling of Telegram message length limits

### Documentation
- **Comprehensive installation guide** - Step-by-step instructions for all supported platforms
- **Security documentation** - Complete security considerations and deployment guidelines  
- **Troubleshooting guide** - Common issues and solutions
- **API reference** - Complete documentation of all configuration options and command-line arguments
- **Integration examples** - Sample configurations for various deployment scenarios

### Infrastructure
- **Project structure** - Organized file layout following POSIX shell project standards
- **Development guidelines** - Coding standards and contribution workflow
- **License** - MIT license for open-source distribution
- **Version control** - Proper `.gitignore` and repository structure

## [1.0.0] - 2024-10-25

### Added
- Initial release of AlertGrams Telegram Alert Service
- Complete POSIX-compliant implementation
- Production-ready installation and deployment system
- Comprehensive documentation and security guidelines

---

**Note**: This project follows [POSIX shell standards](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html) and is designed for maximum compatibility across UNIX-like systems.