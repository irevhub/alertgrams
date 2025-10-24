#!/bin/sh
# AlertGrams Service Management Helper
# ===================================
# Description: Helper script for managing AlertGrams service
# Usage: ./service-management.sh [start|stop|restart|status|logs|config]

set -eu

SERVICE_NAME="alertgrams-monitor"
CONFIG_DIR="/etc/alertgrams"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Check if service exists
check_service() {
    if ! systemctl list-unit-files | grep -q "^$SERVICE_NAME.service"; then
        print_error "AlertGrams service is not installed"
        printf "Please run: sudo ./install-service.sh\n"
        exit 1
    fi
}

# Service actions
service_start() {
    print_info "Starting AlertGrams service..."
    if sudo systemctl start "$SERVICE_NAME"; then
        print_info "Service started successfully"
        sleep 2
        sudo systemctl status "$SERVICE_NAME" --no-pager -l
    else
        print_error "Failed to start service"
        exit 1
    fi
}

service_stop() {
    print_info "Stopping AlertGrams service..."
    if sudo systemctl stop "$SERVICE_NAME"; then
        print_info "Service stopped successfully"
    else
        print_error "Failed to stop service"
        exit 1
    fi
}

service_restart() {
    print_info "Restarting AlertGrams service..."
    if sudo systemctl restart "$SERVICE_NAME"; then
        print_info "Service restarted successfully"
        sleep 2
        sudo systemctl status "$SERVICE_NAME" --no-pager -l
    else
        print_error "Failed to restart service"
        exit 1
    fi
}

service_status() {
    print_info "AlertGrams service status:"
    sudo systemctl status "$SERVICE_NAME" --no-pager -l
}

service_logs() {
    print_info "Showing AlertGrams service logs (Ctrl+C to exit):"
    sudo journalctl -u "$SERVICE_NAME" -f --no-pager
}

service_config() {
    if [ -f "$CONFIG_DIR/.env" ]; then
        print_info "Opening configuration file..."
        if command -v nano >/dev/null 2>&1; then
            sudo nano "$CONFIG_DIR/.env"
        elif command -v vi >/dev/null 2>&1; then
            sudo vi "$CONFIG_DIR/.env"
        else
            print_error "No text editor found (nano/vi)"
            printf "Configuration file location: %s/.env\n" "$CONFIG_DIR"
            exit 1
        fi
        
        print_info "Configuration updated. Reloading service..."
        sudo systemctl reload "$SERVICE_NAME"
    else
        print_error "Configuration file not found: $CONFIG_DIR/.env"
        exit 1
    fi
}

show_usage() {
    printf "AlertGrams Service Management\n"
    printf "============================\n\n"
    printf "Usage: %s [COMMAND]\n\n" "$0"
    printf "Commands:\n"
    printf "  start     Start the AlertGrams service\n"
    printf "  stop      Stop the AlertGrams service\n"
    printf "  restart   Restart the AlertGrams service\n"
    printf "  status    Show service status\n"
    printf "  logs      Show live service logs\n"
    printf "  config    Edit configuration file\n"
    printf "  test      Run monitoring test\n"
    printf "\nExamples:\n"
    printf "  %s start\n" "$0"
    printf "  %s logs\n" "$0"
    printf "  %s config\n" "$0"
}

# Test monitoring
service_test() {
    print_info "Running monitoring test..."
    if sudo -u alertgrams /usr/local/bin/alertgrams-monitor.sh test; then
        print_info "Monitoring test completed successfully"
    else
        print_error "Monitoring test failed"
        exit 1
    fi
}

# Main function
main() {
    case "${1:-}" in
        start)
            check_service
            service_start
            ;;
        stop)
            check_service
            service_stop
            ;;
        restart)
            check_service
            service_restart
            ;;
        status)
            check_service
            service_status
            ;;
        logs)
            check_service
            service_logs
            ;;
        config)
            check_service
            service_config
            ;;
        test)
            service_test
            ;;
        -h|--help|help)
            show_usage
            ;;
        "")
            show_usage
            exit 1
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"