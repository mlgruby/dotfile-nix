#!/bin/bash
# scripts/analyze-build-performance.sh
#
# Build Performance Analysis and Optimization Script
#
# Purpose:
# - Analyze Nix Darwin rebuild performance
# - Identify slow derivations and bottlenecks
# - Provide optimization recommendations
# - Cache expensive operations
#
# Features:
# - Build time analysis
# - Derivation dependency analysis
# - Binary cache utilization metrics
# - Performance optimization suggestions
#
# Usage:
#   ./scripts/analyze-build-performance.sh [--profile|--fix|--report]

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
REPORT_DIR="$DOTFILE_DIR/.performance-reports"
HOSTNAME=$(hostname)

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

# Create report directory
mkdir -p "$REPORT_DIR"

# Analysis functions
analyze_current_system() {
    log_step "Analyzing current system configuration..."
    
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$REPORT_DIR/system_analysis_$timestamp.txt"
    
    {
        echo "=== Nix Darwin System Analysis - $(date) ==="
        echo
        
        echo "=== System Information ==="
        echo "Hostname: $HOSTNAME"
        echo "macOS Version: $(sw_vers -productVersion)"
        echo "Hardware: $(system_profiler SPHardwareDataType | grep "Model Name" | awk -F: '{print $2}' | xargs)"
        echo "CPU Cores: $(sysctl -n hw.ncpu)"
        echo "Memory: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GB"
        echo
        
        echo "=== Nix Configuration ==="
        nix show-config | grep -E "(max-jobs|cores|substituters|trusted|experimental)" || true
        echo
        
        echo "=== Current Generation ==="
        darwin-rebuild list-generations | head -5 || true
        echo
        
        echo "=== Store Statistics ==="
        nix path-info --store /nix/store --all --size --human-readable | head -20 || true
        echo
        
        echo "=== Recent Builds ==="
        find /nix/var/log/nix -name "drvs" -type d -exec find {} -name "*.drv" -mtime -1 \; 2>/dev/null | head -10 || echo "No recent build logs found"
        
    } > "$report_file"
    
    log_success "System analysis saved to: $report_file"
    return 0
}

profile_rebuild() {
    log_step "Profiling rebuild performance..."
    
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local profile_file="$REPORT_DIR/rebuild_profile_$timestamp.txt"
    
    log_info "Starting timed rebuild (dry-run)..."
    
    {
        echo "=== Rebuild Performance Profile - $(date) ==="
        echo
        
        echo "=== Dry Run Analysis ==="
        echo "Running: time darwin-rebuild build --flake . --dry-run"
        time darwin-rebuild build --flake . --dry-run 2>&1
        echo
        
        echo "=== Flake Evaluation Time ==="
        echo "Running: time nix eval .#darwinConfigurations.$HOSTNAME.system"
        time nix eval ".#darwinConfigurations.$HOSTNAME.system" --json > /dev/null 2>&1
        echo
        
        echo "=== Store Path Analysis ==="
        echo "System store path:"
        nix eval --raw ".#darwinConfigurations.$HOSTNAME.system.outPath" 2>/dev/null || echo "Unable to get system path"
        echo
        
        echo "=== Build Dependencies ==="
        echo "Checking required builds..."
        nix path-info --derivation ".#darwinConfigurations.$HOSTNAME.system" 2>/dev/null | head -10 || echo "Unable to get derivation info"
        
    } 2>&1 | tee "$profile_file"
    
    log_success "Rebuild profile saved to: $profile_file"
    return 0
}

check_binary_cache_hits() {
    log_step "Analyzing binary cache performance..."
    
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local cache_report="$REPORT_DIR/cache_analysis_$timestamp.txt"
    
    {
        echo "=== Binary Cache Analysis - $(date) ==="
        echo
        
        echo "=== Configured Substituters ==="
        nix show-config | grep substituters || true
        echo
        
        echo "=== Cache Hit Analysis ==="
        echo "Checking system derivation cache status..."
        local system_drv
        system_drv=$(nix eval --raw ".#darwinConfigurations.$HOSTNAME.system.drvPath" 2>/dev/null || echo "unknown")
        if [[ "$system_drv" != "unknown" ]]; then
            echo "System derivation: $system_drv"
            nix path-info --store https://cache.nixos.org/ "$system_drv" 2>/dev/null && echo "✓ Available in cache.nixos.org" || echo "✗ Not in cache.nixos.org"
        fi
        echo
        
        echo "=== Store Optimization Status ==="
        du -sh /nix/store 2>/dev/null || echo "Unable to check store size"
        echo
        
        echo "=== Recent Cache Activity ==="
        # Check for recent substitution logs
        find /nix/var/log/nix -name "*.log" -mtime -1 2>/dev/null | head -5 || echo "No recent logs found"
        
    } > "$cache_report"
    
    log_success "Cache analysis saved to: $cache_report"
    return 0
}

optimize_performance() {
    log_step "Applying performance optimizations..."
    
    log_info "Running store optimization..."
    nix store optimise --option max-jobs auto || log_warning "Store optimization failed"
    
    log_info "Running garbage collection..."
    nix-collect-garbage -d --option max-jobs auto || log_warning "Garbage collection failed"
    
    log_info "Updating flake inputs for latest optimizations..."
    nix flake update || log_warning "Flake update failed"
    
    log_success "Performance optimizations completed"
}

generate_recommendations() {
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local rec_file="$REPORT_DIR/recommendations_$timestamp.md"
    
    log_step "Generating performance recommendations..."
    
    cat > "$rec_file" << 'EOF'
# Nix Darwin Performance Optimization Recommendations

Generated on: $(date)

## Current Optimizations Applied

### 1. Nix Settings Optimizations ✅
- `max-jobs = "auto"` - Automatic job count based on CPU cores
- `cores = 0` - Use all available cores per job
- Enhanced binary cache configuration
- Automatic store optimization enabled
- Daily garbage collection configured

### 2. Build Acceleration ✅
- `keep-derivations = true` - Faster incremental rebuilds
- `keep-outputs = true` - Avoid rebuilding existing outputs
- Multiple trusted substituters configured
- Build timeout optimizations

## Additional Recommendations

### 3. Development Workflow Optimizations
```bash
# Use these commands for faster rebuilds:
rebuild-fast() {
  darwin-rebuild switch --flake . --option max-jobs auto --option cores 0
}

# Check what will be built before rebuilding:
rebuild-check() {
  darwin-rebuild build --flake . --dry-run
}
```

### 4. Cache Optimization
- Monitor cache hit rates with: `analyze-build-performance.sh --cache`
- Consider setting up a local binary cache for frequently built derivations
- Use `nix-build --check` to verify reproducibility

### 5. Configuration Optimizations
- Minimize expensive home-manager modules during development
- Use `programs.<tool>.enable = false` to disable unused tools temporarily
- Split large configuration files into smaller modules

### 6. Hardware Considerations
- SSD storage recommended for `/nix/store`
- Minimum 16GB RAM for large rebuilds
- Consider `tmpfs` for `/tmp` to speed up builds

## Monitoring Commands

```bash
# Monitor build performance
time darwin-rebuild switch --flake .

# Check store size and optimization status
nix store optimise --dry-run

# Analyze what's using space
nix path-info --all --size --human-readable | sort -hr | head -20

# Check substituter status
nix store ping --store https://cache.nixos.org/
```

## Performance Metrics

Run `analyze-build-performance.sh --profile` regularly to track:
- Build times
- Cache hit rates
- Store size growth
- Evaluation time

## Quick Wins

1. **Enable all optimizations**: Done ✅
2. **Use fast rebuild alias**: `rebuild` alias configured ✅
3. **Regular cleanup**: Automated daily ✅
4. **Monitor performance**: Use this script regularly

EOF

    # Replace $(date) in the file
    sed -i "s/\$(date)/$(date)/g" "$rec_file"
    
    log_success "Recommendations saved to: $rec_file"
    cat "$rec_file"
}

show_usage() {
    cat << EOF
🚀 Nix Darwin Build Performance Analyzer

Usage:
    $0 [OPTIONS]

Options:
    --profile      Profile rebuild performance and timing
    --cache        Analyze binary cache hit rates and performance
    --optimize     Run performance optimizations (cleanup, dedupe)
    --report       Generate comprehensive performance report
    --recommendations  Show optimization recommendations
    --help         Show this help message

Examples:
    $0 --profile              # Profile rebuild performance
    $0 --cache                # Check cache performance
    $0 --optimize             # Run optimizations
    $0 --report               # Full performance analysis

Reports are saved in: $REPORT_DIR/

EOF
}

# Main execution
main() {
    case "${1:-}" in
        --profile)
            profile_rebuild
            ;;
        --cache)
            check_binary_cache_hits
            ;;
        --optimize)
            optimize_performance
            ;;
        --report)
            analyze_current_system
            profile_rebuild
            check_binary_cache_hits
            generate_recommendations
            ;;
        --recommendations)
            generate_recommendations
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            log_info "Running basic performance analysis..."
            analyze_current_system
            log_info "Run with --help to see all options"
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
 