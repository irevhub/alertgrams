#!/bin/sh
# AlertGrams Service Installer
# ===========================
# Description: Install AlertGrams monitoring as systemd service
# Usage: ./install-service.sh
# Author: AlertGrams Project

set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SERVICE_NAME="alertgrams-monitor"
SERVICE_USER="alertgrams"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/alertgrams"
LOG_DIR="/var/log/alertgrams"

# Print colored output
print_info() {
    printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$1"
}

print_warn() {
    printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$1"
}

print_error() {
    printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1" >&2
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "This script must be run as root"
        printf "Usage: sudo %s\n" "$0"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    print_info "Checking system requirements..."
    
    # Check for systemd
    if ! command -v systemctl >/dev/null 2>&1; then
        print_error "systemd is required but not found"
        print_error "This system may not support systemd services"
        exit 1
    fi
    
    # Check for required files
    if [ ! -f "./alertgrams-monitor.sh" ]; then
        print_error "alertgrams-monitor.sh not found in current directory"
        print_error "Please ensure you're running this script from the AlertGrams directory"
        exit 1
    fi
    
    if [ ! -f "./alertgrams-monitor.service" ]; then
        print_error "alertgrams-monitor.service not found in current directory"
        print_error "Please ensure you're running this script from the AlertGrams directory"
        exit 1
    fi
    
    # Check for alert.sh - make it more flexible
    if [ ! -f "./alert.sh" ] && [ ! -f "/usr/local/bin/alert.sh" ]; then
        print_warn "alert.sh not found in current directory or /usr/local/bin/"
        print_warn "The service may not work properly without alert.sh"
        printf "Do you want to continue anyway? (y/N): "
        read -r continue_anyway
        case "$continue_anyway" in
            [yY]|[yY][eE][sS])
                print_info "Continuing installation..."
                ;;
            *)
                print_info "Installation cancelled. Please install AlertGrams first with: ./install.sh"
                exit 1
                ;;
        esac
    fi
    
    # Check for required system tools
    missing_tools=""
    for tool in curl wget grep awk sed tail head wc; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools="$missing_tools $tool"
        fi
    done
    
    if [ -n "$missing_tools" ]; then
        print_error "Missing required tools:$missing_tools"
        print_error "Please install these tools before proceeding"
        exit 1
    fi
    
    # Check if either curl or wget is available
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        print_error "Neither curl nor wget found - required for sending alerts"
        exit 1
    fi
    
    print_info "System requirements check passed"
}

# Create system user
create_user() {
    if id "$SERVICE_USER" >/dev/null 2>&1; then
        print_info "User '$SERVICE_USER' already exists"
    else
        print_info "Creating system user '$SERVICE_USER'..."
        
        if command -v useradd >/dev/null 2>&1; then
            useradd --system --no-create-home --shell /bin/false "$SERVICE_USER"
        elif command -v adduser >/dev/null 2>&1; then
            adduser --system --no-create-home --shell /bin/false "$SERVICE_USER"
        else
            print_error "Cannot create user: neither useradd nor adduser found"
            exit 1
        fi
        
        print_info "User '$SERVICE_USER' created successfully"
    fi
    
    # Add user to adm group for log access (needed for syslog monitoring)
    if getent group adm >/dev/null 2>&1; then
        if ! groups "$SERVICE_USER" | grep -q adm; then
            usermod -a -G adm "$SERVICE_USER"
            print_info "Added '$SERVICE_USER' to 'adm' group for log access"
        fi
    else
        print_warn "Group 'adm' not found - syslog monitoring may not work"
    fi
}

# Create directories
create_directories() {
    print_info "Creating directories..."
    
    # Create config directory
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        print_info "Created directory: $CONFIG_DIR"
    fi
    
    # Create log directory
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        print_info "Created directory: $LOG_DIR"
    fi
    
    # Set permissions
    chown "$SERVICE_USER:$SERVICE_USER" "$CONFIG_DIR" "$LOG_DIR"
    chmod 750 "$CONFIG_DIR" "$LOG_DIR"
}

# Install files
install_files() {
    print_info "Installing service files..."
    
    # Copy monitoring script
    cp "./alertgrams-monitor.sh" "$INSTALL_DIR/"
    chmod 755 "$INSTALL_DIR/alertgrams-monitor.sh"
    chown root:root "$INSTALL_DIR/alertgrams-monitor.sh"
    print_info "Installed: $INSTALL_DIR/alertgrams-monitor.sh"
    
    # Always copy alert.sh (force update to ensure latest version with multi-path config support)
    if [ -f "./alert.sh" ]; then
        cp "./alert.sh" "$INSTALL_DIR/"
        chmod 755 "$INSTALL_DIR/alert.sh"
        chown root:root "$INSTALL_DIR/alert.sh"
        print_info "Installed: $INSTALL_DIR/alert.sh"
    else
        print_error "alert.sh not found - service will not work without it"
        exit 1
    fi
    
    # Copy service file
    cp "./alertgrams-monitor.service" "/etc/systemd/system/"
    chmod 644 "/etc/systemd/system/alertgrams-monitor.service"
    chown root:root "/etc/systemd/system/alertgrams-monitor.service"
    print_info "Installed: /etc/systemd/system/alertgrams-monitor.service"
    
    # Handle configuration with proper system paths
    if [ -f "./.env" ] && [ ! -f "$CONFIG_DIR/.env" ]; then
        cp "./.env" "$CONFIG_DIR/"
        
        # Fix LOG_FILE path for service mode
        sed -i 's|^LOG_FILE=alerts\.log$|LOG_FILE=/var/log/alertgrams/alerts.log|' "$CONFIG_DIR/.env"
        sed -i 's|^LOG_FILE=./alerts\.log$|LOG_FILE=/var/log/alertgrams/alerts.log|' "$CONFIG_DIR/.env"
        
        chmod 600 "$CONFIG_DIR/.env"
        chown "$SERVICE_USER:$SERVICE_USER" "$CONFIG_DIR/.env"
        print_info "Copied configuration to: $CONFIG_DIR/.env"
        print_info "Updated LOG_FILE path for service mode"
    elif [ -f "./env.example" ] && [ ! -f "$CONFIG_DIR/.env" ]; then
        cp "./env.example" "$CONFIG_DIR/.env"
        
        # Fix LOG_FILE path for service mode
        sed -i 's|^LOG_FILE=alerts\.log$|LOG_FILE=/var/log/alertgrams/alerts.log|' "$CONFIG_DIR/.env"
        sed -i 's|^#LOG_FILE=alerts\.log$|LOG_FILE=/var/log/alertgrams/alerts.log|' "$CONFIG_DIR/.env"
        
        chmod 600 "$CONFIG_DIR/.env"
        chown "$SERVICE_USER:$SERVICE_USER" "$CONFIG_DIR/.env"
        print_warn "Copied example configuration. Please edit $CONFIG_DIR/.env"
        print_info "Updated LOG_FILE path for service mode"
    else
        print_warn "No configuration file found - service may need manual configuration"
    fi
    
    # Create log file with proper permissions
    touch "$LOG_DIR/alerts.log"
    chown "$SERVICE_USER:$SERVICE_USER" "$LOG_DIR/alerts.log"
    chmod 644 "$LOG_DIR/alerts.log"
    print_info "Created log file: $LOG_DIR/alerts.log"
}

# Configure systemd
configure_systemd() {
    print_info "Configuring systemd service..."
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable "$SERVICE_NAME"
    print_info "Service enabled for auto-start"
}

# Test configuration and functionality
test_configuration() {
    print_info "Testing configuration and functionality..."
    
    # Check if config file exists and has required variables
    config_file="$CONFIG_DIR/.env"
    if [ -f "$config_file" ]; then
        if grep -q "TELEGRAM_API_KEY" "$config_file" && grep -q "TELEGRAM_CHAT_ID" "$config_file"; then
            print_info "Configuration file contains required variables"
            
            # Test if alert.sh can read the config and send a test alert
            if sudo -u "$SERVICE_USER" "$INSTALL_DIR/alert.sh" "INFO" "AlertGrams service installation test" >/dev/null 2>&1; then
                print_info "Alert functionality test passed"
            else
                print_warn "Alert functionality test failed - check Telegram configuration"
                print_warn "You may need to verify TELEGRAM_API_KEY and TELEGRAM_CHAT_ID"
            fi
        else
            print_warn "Configuration file missing required variables (TELEGRAM_API_KEY, TELEGRAM_CHAT_ID)"
            print_warn "Please edit $config_file before starting the service"
        fi
    else
        print_warn "Configuration file not found: $config_file"
        print_warn "Service may not work without proper configuration"
    fi
    
    # Test monitoring script with basic syntax check
    if [ -x "$INSTALL_DIR/alertgrams-monitor.sh" ]; then
        if sh -n "$INSTALL_DIR/alertgrams-monitor.sh"; then
            print_info "Monitoring script syntax check passed"
        else
            print_error "Monitoring script has syntax errors"
            return 1
        fi
    else
        print_error "Monitoring script not found or not executable"
        return 1
    fi
    
    # Test if monitoring script can run in test mode
    if sudo -u "$SERVICE_USER" "$INSTALL_DIR/alertgrams-monitor.sh" test >/dev/null 2>&1; then
        print_info "Monitoring script test mode passed"
        return 0
    else
        print_warn "Monitoring script test mode failed - check configuration"
        return 1
    fi
}

# Start service
start_service() {
    print_info "Starting AlertGrams monitoring service..."
    
    if systemctl start "$SERVICE_NAME"; then
        print_info "Service started successfully"
        
        # Check status
        sleep 2
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            print_info "Service is running"
            systemctl status "$SERVICE_NAME" --no-pager -l
        else
            print_error "Service failed to start"
            systemctl status "$SERVICE_NAME" --no-pager -l
            return 1
        fi
    else
        print_error "Failed to start service"
        return 1
    fi
}

# Show service information
show_service_info() {
    printf "\n%b=== AlertGrams Service Installation Complete ===%b\n" "$GREEN" "$NC"
    printf "\nService Management Commands:\n"
    printf "  Start service:   sudo systemctl start %s\n" "$SERVICE_NAME"
    printf "  Stop service:    sudo systemctl stop %s\n" "$SERVICE_NAME"
    printf "  Restart service: sudo systemctl restart %s\n" "$SERVICE_NAME"
    printf "  Check status:    sudo systemctl status %s\n" "$SERVICE_NAME"
    printf "  View logs:       sudo journalctl -u %s -f\n" "$SERVICE_NAME"
    printf "  Reload config:   sudo systemctl reload %s\n" "$SERVICE_NAME"
    
    printf "\nHelper Script Commands:\n"
    printf "  ./service-management.sh start\n"
    printf "  ./service-management.sh stop\n"
    printf "  ./service-management.sh restart\n"
    printf "  ./service-management.sh status\n"
    printf "  ./service-management.sh logs\n"
    printf "  ./service-management.sh config\n"
    
    printf "\nConfiguration:\n"
    printf "  Config file:     %s/.env\n" "$CONFIG_DIR"
    printf "  Log directory:   %s\n" "$LOG_DIR"
    printf "  Service user:    %s\n" "$SERVICE_USER"
    printf "  Alert log:       %s/alerts.log\n" "$LOG_DIR"
    
    printf "\nTo edit configuration:\n"
    printf "  sudo nano %s/.env\n" "$CONFIG_DIR"
    printf "  sudo systemctl reload %s\n" "$SERVICE_NAME"
    
    printf "\nUseful Log Commands:\n"
    printf "  journalctl -u %s                    # All logs\n" "$SERVICE_NAME"
    printf "  journalctl -u %s -f                # Follow real-time\n" "$SERVICE_NAME"
    printf "  journalctl -u %s --since today     # Today only\n" "$SERVICE_NAME"
    printf "  journalctl -u %s -n 50             # Last 50 lines\n" "$SERVICE_NAME"
    printf "  journalctl -u %s -p err            # Errors only\n" "$SERVICE_NAME"
    
    printf "\n%bNote:%b If you encounter issues:\n" "$YELLOW" "$NC"
    printf "1. Check service status: sudo systemctl status %s\n" "$SERVICE_NAME"
    printf "2. View recent logs: sudo journalctl -u %s -n 20\n" "$SERVICE_NAME"
    printf "3. Test alert manually: sudo -u %s %s/alert.sh INFO \"test\"\n" "$SERVICE_USER" "$INSTALL_DIR"
}

# Uninstall service
uninstall_service() {
    print_info "Uninstalling AlertGrams service..."
    
    # Stop and disable service
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_info "Stopping service..."
        systemctl stop "$SERVICE_NAME"
    fi
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        print_info "Disabling service..."
        systemctl disable "$SERVICE_NAME"
    fi
    
    # Remove service file
    if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
        rm "/etc/systemd/system/$SERVICE_NAME.service"
        print_info "Removed service file"
    fi
    
    # Remove monitoring script
    if [ -f "$INSTALL_DIR/alertgrams-monitor.sh" ]; then
        rm "$INSTALL_DIR/alertgrams-monitor.sh"
        print_info "Removed monitoring script"
    fi
    
    # Remove alert.sh (optional)
    printf "Do you want to remove alert.sh as well? (y/N): "
    read -r remove_alert
    case "$remove_alert" in
        [yY]|[yY][eE][sS])
            if [ -f "$INSTALL_DIR/alert.sh" ]; then
                rm "$INSTALL_DIR/alert.sh"
                print_info "Removed alert.sh"
            fi
            ;;
        *)
            print_info "Kept alert.sh for manual use"
            ;;
    esac
    
    # Ask about removing user and directories
    printf "Do you want to remove user '$SERVICE_USER' and directories? (y/N): "
    read -r remove_user
    case "$remove_user" in
        [yY]|[yY][eE][sS])
            if id "$SERVICE_USER" >/dev/null 2>&1; then
                userdel "$SERVICE_USER" 2>/dev/null || print_warn "Could not remove user $SERVICE_USER"
                print_info "Removed user $SERVICE_USER"
            fi
            
            if [ -d "$LOG_DIR" ]; then
                rm -rf "$LOG_DIR"
                print_info "Removed log directory"
            fi
            
            printf "Remove configuration directory %s? (y/N): " "$CONFIG_DIR"
            read -r remove_config
            case "$remove_config" in
                [yY]|[yY][eE][sS])
                    rm -rf "$CONFIG_DIR"
                    print_info "Removed configuration directory"
                    ;;
                *)
                    print_info "Configuration preserved in $CONFIG_DIR"
                    ;;
            esac
            ;;
        *)
            print_info "User and directories preserved"
            print_info "Configuration preserved in $CONFIG_DIR"
            ;;
    esac
    
    # Reload systemd
    systemctl daemon-reload
    
    print_info "AlertGrams service uninstallation completed"
}

# Show usage information
show_usage() {
    printf "AlertGrams Service Installer\n"
    printf "===========================\n\n"
    printf "Install and manage AlertGrams monitoring as a systemd service.\n\n"
    printf "Usage: sudo %s [OPTION]\n\n" "$0"
    printf "Options:\n"
    printf "  (no option)   Install AlertGrams service\n"
    printf "  uninstall     Remove AlertGrams service\n"
    printf "  fix|repair    Fix common service issues\n"
    printf "  -h|--help     Show this help message\n\n"
    printf "Examples:\n"
    printf "  sudo %s                 # Install service\n" "$0"
    printf "  sudo %s uninstall       # Remove service\n" "$0"
    printf "  sudo %s fix             # Fix common issues\n" "$0"
    printf "\nNote: This script must be run with sudo privileges.\n"
}

# Main function
main() {
    # Handle help option first
    case "${1:-}" in
        "-h"|"--help"|"help")
            show_usage
            exit 0
            ;;
    esac
    
    printf "AlertGrams Service Installer\n"
    printf "===========================\n\n"
    
    # Handle special options
    case "${1:-}" in
        "uninstall")
            printf "Do you want to uninstall AlertGrams service? (y/N): "
            read -r confirm
            case "$confirm" in
                [yY]|[yY][eE][sS])
                    uninstall_service
                    exit 0
                    ;;
                *)
                    print_info "Uninstall cancelled"
                    exit 0
                    ;;
            esac
            ;;
        "fix"|"repair")
            print_info "Running AlertGrams service repair..."
            if systemctl list-unit-files | grep -q "^$SERVICE_NAME.service"; then
                print_info "Service found, attempting repair..."
                
                # Fix common issues
                if [ -f "$CONFIG_DIR/.env" ]; then
                    sed -i 's|^LOG_FILE=alerts\.log$|LOG_FILE=/var/log/alertgrams/alerts.log|' "$CONFIG_DIR/.env"
                    sed -i 's|^LOG_FILE=./alerts\.log$|LOG_FILE=/var/log/alertgrams/alerts.log|' "$CONFIG_DIR/.env"
                    print_info "Fixed LOG_FILE path in configuration"
                fi
                
                # Ensure log file exists with proper permissions
                if [ ! -f "$LOG_DIR/alerts.log" ]; then
                    touch "$LOG_DIR/alerts.log"
                    chown "$SERVICE_USER:$SERVICE_USER" "$LOG_DIR/alerts.log"
                    chmod 644 "$LOG_DIR/alerts.log"
                    print_info "Created missing log file"
                fi
                
                # Ensure user is in adm group
                if getent group adm >/dev/null 2>&1; then
                    if ! groups "$SERVICE_USER" | grep -q adm; then
                        usermod -a -G adm "$SERVICE_USER"
                        print_info "Added user to adm group for log access"
                    fi
                fi
                
                # Restart service
                systemctl restart "$SERVICE_NAME"
                sleep 3
                
                if systemctl is-active --quiet "$SERVICE_NAME"; then
                    print_info "✅ Service repair completed successfully!"
                    systemctl status "$SERVICE_NAME" --no-pager -l
                else
                    print_error "❌ Service repair failed"
                    journalctl -u "$SERVICE_NAME" -n 10 --no-pager
                fi
            else
                print_error "AlertGrams service not found. Please install first."
            fi
            exit 0
            ;;
    esac
    
    # Check if already installed
    if systemctl list-unit-files | grep -q "^$SERVICE_NAME.service"; then
        print_warn "AlertGrams service is already installed"
        printf "Do you want to reinstall? (y/N): "
        read -r confirm
        case "$confirm" in
            [yY]|[yY][eE][sS])
                uninstall_service
                printf "\n"
                ;;
            *)
                print_info "Installation cancelled"
                exit 0
                ;;
        esac
    fi
    
    # Run installation steps
    check_root
    check_requirements
    create_user
    create_directories
    install_files
    configure_systemd
    
    # Test configuration
    if ! test_configuration; then
        print_warn "Configuration test failed, but installation completed"
        print_warn "Please check configuration in %s/.env" "$CONFIG_DIR"
        print_warn "Service may not work properly without valid Telegram credentials"
        
        printf "Do you want to continue anyway? (y/N): "
        read -r continue_anyway
        case "$continue_anyway" in
            [yY]|[yY][eE][sS])
                print_info "Continuing with potentially incomplete configuration..."
                ;;
            *)
                print_info "Installation cancelled. Please configure Telegram credentials first."
                exit 1
                ;;
        esac
    fi
    
    # Ask to start service
    printf "Do you want to start AlertGrams service now? (Y/n): "
    read -r start_now
    case "$start_now" in
        [nN]|[nN][oO])
            print_info "Service installed but not started"
            show_service_info
            ;;
        *)
            if start_service; then
                # Give service a moment to initialize
                sleep 3
                
                # Check if service is actually running properly
                if systemctl is-active --quiet "$SERVICE_NAME"; then
                    print_info "✅ Service is running successfully!"
                    
                    # Show recent logs to verify functionality
                    printf "\nRecent service logs:\n"
                    journalctl -u "$SERVICE_NAME" -n 10 --no-pager | tail -5
                    
                    show_service_info
                else
                    print_error "❌ Service failed to start properly"
                    printf "\nDebugging information:\n"
                    printf "Service status:\n"
                    systemctl status "$SERVICE_NAME" --no-pager -l | head -10
                    printf "\nRecent logs:\n"
                    journalctl -u "$SERVICE_NAME" -n 15 --no-pager
                    printf "\nTroubleshooting:\n"
                    printf "1. Check configuration: sudo nano %s/.env\n" "$CONFIG_DIR"
                    printf "2. View detailed logs: sudo journalctl -u %s -f\n" "$SERVICE_NAME"
                    printf "3. Test manually: sudo -u %s %s/alert.sh INFO \"test\"\n" "$SERVICE_USER" "$INSTALL_DIR"
                    exit 1
                fi
            else
                printf "Service installed but failed to start. Check logs with:\n"
                printf "  sudo journalctl -u %s -f\n" "$SERVICE_NAME"
                exit 1
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"