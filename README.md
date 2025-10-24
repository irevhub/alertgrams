# AlertGrams 📨 v1.1.1

**Portable Telegram Alert Service with Real-time Syslog Monitoring for Linux/UNIX Systems**

AlertGrams is a lightweight, POSIX-compliant shell script that sends alerts to Telegram without requiring any external dependencies beyond what's already available on most Linux/UNIX systems.

[![POSIX Compliant](https://img.shields.io/badge/POSIX-compliant-green.svg)](https://pubs.opengroup.org/onlinepubs/9699919799/)
[![Shell](https://img.shields.io/badge/shell-sh-blue.svg)](https://en.wikipedia.org/wiki/Bourne_shell)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

### Core Alert System
- **100% Portable**: Works on any POSIX-compliant system
- **Zero Dependencies**: Uses only system default tools (`sh`, `curl`/`wget`, `printf`, `date`)
- **Universal Compatibility**: Tested on Debian, Ubuntu, Alpine, BusyBox, OpenWRT, and Raspberry Pi OS
- **Secure Configuration**: Environment-based configuration with secure file permissions
- **Rich Formatting**: Supports different alert levels with appropriate emojis
- **Logging Support**: Optional file logging for alert history
- **Easy Installation**: Simple setup script included

### System Monitoring (v1.1.0+)
- **Service Mode**: Continuous background monitoring via systemd service
- **Cron Mode**: Periodic monitoring checks via scheduled cron jobs
- **Manual Mode**: On-demand monitoring tools with interactive menu
- **Resource Monitoring**: CPU, memory, and disk usage tracking
- **Service Monitoring**: Configurable service status checking
- **Network Monitoring**: Internet and Telegram API connectivity validation
- **Security Monitoring**: Failed login attempts and system changes detection

### Real-time Syslog Monitoring (v1.1.1+)
- **Immediate Alerts**: Real-time `/var/log/syslog` monitoring with instant notifications
- **Pattern Detection**: Advanced pattern matching for critical, security, and error events
- **Position Tracking**: Efficient log file monitoring with rotation support
- **Configurable Patterns**: Customizable alert patterns for different system events
- **Multi-mode Integration**: Available in Service, Cron, and Manual monitoring modes
- **Critical Events**: Kernel panics, memory issues, system crashes immediate alerts
- **Security Events**: Authentication failures, brute force detection, unauthorized access
- **Error Events**: Service failures, timeouts, connection issues monitoring

## 🚀 Quick Start

### 1. Download and Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/alertgrams.git
cd alertgrams

# Run the installation script
chmod +x install.sh
./install.sh
```

> 📖 **For detailed installation instructions**, see [INSTALL.md](INSTALL.md)

### 2. Configure Telegram Bot

1. **Create a Bot**:
   - Start a chat with [@BotFather](https://t.me/BotFather) on Telegram
   - Send `/newbot` and follow the instructions
   - Copy the API token provided

2. **Get Your Chat ID**:
   - Send a message to [@userinfobot](https://t.me/userinfobot)
   - Copy the ID number (including negative sign if present)

3. **Configure AlertGrams**:
   ```bash
   # Copy the example configuration
   cp .env.example .env
   
   # Edit with your values
   nano .env  # or use your preferred editor
   ```

### 3. Send Your First Alert

```bash
./alert.sh "INFO" "AlertGrams is working!"
```

## 📋 Usage

### Basic Syntax

```bash
./alert.sh "<LEVEL>" "<MESSAGE>"
```

### Alert Levels

| Level | Emoji | Description |
|-------|-------|-------------|
| `INFO` | ✅ | General information |
| `WARNING` | ⚠️ | Warning conditions |
| `CRITICAL` | 🚨 | Critical errors |
| `SUCCESS` | 🎉 | Success notifications |
| `DEBUG` | 🔍 | Debug information |
| `ERROR` | 🚨 | Error conditions |

### Examples

```bash
# System monitoring
./alert.sh "INFO" "System started successfully"
./alert.sh "WARNING" "Disk usage is at 85%"
./alert.sh "CRITICAL" "Database connection failed"
./alert.sh "SUCCESS" "Backup completed successfully"

# With system information
./alert.sh "WARNING" "High CPU usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"

# Disk space monitoring
df -h / | awk 'NR==2 {if($5+0 > 80) system("./alert.sh WARNING \"Disk usage: " $5 " on " $1 "\"")}'
```

> 🆕 **New in v1.1.1**: Real-time syslog monitoring with immediate alerts for critical system events, security incidents, and service failures. See [Syslog Monitoring](#-syslog-monitoring-v111) section below.

### Help and Options

```bash
./alert.sh --help    # Show help information
./alert.sh -h        # Show help information
```

## 📊 System Monitoring (v1.1.0+)

AlertGrams now includes comprehensive system monitoring capabilities with three deployment modes:

### Monitoring Modes

#### 🔄 Service Mode (Recommended)
Continuous background monitoring via systemd service.

```bash
# Enable during installation or run:
sudo systemctl start alertgrams-monitor
sudo systemctl enable alertgrams-monitor

# Check service status
sudo systemctl status alertgrams-monitor
```

**Features:**
- Real-time system resource monitoring
- Real-time syslog monitoring with immediate alerts
- Configurable alert thresholds
- Service status monitoring
- Network connectivity checks
- Security event detection
- Graceful shutdown and reload

#### ⏰ Cron Mode
Periodic monitoring checks via scheduled cron jobs.

```bash
# Cron jobs are automatically created:
*/2 * * * * root cd /usr/local/bin && ./alertgrams-cron.sh syslog    # Every 2 minutes
*/5 * * * * root cd /usr/local/bin && ./alertgrams-cron.sh critical  # Every 5 minutes
*/15 * * * * root cd /usr/local/bin && ./alertgrams-cron.sh service  # Every 15 minutes
0 * * * * root cd /usr/local/bin && ./alertgrams-cron.sh health      # Every hour
0 9 * * * root cd /usr/local/bin && ./alertgrams-cron.sh daily       # 9 AM daily
```

**Features:**
- Syslog monitoring every 2 minutes (immediate alerts)
- Critical checks every 5 minutes
- Service checks every 15 minutes
- Health summaries every hour
- Daily status reports at 9 AM

#### 🔧 Manual Mode
On-demand monitoring tools with interactive menu.

```bash
# Run manual monitoring tools
alertgrams-manual.sh          # Interactive menu
alertgrams-manual.sh status   # Quick status check
alertgrams-manual.sh report   # Full system report
alertgrams-manual.sh syslog   # Syslog analysis
alertgrams-manual.sh test     # Test alert functionality

# Dedicated syslog monitoring
alertgrams-syslog monitor     # Real-time monitoring
alertgrams-syslog analyze 50  # Analyze recent entries

# Or use the convenient aliases
alertgrams-check              # Manual monitoring menu
alertgrams-syslog             # Syslog monitoring
```

**Features:**
- Interactive monitoring menu
- Quick system status checks
- Comprehensive system reports
- Real-time syslog analysis and monitoring
- Alert testing tools
- Custom alert sending

### Monitoring Configuration

Add these variables to your `.env` file for enhanced monitoring:

```bash
# System Monitoring Settings (Optional)
MONITOR_SERVICES="nginx apache2 mysql postgresql ssh"  # Services to monitor
CPU_THRESHOLD=90                                       # CPU alert threshold (%)
MEMORY_THRESHOLD=90                                    # Memory alert threshold (%)
DISK_THRESHOLD=90                                     # Disk alert threshold (%)
MONITOR_INTERVAL=300                                  # Service monitoring interval (seconds)

# Syslog Monitoring Settings (v1.1.1+)
SYSLOG_FILE="/var/log/syslog"                         # Syslog file location
SYSLOG_CHECK_INTERVAL=30                              # Check interval (seconds)
SYSLOG_CRITICAL_PATTERNS="kernel panic|out of memory|segmentation fault|critical error|system crash|hardware error"
SYSLOG_ERROR_PATTERNS="error|failed|failure|denied|rejected|timeout|unreachable"
SYSLOG_SECURITY_PATTERNS="authentication failure|invalid user|failed password|brute force|intrusion|unauthorized"
```

### Monitoring Examples

```bash
# Manual system check
./alertgrams-manual.sh status

# Test monitoring alerts
./alertgrams-manual.sh test

# Check specific system health
./alertgrams-cron.sh health

# Monitor custom services
MONITOR_SERVICES="docker redis mongodb" ./alertgrams-monitor.sh --test

# Syslog monitoring examples (v1.1.1+)
./alertgrams-syslog.sh monitor          # Real-time syslog monitoring
./alertgrams-syslog.sh analyze 50       # Analyze last 50 syslog entries
./alertgrams-manual.sh syslog 100       # Manual syslog analysis via menu
alertgrams-syslog test                   # Test syslog pattern matching
```

## 🔍 Syslog Monitoring (v1.1.1+)

Real-time monitoring of `/var/log/syslog` for immediate admin notifications on critical system events.

### Quick Start

```bash
# Real-time monitoring (continuous)
alertgrams-syslog monitor

# Analyze recent entries
alertgrams-syslog analyze 50

# Test pattern matching
alertgrams-syslog test

# Show current configuration
alertgrams-syslog config
```

### Alert Types

#### 🚨 Critical Alerts (Immediate)
- Kernel panics and system crashes
- Out of memory conditions
- Segmentation faults
- Hardware errors

#### 🔒 Security Alerts (Immediate)  
- Authentication failures
- Invalid user login attempts
- Brute force detection
- Unauthorized access attempts

#### ❌ Error Alerts
- Service start/stop failures
- Network timeouts and connection issues
- Permission denied errors
- System resource unavailability

### Example Alerts

```
🔍 SYSLOG CRITICAL: Oct 25 10:30:15 - kernel: Out of memory: Kill process 1234
🔒 SYSLOG SECURITY: Oct 25 10:32:10 - sshd[5678]: Failed password for invalid user admin
❌ SYSLOG ERROR: Oct 25 10:34:15 - systemd: Service nginx.service failed to start
```

### Advanced Usage

```bash
# Custom syslog file
SYSLOG_FILE=/var/log/messages alertgrams-syslog monitor

# Custom check interval (15 seconds)
SYSLOG_CHECK_INTERVAL=15 alertgrams-syslog monitor

# Background monitoring with logging
nohup alertgrams-syslog monitor > /var/log/alertgrams-syslog.log 2>&1 &
```

## ⚙️ Configuration

### Environment Variables

Edit your `.env` file with the following settings:

```bash
# Required Settings
TELEGRAM_API_KEY=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here

# Optional Settings
LOG_FILE=alerts.log                    # Enable logging (optional)
MAX_MESSAGE_LENGTH=4096               # Message length limit
```

### Configuration Examples

#### System Monitoring Setup
```bash
TELEGRAM_API_KEY=123456789:ABCdefGHIjklMNOpqrSTUvwxyz
TELEGRAM_CHAT_ID=-1001234567890
LOG_FILE=/var/log/system-alerts.log
MAX_MESSAGE_LENGTH=2048
```

#### Application Monitoring Setup
```bash
TELEGRAM_API_KEY=123456789:ABCdefGHIjklMNOpqrSTUvwxyz
TELEGRAM_CHAT_ID=123456789
LOG_FILE=./app-alerts.log
MAX_MESSAGE_LENGTH=4096
```

#### Minimal Setup (No Logging)
```bash
TELEGRAM_API_KEY=123456789:ABCdefGHIjklMNOpqrSTUvwxyz
TELEGRAM_CHAT_ID=123456789
LOG_FILE=
MAX_MESSAGE_LENGTH=4096
```

## 🔧 Integration Examples

### Cron Jobs

```bash
# System health check every 15 minutes
*/15 * * * * /path/to/alertgrams/alert.sh "INFO" "System check - $(date)"

# Daily disk space check
0 9 * * * df -h | grep -E '8[0-9]%|9[0-9]%|100%' && /path/to/alertgrams/alert.sh "WARNING" "High disk usage detected"

# Weekly system update notification
0 10 * * 1 /path/to/alertgrams/alert.sh "INFO" "Weekly system maintenance window"
```

### Log Monitoring

```bash
# Monitor error logs
tail -f /var/log/syslog | grep -i error | while read line; do
    ./alert.sh "ERROR" "System error: $line"
done

# Monitor application logs
tail -f /var/log/myapp.log | grep -i "fatal\|critical" | while read line; do
    ./alert.sh "CRITICAL" "Application error: $line"
done
```

### System Monitoring Scripts

```bash
#!/bin/sh
# System monitoring script

# Check disk space
disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 80 ]; then
    ./alert.sh "WARNING" "Disk usage: ${disk_usage}%"
fi

# Check memory usage
mem_usage=$(free | awk 'NR==2 {printf "%.0f", $3/$2*100}')
if [ "$mem_usage" -gt 90 ]; then
    ./alert.sh "CRITICAL" "Memory usage: ${mem_usage}%"
fi

# Check system load
load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
if [ "$(echo "$load_avg > 2.0" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
    ./alert.sh "WARNING" "High system load: $load_avg"
fi
```

### Docker Container Monitoring

```bash
#!/bin/sh
# Docker monitoring script

# Check if container is running
container_name="myapp"
if ! docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
    ./alert.sh "CRITICAL" "Container $container_name is not running"
fi

# Check container resource usage
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | while read line; do
    if echo "$line" | grep -q "%"; then
        cpu=$(echo "$line" | awk '{print $2}' | sed 's/%//')
        if [ "${cpu%.*}" -gt 80 ]; then
            container=$(echo "$line" | awk '{print $1}')
            ./alert.sh "WARNING" "High CPU usage in container $container: ${cpu}%"
        fi
    fi
done
```

## 🔒 Security

### File Permissions

The installation script automatically sets secure permissions:

```bash
chmod +x alert.sh     # Make script executable
chmod 600 .env        # Secure configuration file
```

### Best Practices

1. **Keep your `.env` file secure**:
   - Never commit it to version control
   - Restrict read access to owner only
   - Store in a secure location

2. **Use dedicated bot tokens**:
   - Create separate bots for different environments
   - Rotate tokens periodically
   - Limit bot permissions

3. **Monitor logs**:
   - Enable logging to track alert history
   - Monitor for unusual activity
   - Rotate log files regularly

## 📊 System Requirements

### Minimum Requirements

- **Shell**: POSIX-compliant shell (`/bin/sh`)
- **HTTP Client**: `curl` or `wget`
- **Core Tools**: `printf`, `date`, `hostname`, `sed`, `cut`

### Tested Platforms

| Platform | Version | Status |
|----------|---------|--------|
| Debian | 10, 11, 12 | ✅ Tested |
| Ubuntu | 18.04, 20.04, 22.04 | ✅ Tested |
| Alpine Linux | 3.14+ | ✅ Tested |
| BusyBox | 1.30+ | ✅ Tested |
| OpenWRT | 21.02+ | ✅ Tested |
| Raspberry Pi OS | Buster, Bullseye | ✅ Tested |
| CentOS/RHEL | 7, 8, 9 | ✅ Tested |
| macOS | 10.15+ | ✅ Tested |

## 🛠️ Troubleshooting

> 📖 **For comprehensive installation troubleshooting**, see [INSTALL.md](INSTALL.md#-troubleshooting)

### Common Issues

#### 1. "Neither curl nor wget is available"

**Solution**: Install curl or wget
```bash
# Debian/Ubuntu
sudo apt-get install curl

# Alpine
apk add curl

# CentOS/RHEL
sudo yum install curl
```

#### 2. "Error: TELEGRAM_API_KEY is required"

**Solution**: Check your `.env` file
```bash
# Verify .env file exists and has correct format
cat .env

# Check file permissions
ls -la .env
```

#### 3. "Failed to send alert to Telegram"

**Solution**: Verify your configuration
```bash
# Test your bot token and chat ID manually
curl -s "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/sendMessage?chat_id=<YOUR_CHAT_ID>&text=Test"
```

#### 4. Permission denied errors

**Solution**: Check file permissions
```bash
chmod +x alert.sh
chmod 600 .env
```

### Debug Mode

Enable verbose output for troubleshooting:

```bash
# Add debug flag to see detailed execution
sh -x ./alert.sh "INFO" "Debug test message"
```

### Log Analysis

If logging is enabled, check the log file:

```bash
# View recent alerts
tail -f alerts.log

# Search for errors
grep -i error alerts.log

# Count alerts by level
grep -o '\[.*\]' alerts.log | sort | uniq -c
```

## 📚 Documentation

### Comprehensive Guides

- **[INSTALL.md](INSTALL.md)** - Detailed installation instructions
- **[SYSLOG-MONITORING.md](SYSLOG-MONITORING.md)** - Complete syslog monitoring setup guide
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and feature updates
- **[SECURITY.md](SECURITY.md)** - Security best practices and considerations

### Configuration Examples

- **[.env.example](.env.example)** - Sample configuration file
- **Service Mode**: Continuous monitoring with systemd integration
- **Cron Mode**: Scheduled monitoring with automatic alerts
- **Manual Mode**: On-demand monitoring tools and analysis

### API Reference

- **Alert Levels**: `INFO`, `WARNING`, `ERROR`, `CRITICAL`
- **Monitoring Modes**: Service, Cron, Manual deployment options
- **Syslog Patterns**: Configurable pattern matching for different event types
- **Environment Variables**: Complete configuration reference

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/alertgrams.git
cd alertgrams

# Create a test environment
cp .env.example .env.test
# Edit .env.test with test credentials

# Run tests
./test.sh
```

### Code Style

- Follow POSIX shell standards
- Use `shellcheck` for linting
- Include comprehensive comments
- Follow the existing naming conventions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [@BotFather](https://t.me/BotFather) for Telegram bot creation
- [@userinfobot](https://t.me/userinfobot) for chat ID discovery
- The POSIX standards committee for shell compatibility
- All contributors and users of AlertGrams

## 📞 Support

- **Installation Guide**: [INSTALL.md](INSTALL.md) - Detailed installation instructions
- **Security Policy**: [SECURITY.md](SECURITY.md) - Security guidelines and best practices
- **Issues**: [GitHub Issues](https://github.com/irev/alertgrams/issues)
- **Discussions**: [GitHub Discussions](https://github.com/irev/alertgrams/discussions)

---

**Made with ❤️ for the sysadmin community**