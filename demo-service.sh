#!/bin/sh
# AlertGrams Service Demo/Test Script
# ==================================
# Description: Demonstrates how AlertGrams service would work without installing
# Usage: ./demo-service.sh

set -eu

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    printf "%b[INFO]%b %s\n" "$GREEN" "$NC" "$1"
}

print_warn() {
    printf "%b[WARN]%b %s\n" "$YELLOW" "$NC" "$1"
}

print_error() {
    printf "%b[ERROR]%b %s\n" "$RED" "$NC" "$1" >&2
}

print_demo() {
    printf "%b[DEMO]%b %s\n" "$BLUE" "$NC" "$1"
}

# Demo functions
demo_install() {
    printf "\n%b=== AlertGrams Service Installation Demo ===%b\n" "$BLUE" "$NC"
    printf "\nThis is what would happen during installation:\n\n"
    
    print_demo "1. Check system requirements (systemd, required files)"
    print_demo "2. Create system user 'alertgrams'"
    print_demo "3. Create directories:"
    print_demo "   - /etc/alertgrams (config)"
    print_demo "   - /var/log/alertgrams (logs)"
    print_demo "4. Install files:"
    print_demo "   - alertgrams-monitor.sh → /usr/local/bin/"
    print_demo "   - alert.sh → /usr/local/bin/"
    print_demo "   - alertgrams-monitor.service → /etc/systemd/system/"
    print_demo "5. Copy configuration files"
    print_demo "6. Enable and start service"
    
    printf "\nTo actually install: %bsudo ./install-service.sh%b\n" "$GREEN" "$NC"
}

demo_management() {
    printf "\n%b=== Service Management Demo ===%b\n" "$BLUE" "$NC"
    printf "\nAfter installation, you can manage the service with:\n\n"
    
    printf "%bSystemctl commands:%b\n" "$GREEN" "$NC"
    printf "  sudo systemctl start alertgrams-monitor\n"
    printf "  sudo systemctl stop alertgrams-monitor\n"
    printf "  sudo systemctl restart alertgrams-monitor\n"
    printf "  sudo systemctl status alertgrams-monitor\n"
    printf "  sudo systemctl enable alertgrams-monitor   # Auto-start on boot\n"
    printf "  sudo systemctl disable alertgrams-monitor  # Disable auto-start\n\n"
    
    printf "%bHelper script commands:%b\n" "$GREEN" "$NC"
    printf "  ./service-management.sh start\n"
    printf "  ./service-management.sh stop\n"
    printf "  ./service-management.sh restart\n"
    printf "  ./service-management.sh status\n"
    printf "  ./service-management.sh logs\n"
    printf "  ./service-management.sh config\n"
    printf "  ./service-management.sh test\n\n"
}

demo_logs() {
    printf "\n%b=== Log Viewing Demo ===%b\n" "$BLUE" "$NC"
    printf "\nAfter service is running, view logs with:\n\n"
    
    printf "%bJournalctl commands:%b\n" "$GREEN" "$NC"
    printf "  journalctl -u alertgrams-monitor           # All logs\n"
    printf "  journalctl -u alertgrams-monitor -f        # Follow real-time\n"
    printf "  journalctl -u alertgrams-monitor --since today  # Today only\n"
    printf "  journalctl -u alertgrams-monitor -n 50     # Last 50 lines\n"
    printf "  journalctl -u alertgrams-monitor -p err    # Errors only\n\n"
    
    printf "%bExample log output:%b\n" "$YELLOW" "$NC"
    printf "Oct 25 10:30:15 server alertgrams-monitor[1234]: [INFO] Running monitoring cycle at Fri Oct 25 10:30:15 UTC 2025\n"
    printf "Oct 25 10:30:16 server alertgrams-monitor[1234]: [INFO] CPU usage: 45%%, Memory: 67%%, Disk: 23%%\n"  
    printf "Oct 25 10:30:17 server alertgrams-monitor[1234]: [INFO] All services running normally\n"
    printf "Oct 25 10:30:18 server alertgrams-monitor[1234]: [INFO] Network connectivity OK\n"
    printf "Oct 25 10:30:19 server alertgrams-monitor[1234]: [INFO] Monitoring cycle completed\n"
}

demo_config() {
    printf "\n%b=== Configuration Demo ===%b\n" "$BLUE" "$NC"
    printf "\nService configuration files:\n\n"
    
    printf "%bMain config:%b /etc/alertgrams/.env\n" "$GREEN" "$NC"
    printf "TELEGRAM_API_KEY=your_bot_token_here\n"
    printf "TELEGRAM_CHAT_ID=your_chat_id_here\n"
    printf "MONITOR_INTERVAL=300\n"
    printf "CPU_THRESHOLD=90\n"
    printf "MEMORY_THRESHOLD=95\n"
    printf "DISK_THRESHOLD=90\n\n"
    
    printf "%bService file:%b /etc/systemd/system/alertgrams-monitor.service\n" "$GREEN" "$NC"
    printf "- Runs as 'alertgrams' user for security\n"
    printf "- Auto-restart on failure\n"
    printf "- Proper resource limits\n"
    printf "- Centralized logging\n\n"
    
    printf "%bTo edit config after install:%b\n" "$GREEN" "$NC"
    printf "  sudo nano /etc/alertgrams/.env\n"
    printf "  sudo systemctl reload alertgrams-monitor\n"
}

test_current_setup() {
    printf "\n%b=== Testing Current Setup ===%b\n" "$BLUE" "$NC"
    
    # Check files
    printf "\nChecking required files:\n"
    for file in "alert.sh" "alertgrams-monitor.sh" "alertgrams-monitor.service" ".env"; do
        if [ -f "./$file" ]; then
            print_info "✓ $file found"
        else
            print_warn "✗ $file missing"
        fi
    done
    
    # Check configuration
    printf "\nChecking configuration:\n"
    if [ -f "./.env" ]; then
        if grep -q "TELEGRAM_API_KEY" "./.env"; then
            print_info "✓ TELEGRAM_API_KEY configured"
        else
            print_warn "✗ TELEGRAM_API_KEY not found in .env"
        fi
        if grep -q "TELEGRAM_CHAT_ID" "./.env"; then
            print_info "✓ TELEGRAM_CHAT_ID configured"
        else
            print_warn "✗ TELEGRAM_CHAT_ID not found in .env"
        fi
    else
        print_warn "✗ .env file not found"
    fi
    
    # Test alert functionality
    printf "\nTesting alert functionality (dry run):\n"
    if [ -f "./alert.sh" ] && [ -f "./.env" ]; then
        print_info "✓ Ready for service installation"
        printf "\nTo install: %bsudo ./install-service.sh%b\n" "$GREEN" "$NC"
    else
        print_warn "✗ Some components missing. Run ./install.sh first"
    fi
}

show_usage() {
    printf "AlertGrams Service Demo\n"
    printf "======================\n\n"
    printf "This script demonstrates how AlertGrams service works without installation.\n\n"
    printf "Usage: %s [COMMAND]\n\n" "$0"
    printf "Commands:\n"
    printf "  install    Show installation process demo\n"
    printf "  manage     Show service management demo\n"
    printf "  logs       Show log viewing demo\n"
    printf "  config     Show configuration demo\n"
    printf "  test       Test current setup\n"
    printf "  all        Show all demos\n"
    printf "\nExamples:\n"
    printf "  %s all\n" "$0"
    printf "  %s test\n" "$0"
    printf "  %s logs\n" "$0"
}

main() {
    case "${1:-all}" in
        install)
            demo_install
            ;;
        manage)
            demo_management
            ;;
        logs)
            demo_logs
            ;;
        config)
            demo_config
            ;;
        test)
            test_current_setup
            ;;
        all)
            demo_install
            demo_management
            demo_logs
            demo_config
            test_current_setup
            ;;
        -h|--help|help)
            show_usage
            ;;
        *)
            printf "Unknown command: %s\n\n" "$1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"