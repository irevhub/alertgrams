#!/bin/sh
# AlertGrams Syslog Monitor
# =========================
# Description: Real-time syslog monitoring with immediate alerts
# Version: 1.1.1
# Author: AlertGrams Project

set -eu

# Load configuration if available
if [ -f ".env" ]; then
    . ./.env
elif [ -f "/etc/alertgrams/.env" ]; then
    . /etc/alertgrams/.env
fi

# Default syslog file locations
SYSLOG_FILE="${SYSLOG_FILE:-/var/log/syslog}"
SYSLOG_BACKUP="${SYSLOG_FILE}.1"

# Alert patterns (configurable via environment)
CRITICAL_PATTERNS="${SYSLOG_CRITICAL_PATTERNS:-"kernel panic|out of memory|segmentation fault|critical error|system crash|hardware error"}"
ERROR_PATTERNS="${SYSLOG_ERROR_PATTERNS:-"error|failed|failure|denied|rejected|timeout|unreachable"}"
WARNING_PATTERNS="${SYSLOG_WARNING_PATTERNS:-"warning|warn|deprecated|retry|fallback"}"
SECURITY_PATTERNS="${SYSLOG_SECURITY_PATTERNS:-"authentication failure|invalid user|failed password|brute force|intrusion|unauthorized"}"

# Monitoring settings
CHECK_INTERVAL="${SYSLOG_CHECK_INTERVAL:-30}"  # seconds
MAX_LINES_PER_CHECK="${SYSLOG_MAX_LINES:-50}"
LAST_POSITION_FILE="${SYSLOG_POSITION_FILE:-/tmp/alertgrams-syslog.pos}"

# Function to send alert
send_syslog_alert() {
    level="$1"
    pattern="$2"
    line="$3"
    timestamp="$4"
    
    alert_script="./alert.sh"
    if [ ! -f "$alert_script" ] && [ -f "/usr/local/bin/alert.sh" ]; then
        alert_script="/usr/local/bin/alert.sh"
    fi
    
    message="🔍 SYSLOG ALERT
Pattern: $pattern
Time: $timestamp
Log: $line"
    
    if [ -f "$alert_script" ]; then
        "$alert_script" "$level" "$message"
    else
        printf "ERROR: alert.sh not found\n" >&2
        return 1
    fi
}

# Get file size and last position
get_file_position() {
    file="$1"
    if [ -f "$file" ]; then
        wc -c < "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Get last checked position
get_last_position() {
    if [ -f "$LAST_POSITION_FILE" ]; then
        cat "$LAST_POSITION_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Save current position
save_position() {
    position="$1"
    echo "$position" > "$LAST_POSITION_FILE"
}

# Check if pattern matches (case insensitive)
pattern_matches() {
    line="$1"
    patterns="$2"
    
    # Convert to lowercase for case-insensitive matching
    line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
    
    # Split patterns by pipe and check each one
    IFS='|'
    for pattern in $patterns; do
        pattern_lower=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
        case "$line_lower" in
            *"$pattern_lower"*)
                echo "$pattern"
                return 0
                ;;
        esac
    done
    return 1
}

# Extract timestamp from syslog line
extract_timestamp() {
    line="$1"
    # Try to extract timestamp (first 3 fields: month day time)
    echo "$line" | awk '{print $1, $2, $3}' | head -c 20
}

# Monitor syslog file for new entries
monitor_syslog() {
    if [ ! -f "$SYSLOG_FILE" ]; then
        printf "ERROR: Syslog file not found: %s\n" "$SYSLOG_FILE" >&2
        return 1
    fi
    
    printf "Starting syslog monitoring: %s\n" "$SYSLOG_FILE"
    printf "Check interval: %d seconds\n" "$CHECK_INTERVAL"
    printf "Critical patterns: %s\n" "$CRITICAL_PATTERNS"
    printf "Error patterns: %s\n" "$ERROR_PATTERNS"
    printf "Security patterns: %s\n" "$SECURITY_PATTERNS"
    printf "\n"
    
    last_position=$(get_last_position)
    current_position=$(get_file_position "$SYSLOG_FILE")
    
    # If file is smaller than last position, it might have been rotated
    if [ "$current_position" -lt "$last_position" ]; then
        printf "Log file appears to have been rotated, resetting position\n"
        last_position=0
    fi
    
    while true; do
        current_position=$(get_file_position "$SYSLOG_FILE")
        
        # Check if file has grown
        if [ "$current_position" -gt "$last_position" ]; then
            # Get new lines since last check
            bytes_to_read=$((current_position - last_position))
            
            # Read new content
            tail -c +"$((last_position + 1))" "$SYSLOG_FILE" | head -c "$bytes_to_read" | while IFS= read -r line; do
                [ -z "$line" ] && continue
                
                timestamp=$(extract_timestamp "$line")
                
                # Check critical patterns first
                if matched_pattern=$(pattern_matches "$line" "$CRITICAL_PATTERNS"); then
                    printf "[CRITICAL] %s: %s\n" "$timestamp" "$line"
                    send_syslog_alert "CRITICAL" "$matched_pattern" "$line" "$timestamp"
                # Check security patterns
                elif matched_pattern=$(pattern_matches "$line" "$SECURITY_PATTERNS"); then
                    printf "[SECURITY] %s: %s\n" "$timestamp" "$line"
                    send_syslog_alert "CRITICAL" "SECURITY: $matched_pattern" "$line" "$timestamp"
                # Check error patterns
                elif matched_pattern=$(pattern_matches "$line" "$ERROR_PATTERNS"); then
                    printf "[ERROR] %s: %s\n" "$timestamp" "$line"
                    send_syslog_alert "ERROR" "$matched_pattern" "$line" "$timestamp"
                # Check warning patterns
                elif matched_pattern=$(pattern_matches "$line" "$WARNING_PATTERNS"); then
                    printf "[WARNING] %s: %s\n" "$timestamp" "$line"
                    send_syslog_alert "WARNING" "$matched_pattern" "$line" "$timestamp"
                fi
            done
            
            # Update position
            save_position "$current_position"
            last_position="$current_position"
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# Analyze recent syslog entries
analyze_recent() {
    lines="${1:-100}"
    
    if [ ! -f "$SYSLOG_FILE" ]; then
        printf "ERROR: Syslog file not found: %s\n" "$SYSLOG_FILE" >&2
        return 1
    fi
    
    printf "Analyzing last %d lines of %s\n" "$lines" "$SYSLOG_FILE"
    printf "=====================================\n\n"
    
    # Get recent entries
    tail -n "$lines" "$SYSLOG_FILE" | while IFS= read -r line; do
        [ -z "$line" ] && continue
        
        timestamp=$(extract_timestamp "$line")
        
        # Check all patterns
        if matched_pattern=$(pattern_matches "$line" "$CRITICAL_PATTERNS"); then
            printf "🚨 [CRITICAL] %s - Pattern: %s\n   %s\n\n" "$timestamp" "$matched_pattern" "$line"
        elif matched_pattern=$(pattern_matches "$line" "$SECURITY_PATTERNS"); then
            printf "🔒 [SECURITY] %s - Pattern: %s\n   %s\n\n" "$timestamp" "$matched_pattern" "$line"
        elif matched_pattern=$(pattern_matches "$line" "$ERROR_PATTERNS"); then
            printf "❌ [ERROR] %s - Pattern: %s\n   %s\n\n" "$timestamp" "$matched_pattern" "$line"
        elif matched_pattern=$(pattern_matches "$line" "$WARNING_PATTERNS"); then
            printf "⚠️  [WARNING] %s - Pattern: %s\n   %s\n\n" "$timestamp" "$matched_pattern" "$line"
        fi
    done
}

# Test syslog patterns
test_patterns() {
    printf "Testing syslog monitoring patterns...\n"
    printf "=====================================\n\n"
    
    # Test lines
    test_lines="
Oct 25 10:30:15 server kernel: Out of memory: Kill process 1234
Oct 25 10:31:20 server sshd[5678]: Failed password for invalid user admin
Oct 25 10:32:10 server systemd: Service failed to start
Oct 25 10:33:05 server kernel: segmentation fault at 0x12345678
Oct 25 10:34:15 server auth: authentication failure for user test
Oct 25 10:35:20 server app: Warning: deprecated function used
"
    
    echo "$test_lines" | while IFS= read -r line; do
        [ -z "$line" ] && continue
        
        timestamp=$(extract_timestamp "$line")
        
        if matched_pattern=$(pattern_matches "$line" "$CRITICAL_PATTERNS"); then
            printf "🚨 CRITICAL MATCH: %s\n   Pattern: %s\n   Line: %s\n\n" "$timestamp" "$matched_pattern" "$line"
        elif matched_pattern=$(pattern_matches "$line" "$SECURITY_PATTERNS"); then
            printf "🔒 SECURITY MATCH: %s\n   Pattern: %s\n   Line: %s\n\n" "$timestamp" "$matched_pattern" "$line"
        elif matched_pattern=$(pattern_matches "$line" "$ERROR_PATTERNS"); then
            printf "❌ ERROR MATCH: %s\n   Pattern: %s\n   Line: %s\n\n" "$timestamp" "$matched_pattern" "$line"
        elif matched_pattern=$(pattern_matches "$line" "$WARNING_PATTERNS"); then
            printf "⚠️  WARNING MATCH: %s\n   Pattern: %s\n   Line: %s\n\n" "$timestamp" "$matched_pattern" "$line"
        else
            printf "ℹ️  NO MATCH: %s\n   Line: %s\n\n" "$timestamp" "$line"
        fi
    done
}

# Show configuration
show_config() {
    printf "AlertGrams Syslog Monitor Configuration\n"
    printf "======================================\n\n"
    printf "Syslog file: %s\n" "$SYSLOG_FILE"
    printf "Check interval: %d seconds\n" "$CHECK_INTERVAL"
    printf "Max lines per check: %d\n" "$MAX_LINES_PER_CHECK"
    printf "Position file: %s\n" "$LAST_POSITION_FILE"
    printf "\nMonitoring Patterns:\n"
    printf "  Critical: %s\n" "$CRITICAL_PATTERNS"
    printf "  Error: %s\n" "$ERROR_PATTERNS"
    printf "  Warning: %s\n" "$WARNING_PATTERNS"
    printf "  Security: %s\n" "$SECURITY_PATTERNS"
    printf "\n"
}

# Signal handlers
cleanup() {
    printf "\nShutting down syslog monitor...\n"
    exit 0
}
trap cleanup INT TERM

# Main execution
case "${1:-monitor}" in
    "monitor"|"start")
        monitor_syslog
        ;;
    "analyze")
        lines="${2:-100}"
        analyze_recent "$lines"
        ;;
    "test"|"test-patterns")
        test_patterns
        ;;
    "config"|"show-config")
        show_config
        ;;
    "help"|"--help"|"-h")
        printf "Usage: %s [command] [options]\n\n" "$0"
        printf "Commands:\n"
        printf "  monitor     - Start real-time syslog monitoring (default)\n"
        printf "  analyze N   - Analyze last N lines (default: 100)\n"
        printf "  test        - Test pattern matching with sample data\n"
        printf "  config      - Show current configuration\n"
        printf "  help        - Show this help message\n"
        printf "\nEnvironment Variables:\n"
        printf "  SYSLOG_FILE                - Path to syslog file (default: /var/log/syslog)\n"
        printf "  SYSLOG_CHECK_INTERVAL      - Check interval in seconds (default: 30)\n"
        printf "  SYSLOG_CRITICAL_PATTERNS   - Critical alert patterns\n"
        printf "  SYSLOG_ERROR_PATTERNS      - Error alert patterns\n"
        printf "  SYSLOG_WARNING_PATTERNS    - Warning alert patterns\n"
        printf "  SYSLOG_SECURITY_PATTERNS   - Security alert patterns\n"
        printf "\nExamples:\n"
        printf "  %s monitor              # Start monitoring\n" "$0"
        printf "  %s analyze 50           # Analyze last 50 lines\n" "$0"
        printf "  %s test                 # Test pattern matching\n" "$0"
        ;;
    *)
        printf "Unknown command: %s\n" "$1"
        printf "Run '%s help' for usage information.\n" "$0"
        exit 1
        ;;
esac