#!/bin/sh
# AlertGrams Installation Script
# ==============================
# Description: Setup script for Telegram Alert Service
# Version: 1.0.0
# Author: AlertGrams Project
#
# This script helps users set up the AlertGrams service by:
# - Checking system requirements
# - Setting up configuration
# - Setting proper permissions
# - Providing usage instructions

set -eu

# Colors for output (if terminal supports it)
RED=''
GREEN=''
YELLOW=''
BLUE=''
NC='' # No Color

# Check if terminal supports colors
setup_colors() {
    if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
        if [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
            RED="$(tput setaf 1)"
            GREEN="$(tput setaf 2)"
            YELLOW="$(tput setaf 3)"
            BLUE="$(tput setaf 4)"
            NC="$(tput sgr0)"
        fi
    fi
}

# Print colored messages
print_info() {
    printf "%s[INFO]%s %s\n" "$BLUE" "$NC" "$1"
}

print_success() {
    printf "%s[SUCCESS]%s %s\n" "$GREEN" "$NC" "$1"
}

print_warning() {
    printf "%s[WARNING]%s %s\n" "$YELLOW" "$NC" "$1"
}

print_error() {
    printf "%s[ERROR]%s %s\n" "$RED" "$NC" "$1" >&2
}

# Check system requirements
check_requirements() {
    print_info "Checking system requirements..."
    
    # Check shell
    if [ -z "${SHELL:-}" ]; then
        print_warning "SHELL environment variable not set, assuming /bin/sh"
    else
        print_info "Shell: $SHELL"
    fi
    
    # Check for HTTP client
    has_curl=0
    has_wget=0
    
    if command -v curl >/dev/null 2>&1; then
        has_curl=1
        curl_version="$(curl --version 2>/dev/null | head -n1 | cut -d' ' -f2 || echo "unknown")"
        print_success "Found curl version: $curl_version"
    fi
    
    if command -v wget >/dev/null 2>&1; then
        has_wget=1
        wget_version="$(wget --version 2>/dev/null | head -n1 | cut -d' ' -f3 || echo "unknown")"
        print_success "Found wget version: $wget_version"
    fi
    
    if [ $has_curl -eq 0 ] && [ $has_wget -eq 0 ]; then
        print_error "Neither curl nor wget is available!"
        print_error "Please install curl or wget to use AlertGrams"
        return 1
    fi
    
    # Check other required tools
    for tool in date hostname printf sed cut; do
        if command -v "$tool" >/dev/null 2>&1; then
            print_success "Found required tool: $tool"
        else
            print_warning "Tool '$tool' not found (may cause issues)"
        fi
    done
    
    return 0
}

# Get user input with default value
get_input() {
    prompt="$1"
    default="$2"
    
    if [ -n "$default" ]; then
        printf "%s [%s]: " "$prompt" "$default"
    else
        printf "%s: " "$prompt"
    fi
    
    read -r input
    if [ -z "$input" ] && [ -n "$default" ]; then
        printf "%s" "$default"
    else
        printf "%s" "$input"
    fi
}

# Create configuration file
create_config() {
    print_info "Setting up configuration..."
    
    if [ -f ".env" ]; then
        print_warning ".env file already exists"
        printf "Do you want to overwrite it? [y/N]: "
        read -r overwrite
        case "$overwrite" in
            [Yy]|[Yy][Ee][Ss])
                print_info "Backing up existing .env to .env.backup"
                cp .env .env.backup
                ;;
            *)
                print_info "Skipping configuration setup"
                return 0
                ;;
        esac
    fi
    
    printf "\n%sConfiguration Setup%s\n" "$BLUE" "$NC"
    printf "==================\n\n"
    
    printf "To use AlertGrams, you need:\n"
    printf "1. A Telegram bot token (get one from @BotFather)\n"
    printf "2. Your Telegram chat ID (send a message to @userinfobot)\n\n"
    
    # Get Telegram API key
    api_key="$(get_input "Enter your Telegram Bot API Key" "")"
    if [ -z "$api_key" ]; then
        print_error "API key is required!"
        return 1
    fi
    
    # Get Chat ID
    chat_id="$(get_input "Enter your Telegram Chat ID" "")"
    if [ -z "$chat_id" ]; then
        print_error "Chat ID is required!"
        return 1
    fi
    
    # Optional settings
    log_file="$(get_input "Log file path (optional)" "alerts.log")"
    max_length="$(get_input "Maximum message length" "4096")"
    
    # Create .env file
    cat > .env << EOF
# AlertGrams Configuration
# ========================
# Telegram Bot API Key (get from @BotFather)
TELEGRAM_API_KEY=$api_key

# Telegram Chat ID (get from @userinfobot)
TELEGRAM_CHAT_ID=$chat_id

# Optional: Log file path (leave empty to disable logging)
LOG_FILE=$log_file

# Optional: Maximum message length (Telegram limit is 4096)
MAX_MESSAGE_LENGTH=$max_length
EOF
    
    print_success "Configuration saved to .env"
    return 0
}

# Set proper permissions
set_permissions() {
    print_info "Setting file permissions..."
    
    if [ -f "alert.sh" ]; then
        chmod +x alert.sh
        print_success "Made alert.sh executable"
    else
        print_warning "alert.sh not found in current directory"
    fi
    
    if [ -f ".env" ]; then
        chmod 600 .env
        print_success "Set secure permissions on .env file"
    fi
}

# Test the configuration
test_configuration() {
    print_info "Testing configuration..."
    
    if [ ! -f "alert.sh" ]; then
        print_error "alert.sh not found!"
        return 1
    fi
    
    if [ ! -f ".env" ]; then
        print_error ".env file not found!"
        return 1
    fi
    
    # Test with a simple message
    if ./alert.sh "INFO" "AlertGrams installation test - $(date)"; then
        print_success "Test alert sent successfully!"
        return 0
    else
        print_error "Failed to send test alert"
        print_info "Please check your configuration and try again"
        return 1
    fi
}

# Show usage examples
show_usage() {
    printf "\n%sUsage Examples%s\n" "$GREEN" "$NC"
    printf "==============\n\n"
    
    cat << 'EOF'
Basic usage:
    ./alert.sh "INFO" "System started successfully"
    ./alert.sh "WARNING" "Disk usage at 85%"
    ./alert.sh "CRITICAL" "Database connection failed"

Advanced examples:
    # Monitor disk space
    df -h | grep -E '8[0-9]%|9[0-9]%|100%' && ./alert.sh "WARNING" "High disk usage detected"
    
    # System monitoring
    uptime | awk '{print $3}' | grep -q 'days' || ./alert.sh "INFO" "System rebooted"
    
    # Log monitoring
    tail -n 10 /var/log/syslog | grep -i error && ./alert.sh "ERROR" "Errors found in syslog"

Integration with cron:
    # Add to crontab for regular checks
    */15 * * * * /path/to/alertgrams/alert.sh "INFO" "System check - $(date)"

For more information, see README.md
EOF
}

# Main installation function
main() {
    setup_colors
    
    printf "%sAlertGrams Installation%s\n" "$BLUE" "$NC"
    printf "======================\n\n"
    
    print_info "Welcome to AlertGrams - POSIX-compliant Telegram Alert Service"
    printf "\n"
    
    # Check requirements
    if ! check_requirements; then
        print_error "System requirements not met"
        exit 1
    fi
    
    printf "\n"
    
    # Create configuration
    if ! create_config; then
        print_error "Configuration setup failed"
        exit 1
    fi
    
    printf "\n"
    
    # Set permissions
    set_permissions
    
    printf "\n"
    
    # Test configuration
    printf "Do you want to send a test alert? [Y/n]: "
    read -r test_choice
    case "$test_choice" in
        [Nn]|[Nn][Oo])
            print_info "Skipping test"
            ;;
        *)
            if test_configuration; then
                printf "\n"
                print_success "Installation completed successfully!"
            else
                printf "\n"
                print_warning "Installation completed but test failed"
                print_info "Please check your configuration manually"
            fi
            ;;
    esac
    
    printf "\n"
    show_usage
    
    printf "\n"
    print_success "AlertGrams is ready to use!"
    print_info "Run './alert.sh --help' for more information"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help|help)
        printf "AlertGrams Installation Script\n\n"
        printf "Usage: %s [OPTIONS]\n\n" "$0"
        printf "Options:\n"
        printf "  -h, --help    Show this help message\n"
        printf "  --check-only  Only check requirements\n"
        printf "  --no-test     Skip the test alert\n\n"
        exit 0
        ;;
    --check-only)
        setup_colors
        check_requirements
        exit $?
        ;;
    *)
        main "$@"
        ;;
esac