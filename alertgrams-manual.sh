#!/bin/sh
# AlertGrams Manual Monitoring Tools
# ==================================
# Description: On-demand monitoring tools for manual execution
# Version: 1.1.1

set -eu

# Load configuration if available
if [ -f ".env" ]; then
    . ./.env
elif [ -f "/etc/alertgrams/.env" ]; then
    . /etc/alertgrams/.env
fi

# Quick system status check
quick_status() {
    printf "AlertGrams - Quick System Status Check\n"
    printf "=====================================\n\n"
    
    # Basic system info
    printf "Hostname: %s\n" "$(hostname)"
    printf "Date: %s\n" "$(date)"
    printf "Uptime: %s\n" "$(uptime | cut -d',' -f1 | cut -d' ' -f4-)"
    
    # CPU usage
    if command -v top >/dev/null 2>&1; then
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "N/A")
        printf "CPU Usage: %s%%\n" "$cpu_usage"
    fi
    
    # Memory usage
    if command -v free >/dev/null 2>&1; then
        mem_usage=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}' 2>/dev/null || echo "N/A")
        printf "Memory Usage: %s%%\n" "$mem_usage"
    fi
    
    # Disk usage (top 3 partitions)
    printf "\nDisk Usage (Top 3):\n"
    df -h | grep -E '^/dev/' | sort -k5 -nr | head -3 | while read -r line; do
        printf "  %s\n" "$line"
    done
    
    printf "\n"
}

# Comprehensive system report
full_report() {
    printf "AlertGrams - Comprehensive System Report\n"
    printf "=======================================\n\n"
    
    # System information
    printf "=== SYSTEM INFORMATION ===\n"
    printf "Hostname: %s\n" "$(hostname)"
    printf "Date: %s\n" "$(date)"
    printf "Kernel: %s\n" "$(uname -r 2>/dev/null || echo 'N/A')"
    printf "Architecture: %s\n" "$(uname -m 2>/dev/null || echo 'N/A')"
    printf "Uptime: %s\n" "$(uptime)"
    printf "\n"
    
    # CPU and Load
    printf "=== CPU & LOAD ===\n"
    if [ -f /proc/cpuinfo ]; then
        cpu_count=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "N/A")
        printf "CPU Cores: %s\n" "$cpu_count"
    fi
    
    if command -v top >/dev/null 2>&1; then
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "N/A")
        printf "Current CPU Usage: %s%%\n" "$cpu_usage"
    fi
    printf "\n"
    
    # Memory information
    printf "=== MEMORY ===\n"
    if command -v free >/dev/null 2>&1; then
        free -h
    else
        printf "Memory information not available\n"
    fi
    printf "\n"
    
    # Disk usage
    printf "=== DISK USAGE ===\n"
    df -h
    printf "\n"
    
    # Network connectivity
    printf "=== NETWORK CONNECTIVITY ===\n"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        printf "Internet connectivity: OK\n"
    else
        printf "Internet connectivity: FAILED\n"
    fi
    
    if ping -c 1 api.telegram.org >/dev/null 2>&1; then
        printf "Telegram API access: OK\n"
    else
        printf "Telegram API access: FAILED\n"
    fi
    printf "\n"
    
    # Running services (if systemctl available)
    if command -v systemctl >/dev/null 2>&1; then
        printf "=== KEY SERVICES STATUS ===\n"
        services="${MONITOR_SERVICES:-nginx apache2 mysql postgresql ssh}"
        for service in $services; do
            if systemctl list-units --type=service | grep -q "^[[:space:]]*$service.service"; then
                status=$(systemctl is-active "$service" 2>/dev/null || echo "unknown")
                printf "%-15s: %s\n" "$service" "$status"
            fi
        done
        printf "\n"
    fi
    
    # Recent system logs (if available)
    if command -v journalctl >/dev/null 2>&1; then
        printf "=== RECENT SYSTEM LOGS (Last 10 entries) ===\n"
        journalctl -n 10 --no-pager 2>/dev/null || printf "System logs not accessible\n"
    elif [ -f /var/log/syslog ]; then
        printf "=== RECENT SYSTEM LOGS (Last 10 entries) ===\n"
        tail -10 /var/log/syslog 2>/dev/null || printf "System logs not accessible\n"
    fi
}

# Test alert functionality
test_alert() {
    printf "Testing AlertGrams functionality...\n"
    
    if [ ! -f "alert.sh" ] && [ ! -f "/usr/local/bin/alert.sh" ]; then
        printf "Error: alert.sh not found\n" >&2
        exit 1
    fi
    
    alert_script="./alert.sh"
    if [ ! -f "$alert_script" ]; then
        alert_script="/usr/local/bin/alert.sh"
    fi
    
    printf "Sending test alert...\n"
    if "$alert_script" "INFO" "AlertGrams manual test - $(date)"; then
        printf "Test alert sent successfully!\n"
    else
        printf "Test alert failed!\n" >&2
        exit 1
    fi
}

# Interactive monitoring menu
interactive_menu() {
    while true; do
        printf "\nAlertGrams Manual Monitoring Menu\n"
        printf "=================================\n"
        printf "1) Quick Status Check\n"
        printf "2) Full System Report\n"
        printf "3) Syslog Analysis\n"
        printf "4) Test Alert\n"
        printf "5) Send Custom Alert\n"
        printf "6) Exit\n"
        printf "\nChoice (1-6): "
        
        read -r choice
        
        case "$choice" in
            1)
                quick_status
                ;;
            2)
                full_report
                ;;
            3)
                # Syslog analysis
                syslog_script="./alertgrams-syslog.sh"
                if [ ! -f "$syslog_script" ]; then
                    syslog_script="/usr/local/bin/alertgrams-syslog.sh"
                fi
                
                if [ -f "$syslog_script" ]; then
                    printf "Analyzing recent syslog entries...\n"
                    "$syslog_script" analyze 50
                else
                    printf "Syslog monitoring script not found.\n"
                fi
                ;;
            4)
                test_alert
                ;;
            5)
                printf "Alert Level (INFO/WARNING/CRITICAL): "
                read -r level
                printf "Message: "
                read -r message
                
                alert_script="./alert.sh"
                if [ ! -f "$alert_script" ]; then
                    alert_script="/usr/local/bin/alert.sh"
                fi
                
                if "$alert_script" "$level" "$message"; then
                    printf "Alert sent successfully!\n"
                else
                    printf "Alert failed!\n"
                fi
                ;;
            6)
                printf "Goodbye!\n"
                exit 0
                ;;
            *)
                printf "Invalid choice. Please select 1-6.\n"
                ;;
        esac
        
        printf "\nPress Enter to continue..."
        read -r dummy
    done
}

# Execute based on parameter or show menu
case "${1:-menu}" in
    "status"|"quick")
        quick_status
        ;;
    "report"|"full")
        full_report
        ;;
    "syslog"|"logs")
        # Run syslog analysis
        syslog_script="./alertgrams-syslog.sh"
        if [ ! -f "$syslog_script" ]; then
            syslog_script="/usr/local/bin/alertgrams-syslog.sh"
        fi
        
        if [ -f "$syslog_script" ]; then
            lines="${2:-50}"
            "$syslog_script" analyze "$lines"
        else
            printf "Error: Syslog monitoring script not found\n" >&2
            exit 1
        fi
        ;;
    "test")
        test_alert
        ;;
    "menu"|"interactive")
        interactive_menu
        ;;
    *)
        printf "AlertGrams Manual Monitoring Tools\n"
        printf "==================================\n"
        printf "Usage: %s [command]\n\n" "$0"
        printf "Commands:\n"
        printf "  status    - Quick system status check\n"
        printf "  report    - Comprehensive system report\n"
        printf "  syslog N  - Analyze last N syslog entries (default: 50)\n"
        printf "  test      - Test alert functionality\n"
        printf "  menu      - Interactive menu (default)\n"
        printf "\nWith no arguments, starts interactive menu.\n"
        ;;
esac