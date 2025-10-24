# AlertGrams 📨

**Portable Telegram Alert Service for Linux/UNIX Systems**

AlertGrams is a lightweight, POSIX-compliant shell script that sends alerts to Telegram without requiring any external dependencies beyond what's already available on most Linux/UNIX systems.

[![POSIX Compliant](https://img.shields.io/badge/POSIX-compliant-green.svg)](https://pubs.opengroup.org/onlinepubs/9699919799/)
[![Shell](https://img.shields.io/badge/shell-sh-blue.svg)](https://en.wikipedia.org/wiki/Bourne_shell)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

- **100% Portable**: Works on any POSIX-compliant system
- **Zero Dependencies**: Uses only system default tools (`sh`, `curl`/`wget`, `printf`, `date`)
- **Universal Compatibility**: Tested on Debian, Ubuntu, Alpine, BusyBox, OpenWRT, and Raspberry Pi OS
- **Secure Configuration**: Environment-based configuration with secure file permissions
- **Rich Formatting**: Supports different alert levels with appropriate emojis
- **Logging Support**: Optional file logging for alert history
- **Easy Installation**: Simple setup script included

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

### Help and Options

```bash
./alert.sh --help    # Show help information
./alert.sh -h        # Show help information
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

- **Issues**: [GitHub Issues](https://github.com/irev/alertgrams/issues)
- **Discussions**: [GitHub Discussions](https://github.com/irev/alertgrams/discussions)
- **Security**: [Security Policy](SECURITY.md)

---

**Made with ❤️ for the sysadmin community**