# AlertGrams Installation Guide

This guide provides detailed instructions for installing and configuring AlertGrams on your system.

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Quick Installation](#-quick-installation)
- [Detailed Installation Steps](#-detailed-installation-steps)
- [Configuration Setup](#-configuration-setup)
- [Installation Options](#-installation-options)
- [Troubleshooting](#-troubleshooting)
- [Verification](#-verification)
- [Uninstallation](#-uninstallation)

## 🔧 Prerequisites

### System Requirements

AlertGrams is designed to work on any POSIX-compliant system. Before installation, ensure you have:

#### Required Components
- **Shell**: POSIX-compliant shell (`/bin/sh`)
- **HTTP Client**: Either `curl` or `wget`
- **Core Tools**: `printf`, `date`, `hostname`, `sed`, `cut`

#### Supported Platforms
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

### Telegram Setup

Before installing AlertGrams, you need:

1. **Telegram Bot Token**:
   - Start a chat with [@BotFather](https://t.me/BotFather)
   - Send `/newbot` and follow the instructions
   - Copy the API token provided

2. **Chat ID**:
   - Send a message to [@userinfobot](https://t.me/userinfobot)
   - Copy the ID number (including negative sign if present)
   - For group chats, add your bot to the group first

## 🚀 Quick Installation

For a standard installation with interactive setup:

```bash
# Clone the repository
git clone https://github.com/yourusername/alertgrams.git
cd alertgrams

# Make installer executable
chmod +x install.sh

# Run the interactive installer
./install.sh
```

The installer will:
1. Check system requirements
2. Guide you through configuration setup
3. Set proper file permissions
4. Test your configuration
5. Provide usage examples

## 📖 Detailed Installation Steps

### Step 1: Download AlertGrams

```bash
# Option 1: Clone from Git
git clone https://github.com/irev/alertgrams.git
cd alertgrams

# Option 2: Download and extract
wget https://github.com/irev/alertgrams/archive/main.zip
unzip main.zip
cd alertgrams-main

# Option 3: Manual download
# Download all files to a directory and navigate to it
```

### Step 2: Check System Requirements

Before proceeding, verify your system meets the requirements:

```bash
./install.sh --check-only
```

Expected output:
```
[INFO] Checking system requirements...
[INFO] Shell: /bin/bash
[SUCCESS] Found curl version: 7.68.0
[SUCCESS] Found wget version: 1.20.3
[SUCCESS] Found required tool: date
[SUCCESS] Found required tool: hostname
[SUCCESS] Found required tool: printf
[SUCCESS] Found required tool: sed
[SUCCESS] Found required tool: cut
```

### Step 3: Run Installation

Choose one of the installation methods:

#### Interactive Installation (Recommended)
```bash
./install.sh
```

#### Configuration Only (Skip Testing)
```bash
./install.sh --config-only
```

#### Silent Installation (No Test Alert)
```bash
./install.sh --no-test
```

### Step 4: File Permissions

The installer automatically sets secure permissions:

```bash
# Script permissions (executable)
chmod 755 alert.sh install.sh

# Configuration permissions (secure)
chmod 600 .env

# Verify permissions
ls -la alert.sh install.sh .env
```

Expected output:
```
-rwxr-xr-x 1 user user alert.sh
-rwxr-xr-x 1 user user install.sh
-rw------- 1 user user .env
```

## ⚙️ Configuration Setup

### Interactive Configuration

The installer will guide you through configuration:

1. **Telegram Bot API Key** (Required):
   ```
   Enter your Telegram Bot API Key: 123456789:ABCdefGHIjklMNOpqrSTUvwxyz
   ```

2. **Telegram Chat ID** (Required):
   ```
   Enter your Telegram Chat ID: 123456789
   ```

3. **Log File Path** (Optional):
   ```
   Log file path (empty to disable logging) [alerts.log]: 
   ```

4. **Maximum Message Length** (Optional):
   ```
   Maximum message length [4096]: 
   ```

### Manual Configuration

If you prefer to configure manually:

```bash
# Copy the example configuration
cp .env.example .env

# Edit with your preferred editor
nano .env  # or vim, emacs, etc.
```

Configuration file structure:
```bash
# Required settings
TELEGRAM_API_KEY=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here

# Optional settings
LOG_FILE=alerts.log
MAX_MESSAGE_LENGTH=4096
```

### Configuration for Different Environments

#### Development Environment
```bash
TELEGRAM_API_KEY=123456789:ABCdefGHIjklMNOpqrSTUvwxyz-dev
TELEGRAM_CHAT_ID=123456789
LOG_FILE=dev-alerts.log
MAX_MESSAGE_LENGTH=2048
```

#### Production Environment
```bash
TELEGRAM_API_KEY=987654321:ZYXwvuTSRqpONmlkJIhGfEdCbA-prod
TELEGRAM_CHAT_ID=-1001234567890
LOG_FILE=/var/log/alertgrams/alerts.log
MAX_MESSAGE_LENGTH=4096
```

#### Minimal Configuration
```bash
TELEGRAM_API_KEY=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here
LOG_FILE=
MAX_MESSAGE_LENGTH=4096
```

## 🛠️ Installation Options

The installer supports various options for different use cases:

### Available Commands

```bash
# Show help and all options
./install.sh --help

# Check system requirements only
./install.sh --check-only

# Display current configuration
./install.sh --show-config

# Quick configuration validation
./install.sh --check-config

# Setup configuration only (no testing)
./install.sh --config-only

# Test existing configuration
./install.sh --test-only

# Full installation without test alert
./install.sh --no-test
```

### Installation Workflows

#### First-Time Installation
```bash
# 1. Check requirements
./install.sh --check-only

# 2. Full installation with test
./install.sh
```

#### Updating Configuration
```bash
# 1. View current configuration
./install.sh --show-config

# 2. Update configuration
./install.sh --config-only

# 3. Test new configuration
./install.sh --test-only
```

#### Production Deployment
```bash
# 1. Check system compatibility
./install.sh --check-only

# 2. Configure without testing
./install.sh --config-only

# 3. Test in controlled manner
./install.sh --test-only

# 4. Verify configuration
./install.sh --check-config
```

### Advanced Installation

#### Custom Installation Directory

```bash
# Create custom directory
sudo mkdir -p /opt/alertgrams
sudo chown $USER:$USER /opt/alertgrams

# Install to custom location
cp -r * /opt/alertgrams/
cd /opt/alertgrams
./install.sh
```

#### System-wide Installation

```bash
# Create system user
sudo useradd -r -s /bin/false alertgrams
sudo mkdir /opt/alertgrams
sudo chown alertgrams:alertgrams /opt/alertgrams

# Install as system user
sudo -u alertgrams git clone <repo> /opt/alertgrams
cd /opt/alertgrams
sudo -u alertgrams ./install.sh --config-only

# Create systemd service (optional)
sudo tee /etc/systemd/system/alertgrams.service << 'EOF'
[Unit]
Description=AlertGrams Service
After=network.target

[Service]
Type=oneshot
User=alertgrams
WorkingDirectory=/opt/alertgrams
ExecStart=/opt/alertgrams/alert.sh "INFO" "System check"

[Install]
WantedBy=multi-user.target
EOF
```

## 🔍 Troubleshooting

### Common Installation Issues

#### Issue: "Neither curl nor wget is available"

**Solution**: Install an HTTP client
```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install curl

# CentOS/RHEL
sudo yum install curl

# Alpine Linux
apk add curl

# macOS (with Homebrew)
brew install curl
```

#### Issue: "Permission denied" when running installer

**Solution**: Make installer executable
```bash
chmod +x install.sh
./install.sh
```

#### Issue: Configuration file permissions warning

**Solution**: Fix file permissions
```bash
chmod 600 .env
./install.sh --show-config  # Verify fix
```

#### Issue: "Configuration is incomplete or invalid"

**Solution**: Check configuration values
```bash
# Show current configuration
./install.sh --show-config

# Reconfigure
./install.sh --config-only

# Test configuration
./install.sh --test-only
```

#### Issue: Configuration shows placeholder values as valid (Windows)

**Symptoms**: Configuration validation fails when it shouldn't
**Cause**: Windows line endings (`\r\n`) in `.env` file

**Solution**: Convert line endings to Unix format
```bash
# Method 1: Use dos2unix (if available)
dos2unix .env

# Method 2: Use sed to remove carriage returns  
sed -i 's/\r$//' .env

# Method 3: Use tr to remove carriage returns
tr -d '\r' < .env > .env.tmp && mv .env.tmp .env

# Verify fix
./install.sh --check-config
```

### Configuration Issues

#### Issue: Bot token invalid

**Symptoms**: 
- "Failed to send test alert"
- HTTP 401 errors

**Solution**:
1. Verify token with @BotFather
2. Check for extra spaces or characters
3. Regenerate token if necessary

```bash
# Test token manually
curl -s "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"
```

#### Issue: Chat ID invalid

**Symptoms**:
- "Failed to send test alert" 
- HTTP 400 errors

**Solution**:
1. Get correct Chat ID from @userinfobot
2. For groups, ensure bot is added first
3. Check for correct negative sign

```bash
# Test chat ID manually
curl -s "https://api.telegram.org/bot<YOUR_TOKEN>/sendMessage?chat_id=<YOUR_CHAT_ID>&text=Test"
```

### System-Specific Issues

#### BusyBox/Alpine Linux

```bash
# Install required tools if missing
apk add curl bash coreutils
```

#### OpenWRT

```bash
# Install required packages
opkg update
opkg install curl coreutils-date
```

#### macOS

```bash
# Install GNU coreutils if needed
brew install coreutils
```

## ✅ Verification

### Post-Installation Checks

#### 1. Verify Installation

```bash
# Check all files are present
ls -la alert.sh install.sh .env README.md

# Verify permissions
./install.sh --show-config
```

#### 2. Test Configuration

```bash
# Quick validation
./install.sh --check-config

# Full test with alert
./install.sh --test-only
```

#### 3. Manual Test

```bash
# Send test alert
./alert.sh "INFO" "Installation verification test"

# Check logs (if enabled)
tail -f alerts.log
```

### Expected Results

After successful installation, you should see:

```bash
./install.sh --show-config
```

Output:
```
Current AlertGrams Configuration
================================

[SUCCESS] Configuration is complete and valid

Configuration Details:
  • API Key: 1234**** ✅
  • Chat ID: 123456789 ✅
  • Log File: alerts.log
  • Max Length: 4096 characters

Configuration File: .env
Last Modified: Oct 24 15:30
File Permissions: -rw------- ✅ (secure)
```

## 🗑️ Uninstallation

### Remove AlertGrams

```bash
# Navigate to installation directory
cd /path/to/alertgrams

# Remove configuration (backup first if needed)
cp .env .env.backup  # Optional backup
rm .env

# Remove log files
rm -f alerts.log *.log

# Remove the entire directory
cd ..
rm -rf alertgrams
```

### System-wide Uninstallation

```bash
# Stop and remove systemd service (if installed)
sudo systemctl stop alertgrams.service
sudo systemctl disable alertgrams.service
sudo rm /etc/systemd/system/alertgrams.service
sudo systemctl daemon-reload

# Remove system user and files
sudo rm -rf /opt/alertgrams
sudo userdel alertgrams

# Remove log rotation (if configured)
sudo rm -f /etc/logrotate.d/alertgrams
```

## 📞 Getting Help

If you encounter issues during installation:

1. **Check the logs**: Review any error messages carefully
2. **Verify requirements**: Run `./install.sh --check-only`
3. **Test manually**: Try sending alerts with curl/wget directly
4. **Check documentation**: Review README.md and SECURITY.md
5. **Report issues**: Create an issue on GitHub with:
   - Your operating system and version
   - Installation method used
   - Complete error messages
   - Output of `./install.sh --check-only`

## 🔗 Next Steps

After successful installation:

1. **Read the User Guide**: Check README.md for usage examples
2. **Review Security**: Read SECURITY.md for security best practices  
3. **Set up Monitoring**: Configure cron jobs or system integration
4. **Test Thoroughly**: Send various alert types to verify functionality

---


**Installation complete!** 🎉 Your AlertGrams service is ready to use.
