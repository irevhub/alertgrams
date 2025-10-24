#!/bin/sh
# AlertGrams Cron Monitoring Scripts
# ==================================
# Description: Periodic monitoring scripts for cron-based monitoring
# Version: 1.1.1

# Critical system checks (every 5 minutes)
critical_check() {
    # CPU and memory critical thresholds
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null)
    if [ -n "$cpu_usage" ] && [ "${cpu_usage%.*}" -gt 95 ]; then
        ./alert.sh "CRITICAL" "Critical CPU usage: ${cpu_usage}%"
    fi
    
    mem_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}' 2>/dev/null)
    if [ -n "$mem_usage" ] && [ "$mem_usage" -gt 95 ]; then
        ./alert.sh "CRITICAL" "Critical memory usage: ${mem_usage}%"
    fi
    
    # Disk space critical check
    df -h | awk '$5+0 > 95 {
        gsub(/%/, "", $5)
        print $6 ":" $5
    }' | while IFS=: read -r mount usage; do
        ./alert.sh "CRITICAL" "Critical disk usage: $mount at ${usage}%"
    done
}

# Service monitoring (every 15 minutes)
service_check() {
    services="${MONITOR_SERVICES:-nginx apache2 mysql postgresql}"
    
    for service in $services; do
        if command -v systemctl >/dev/null 2>&1; then
            if systemctl list-units --type=service | grep -q "^[[:space:]]*$service.service"; then
                if ! systemctl is-active --quiet "$service" 2>/dev/null; then
                    ./alert.sh "ERROR" "Service '$service' is down"
                fi
            fi
        fi
    done
}

# System health check (hourly)
system_health_check() {
    # Load average
    load_avg=$(uptime | awk -F'load average:' '{print $2}')
    
    # Disk usage summary
    disk_usage=$(df -h | grep -E '^/dev/' | awk '$5+0 > 80 {print $6 ":" $5}' | tr '\n' ', ')
    
    # Memory usage
    mem_info=$(free -h | grep Mem | awk '{print "Used:" $3 "/" $2}')
    
    if [ -n "$disk_usage" ]; then
        ./alert.sh "WARNING" "System Health Alert:
Load Average: $load_avg
Memory: $mem_info
High Disk Usage: $disk_usage"
    fi
}

# Daily summary report
daily_summary() {
    uptime_info=$(uptime)
    hostname_info=$(hostname)
    
    ./alert.sh "INFO" "Daily Server Status - $hostname_info
Uptime: $uptime_info
Status: Operational
Monitoring: Cron-based periodic checks active"
}

# Syslog monitoring (every 2 minutes)
syslog_check() {
    syslog_script="$(dirname "$0")/alertgrams-syslog.sh"
    
    if [ -f "$syslog_script" ]; then
        # Quick analysis of recent entries
        "$syslog_script" analyze 20 | grep -E "CRITICAL|SECURITY|ERROR" | head -5 | while IFS= read -r line; do
            level=$(echo "$line" | grep -o '\[.*\]' | tr -d '[]')
            message=$(echo "$line" | sed 's/^.*\] //')
            ./alert.sh "$level" "Syslog Alert: $message"
        done
    fi
}

# Execute based on script name or parameter
case "${1:-$(basename "$0")}" in
    "critical"|"critical_check")
        critical_check
        ;;
    "service"|"service_check")
        service_check
        ;;
    "health"|"system_health_check")
        system_health_check
        ;;
    "daily"|"daily_summary")
        daily_summary
        ;;
    "syslog"|"syslog_check")
        syslog_check
        ;;
    *)
        printf "Usage: %s {critical|service|health|daily|syslog}\n" "$0"
        printf "  critical - Critical system resource checks\n"
        printf "  service  - Service status monitoring\n"
        printf "  health   - System health summary\n"
        printf "  daily    - Daily status report\n"
        printf "  syslog   - Syslog monitoring check\n"
        exit 1
        ;;
esac