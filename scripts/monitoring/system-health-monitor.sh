#!/bin/bash
# scripts/system-health-monitor.sh
#
# System Health Monitoring and Maintenance Script
#
# Purpose:
# - Monitor macOS system health metrics
# - Perform automated maintenance tasks
# - Generate health reports and alerts
# - Integrate with Nix Darwin environment
#
# Features:
# - CPU, memory, disk, and network monitoring
# - Nix store health checks
# - Homebrew maintenance
# - Log analysis and cleanup
# - Performance optimization suggestions
#
# Usage:
#   ./scripts/system-health-monitor.sh [--check|--maintain|--report|--alert]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILE_DIR="$(dirname "$SCRIPT_DIR")"
REPORTS_DIR="$DOTFILE_DIR/.health-reports"
HOSTNAME=$(hostname)

# Health check thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
LOAD_THRESHOLD=8

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Create reports directory
mkdir -p "$REPORTS_DIR"

# System information gathering
get_system_info() {
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    cat << EOF
=== System Health Report - $timestamp ===

Hardware Information:
- Model: $(system_profiler SPHardwareDataType | grep "Model Name" | awk -F: '{print $2}' | xargs)
- Processor: $(system_profiler SPHardwareDataType | grep "Processor Name" | awk -F: '{print $2}' | xargs)
- Memory: $(system_profiler SPHardwareDataType | grep "Memory" | awk -F: '{print $2}' | xargs)
- Serial: $(system_profiler SPHardwareDataType | grep "Serial Number" | awk -F: '{print $2}' | xargs)

Software Information:
- macOS Version: $(sw_vers -productVersion)
- Build: $(sw_vers -buildVersion)
- Hostname: $HOSTNAME
- Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')

EOF
}

# CPU monitoring
check_cpu_usage() {
    local cpu_usage
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    
    echo "CPU Usage: ${cpu_usage}%"
    
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        log_warning "High CPU usage detected: ${cpu_usage}%"
        # Get top CPU processes
        echo "Top CPU-consuming processes:"
        ps -A -o %cpu,pid,comm | sort -nr | head -5
        return 1
    else
        log_success "CPU usage normal: ${cpu_usage}%"
        return 0
    fi
}

# Memory monitoring
check_memory_usage() {
    local memory_pressure
    local memory_used_gb
    local memory_total_gb
    local memory_percent
    
    # Get memory information
    memory_pressure=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print 100-$5}' | sed 's/%//')
    memory_total_gb=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
    
    # Calculate used memory from vm_stat
    local pages_active pages_inactive pages_speculative pages_wired
    eval "$(vm_stat | awk '
        /Pages active/ { print "pages_active=" $3 }
        /Pages inactive/ { print "pages_inactive=" $3 }
        /Pages speculative/ { print "pages_speculative=" $3 }
        /Pages wired down/ { print "pages_wired=" $4 }
    ' | sed 's/\.//g')"
    
    local page_size=4096
    local memory_used_bytes=$(( (pages_active + pages_inactive + pages_speculative + pages_wired) * page_size ))
    memory_used_gb=$(echo "scale=1; $memory_used_bytes / 1024 / 1024 / 1024" | bc)
    memory_percent=$(echo "scale=1; ($memory_used_gb / $memory_total_gb) * 100" | bc)
    
    echo "Memory Usage: ${memory_used_gb}GB / ${memory_total_gb}GB (${memory_percent}%)"
    echo "Memory Pressure: ${memory_pressure}%"
    
    if (( $(echo "$memory_percent > $MEMORY_THRESHOLD" | bc -l) )); then
        log_warning "High memory usage detected: ${memory_percent}%"
        echo "Top memory-consuming processes:"
        ps -A -o %mem,pid,comm | sort -nr | head -5
        return 1
    else
        log_success "Memory usage normal: ${memory_percent}%"
        return 0
    fi
}

# Disk space monitoring
check_disk_usage() {
    local issues=0
    
    echo "Disk Usage:"
    df -h | grep -E '^/dev/' | while read -r _ size used _ capacity mount; do
        local usage_percent
        usage_percent=$(echo "$capacity" | sed 's/%//')
        echo "  $mount: $used / $size ($capacity)"
        
        if [ "$usage_percent" -gt "$DISK_THRESHOLD" ]; then
            log_warning "High disk usage on $mount: $capacity"
            issues=$((issues + 1))
        fi
    done
    
    # Check Nix store size specifically
    if [ -d "/nix/store" ]; then
        local nix_store_size
        nix_store_size=$(du -sh /nix/store 2>/dev/null | awk '{print $1}')
        echo "  Nix Store: $nix_store_size"
        log_info "Nix store size: $nix_store_size"
    fi
    
    return $issues
}

# Load average monitoring
check_load_average() {
    local load_1min load_5min load_15min cpu_cores
    
    load_1min=$(uptime | awk '{print $(NF-2)}' | sed 's/,//')
    load_5min=$(uptime | awk '{print $(NF-1)}' | sed 's/,//')
    load_15min=$(uptime | awk '{print $NF}')
    cpu_cores=$(sysctl -n hw.ncpu)
    
    echo "Load Average: $load_1min, $load_5min, $load_15min (${cpu_cores} cores)"
    
    if (( $(echo "$load_1min > $LOAD_THRESHOLD" | bc -l) )); then
        log_warning "High load average: $load_1min"
        return 1
    else
        log_success "Load average normal: $load_1min"
        return 0
    fi
}

# Network connectivity check
check_network() {
    local issues=0
    
    echo "Network Connectivity:"
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "Internet connectivity: OK"
    else
        log_error "Internet connectivity: FAILED"
        issues=$((issues + 1))
    fi
    
    # Check DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        log_success "DNS resolution: OK"
    else
        log_error "DNS resolution: FAILED"
        issues=$((issues + 1))
    fi
    
    # Check active network interfaces
    echo "Active Network Interfaces:"
    ifconfig | grep -E '^[a-z]' | awk '{print "  " $1}' | sed 's/://'
    
    return $issues
}

# Nix system health check
check_nix_health() {
    local issues=0
    
    echo "Nix System Health:"
    
    # Check if Nix daemon is running
    if pgrep -x "nix-daemon" >/dev/null; then
        log_success "Nix daemon: Running"
    else
        log_error "Nix daemon: Not running"
        issues=$((issues + 1))
    fi
    
    # Check Nix store integrity
    if command -v nix >/dev/null 2>&1; then
        log_info "Checking Nix store integrity..."
        if nix store verify --all >/dev/null 2>&1; then
            log_success "Nix store: Verified"
        else
            log_warning "Nix store: Verification issues detected"
            issues=$((issues + 1))
        fi
        
        # Check for garbage collection opportunities
        local gc_size
        gc_size=$(nix-collect-garbage --dry-run 2>/dev/null | grep "would be freed" | awk '{print $1, $2, $3}' || echo "0 bytes")
        echo "Garbage collection potential: $gc_size"
        
        # Check current generation
        if command -v darwin-rebuild >/dev/null 2>&1; then
            local current_gen
            current_gen=$(darwin-rebuild list-generations | tail -1 | awk '{print $1}')
            echo "Current system generation: $current_gen"
        fi
    else
        log_error "Nix command not available"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Homebrew health check
check_homebrew_health() {
    local issues=0
    
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew Health:"
        
        # Check for outdated packages
        local outdated_count
        outdated_count=$(brew outdated | wc -l | xargs)
        echo "Outdated packages: $outdated_count"
        
        if [ "$outdated_count" -gt 10 ]; then
            log_warning "Many outdated Homebrew packages: $outdated_count"
        fi
        
        # Check Homebrew health
        if brew doctor >/dev/null 2>&1; then
            log_success "Homebrew: Healthy"
        else
            log_warning "Homebrew: Issues detected"
            issues=$((issues + 1))
        fi
    else
        echo "Homebrew: Not installed"
    fi
    
    return $issues
}

# Temperature monitoring (if available)
check_temperature() {
    # Check if temperature monitoring tools are available
    if command -v osx-cpu-temp >/dev/null 2>&1; then
        local cpu_temp
        cpu_temp=$(osx-cpu-temp)
        echo "CPU Temperature: $cpu_temp"
        
        # Extract numeric value and check threshold
        local temp_value
        temp_value=$(echo "$cpu_temp" | sed 's/°C//')
        if (( $(echo "$temp_value > 80" | bc -l) )); then
            log_warning "High CPU temperature: $cpu_temp"
            return 1
        fi
    else
        echo "Temperature monitoring: Not available (install osx-cpu-temp)"
    fi
    
    return 0
}

# System maintenance tasks
perform_maintenance() {
    log_step "Performing system maintenance..."
    
    local maintenance_log
    maintenance_log="$REPORTS_DIR/maintenance_$(date +%Y%m%d_%H%M%S).log"
    
    {
        echo "=== System Maintenance - $(date) ==="
        echo
        
        # Nix maintenance
        if command -v nix >/dev/null 2>&1; then
            echo "=== Nix Maintenance ==="
            echo "Running garbage collection..."
            nix-collect-garbage -d --option max-jobs auto || echo "Garbage collection failed"
            
            echo "Optimizing Nix store..."
            nix store optimise --option max-jobs auto || echo "Store optimization failed"
            
            echo "Verifying store integrity..."
            nix store verify --all || echo "Store verification failed"
            echo
        fi
        
        # Homebrew maintenance
        if command -v brew >/dev/null 2>&1; then
            echo "=== Homebrew Maintenance ==="
            echo "Updating Homebrew..."
            brew update || echo "Homebrew update failed"
            
            echo "Upgrading packages..."
            brew upgrade || echo "Homebrew upgrade failed"
            
            echo "Cleaning up..."
            brew cleanup || echo "Homebrew cleanup failed"
            
            echo "Running doctor..."
            brew doctor || echo "Homebrew doctor found issues"
            echo
        fi
        
        # System cleanup
        echo "=== System Cleanup ==="
        echo "Cleaning temporary files..."
        find /tmp -type f -mtime +7 -delete 2>/dev/null || echo "Temp cleanup failed"
        
        echo "Cleaning user cache..."
        find "$HOME/Library/Caches" -type f -mtime +30 -delete 2>/dev/null || echo "Cache cleanup failed"
        
        echo "Cleaning logs..."
        find "$HOME/Library/Logs" -type f -mtime +30 -delete 2>/dev/null || echo "Log cleanup failed"
        
        # macOS maintenance
        echo "=== macOS Maintenance ==="
        echo "Rebuilding Spotlight index..."
        sudo mdutil -E / || echo "Spotlight rebuild failed"
        
        echo "Flushing DNS cache..."
        sudo dscacheutil -flushcache || echo "DNS flush failed"
        
        echo "=== Maintenance Complete ==="
        
    } | tee "$maintenance_log"
    
    log_success "Maintenance completed. Log saved to: $maintenance_log"
}

# Generate comprehensive health report
generate_health_report() {
    log_step "Generating comprehensive health report..."
    
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$REPORTS_DIR/health_report_$timestamp.txt"
    
    {
        get_system_info
        echo
        
        echo "=== System Health Checks ==="
        echo
        
        echo "CPU Status:"
        check_cpu_usage
        echo
        
        echo "Memory Status:"
        check_memory_usage
        echo
        
        echo "Disk Status:"
        check_disk_usage
        echo
        
        echo "Load Average:"
        check_load_average
        echo
        
        echo "Network Status:"
        check_network
        echo
        
        echo "Temperature Status:"
        check_temperature
        echo
        
        check_nix_health
        echo
        
        check_homebrew_health
        echo
        
        echo "=== Process Information ==="
        echo "Top CPU processes:"
        ps -A -o %cpu,pid,comm | sort -nr | head -10
        echo
        
        echo "Top Memory processes:"
        ps -A -o %mem,pid,comm | sort -nr | head -10
        echo
        
        echo "=== Startup Items ==="
        launchctl list | grep -v "0x0" | head -20
        echo
        
        echo "=== Recent System Errors ==="
        log show --predicate 'eventType == logEvent and messageType == error' --last 1h --style compact | head -20 || echo "No recent errors found"
        
    } > "$report_file"
    
    log_success "Health report generated: $report_file"
    
    # Display summary
    echo
    log_info "=== Health Summary ==="
    local issues=0
    
    check_cpu_usage || issues=$((issues + 1))
    check_memory_usage || issues=$((issues + 1))
    check_disk_usage || issues=$((issues + 1))
    check_load_average || issues=$((issues + 1))
    check_network || issues=$((issues + 1))
    check_nix_health || issues=$((issues + 1))
    check_homebrew_health || issues=$((issues + 1))
    
    if [ $issues -eq 0 ]; then
        log_success "System health: EXCELLENT (0 issues)"
    elif [ $issues -le 2 ]; then
        log_warning "System health: GOOD ($issues issues)"
    elif [ $issues -le 4 ]; then
        log_warning "System health: FAIR ($issues issues)"
    else
        log_error "System health: POOR ($issues issues)"
    fi
    
    return $issues
}

# Alert system for critical issues
check_alerts() {
    local critical_issues=0
    
    log_step "Checking for critical system issues..."
    
    # Check critical disk space
    if df / | awk 'NR==2 {if ($5+0 > 95) exit 1}'; then
        log_error "CRITICAL: Root disk usage above 95%"
        critical_issues=$((critical_issues + 1))
    fi
    
    # Check critical memory usage
    local memory_pressure
    memory_pressure=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print 100-$5}' | sed 's/%//')
    if (( $(echo "$memory_pressure > 95" | bc -l) )); then
        log_error "CRITICAL: Memory pressure above 95%"
        critical_issues=$((critical_issues + 1))
    fi
    
    # Check if system is responsive
    if ! ping -c 1 -t 5 localhost >/dev/null 2>&1; then
        log_error "CRITICAL: System not responding to local ping"
        critical_issues=$((critical_issues + 1))
    fi
    
    # Check Nix daemon
    if ! pgrep -x "nix-daemon" >/dev/null; then
        log_error "CRITICAL: Nix daemon not running"
        critical_issues=$((critical_issues + 1))
    fi
    
    if [ $critical_issues -eq 0 ]; then
        log_success "No critical issues detected"
    else
        log_error "Found $critical_issues critical issues"
        # Here you could add notification logic (e.g., send email, Slack, etc.)
    fi
    
    return $critical_issues
}

# Usage information
show_usage() {
    cat << EOF
🏥 System Health Monitor

Usage:
    $0 [OPTIONS]

Options:
    --check        Quick health check
    --maintain     Perform maintenance tasks
    --report       Generate comprehensive health report
    --alert        Check for critical issues only
    --help         Show this help message

Examples:
    $0 --check                # Quick health check
    $0 --maintain             # Run maintenance
    $0 --report               # Full health report
    $0 --alert                # Critical issues only

Reports are saved in: $REPORTS_DIR/

EOF
}

# Main execution
main() {
    case "${1:-}" in
        --check)
            log_info "Running quick health check..."
            generate_health_report
            ;;
        --maintain)
            perform_maintenance
            ;;
        --report)
            generate_health_report
            ;;
        --alert)
            check_alerts
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            log_info "Running default health check..."
            generate_health_report
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Ensure we're in the right directory
if [[ ! -f "$DOTFILE_DIR/flake.nix" ]]; then
    log_error "Must be run from dotfile directory or subdirectory"
    exit 1
fi

# Change to dotfile directory
cd "$DOTFILE_DIR"

# Run main function
main "$@"
