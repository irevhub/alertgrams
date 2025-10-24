# Changelog

All notable changes to the AlertGrams project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.1] - 2025-10-25

### Added
- **Syslog Real-time Monitoring**: Comprehensive /var/log/syslog monitoring system
  - **alertgrams-syslog.sh**: Dedicated syslog monitoring daemon with:
    - Real-time log file monitoring with position tracking
    - Configurable pattern matching for different alert levels
    - Critical patterns: kernel panic, out of memory, system crashes
    - Security patterns: authentication failures, brute force attempts
    - Error patterns: service failures, timeouts, access denied
    - Immediate alert sending for critical system events
    - Log rotation handling and position recovery
    - Test mode for pattern validation
  - **Integrated Monitoring**: Syslog checks added to all monitoring modes:
    - Service mode: Continuous syslog monitoring in background daemon
    - Cron mode: Syslog checks every 2 minutes for immediate alerts  
    - Manual mode: On-demand syslog analysis and pattern testing

### Enhanced
- **Monitoring Infrastructure**: Extended all monitoring components for syslog support
  - Enhanced alertgrams-monitor.sh with real-time syslog checking
  - Updated alertgrams-cron.sh with frequent syslog monitoring
  - Improved installation system to deploy syslog monitoring components
  - Added convenient 'alertgrams-syslog' command alias for easy access

### Improved
- **Alert Response Time**: Reduced response time for critical system events
  - Syslog monitoring every 2 minutes in cron mode (vs 5-15 minutes for other checks)
  - Immediate processing of critical patterns (kernel panic, memory issues)
  - Real-time security event detection (failed logins, unauthorized access)
- **Configuration**: Added syslog-specific environment variables
  - SYSLOG_FILE: Custom syslog file location (default: /var/log/syslog)
  - SYSLOG_CRITICAL_PATTERNS: Configurable critical alert patterns
  - SYSLOG_ERROR_PATTERNS: Configurable error alert patterns  
  - SYSLOG_SECURITY_PATTERNS: Configurable security alert patterns
  - SYSLOG_CHECK_INTERVAL: Monitoring frequency control

### Technical Details
- **Pattern Matching**: Advanced regex-based pattern detection system
- **Position Tracking**: Efficient log file position tracking to avoid duplicate alerts
- **Log Rotation Support**: Automatic detection and handling of log file rotation
- **Resource Efficiency**: Minimal system impact with optimized file reading
- **Error Handling**: Robust error recovery and graceful degradation

## [1.1.0] - 2025-10-25

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

## [1.0.0] - 2024-12-19

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