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

# Installation configuration
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/alertgrams"
SERVICE_DIR="/etc/systemd/system"
SILENT_MODE=false

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

# Enhanced dependency checking for system installation
check_system_dependencies() {
    print_info "Checking system dependencies for installation..."
    
    missing_deps=""
    
    # Check for required commands for system installation
    for cmd in cp chmod chown mkdir; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps="$missing_deps $cmd"
        fi
    done
    
    # Check if running as root for system installation
    if [ "$(id -u)" -ne 0 ] && [ "${INSTALL_SYSTEM:-false}" = "true" ]; then
        print_warning "System installation requires root privileges"
        print_info "Run with 'sudo' for system-wide installation"
        return 1
    fi
    
    if [ -n "$missing_deps" ]; then
        print_error "Missing required commands:$missing_deps"
        return 1
    fi
    
    return 0
}

# Check for existing installation
check_existing_installation() {
    existing_files=""
    
    # Check for existing files in system locations
    if [ -f "$INSTALL_DIR/alert.sh" ]; then
        existing_files="$existing_files $INSTALL_DIR/alert.sh"
    fi
    
    if [ -f "$CONFIG_DIR/.env" ]; then
        existing_files="$existing_files $CONFIG_DIR/.env"
    fi
    
    if [ -f "$SERVICE_DIR/alertgrams.service" ]; then
        existing_files="$existing_files $SERVICE_DIR/alertgrams.service"
    fi
    
    if [ -n "$existing_files" ]; then
        print_warning "Existing AlertGrams installation detected:"
        for file in $existing_files; do
            printf "  • %s\n" "$file"
        done
        return 0
    fi
    
    return 1
}

# Backup existing configuration
backup_existing_config() {
    if [ -f "$CONFIG_DIR/.env" ]; then
        backup_file="$CONFIG_DIR/.env.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backing up existing configuration to $backup_file"
        cp "$CONFIG_DIR/.env" "$backup_file"
        print_success "Configuration backed up successfully"
    fi
}

# Copy scripts to system locations
install_system_files() {
    print_info "Installing AlertGrams to system locations..."
    
    # Create directories
    for dir in "$INSTALL_DIR" "$CONFIG_DIR"; do
        if [ ! -d "$dir" ]; then
            print_info "Creating directory: $dir"
            mkdir -p "$dir"
        fi
    done
    
    # Copy main script
    if [ -f "alert.sh" ]; then
        print_info "Installing alert.sh to $INSTALL_DIR/"
        cp alert.sh "$INSTALL_DIR/alert.sh"
        chmod 755 "$INSTALL_DIR/alert.sh"
        print_success "alert.sh installed successfully"
    else
        print_error "alert.sh not found in current directory"
        return 1
    fi
    
    # Copy or create configuration
    if [ -f ".env" ]; then
        print_info "Installing configuration to $CONFIG_DIR/"
        cp .env "$CONFIG_DIR/.env"
        chmod 600 "$CONFIG_DIR/.env"
        print_success "Configuration installed successfully"
    elif [ -f ".env.example" ]; then
        print_info "Creating configuration from example"
        cp .env.example "$CONFIG_DIR/.env"
        chmod 600 "$CONFIG_DIR/.env"
        print_info "Please configure $CONFIG_DIR/.env with your credentials"
    else
        print_warning "No configuration file found, will create from template"
    fi
    
    # Update script to use system config location
    sed -i "s|^\(.*\)\.env|\1$CONFIG_DIR/.env|" "$INSTALL_DIR/alert.sh" 2>/dev/null || true
    
    return 0
}

# Validate Telegram token format
validate_token_format() {
    token="$1"
    
    # Basic format validation: digits:alphanumeric_with_hyphens_underscores
    if echo "$token" | grep -q "^[0-9]\{8,12\}:[A-Za-z0-9_-]\{35,50\}$"; then
        return 0
    else
        return 1
    fi
}

# Enhanced configuration validation with format checking
validate_configuration_inputs() {
    api_key="$1"
    chat_id="$2"
    
    # Validate API key format
    if ! validate_token_format "$api_key"; then
        print_error "Invalid bot token format"
        print_info "Expected format: 123456789:ABCdefGHIjklMNOpqrSTUv-wxyz_123"
        return 1
    fi
    
    # Validate Chat ID format (numeric, can be negative for groups)
    if ! echo "$chat_id" | grep -q "^-\?[0-9]\{5,15\}$"; then
        print_error "Invalid chat ID format"
        print_info "Expected format: 123456789 or -1001234567890 (for groups)"
        return 1
    fi
    
    print_success "Configuration format validation passed"
    return 0
}

# Create systemd service file
create_systemd_service() {
    service_user="${1:-alertgrams}"
    
    if [ ! -d "$SERVICE_DIR" ]; then
        print_warning "Systemd not available, skipping service creation"
        return 1
    fi
    
    print_info "Creating systemd service file..."
    
    cat > "$SERVICE_DIR/alertgrams.service" << EOF
[Unit]
Description=AlertGrams Telegram Alert Service
After=network.target

[Service]
Type=oneshot
User=$service_user
Group=$service_user
WorkingDirectory=$CONFIG_DIR
Environment=PATH=/usr/local/bin:/usr/bin:/bin
ExecStart=$INSTALL_DIR/alert.sh "INFO" "AlertGrams service is running"
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    chmod 644 "$SERVICE_DIR/alertgrams.service"
    print_success "Systemd service file created"
    
    # Reload systemd daemon
    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload
        print_success "Systemd daemon reloaded"
    fi
    
    return 0
}

# Create service user
create_service_user() {
    username="alertgrams"
    
    if id "$username" >/dev/null 2>&1; then
        print_info "User '$username' already exists"
        return 0
    fi
    
    print_info "Creating service user: $username"
    
    # Create system user
    if command -v useradd >/dev/null 2>&1; then
        useradd --system --no-create-home --shell /bin/false "$username"
        print_success "Service user '$username' created"
    else
        print_warning "Cannot create user (useradd not available)"
        return 1
    fi
    
    # Set ownership of config directory
    chown -R "$username:$username" "$CONFIG_DIR"
    
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

# Load existing configuration if available
load_existing_config() {
    if [ -f ".env" ]; then
        # Load existing values
        EXISTING_API_KEY=""
        EXISTING_CHAT_ID=""
        EXISTING_LOG_FILE=""
        EXISTING_MAX_LENGTH=""
        
        # Read existing configuration (safely)
        while IFS='=' read -r key value; do
            # Remove carriage return if present (Windows line endings)
            value=$(printf "%s" "$value" | tr -d '\r')
            # Skip comments and empty lines
            case "$key" in
                \#*|'') continue ;;
                TELEGRAM_API_KEY) EXISTING_API_KEY="$value" ;;
                TELEGRAM_CHAT_ID) EXISTING_CHAT_ID="$value" ;;
                LOG_FILE) EXISTING_LOG_FILE="$value" ;;
                MAX_MESSAGE_LENGTH) EXISTING_MAX_LENGTH="$value" ;;
            esac
        done < .env
        
        return 0
    fi
    return 1
}

# Validate mandatory settings
validate_mandatory_settings() {
    api_key="$1"
    chat_id="$2"
    
    # Check API key
    if [ -z "$api_key" ] || [ "$api_key" = "YOUR_BOT_TOKEN_HERE" ]; then
        return 1
    fi
    
    # Check Chat ID  
    if [ -z "$chat_id" ] || [ "$chat_id" = "YOUR_CHAT_ID_HERE" ]; then
        return 1
    fi
    
    return 0
}

# Validate Telegram credentials by making API calls
validate_telegram_credentials() {
    api_key="$1"
    chat_id="$2"
    
    # Check if HTTP client is available
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        return 1
    fi
    
    printf "Checking bot token... "
    
    # Test bot token with getMe API call
    api_url="https://api.telegram.org/bot${api_key}/getMe"
    
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -s --connect-timeout 10 --max-time 15 "$api_url" 2>/dev/null)
    elif command -v wget >/dev/null 2>&1; then
        response=$(wget -q --timeout=15 -O- "$api_url" 2>/dev/null)
    else
        return 1
    fi
    
    # Check if API call was successful
    if echo "$response" | grep -q '"ok":true'; then
        printf "✅\n"
        printf "Checking chat access... "
        
        # Test chat ID by sending a test message (without actually sending)
        chat_url="https://api.telegram.org/bot${api_key}/getChat?chat_id=${chat_id}"
        
        if command -v curl >/dev/null 2>&1; then
            chat_response=$(curl -s --connect-timeout 10 --max-time 15 "$chat_url" 2>/dev/null)
        elif command -v wget >/dev/null 2>&1; then
            chat_response=$(wget -q --timeout=15 -O- "$chat_url" 2>/dev/null)
        else
            return 1
        fi
        
        if echo "$chat_response" | grep -q '"ok":true'; then
            printf "✅\n"
            return 0
        else
            printf "❌\n"
            if echo "$chat_response" | grep -q "chat not found"; then
                print_warning "Chat ID appears to be invalid or bot doesn't have access"
            elif echo "$chat_response" | grep -q "bot was blocked"; then
                print_warning "Bot was blocked by the user"
            else
                print_warning "Could not access chat (may need to start conversation with bot first)"
            fi
            return 1
        fi
    else
        printf "❌\n"
        if echo "$response" | grep -q "unauthorized"; then
            print_warning "Bot token appears to be invalid"
        else
            print_warning "Could not validate bot token"
        fi
        return 1
    fi
}

# Get mandatory setting with validation and better user guidance
get_mandatory_setting() {
    prompt="$1"
    current_value="$2"
    setting_name="$3"
    
    # If we have a valid current value, ask if user wants to keep it
    if [ -n "$current_value" ] && [ "$current_value" != "YOUR_BOT_TOKEN_HERE" ] && [ "$current_value" != "YOUR_CHAT_ID_HERE" ]; then
        # Show masked value for security (API key only)
        if [ "$setting_name" = "API_KEY" ]; then
            masked_value="$(echo "$current_value" | sed 's/\(.\{4\}\).*/\1****/')"
            printf "Current Bot Token: %s%s%s\n" "$GREEN" "$masked_value" "$NC" >&2
            printf "Keep this token? [%sY%s/n]: " "$GREEN" "$NC" >&2
        else
            printf "Current Chat ID: %s%s%s\n" "$GREEN" "$current_value" "$NC" >&2
            printf "Keep this Chat ID? [%sY%s/n]: " "$GREEN" "$NC" >&2
        fi
        
        read -r keep_current </dev/tty
        case "$keep_current" in
            [Nn]|[Nn][Oo])
                if [ "$setting_name" = "API_KEY" ]; then
                    printf "\n%sEntering new Bot Token:%s\n" "$YELLOW" "$NC" >&2
                else
                    printf "\n%sEntering new Chat ID:%s\n" "$YELLOW" "$NC" >&2
                fi
                ;;
            *)
                if [ "$setting_name" = "API_KEY" ]; then
                    printf "✅ Keeping existing bot token\n" >&2
                else
                    printf "✅ Keeping existing chat ID\n" >&2
                fi
                printf "%s" "$current_value"
                return 0
                ;;
        esac
    fi
    
    # Ask for new value with helpful prompts
    while true; do
        if [ "$setting_name" = "API_KEY" ]; then
            printf "Enter your Bot Token (from @BotFather): " >&2
            read -r new_value </dev/tty
            
            # Validate bot token format
            if [ -n "$new_value" ]; then
                if echo "$new_value" | grep -q "^[0-9]\+:[A-Za-z0-9_-]\+$"; then
                    printf "✅ Bot token format looks correct\n" >&2
                    printf "%s" "$new_value"
                    return 0
                else
                    print_warning "Bot token format seems incorrect" >&2
                    printf "Expected format: 123456789:ABCdefGHIjklMNOpqrSTUvwxyz\n" >&2
                    printf "Continue anyway? [y/N]: " >&2
                    read -r continue_anyway </dev/tty
                    case "$continue_anyway" in
                        [Yy]|[Yy][Ee][Ss])
                            printf "%s" "$new_value"
                            return 0
                            ;;
                        *)
                            printf "Please enter a valid bot token.\n\n" >&2
                            continue
                            ;;
                    esac
                fi
            else
                print_error "Bot token cannot be empty!" >&2
                printf "%sHow to get a bot token:%s\n" "$BLUE" "$NC" >&2
                printf "1. Open Telegram and search for @BotFather\n" >&2
                printf "2. Send /newbot command\n" >&2
                printf "3. Follow the instructions to create your bot\n" >&2
                printf "4. Copy the token provided\n\n" >&2
                continue
            fi
        else
            printf "Enter your Chat ID (from @userinfobot): " >&2
            read -r new_value </dev/tty
            
            # Validate chat ID format
            if [ -n "$new_value" ]; then
                if echo "$new_value" | grep -q "^-\?[0-9]\+$"; then
                    printf "✅ Chat ID format looks correct\n" >&2
                    printf "%s" "$new_value"
                    return 0
                else
                    print_warning "Chat ID format seems incorrect" >&2
                    printf "Expected format: 123456789 or -1001234567890 (for groups)\n" >&2
                    printf "Continue anyway? [y/N]: " >&2
                    read -r continue_anyway </dev/tty
                    case "$continue_anyway" in
                        [Yy]|[Yy][Ee][Ss])
                            printf "%s" "$new_value"
                            return 0
                            ;;
                        *)
                            printf "Please enter a valid chat ID.\n\n" >&2
                            continue
                            ;;
                    esac
                fi
            else
                print_error "Chat ID cannot be empty!" >&2
                printf "%sHow to get your chat ID:%s\n" "$BLUE" "$NC" >&2
                printf "1. Send a message to @userinfobot on Telegram\n" >&2
                printf "2. Copy the ID number shown\n" >&2
                printf "3. For groups: add your bot to the group first\n\n" >&2
                continue
            fi
        fi
    done
}

# Get optional setting with current value display
get_optional_setting() {
    prompt="$1"
    current_value="$2"
    default_value="$3"
    
    if [ -n "$current_value" ]; then
        printf "%s\nCurrent value: %s%s%s\n" "$prompt" "$GREEN" "$current_value" "$NC" >&2
        printf "Keep current value? [%sY%s/n]: " "$GREEN" "$NC" >&2
        read -r keep_current </dev/tty
        case "$keep_current" in
            [Nn]|[Nn][Oo])
                printf "Enter new value [%s]: " "$default_value" >&2
                read -r new_value </dev/tty
                if [ -z "$new_value" ]; then
                    printf "%s" "$default_value"
                else
                    printf "%s" "$new_value"
                fi
                ;;
            *)
                printf "✅ Keeping current value\n" >&2
                printf "%s" "$current_value"
                ;;
        esac
    else
        printf "%s [%s]: " "$prompt" "$default_value" >&2
        read -r new_value </dev/tty
        if [ -z "$new_value" ]; then
            printf "%s" "$default_value"
        else
            printf "%s" "$new_value"
        fi
    fi
}

# Create configuration file
create_config() {
    print_info "Setting up configuration..."
    
    # Load existing configuration
    config_exists=false
    if load_existing_config; then
        config_exists=true
        print_info "Found existing configuration"
        
        # Check if mandatory settings are properly configured
        if validate_mandatory_settings "$EXISTING_API_KEY" "$EXISTING_CHAT_ID"; then
            print_success "Current configuration appears to be complete"
            printf "Do you want to review/modify the configuration? [y/N]: "
            read -r modify_config
            case "$modify_config" in
                [Yy]|[Yy][Ee][Ss])
                    print_info "Reviewing current configuration..."
                    ;;
                *)
                    print_info "Keeping existing configuration"
                    return 0
                    ;;
            esac
        else
            print_warning "Current configuration is incomplete or contains default values"
            print_info "Let's complete the configuration..."
        fi
        
        # Backup existing config
        print_info "Backing up existing .env to .env.backup"
        cp .env .env.backup
    fi
    
    printf "\n%sConfiguration Setup%s\n" "$BLUE" "$NC"
    printf "===================\n\n"
    
    if [ "$config_exists" = false ]; then
        printf "To use AlertGrams, you need:\n"
        printf "1. A Telegram bot token (get one from @BotFather)\n"
        printf "2. Your Telegram chat ID (send a message to @userinfobot)\n\n"
        
        printf "%sMandatory Settings:%s\n" "$YELLOW" "$NC"
        printf "These settings are required for AlertGrams to work:\n\n"
    else
        printf "%sReviewing Configuration:%s\n" "$YELLOW" "$NC"
        printf "Current settings will be shown with options to keep or change them:\n\n"
        
        printf "%sMandatory Settings:%s\n" "$YELLOW" "$NC"
    fi
    
    # Get mandatory settings with improved guidance
    api_key=""
    chat_id=""
    
    # Check if both mandatory settings are missing or contain defaults
    both_missing=false
    if [ -z "${EXISTING_API_KEY:-}" ] || [ "${EXISTING_API_KEY:-}" = "YOUR_BOT_TOKEN_HERE" ] || \
       [ -z "${EXISTING_CHAT_ID:-}" ] || [ "${EXISTING_CHAT_ID:-}" = "YOUR_CHAT_ID_HERE" ]; then
        both_missing=true
    fi
    
    # If both are missing, provide step-by-step guidance with direct input
    if [ "$both_missing" = true ] && [ "$config_exists" = false ]; then
        printf "%sStep-by-Step Setup Guide:%s\n" "$GREEN" "$NC"
        printf "Follow these steps to get your Telegram credentials:\n\n"
        
        printf "%s1. Get Bot Token:%s\n" "$BLUE" "$NC"
        printf "   • Open Telegram and search for @BotFather\n"
        printf "   • Send /newbot command\n"
        printf "   • Follow instructions to create your bot\n"
        printf "   • Copy the token provided (format: 123456789:ABCdefGHI...)\n\n"
        
        printf "%s2. Get Chat ID:%s\n" "$BLUE" "$NC"
        printf "   • Send a message to @userinfobot\n"
        printf "   • Copy the ID number shown (may include negative sign)\n"
        printf "   • For groups: add your bot first, then get group ID\n\n"
        
        printf "Press Enter when you have both credentials ready..."
        read -r _ </dev/tty
        printf "\n"
        
        # Direct input for both credentials
        printf "%sNow enter your credentials:%s\n" "$YELLOW" "$NC"
        printf "Bot Token (from @BotFather): "
        read -r api_key </dev/tty
        
        printf "Chat ID (from @userinfobot): "
        read -r chat_id </dev/tty
        printf "\n"
        
        # Validate inputs
        if [ -z "$api_key" ]; then
            print_error "Bot token cannot be empty!"
            return 1
        fi
        
        if [ -z "$chat_id" ]; then
            print_error "Chat ID cannot be empty!"
            return 1
        fi
        
        print_success "✅ Credentials received successfully!"
        
    else
        # Get Bot Token (existing logic for when config already exists)
        if [ -z "${EXISTING_API_KEY:-}" ] || [ "${EXISTING_API_KEY:-}" = "YOUR_BOT_TOKEN_HERE" ]; then
            printf "%sBot Token Setup:%s\n" "$YELLOW" "$NC"
            printf "Your bot token is not configured yet.\n"
            api_key="$(get_mandatory_setting "Enter your Telegram Bot API Key" "" "API_KEY")"
        else
            printf "%sBot Token Review:%s\n" "$YELLOW" "$NC"
            api_key="$(get_mandatory_setting "Current Bot Token" "${EXISTING_API_KEY}" "API_KEY")"
        fi
        
        if [ -z "$api_key" ]; then
            print_error "Bot token is required and cannot be empty!"
            print_info "Please get a bot token from @BotFather on Telegram"
            return 1
        fi
        
        printf "\n"
        
        # Get Chat ID (existing logic for when config already exists)
        if [ -z "${EXISTING_CHAT_ID:-}" ] || [ "${EXISTING_CHAT_ID:-}" = "YOUR_CHAT_ID_HERE" ]; then
            printf "%sChat ID Setup:%s\n" "$YELLOW" "$NC"
            printf "Your chat ID is not configured yet.\n"
            chat_id="$(get_mandatory_setting "Enter your Telegram Chat ID" "" "CHAT_ID")"
        else
            printf "%sChat ID Review:%s\n" "$YELLOW" "$NC"
            chat_id="$(get_mandatory_setting "Current Chat ID" "${EXISTING_CHAT_ID}" "CHAT_ID")"
        fi
        
        if [ -z "$chat_id" ]; then
            print_error "Chat ID is required and cannot be empty!"
            print_info "Please get your chat ID from @userinfobot on Telegram"
            return 1
        fi
    fi
    
    # Validate credentials if possible
    printf "\n%sValidating Telegram Credentials:%s\n" "$BLUE" "$NC"
    if validate_telegram_credentials "$api_key" "$chat_id"; then
        print_success "✅ Telegram credentials validated successfully!"
    else
        print_warning "⚠️ Could not validate credentials (this is normal if offline)"
        printf "We'll proceed with the configuration anyway.\n"
        printf "You can test the configuration later with: ./install.sh --test-only\n"
    fi
    
    printf "\n%sOptional Settings:%s\n" "$YELLOW" "$NC"
    printf "These settings can be left with default values.\n\n"
    
    printf "%sAvailable optional settings:%s\n" "$BLUE" "$NC"
    printf "  • Log file: Where to save alert logs (default: alerts.log)\n"
    printf "  • Max message length: Telegram message limit (default: 4096)\n\n"
    
    if [ "$SILENT_MODE" = false ]; then
        printf "%sDo you want to configure optional settings? [y/N]:%s " "$YELLOW" "$NC"
        read -r configure_optional </dev/tty
        case "$configure_optional" in
            [Yy]|[Yy][Ee][Ss])
                printf "\n%sConfiguring Optional Settings:%s\n" "$GREEN" "$NC"
                printf "You can press Enter to use the default value shown in brackets.\n\n"
                
                # Get optional settings with better prompts
                log_file="$(get_optional_setting "Log file path (empty to disable logging)" "${EXISTING_LOG_FILE:-}" "alerts.log")"
                printf "\n"
                max_length="$(get_optional_setting "Maximum message length" "${EXISTING_MAX_LENGTH:-}" "4096")"
                ;;
            *)
                print_success "Using default optional settings:"
                printf "  • Log file: %salerts.log%s\n" "$GREEN" "$NC"
                printf "  • Max message length: %s4096%s characters\n" "$GREEN" "$NC"
                log_file="${EXISTING_LOG_FILE:-alerts.log}"
                max_length="${EXISTING_MAX_LENGTH:-4096}"
                ;;
        esac
    else
        # Silent mode - use defaults
        print_info "Silent mode: Using default optional settings"
        log_file="${EXISTING_LOG_FILE:-alerts.log}"
        max_length="${EXISTING_MAX_LENGTH:-4096}"
    fi
    
    # Validate max_length is numeric
    if ! printf "%s" "$max_length" | grep -q '^[0-9]\+$'; then
        print_warning "Invalid maximum message length, using default: 4096"
        max_length="4096"
    fi
    
    # Create .env file
    printf "\n"
    print_info "Creating configuration file..."
    
    cat > .env << EOF
# AlertGrams Configuration
# ========================
# Generated on: $(date)

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
    
    # Show configuration summary (with masked API key)
    printf "\n%sConfiguration Summary:%s\n" "$GREEN" "$NC"
    masked_api="$(echo "$api_key" | sed 's/\(.\{4\}\).*/\1****/')"
    printf "  • API Key: %s\n" "$masked_api"
    printf "  • Chat ID: %s\n" "$chat_id"
    printf "  • Log File: %s\n" "${log_file:-"(disabled)"}"
    printf "  • Max Length: %s characters\n" "$max_length"
    
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

# Test the configuration with user confirmation
test_configuration() {
    # Ask user if they want to send a test alert
    if [ "$SILENT_MODE" = false ]; then
        printf "\n%sDo you want to send a test alert now? (y/n):%s " "$YELLOW" "$NC"
        read -r send_test </dev/tty
        case "$send_test" in
            [Nn]|[Nn][Oo])
                print_info "Skipping test alert"
                return 0
                ;;
        esac
    fi
    
    print_info "Testing configuration..."
    
    # Determine config and script locations
    config_file=".env"
    script_file="alert.sh"
    
    # Check for system installation
    if [ "${INSTALL_SYSTEM:-false}" = "true" ]; then
        config_file="$CONFIG_DIR/.env"
        script_file="$INSTALL_DIR/alert.sh"
    fi
    
    # Check required files
    if [ ! -f "$script_file" ]; then
        print_error "alert.sh not found at $script_file!"
        print_info "Make sure the installation completed successfully"
        return 1
    fi
    
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found at $config_file!"
        print_info "Configuration file is missing. Please run the setup again."
        return 1
    fi
    
    # Validate configuration before testing
    print_info "Validating configuration..."
    
    # Load and check configuration from appropriate location
    if [ "${INSTALL_SYSTEM:-false}" = "true" ]; then
        # Load from system config
        temp_api_key=""
        temp_chat_id=""
        while IFS='=' read -r key value; do
            value=$(printf "%s" "$value" | tr -d '\r')
            case "$key" in
                \#*|'') continue ;;
                TELEGRAM_API_KEY) temp_api_key="$value" ;;
                TELEGRAM_CHAT_ID) temp_chat_id="$value" ;;
            esac
        done < "$config_file"
        
        if ! validate_mandatory_settings "$temp_api_key" "$temp_chat_id"; then
            print_error "Configuration validation failed!"
            print_info "Please check your configuration at $config_file"
            return 1
        fi
        
        # Additional format validation
        if ! validate_configuration_inputs "$temp_api_key" "$temp_chat_id"; then
            return 1
        fi
    else
        # Load from local config
        if load_existing_config; then
            if ! validate_mandatory_settings "$EXISTING_API_KEY" "$EXISTING_CHAT_ID"; then
                print_error "Configuration validation failed!"
                print_info "Please check your .env file or run the configuration setup again"
                return 1
            fi
            
            # Additional format validation
            if ! validate_configuration_inputs "$EXISTING_API_KEY" "$EXISTING_CHAT_ID"; then
                return 1
            fi
        else
            print_error "Could not load configuration from $config_file"
            return 1
        fi
    fi
    
    print_success "Configuration validation passed"
    
    # Test HTTP client availability
    print_info "Checking HTTP client availability..."
    if command -v curl >/dev/null 2>&1; then
        print_success "Found curl"
    elif command -v wget >/dev/null 2>&1; then
        print_success "Found wget"
    else
        print_error "Neither curl nor wget is available!"
        print_info "Please install curl or wget to send HTTP requests"
        return 1
    fi
    
    # Test with a simple message
    print_info "Sending test alert to Telegram..."
    test_message="AlertGrams installation test - $(date)"
    
    if [ "${INSTALL_SYSTEM:-false}" = "true" ]; then
        # Use system installation
        if "$script_file" "INFO" "$test_message"; then
            send_test_success
            return 0
        else
            send_test_failure
            return 1
        fi
    else
        # Use local installation
        if ./alert.sh "INFO" "$test_message"; then
            send_test_success
            return 0
        else
            send_test_failure
            return 1
        fi
    fi
}

# Test success message
send_test_success() {
    print_success "Test alert sent successfully!"
    printf "\n%sTest Results:%s\n" "$GREEN" "$NC"
    printf "  ✅ Configuration is valid\n"
    printf "  ✅ HTTP client is working\n"
    printf "  ✅ Telegram API connection successful\n"
    printf "  ✅ Alert message delivered\n"
    printf "\nCheck your Telegram chat to confirm you received the test message.\n"
}

# Test failure message
send_test_failure() {
    print_error "Failed to send test alert"
    printf "\n%sTroubleshooting:%s\n" "$YELLOW" "$NC"
    printf "1. Verify your bot token is correct and properly formatted\n"
    printf "2. Check that your chat ID is valid and accessible\n"
    printf "3. Ensure your bot has permission to send messages\n"
    printf "4. Check your internet connection\n"
    printf "5. Review the error messages above\n"
    printf "\nFor more help, see the README.md file.\n"
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

# Setup service functionality
setup_service() {
    if [ "$SILENT_MODE" = false ]; then
        printf "\n%sThis will run alertgrams as service. Do you want to proceed? (y/n):%s " "$YELLOW" "$NC"
        read -r setup_service_choice </dev/tty
        case "$setup_service_choice" in
            [Nn]|[Nn][Oo])
                print_info "Skipping service setup"
                return 0
                ;;
        esac
    fi
    
    print_info "Setting up AlertGrams as a system service..."
    
    # Create service user
    if create_service_user; then
        print_success "Service user created successfully"
    else
        print_warning "Service user creation failed, using current user"
    fi
    
    # Create systemd service
    if create_systemd_service "alertgrams"; then
        print_success "Systemd service created successfully"
        print_info "To enable service: sudo systemctl enable alertgrams"
        print_info "To start service:  sudo systemctl start alertgrams"
        print_info "To check status:   sudo systemctl status alertgrams"
    else
        print_warning "Could not create systemd service"
    fi
    
    return 0
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
    
    # Check for system installation option
    if [ "${INSTALL_SYSTEM:-false}" = "true" ]; then
        printf "\n"
        print_info "Performing system-wide installation..."
        
        # Check system dependencies
        if ! check_system_dependencies; then
            print_error "System dependencies not met"
            exit 1
        fi
        
        # Check for existing installation
        if check_existing_installation; then
            if [ "$SILENT_MODE" = false ]; then
                printf "Do you want to continue and overwrite? [y/N]: "
                read -r overwrite_choice </dev/tty
                case "$overwrite_choice" in
                    [Yy]|[Yy][Ee][Ss])
                        backup_existing_config
                        ;;
                    *)
                        print_info "Installation cancelled by user"
                        exit 0
                        ;;
                esac
            else
                backup_existing_config
            fi
        fi
        
        # Install system files
        if ! install_system_files; then
            print_error "System file installation failed"
            exit 1
        fi
        
        print_success "System files installed successfully"
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
    
    # Test configuration (with user confirmation)
    if test_configuration; then
        printf "\n"
        print_success "Configuration test completed successfully!"
    else
        printf "\n"
        print_warning "Configuration test failed"
        print_info "Please check your configuration manually"
    fi
    
    # Setup service if system installation
    if [ "${INSTALL_SYSTEM:-false}" = "true" ]; then
        setup_service
    fi
    
    printf "\n"
    show_usage
    
    printf "\n"
    print_success "AlertGrams installation completed!"
    
    if [ "${INSTALL_SYSTEM:-false}" = "true" ]; then
        print_info "System installation complete. Use 'alert.sh' from anywhere"
        print_info "Configuration located at: $CONFIG_DIR/.env"
    else
        print_info "Local installation complete. Run './alert.sh --help' for more information"
    fi
}

# Show current configuration (without sensitive data)
show_config() {
    setup_colors
    
    if [ ! -f ".env" ]; then
        print_error "No configuration file found (.env)"
        print_info "Run './install.sh' to create initial configuration"
        return 1
    fi
    
    printf "%sCurrent AlertGrams Configuration%s\n" "$BLUE" "$NC"
    printf "================================\n\n"
    
    if load_existing_config; then
        # Show configuration status
        if validate_mandatory_settings "$EXISTING_API_KEY" "$EXISTING_CHAT_ID"; then
            print_success "Configuration is complete and valid"
        else
            print_warning "Configuration is incomplete or contains default values"
        fi
        
        printf "\n%sConfiguration Details:%s\n" "$YELLOW" "$NC"
        
        # Show API key (masked)
        if [ -n "$EXISTING_API_KEY" ] && [ "$EXISTING_API_KEY" != "YOUR_BOT_TOKEN_HERE" ]; then
            masked_api="$(echo "$EXISTING_API_KEY" | sed 's/\(.\{4\}\).*/\1****/')"
            printf "  • API Key: %s ✅\n" "$masked_api"
        else
            printf "  • API Key: Not configured ❌\n"
        fi
        
        # Show Chat ID
        if [ -n "$EXISTING_CHAT_ID" ] && [ "$EXISTING_CHAT_ID" != "YOUR_CHAT_ID_HERE" ]; then
            printf "  • Chat ID: %s ✅\n" "$EXISTING_CHAT_ID"
        else
            printf "  • Chat ID: Not configured ❌\n"
        fi
        
        # Show optional settings
        printf "  • Log File: %s\n" "${EXISTING_LOG_FILE:-"(disabled)"}"
        printf "  • Max Length: %s characters\n" "${EXISTING_MAX_LENGTH:-"4096"}"
        
        printf "\n%sConfiguration File:%s .env\n" "$YELLOW" "$NC"
        printf "%sLast Modified:%s $(ls -l .env 2>/dev/null | awk '{print $6, $7, $8}')\n" "$YELLOW" "$NC"
        
        # Check file permissions
        if [ -r ".env" ]; then
            perms="$(ls -l .env | cut -c1-10)"
            if [ "$perms" = "-rw-------" ]; then
                printf "%sFile Permissions:%s %s ✅ (secure)\n" "$YELLOW" "$NC" "$perms"
            else
                printf "%sFile Permissions:%s %s ⚠️ (recommend: chmod 600 .env)\n" "$YELLOW" "$NC" "$perms"
            fi
        fi
        
    else
        print_error "Could not load configuration file"
        return 1
    fi
}

# Quick configuration check
check_config() {
    setup_colors
    
    if [ ! -f ".env" ]; then
        print_error "Configuration file not found"
        return 1
    fi
    
    if load_existing_config && validate_mandatory_settings "$EXISTING_API_KEY" "$EXISTING_CHAT_ID"; then
        print_success "Configuration is valid"
        return 0
    else
        print_error "Configuration is incomplete or invalid"
        return 1
    fi
}

# Parse command line arguments
case "${1:-}" in
    -h|--help|help)
        printf "AlertGrams Installation Script\n\n"
        printf "Usage: %s [OPTIONS]\n\n" "$0"
        printf "Options:\n"
        printf "  -h, --help         Show this help message\n"
        printf "  --check-only       Only check system requirements\n"
        printf "  --show-config      Display current configuration\n"
        printf "  --check-config     Quick configuration validation\n"
        printf "  --config-only      Setup configuration only (skip tests)\n"
        printf "  --configure        Interactive configuration setup\n"
        printf "  --no-test          Skip the test alert\n"
        printf "  --test-only        Only run configuration test\n"
        printf "  --system           Install system-wide (requires root)\n"
        printf "  --silent           Silent installation (no prompts)\n"
        printf "  --service          Setup as system service (with --system)\n\n"
        printf "Examples:\n"
        printf "  %s                        Full local installation\n" "$0"
        printf "  %s --system               System-wide installation\n" "$0"
        printf "  %s --system --service     System install with service\n" "$0"
        printf "  %s --show-config          Show current configuration\n" "$0"
        printf "  %s --config-only          Setup configuration only\n" "$0"
        printf "  %s --silent --system      Silent system installation\n" "$0"
        printf "\n"
        exit 0
        ;;
    --system)
        INSTALL_SYSTEM=true
        shift
        # Check for additional options
        case "${1:-}" in
            --service)
                SETUP_SERVICE=true
                shift
                ;;
            --silent)
                SILENT_MODE=true
                shift
                ;;
        esac
        main "$@"
        exit 0
        ;;
    --silent)
        SILENT_MODE=true
        shift
        # Check for additional options
        case "${1:-}" in
            --system)
                INSTALL_SYSTEM=true
                shift
                case "${1:-}" in
                    --service)
                        SETUP_SERVICE=true
                        ;;
                esac
                ;;
        esac
        main "$@"
        exit 0
        ;;
    --configure)
        setup_colors
        printf "%sAlertGrams Interactive Configuration%s\n" "$BLUE" "$NC"
        printf "===================================\n\n"
        check_requirements && create_config && set_permissions
        exit $?
        ;;
    --check-only)
        setup_colors
        check_requirements
        exit $?
        ;;
    --show-config)
        show_config
        exit $?
        ;;
    --check-config)
        check_config
        exit $?
        ;;
    --config-only)
        setup_colors
        printf "%sAlertGrams Configuration Setup%s\n" "$BLUE" "$NC"
        printf "=============================\n\n"
        check_requirements && create_config && set_permissions
        exit $?
        ;;
    --test-only)
        setup_colors
        printf "%sAlertGrams Configuration Test%s\n" "$BLUE" "$NC"
        printf "============================\n\n"
        test_configuration
        exit $?
        ;;
    --no-test)
        main_no_test() {
            setup_colors
            printf "%sAlertGrams Installation (No Test)%s\n" "$BLUE" "$NC"
            printf "=================================\n\n"
            print_info "Welcome to AlertGrams - POSIX-compliant Telegram Alert Service"
            printf "\n"
            
            if ! check_requirements; then
                print_error "System requirements not met"
                exit 1
            fi
            
            printf "\n"
            if ! create_config; then
                print_error "Configuration setup failed"
                exit 1
            fi
            
            printf "\n"
            set_permissions
            
            printf "\n"
            show_usage
            
            printf "\n"
            print_success "AlertGrams installation completed!"
            print_info "Run './install.sh --test-only' to test your configuration"
            print_info "Run './alert.sh --help' for usage information"
        }
        main_no_test
        exit $?
        ;;
    *)
        main "$@"
        ;;
esac