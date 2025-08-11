#!/bin/bash
# Enhanced Nix daemon status checker and auto-starter
# Usage: ./scripts/utils/check-nix-daemon.sh [--auto-fix] [--quiet]
#
# Options:
#   --auto-fix: Automatically fix daemon issues without prompts
#   --quiet: Minimal output, useful for startup scripts

# Parse command line arguments
AUTO_FIX=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-fix)
            AUTO_FIX=true
            shift
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--auto-fix] [--quiet]"
            exit 1
            ;;
    esac
done

# Logging function
log() {
    if [ "$QUIET" = false ]; then
        echo "$1"
    fi
}

log "🔍 Checking Nix daemon status..."

# Check if daemon plist exists
if [ ! -f "/Library/LaunchDaemons/org.nixos.nix-daemon.plist" ]; then
    log "❌ Nix daemon plist not found!"
    log "   This usually means Nix needs to be reinstalled."
    exit 1
fi

# Function to test if Nix is working
test_nix() {
    nix --version > /dev/null 2>&1
}

# Function to start/restart daemon
start_daemon() {
    log "🔄 Starting Nix daemon..."
    
    # Unload first (in case it's in a bad state)
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
    
    # Load and enable
    sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    sudo launchctl enable system/org.nixos.nix-daemon
    
    # Wait a moment for daemon to start
    sleep 2
}

# Check if daemon is running
if sudo launchctl list | grep -q "org.nixos.nix-daemon"; then
    daemon_status=$(sudo launchctl list | grep "org.nixos.nix-daemon")
    log "✅ Nix daemon is loaded: $daemon_status"
    
    # Test if Nix actually works
    if test_nix; then
        nix_version=$(nix --version 2>/dev/null)
        log "✅ Nix is working: $nix_version"
        
        # Ensure it's enabled for startup
        sudo launchctl enable system/org.nixos.nix-daemon 2>/dev/null || true
        
        if [ "$QUIET" = false ]; then
            echo ""
            echo "📋 Current Nix services status:"
            sudo launchctl list | grep nix
        fi
        exit 0
    else
        log "❌ Nix daemon is loaded but not responding"
        if [ "$AUTO_FIX" = true ]; then
            start_daemon
        else
            log "🔧 Run with --auto-fix to automatically restart the daemon"
            exit 1
        fi
    fi
else
    log "❌ Nix daemon is not running"
    if [ "$AUTO_FIX" = true ]; then
        start_daemon
    else
        log "🔧 Run with --auto-fix to automatically start the daemon"
        exit 1
    fi
fi

# Verify the fix worked
if test_nix; then
    nix_version=$(nix --version 2>/dev/null)
    log "✅ Nix daemon successfully started: $nix_version"
    exit 0
else
    log "❌ Failed to start Nix daemon properly"
    log ""
    log "🔧 Manual troubleshooting steps:"
    log "   1. Check for permission issues: sudo ls -la /nix/var/nix/daemon-socket/"
    log "   2. Try manual restart: sudo launchctl kickstart -k system/org.nixos.nix-daemon"
    log "   3. Check system logs: log show --predicate 'subsystem == \"org.nixos.nix-daemon\"' --last 10m"
    exit 1
fi