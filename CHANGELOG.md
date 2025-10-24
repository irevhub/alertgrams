# Changelog

All notable changes to the AlertGrams project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-10-19

### Added
- **System Monitoring Service**: Complete monitoring infrastructure with three deployment modes
  - **Service Mode**: Continuous background monitoring via systemd service
  - **Cron Mode**: Periodic monitoring checks via cron jobs
  - **Manual Mode**: On-demand monitoring tools and interactive menu
- **alertgrams-monitor.sh**: Comprehensive monitoring daemon with:
  - System resource monitoring (CPU, memory, disk usage)
  - Service status monitoring with configurable service list
  - Network connectivity checks (internet and Telegram API)
  - Security event monitoring (failed logins, system changes)
  - Signal handling for graceful shutdown and configuration reload
  - Test mode for validation and debugging
  - Configuration loading from multiple locations
- **alertgrams-cron.sh**: Periodic monitoring script with four check levels:
  - Critical checks (every 5 minutes): CPU/memory/disk critical thresholds
  - Service checks (every 15 minutes): Monitored service status
  - Health checks (hourly): System health summary with load average
  - Daily summary (9 AM): Complete system status report
- **alertgrams-manual.sh**: Interactive monitoring tools with:
  - Quick status check for immediate system overview
  - Comprehensive system report with detailed metrics
  - Test alert functionality
  - Interactive menu system for easy navigation
  - Custom alert sending capability

### Enhanced
- **Installation System**: Major upgrade to support monitoring infrastructure
  - Interactive monitoring mode selection during installation
  - Automatic systemd service creation and management
  - Cron job configuration with proper permissions
  - Manual tool installation with convenient shortcuts
  - Enhanced error handling and user feedback
- **Configuration Management**: Improved environment variable handling
  - Support for multiple configuration file locations
  - Better validation of monitoring-specific settings
  - Secure file permissions for monitoring components

### Improved
- **Documentation**: Enhanced installation and usage documentation
- **Error Handling**: Better error messages and recovery procedures
- **Security**: Improved systemd service security settings
- **Portability**: Maintained POSIX compliance across all new components

### Technical Details
- **Monitoring Thresholds**: Configurable alert thresholds for all metrics
- **Service Integration**: Full systemd integration with proper lifecycle management
- **Cron Integration**: System-wide cron jobs with error suppression
- **Signal Handling**: Proper UNIX signal handling in monitoring daemon
- **Resource Management**: Efficient system resource usage monitoring
- **Network Monitoring**: Connectivity validation for critical services

## [1.0.0] - 2024-10-19

### Added
- **Core AlertGrams System**: Complete Telegram alert service implementation
  - POSIX-compliant shell scripting for maximum compatibility
  - Support for INFO, WARNING, and CRITICAL alert levels
  - Emoji-enhanced message formatting
  - URL encoding for proper Telegram API integration
- **alert.sh**: Main alert sending script with:
  - Configuration loading from .env files
  - Fallback support for curl and wget
  - Proper error handling and logging
  - Message formatting with timestamps and hostname
- **Comprehensive Installation System**: Full-featured installer script
  - Interactive configuration setup with validation
  - System requirement checking
  - Telegram bot token and chat ID validation
  - Optional settings with user-friendly defaults
  - Automatic permission setting
  - Test alert functionality
- **Configuration Management**: Robust .env file handling
  - Interactive configuration wizard
  - Input validation and sanitization
  - Windows line ending compatibility
  - Secure file permissions
- **Documentation**: Complete setup and usage documentation
  - Installation instructions
  - Configuration examples
  - Usage examples and best practices
  - Troubleshooting guide

### Features
- **Zero Dependencies**: Uses only system default tools (sh, curl/wget, printf, date)
- **Universal Compatibility**: Works on Debian, Ubuntu, Alpine, BusyBox, OpenWRT, Raspberry Pi OS
- **Security**: Proper file permissions and input validation
- **Reliability**: Comprehensive error handling and fallback mechanisms
- **Usability**: Interactive installation with clear user guidance

### Technical Implementation
- **POSIX Compliance**: Strict adherence to POSIX shell standards
- **Error Handling**: Comprehensive error checking with meaningful messages
- **Configuration**: Environment-based configuration with validation
- **Logging**: Structured logging with appropriate output streams
- **Testing**: Built-in configuration testing and validation

---

## Version History Summary

- **v1.1.0**: Added comprehensive monitoring system with three deployment modes
- **v1.0.0**: Initial release with core alert functionality and installation system

## Future Roadmap

- Web dashboard for monitoring status
- Additional alert channels (email, SMS)
- Advanced monitoring rules and thresholds
- Monitoring data persistence and reporting

- Integration with popular monitoring tools
