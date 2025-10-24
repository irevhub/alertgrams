#!/bin/sh
# Telegram Alert Script (POSIX-Compliant)
# ----------------------------------------
# Description: Send alerts to Telegram bot without external dependencies
# Version: 1.1.1
# Author: AlertGrams Project
#
# Usage:
#   ./alert.sh "<LEVEL>" "<MESSAGE>"
#
# Examples:
#   ./alert.sh "CRITICAL" "Disk space low on /dev/root"
#   ./alert.sh "INFO" "Backup completed successfully"
#   ./alert.sh "WARNING" "High CPU usage detected"
#
# Requirements:
#   - /bin/sh (POSIX shell)
#   - curl or wget
#   - .env file with TELEGRAM_API_KEY and TELEGRAM_CHAT_ID

set -eu

# Load configuration from .env file
load_config() {
    if [ -f ".env" ]; then
        set -a
        # shellcheck disable=SC1091
        . ./.env
        set +a
    else
        printf "Error: Missing .env file. Please create one with TELEGRAM_API_KEY and TELEGRAM_CHAT_ID\n" >&2
        printf "Use .env.example as a template\n" >&2
        exit 1
    fi
}

# Validate required configuration
validate_config() {
    : "${TELEGRAM_API_KEY:?Error: TELEGRAM_API_KEY is required in .env file}"
    : "${TELEGRAM_CHAT_ID:?Error: TELEGRAM_CHAT_ID is required in .env file}"
    
    # Optional settings with defaults
    LOG_FILE="${LOG_FILE:-}"
    MAX_MESSAGE_LENGTH="${MAX_MESSAGE_LENGTH:-4096}"
}

# URL encode text for safe transmission
url_encode() {
    text="$1"
    # Basic URL encoding for common characters
    printf '%s' "$text" | sed '
        s/ /%20/g
        s/!/%21/g
        s/"/%22/g
        s/#/%23/g
        s/\$/%24/g
        s/&/%26/g
        s/'\''/%27/g
        s/(/%28/g
        s/)/%29/g
        s/\*/%2A/g
        s/+/%2B/g
        s/,/%2C/g
        s/-/%2D/g
        s/\./%2E/g
        s/\//%2F/g
        s/:/%3A/g
        s/;/%3B/g
        s/</%3C/g
        s/=/%3D/g
        s/>/%3E/g
        s/?/%3F/g
        s/@/%40/g
        s/\[/%5B/g
        s/\\/%5C/g
        s/\]/%5D/g
        s/\^/%5E/g
        s/_/%5F/g
        s/`/%60/g
        s/{/%7B/g
        s/|/%7C/g
        s/}/%7D/g
        s/~/%7E/g
        s/\n/%0A/g
    '
}

# Get appropriate emoji for alert level
get_emoji() {
    level="$1"
    case "$level" in
        INFO|info) printf "✅";;
        WARNING|warn|warning) printf "⚠️";;
        CRITICAL|crit|critical|ERROR|error) printf "🚨";;
        SUCCESS|success) printf "🎉";;
        DEBUG|debug) printf "🔍";;
        *) printf "💬";;
    esac
}

# Format message for Telegram (Markdown)
format_message() {
    level="$1"
    message="$2"
    timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)"
    hostname="$(hostname 2>/dev/null || echo "unknown")"
    emoji="$(get_emoji "$level")"
    
    # Escape special Markdown characters in message
    escaped_message="$(printf '%s' "$message" | sed 's/\*/\\*/g; s/_/\\_/g; s/\[/\\[/g; s/`/\\`/g')"
    
    # Build formatted message
    formatted_text="*${emoji} [${level}] Alert*
Host: _${hostname}_
Time: \`${timestamp}\`

${escaped_message}"
    
    # Truncate if too long
    if [ ${#formatted_text} -gt "$MAX_MESSAGE_LENGTH" ]; then
        truncated_length=$((MAX_MESSAGE_LENGTH - 50))
        formatted_text="$(printf '%s' "$formatted_text" | cut -c1-$truncated_length)... [truncated]"
    fi
    
    printf '%s' "$formatted_text"
}

# Send message via HTTP client
send_http_request() {
    api_url="$1"
    payload="$2"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsS -X POST "$api_url" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "$payload" >/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- --post-data="$payload" \
            --header="Content-Type: application/x-www-form-urlencoded" \
            "$api_url" >/dev/null
    else
        printf "Error: Neither curl nor wget is available\n" >&2
        printf "Please install curl or wget to send HTTP requests\n" >&2
        return 1
    fi
}

# Log message to file if logging is enabled
log_message() {
    if [ -n "$LOG_FILE" ]; then
        timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)"
        level="$1"
        message="$2"
        printf "%s [%s] %s\n" "$timestamp" "$level" "$message" >> "$LOG_FILE"
    fi
}

# Main function
send_alert() {
    level="${1:-INFO}"
    message="${2:-No message provided}"
    
    # Validate inputs
    if [ -z "$level" ] || [ -z "$message" ]; then
        printf "Error: Both level and message are required\n" >&2
        printf "Usage: %s <LEVEL> <MESSAGE>\n" "$0" >&2
        exit 1
    fi
    
    # Load and validate configuration
    load_config
    validate_config
    
    # Format message
    formatted_text="$(format_message "$level" "$message")"
    
    # Prepare API request
    api_url="https://api.telegram.org/bot${TELEGRAM_API_KEY}/sendMessage"
    encoded_text="$(url_encode "$formatted_text")"
    payload="chat_id=${TELEGRAM_CHAT_ID}&parse_mode=Markdown&text=${encoded_text}"
    
    # Send request
    if send_http_request "$api_url" "$payload"; then
        timestamp="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)"
        printf "%s [%s] Alert sent to Telegram successfully\n" "$timestamp" "$level"
        log_message "$level" "$message"
        return 0
    else
        printf "Error: Failed to send alert to Telegram\n" >&2
        return 1
    fi
}

# Show help
show_help() {
    cat << 'EOF'
Telegram Alert Script - Send alerts to Telegram bot

USAGE:
    ./alert.sh <LEVEL> <MESSAGE>

LEVELS:
    INFO, WARNING, CRITICAL, SUCCESS, DEBUG, ERROR

EXAMPLES:
    ./alert.sh "INFO" "System started successfully"
    ./alert.sh "WARNING" "Disk usage is at 85%"
    ./alert.sh "CRITICAL" "Database connection failed"
    ./alert.sh "SUCCESS" "Backup completed"

CONFIGURATION:
    Create a .env file with:
        TELEGRAM_API_KEY=your_bot_token
        TELEGRAM_CHAT_ID=your_chat_id
        LOG_FILE=alerts.log (optional)
        MAX_MESSAGE_LENGTH=4096 (optional)

REQUIREMENTS:
    - POSIX-compliant shell (/bin/sh)
    - curl or wget
    - Configured .env file

For more information, see README.md
EOF
}

# Parse command line arguments
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    "")
        printf "Error: Missing arguments\n" >&2
        show_help
        exit 1
        ;;
    *)
        send_alert "$1" "${2:-}"
        ;;
esac