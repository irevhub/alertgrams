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

# Configuration defaults - Enhanced for better filtering
MONITOR_INTERVAL="${MONITOR_INTERVAL:-300}"      # 5 minutes - tidak perlu terlalu sering
CPU_THRESHOLD="${CPU_THRESHOLD:-90}"             # 90% - lebih konservatif
MEMORY_THRESHOLD="${MEMORY_THRESHOLD:-95}"       # 95% - hanya alert jika benar-benar kritis
DISK_THRESHOLD="${DISK_THRESHOLD:-90}"           # 90% - beri waktu untuk cleanup
MONITOR_SERVICES="${MONITOR_SERVICES:-nginx apache2 mysql postgresql redis-server}"
LOG_FILES="${LOG_FILES:-/var/log/syslog /var/log/auth.log}"
LOAD_THRESHOLD_MULTIPLIER="${LOAD_THRESHOLD_MULTIPLIER:-2.0}"  # 2x CPU cores
NETWORK_TEST_HOSTS="${NETWORK_TEST_HOSTS:-8.8.8.8 1.1.1.1 google.com}"

# Syslog monitoring configuration - Enhanced filtering
SYSLOG_FILE="${SYSLOG_FILE:-/var/log/syslog}"

# Critical patterns - hanya untuk masalah serius
SYSLOG_CRITICAL_PATTERNS="${SYSLOG_CRITICAL_PATTERNS:-kernel panic|oops|segmentation fault|out of memory|oom-killer|system crash|hardware error|critical temperature|disk error|filesystem error|raid.*fail|power.*fail}"

# Security patterns - fokus pada ancaman keamanan nyata
SYSLOG_SECURITY_PATTERNS="${SYSLOG_SECURITY_PATTERNS:-authentication failure.*root|invalid user.*ssh|failed password.*ssh.*attempts|brute.*force|intrusion detected|unauthorized access|privilege escalation|malware|rootkit}"

# Error patterns - error yang memerlukan tindakan
SYSLOG_ERROR_PATTERNS="${SYSLOG_ERROR_PATTERNS:-service.*failed|daemon.*died|connection.*refused.*critical|network.*unreachable.*prod|certificate.*expired|ssl.*handshake.*failed.*repeated|database.*connection.*lost}"

# Exclude patterns - hindari noise dari log normal
SYSLOG_EXCLUDE_PATTERNS="${SYSLOG_EXCLUDE_PATTERNS:-dhcp.*lease|systemd.*started|systemd.*stopped|cron.*session|sudo.*session|user.*logged|anacron.*job|logrotate.*completed}"

# Alert throttling
ALERT_COOLDOWN_FILE="/tmp/alertgrams-cooldown"
ALERT_COOLDOWN_SECONDS="${ALERT_COOLDOWN_SECONDS:-300}"  # 5 menit cooldown per pattern

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

# Function to check if alert should be throttled
should_throttle_alert() {
    pattern_hash="$1"
    current_time=$(date +%s)
    
    if [ -f "$ALERT_COOLDOWN_FILE" ]; then
        while IFS=: read -r hash timestamp; do
            if [ "$hash" = "$pattern_hash" ]; then
                time_diff=$((current_time - timestamp))
                if [ "$time_diff" -lt "$ALERT_COOLDOWN_SECONDS" ]; then
                    return 0  # Should throttle
                fi
            fi
        done < "$ALERT_COOLDOWN_FILE"
    fi
    
    # Update cooldown file
    {
        if [ -f "$ALERT_COOLDOWN_FILE" ]; then
            # Remove old entries and current pattern
            awk -F: -v hash="$pattern_hash" -v cutoff="$((current_time - ALERT_COOLDOWN_SECONDS))" '
                $1 != hash && $2 > cutoff { print }
            ' "$ALERT_COOLDOWN_FILE"
        fi
        echo "$pattern_hash:$current_time"
    } > "${ALERT_COOLDOWN_FILE}.tmp" && mv "${ALERT_COOLDOWN_FILE}.tmp" "$ALERT_COOLDOWN_FILE"
    
    return 1  # Don't throttle
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

# Smart service monitoring - skip jika service memang tidak seharusnya jalan
check_services() {
    if [ -z "$MONITOR_SERVICES" ]; then
        return 0
    fi
    
    for service in $MONITOR_SERVICES; do
        service_exists=0
        
        if command -v systemctl >/dev/null 2>&1; then
            if systemctl list-unit-files | grep -q "^${service}.service"; then
                service_exists=1
                if ! systemctl is-active --quiet "$service" 2>/dev/null; then
                    # Check if service is supposed to be enabled
                    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                        send_alert "CRITICAL" "🔧 Service Down: '$service' is enabled but not running"
                    fi
                fi
            fi
        elif command -v service >/dev/null 2>&1; then
            if service "$service" status >/dev/null 2>&1 || [ $? -ne 4 ]; then
                service_exists=1
                if ! service "$service" status >/dev/null 2>&1; then
                    send_alert "CRITICAL" "🔧 Service Down: '$service' is not running"
                fi
            fi
        fi
        
        # Jika service tidak ditemukan, beri peringatan sekali saja
        if [ "$service_exists" -eq 0 ]; then
            pattern_hash="service_not_found_${service}"
            if should_throttle_alert "$pattern_hash"; then
                continue
            fi
            printf "[WARNING] Service '%s' not found on this system\n" "$service"
        fi
    done
}

# Network check dengan multiple fallback
check_network() {
    test_hosts="${NETWORK_TEST_HOSTS:-8.8.8.8 1.1.1.1 google.com}"
    failed_hosts=0
    total_hosts=0
    
    for host in $test_hosts; do
        total_hosts=$((total_hosts + 1))
        
        if command -v ping >/dev/null 2>&1; then
            if ! ping -c 1 -W 5 "$host" >/dev/null 2>&1; then
                failed_hosts=$((failed_hosts + 1))
            fi
        fi
    done
    
    # Alert hanya jika semua host gagal atau mayoritas gagal
    if [ "$failed_hosts" -eq "$total_hosts" ]; then
        send_alert "CRITICAL" "🌐 Network connectivity lost: All test hosts unreachable"
    elif [ "$failed_hosts" -gt $((total_hosts / 2)) ]; then
        send_alert "WARNING" "🌐 Network issues: $failed_hosts/$total_hosts hosts unreachable"
    fi
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

# Enhanced syslog checking with smart filtering
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
    
    # Handle log rotation
    if [ "$current_position" -lt "$last_position" ]; then
        last_position="0"
        printf "[INFO] Log rotation detected, resetting position\n"
    fi
    
    # Check if there are new entries
    if [ "$current_position" -gt "$last_position" ]; then
        bytes_to_read=$((current_position - last_position))
        
        # Process new log entries
        tail -c +"$((last_position + 1))" "$SYSLOG_FILE" | head -c "$bytes_to_read" | \
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            
            # Skip if line matches exclude patterns
            line_lower=$(printf "%s" "$line" | tr '[:upper:]' '[:lower:]')
            excluded=0
            
            # Check exclude patterns
            for pattern in $(printf "%s" "$SYSLOG_EXCLUDE_PATTERNS" | tr '|' ' '); do
                if printf "%s" "$line_lower" | grep -q "$pattern"; then
                    excluded=1
                    break
                fi
            done
            
            [ "$excluded" -eq 1 ] && continue
            
            # Extract timestamp and create shorter line for alerts
            timestamp=$(printf "%s" "$line" | awk '{print $1, $2, $3}')
            process=$(printf "%s" "$line" | awk '{print $5}' | cut -d'[' -f1 | cut -d':' -f1)
            message_part=$(printf "%s" "$line" | cut -d' ' -f6- | head -c 100)
            
            # Check critical patterns (highest priority)
            for pattern in $(printf "%s" "$SYSLOG_CRITICAL_PATTERNS" | tr '|' ' '); do
                if printf "%s" "$line_lower" | grep -q "$pattern"; then
                    pattern_hash=$(printf "%s" "$pattern" | md5sum | cut -d' ' -f1 2>/dev/null || echo "$pattern")
                    
                    if should_throttle_alert "$pattern_hash"; then
                        printf "[DEBUG] Throttled critical alert for pattern: %s\n" "$pattern"
                        continue
                    fi
                    
                    alert_msg="� SYSTEM CRITICAL
Host: $(hostname)
Time: $timestamp
Process: $process
Issue: $message_part"
                    
                    send_alert "CRITICAL" "$alert_msg"
                    printf "[CRITICAL] Syslog alert: %s\n" "$line"
                    break
                fi
            done
            
            # Check security patterns
            for pattern in $(printf "%s" "$SYSLOG_SECURITY_PATTERNS" | tr '|' ' '); do
                if printf "%s" "$line_lower" | grep -q "$pattern"; then
                    pattern_hash=$(printf "%s" "$pattern" | md5sum | cut -d' ' -f1 2>/dev/null || echo "$pattern")
                    
                    if should_throttle_alert "$pattern_hash"; then
                        printf "[DEBUG] Throttled security alert for pattern: %s\n" "$pattern"
                        continue
                    fi
                    
                    alert_msg="�️ SECURITY ALERT
Host: $(hostname)
Time: $timestamp
Process: $process
Event: $message_part"
                    
                    send_alert "CRITICAL" "$alert_msg"
                    printf "[SECURITY] Syslog alert: %s\n" "$line"
                    break
                fi
            done
            
            # Check error patterns (lower priority, longer cooldown)
            for pattern in $(printf "%s" "$SYSLOG_ERROR_PATTERNS" | tr '|' ' '); do
                if printf "%s" "$line_lower" | grep -q "$pattern"; then
                    pattern_hash=$(printf "%s" "$pattern" | md5sum | cut -d' ' -f1 2>/dev/null || echo "$pattern")
                    
                    # Longer cooldown for errors (10 minutes)
                    if should_throttle_alert "${pattern_hash}_error"; then
                        printf "[DEBUG] Throttled error alert for pattern: %s\n" "$pattern"
                        continue
                    fi
                    
                    alert_msg="⚠️ SYSTEM ERROR
Host: $(hostname)
Time: $timestamp
Service: $process
Error: $message_part"
                    
                    send_alert "WARNING" "$alert_msg"
                    printf "[ERROR] Syslog alert: %s\n" "$line"
                    break
                fi
            done
        done
        
        # Save current position
        printf "%s" "$current_position" > "$SYSLOG_POSITION_FILE"
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