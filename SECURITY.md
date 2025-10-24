# Security Policy

## 🔒 Security Overview

AlertGrams takes security seriously. This document outlines our security practices, potential risks, and guidelines for secure deployment and usage.

## 🚨 Reporting Security Vulnerabilities

If you discover a security vulnerability in AlertGrams, please report it responsibly:

### Reporting Process

1. **DO NOT** create a public GitHub issue for security vulnerabilities
2. **Email**: security@alertgrams.project (or create a private security advisory on GitHub)
3. **Include**: 
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested mitigation (if any)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Assessment**: Within 7 days
- **Fix Development**: Depends on severity (1-30 days)
- **Public Disclosure**: After fix is available and users have time to update

## 🛡️ Security Considerations

### 1. Telegram Bot Token Security

**Risk**: Telegram bot tokens provide full access to your bot and can be used to send messages on your behalf.

**Mitigations**:
- ✅ Store tokens in `.env` file with restricted permissions (600)
- ✅ Never commit `.env` files to version control
- ✅ Use different bots for different environments (dev/staging/prod)
- ✅ Rotate tokens periodically
- ✅ Monitor bot usage for unusual activity

**Best Practices**:
```bash
# Set secure permissions
chmod 600 .env

# Verify permissions
ls -la .env
# Should show: -rw------- 1 user user

# Add .env to .gitignore
echo ".env" >> .gitignore
```

### 2. Chat ID Exposure

**Risk**: Chat IDs can reveal information about your Telegram usage and allow unauthorized message sending.

**Mitigations**:
- ✅ Treat Chat IDs as sensitive information
- ✅ Use dedicated alert channels/groups
- ✅ Regularly audit who has access to alert channels
- ✅ Consider using bot-specific groups rather than personal chats

### 3. Message Content Security

**Risk**: Alert messages may contain sensitive system information.

**Current Protections**:
- ✅ URL encoding prevents injection attacks
- ✅ Markdown escaping prevents formatting attacks
- ✅ Message length limits prevent oversized payloads
- ✅ Input validation on alert levels

**Additional Recommendations**:
```bash
# Sanitize sensitive data before sending
./alert.sh "WARNING" "Database error occurred" # Good
./alert.sh "WARNING" "Database error: password123 failed" # Bad
```

### 4. File System Security

**Risk**: Improper file permissions could expose configuration or logs.

**File Permission Requirements**:
```bash
# Script files (executable by owner)
chmod 755 alert.sh install.sh

# Configuration files (readable by owner only)
chmod 600 .env

# Log files (writable by owner only)
chmod 640 alerts.log

# Directory permissions
chmod 750 /path/to/alertgrams/
```

### 5. Network Security

**Risk**: HTTP requests could be intercepted or modified.

**Current Protections**:
- ✅ HTTPS-only connections to Telegram API
- ✅ Certificate validation by curl/wget
- ✅ Fail-fast on HTTP errors

**Additional Recommendations**:
- Use network monitoring to detect unusual API calls
- Consider running behind a firewall with restricted outbound access
- Monitor for failed connection attempts

### 6. Input Validation

**Risk**: Malicious input could cause unexpected behavior.

**Current Protections**:
- ✅ Parameter validation (level and message required)
- ✅ Configuration validation (required fields checked)
- ✅ URL encoding of all user input
- ✅ Message length limits enforced

**Secure Usage Examples**:
```bash
# Safe: Static messages
./alert.sh "INFO" "Backup completed"

# Safe: Validated input
level="INFO"
message="System check completed"
./alert.sh "$level" "$message"

# Caution: User input (validate first)
user_input="$(echo "$1" | tr -d '\n\r')"  # Remove newlines
./alert.sh "INFO" "User action: $user_input"
```

## 🔐 Secure Deployment Guide

### 1. Initial Setup

```bash
# Create dedicated user for AlertGrams
sudo useradd -r -s /bin/false alertgrams
sudo mkdir /opt/alertgrams
sudo chown alertgrams:alertgrams /opt/alertgrams

# Install as alertgrams user
sudo -u alertgrams git clone <repo> /opt/alertgrams
cd /opt/alertgrams
sudo -u alertgrams ./install.sh
```

### 2. Production Configuration

```bash
# Set restrictive permissions
sudo chmod 750 /opt/alertgrams
sudo chmod 600 /opt/alertgrams/.env
sudo chmod 755 /opt/alertgrams/alert.sh

# Create secure log directory
sudo mkdir /var/log/alertgrams
sudo chown alertgrams:alertgrams /var/log/alertgrams
sudo chmod 750 /var/log/alertgrams
```

### 3. System Integration

```bash
# Create systemd service (optional)
cat << 'EOF' | sudo tee /etc/systemd/system/alertgrams-test.service
[Unit]
Description=AlertGrams Test Service
After=network.target

[Service]
Type=oneshot
User=alertgrams
WorkingDirectory=/opt/alertgrams
ExecStart=/opt/alertgrams/alert.sh "INFO" "System check"

[Install]
WantedBy=multi-user.target
EOF

# Enable and test
sudo systemctl enable alertgrams-test.timer
sudo systemctl start alertgrams-test.service
```

### 4. Monitoring and Auditing

```bash
# Monitor configuration file access
sudo auditctl -w /opt/alertgrams/.env -p ra -k alertgrams_config

# Monitor script execution
sudo auditctl -w /opt/alertgrams/alert.sh -p x -k alertgrams_exec

# Log rotation for alert logs
cat << 'EOF' | sudo tee /etc/logrotate.d/alertgrams
/var/log/alertgrams/*.log {
    daily
    rotate 30
    compress
    delaycompress
    create 640 alertgrams alertgrams
    postrotate
        # Signal any processes if needed
    endscript
}
EOF
```

## ⚠️ Known Security Limitations

### 1. Shell Script Limitations

- **No built-in encryption**: Messages are sent as plain text to Telegram
- **Limited input sanitization**: Basic URL encoding only
- **Process visibility**: Script arguments may be visible in process lists

### 2. Telegram API Limitations

- **Message persistence**: Messages are stored on Telegram's servers
- **Rate limiting**: No built-in rate limiting (rely on Telegram's limits)
- **No message authentication**: Cannot verify message integrity after sending

### 3. System Dependencies

- **HTTP client security**: Depends on curl/wget security
- **System shell security**: Vulnerable to shell-level attacks
- **File system security**: Relies on UNIX file permissions

## 🔧 Security Hardening Checklist

### Pre-deployment

- [ ] Review all configuration options
- [ ] Set up dedicated Telegram bot
- [ ] Create separate environment configurations
- [ ] Implement log rotation
- [ ] Set up monitoring alerts

### Deployment

- [ ] Use dedicated system user
- [ ] Set restrictive file permissions (600 for .env, 755 for scripts)
- [ ] Place in secure directory (/opt/ or /usr/local/)
- [ ] Configure proper logging with rotation
- [ ] Test security configuration

### Post-deployment

- [ ] Monitor bot activity regularly
- [ ] Audit file permissions monthly
- [ ] Rotate bot tokens quarterly
- [ ] Review and update configurations
- [ ] Keep system dependencies updated

### Monitoring

- [ ] Set up alerts for failed authentication
- [ ] Monitor unusual API usage patterns
- [ ] Track configuration file access
- [ ] Log all alert activities
- [ ] Regular security reviews

## 🚨 Incident Response

### If Bot Token is Compromised

1. **Immediate Actions**:
   ```bash
   # Revoke the compromised token via @BotFather
   # /revoke command in BotFather chat
   
   # Generate new token
   # /newtoken command in BotFather chat
   
   # Update configuration
   nano .env  # Update TELEGRAM_API_KEY
   ```

2. **Investigation**:
   - Review alert logs for unauthorized messages
   - Check system logs for unusual access
   - Audit who had access to the configuration

3. **Recovery**:
   - Update all environments with new token
   - Review and improve access controls
   - Document the incident for future reference

### If System is Compromised

1. **Isolation**: Stop AlertGrams service
2. **Assessment**: Determine scope of compromise
3. **Recovery**: Restore from clean backups
4. **Hardening**: Implement additional security measures

## 📋 Security Updates

We regularly review and update our security practices. Subscribe to our security announcements:

- **GitHub Releases**: Watch for security-tagged releases
- **Security Advisories**: Enable GitHub security advisories
- **Mailing List**: Subscribe to security updates (if available)

## 🤝 Contributing to Security

Help us improve AlertGrams security:

1. **Code Review**: Review pull requests for security issues
2. **Security Testing**: Test the application in various environments
3. **Documentation**: Improve security documentation
4. **Best Practices**: Share secure deployment experiences

## 📚 Additional Resources

- [OWASP Shell Injection Prevention](https://owasp.org/www-community/attacks/Command_Injection)
- [Telegram Bot Security Best Practices](https://core.telegram.org/bots#security)
- [Linux File Permissions Guide](https://wiki.archlinux.org/title/File_permissions_and_attributes)
- [Secure Shell Scripting](https://mywiki.wooledge.org/BashGuide/Practices)

---

**Remember**: Security is a shared responsibility. While we strive to make AlertGrams secure by default, proper deployment and configuration are essential for maintaining security in your environment.