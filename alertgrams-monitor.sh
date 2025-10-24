#!/bin/sh
# AlertGrams Monitoring Daemon Service
# ====================================
# Description: Continuous server monitoring service for AlertGrams
# Version: 1.1.1
# Author: AlertGrams Project
#
# This daemon provides continuous monitoring of:
# - System resources (CPU, Memory, Disk)
# - Critical services status
# - Network connectivity
# - Log file changes
# - Security events

set -eu

# Configuration defaults
MONITOR_INTERVAL="${MONITOR_INTERVAL:-300}"      # 5 minutes
CPU_THRESHOLD="${CPU_THRESHOLD:-85}"             # 85% CPU usage
MEMORY_THRESHOLD="${MEMORY_THRESHOLD:-90}"       # 90% memory usage
DISK_THRESHOLD="${DISK_THRESHOLD:-85}"           # 85% disk usage
MONITOR_SERVICES="${MONITOR_SERVICES:-nginx apache2 mysql postgresql redis-server}"
LOG_FILES="${LOG_FILES:-/var/log/syslog /var/log/auth.log}"

# Syslog monitoring configuration
SYSLOG_FILE="${SYSLOG_FILE:-/var/log/syslog}"
SYSLOG_CRITICAL_PATTERNS="${SYSLOG_CRITICAL_PATTERNS:-kernel panic|out of memory|segmentation fault|critical error|system crash|hardware error}"
SYSLOG_ERROR_PATTERNS="${SYSLOG_ERROR_PATTERNS:-error|failed|failure|denied|rejected|timeout|unreachable}"
SYSLOG_SECURITY_PATTERNS="${SYSLOG_SECURITY_PATTERNS:-authentication failure|invalid user|failed password|brute force|intrusion|unauthorized}"
SYSLOG_POSITION_FILE="${SYSLOG_POSITION_FILE:-/tmp/alertgrams-syslog.pos}"

# Load configuration
load_config() {
    config_file="/etc/alertgrams/.env"
    if [ ! -f "$config_file" ]; then
        config_file="$(dirname "$0")/.env"
    fi
    
    if [ -f "$config_file" ]; then
        set -a
        while IFS='=' read -r key value; do
            # Remove carriage return if present
            value=$(printf "%s" "$value" | tr -d '\r')
            case "$key" in
                \#*|'') continue ;;
                *) eval "$key=\"$value\"" ;;
            esac
        done < "$config_file"
        set +a
        printf "[INFO] Configuration loaded from %s\n" "$config_file"
    else
        printf "[ERROR] Configuration file not found\n" >&2
        exit 1
    fi
}

# Send alert wrapper
send_alert() {
    level="$1"
    message="$2"
    
    if [ -x "/usr/local/bin/alert.sh" ]; then
        /usr/local/bin/alert.sh "$level" "$message"
    elif [ -x "$(dirname "$0")/alert.sh" ]; then
        "$(dirname "$0")/alert.sh" "$level" "$message"
    else
        printf "[ERROR] alert.sh not found\n" >&2
        return 1
    fi
}

# System resource monitoring
check_system_resources() {
    # CPU usage check
    if command -v top >/dev/null 2>&1; then
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        if [ -n "$cpu_usage" ] && [ "${cpu_usage%.*}" -gt "$CPU_THRESHOLD" ]; then
            send_alert "WARNING" "High CPU usage detected: ${cpu_usage}%"
        fi
    fi
    
    # Memory usage check
    if command -v free >/dev/null 2>&1; then
        mem_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
        if [ -n "$mem_usage" ] && [ "$mem_usage" -gt "$MEMORY_THRESHOLD" ]; then
            send_alert "CRITICAL" "High memory usage detected: ${mem_usage}%"
        fi
    fi
    
    # Disk space check
    df -h 2>/dev/null | awk -v thresh="$DISK_THRESHOLD" '
    NR>1 && $5+0 > thresh {
        gsub(/%/, "", $5)
        printf "%s:%s\n", $6, $5
    }' | while IFS=: read -r mount usage; do
        if [ -n "$mount" ] && [ -n "$usage" ]; then
            send_alert "WARNING" "High disk usage: $mount at ${usage}%"
        fi
    done
}

# Service status monitoring
check_services() {
    if [ -z "$MONITOR_SERVICES" ]; then
        return 0
    fi
    
    for service in $MONITOR_SERVICES; do
        if command -v systemctl >/dev/null 2>&1; then
            if systemctl list-units --type=service | grep -q "^[[:space:]]*$service.service"; then
                if ! systemctl is-active --quiet "$service" 2>/dev/null; then
                    send_alert "CRITICAL" "Service '$service' is not running"
                fi
            fi
        elif command -v service >/dev/null 2>&1; then
            if ! service "$service" status >/dev/null 2>&1; then
                send_alert "CRITICAL" "Service '$service' is not running"
            fi
        fi
    done
}

# Network connectivity check
check_network() {
    test_hosts="8.8.8.8 1.1.1.1"
    
    for host in $test_hosts; do
        if command -v ping >/dev/null 2>&1; then
            if ! ping -c 1 -W 5 "$host" >/dev/null 2>&1; then
                send_alert "WARNING" "Network connectivity issue: Cannot reach $host"
                break
            fi
        fi
    done
}

# Load average check
check_load_average() {
    if command -v uptime >/dev/null 2>&1; then
        load_5min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | tr -d ' ')
        cpu_cores=$(nproc 2>/dev/null || echo "1")
        
        if [ -n "$load_5min" ] && [ -n "$cpu_cores" ]; then
            # Convert to integer comparison (multiply by 100)
            load_int=$(printf "%.0f" "$(echo "$load_5min * 100" | bc 2>/dev/null || echo "$load_5min")")
            threshold_int=$((cpu_cores * 150))  # 1.5 * cores * 100
            
            if [ "$load_int" -gt "$threshold_int" ]; then
                send_alert "WARNING" "High system load: $load_5min (cores: $cpu_cores)"
            fi
        fi
    fi
}

# Process monitoring
check_critical_processes() {
    critical_processes="${CRITICAL_PROCESSES:-}"
    
    if [ -n "$critical_processes" ]; then
        for process in $critical_processes; do
            if ! pgrep "$process" >/dev/null 2>&1; then
                send_alert "CRITICAL" "Critical process '$process' is not running"
            fi
        done
    fi
}

# Security monitoring
check_security_events() {
    auth_log="/var/log/auth.log"
    if [ -f "$auth_log" ]; then
        # Check for failed login attempts in last 5 minutes
        failed_count=$(grep "Failed password" "$auth_log" 2>/dev/null | \
                      grep "$(date '+%b %d %H:%M' -d '5 minutes ago')" | wc -l)
        
        if [ "$failed_count" -gt 5 ]; then
            send_alert "WARNING" "Multiple failed login attempts detected: $failed_count in last 5 minutes"
        fi
    fi
}

# Check syslog for critical entries
check_syslog() {
    if [ ! -f "$SYSLOG_FILE" ]; then
        printf "[WARNING] Syslog file not found: %s\n" "$SYSLOG_FILE"
        return 0
    fi
    
    # Get current and last positions
    current_position=$(wc -c < "$SYSLOG_FILE" 2>/dev/null || echo "0")
    last_position="0"
    
    if [ -f "$SYSLOG_POSITION_FILE" ]; then
        last_position=$(cat "$SYSLOG_POSITION_FILE" 2>/dev/null || echo "0")
    fi
    
    # If file is smaller, it might have been rotated
    if [ "$current_position" -lt "$last_position" ]; then
        last_position="0"
    fi
    
    # Check if there are new entries
    if [ "$current_position" -gt "$last_position" ]; then
        bytes_to_read=$((current_position - last_position))
        
        # Read new content and check for patterns
        tail -c +"$((last_position + 1))" "$SYSLOG_FILE" | head -c "$bytes_to_read" | while IFS= read -r line; do
            [ -z "$line" ] && continue
            
            # Convert to lowercase for case-insensitive matching
            line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
            timestamp=$(echo "$line" | awk '{print $1, $2, $3}' | head -c 20)
            
            # Check critical patterns
            if echo "$line_lower" | grep -qE "$(echo "$SYSLOG_CRITICAL_PATTERNS" | tr '|' '\n' | head -1)"; then
                send_alert "CRITICAL" "🔍 SYSLOG CRITICAL: $timestamp - $line"
                printf "[CRITICAL] Syslog alert: %s\n" "$line"
            # Check security patterns  
            elif echo "$line_lower" | grep -qE "$(echo "$SYSLOG_SECURITY_PATTERNS" | tr '|' '\n' | head -1)"; then
                send_alert "CRITICAL" "🔒 SYSLOG SECURITY: $timestamp - $line"
                printf "[SECURITY] Syslog alert: %s\n" "$line"
            # Check error patterns
            elif echo "$line_lower" | grep -qE "$(echo "$SYSLOG_ERROR_PATTERNS" | tr '|' '\n' | head -1)"; then
                send_alert "ERROR" "❌ SYSLOG ERROR: $timestamp - $line"
                printf "[ERROR] Syslog alert: %s\n" "$line"
            fi
        done
        
        # Save current position
        echo "$current_position" > "$SYSLOG_POSITION_FILE"
    fi
}

# Main monitoring function
run_monitoring_cycle() {
    printf "[INFO] Running monitoring cycle at $(date)\n"
    
    check_system_resources
    check_services
    check_network
    check_load_average
    check_critical_processes
    check_security_events
    check_syslog
    
    printf "[INFO] Monitoring cycle completed\n"
}

# Signal handlers
cleanup() {
    printf "[INFO] AlertGrams monitoring service stopping...\n"
    send_alert "INFO" "AlertGrams monitoring service stopped on $(hostname)"
    exit 0
}

reload_config() {
    printf "[INFO] Reloading configuration...\n"
    load_config
    send_alert "INFO" "AlertGrams monitoring configuration reloaded"
}

# Set up signal handlers
trap cleanup TERM INT
trap reload_config HUP

# Main execution
main() {
    printf "AlertGrams Monitoring Service v1.1.0\n"
    printf "====================================\n"
    printf "Starting monitoring service...\n"
    
    # Load configuration
    load_config
    
    # Send startup notification
    send_alert "INFO" "AlertGrams monitoring service started on $(hostname)"
    
    # Main monitoring loop
    while true; do
        run_monitoring_cycle
        
        # Sleep for the specified interval
        sleep "$MONITOR_INTERVAL"
    done
}

# Check if running as daemon or called directly
if [ "${1:-}" = "test" ]; then
    # Test mode - run once and exit
    load_config
    printf "Running test monitoring cycle...\n"
    run_monitoring_cycle
    printf "Test completed.\n"
else
    # Normal daemon mode
    main
fi