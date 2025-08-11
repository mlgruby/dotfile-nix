#!/bin/bash
# Nix Daemon Startup Script
# This script ensures the Nix daemon is running when the user logs in
# It should be run automatically at login for seamless operation
#
# Usage: Called automatically at login or run manually when needed

# Exit on any error, but don't fail the entire login process
set +e

# Logging
LOG_FILE="$HOME/.local/var/log/nix-daemon-startup.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log with timestamp
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Start logging
log_with_timestamp "=== Nix Daemon Startup Check ==="

# Run the daemon check script in quiet auto-fix mode
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_CHECK_SCRIPT="$SCRIPT_DIR/check-nix-daemon.sh"

if [ -f "$DAEMON_CHECK_SCRIPT" ]; then
    log_with_timestamp "Running daemon check script..."
    
    # Run the check with auto-fix and capture output
    OUTPUT=$("$DAEMON_CHECK_SCRIPT" --auto-fix --quiet 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        log_with_timestamp "✅ Nix daemon is working properly"
    else
        log_with_timestamp "❌ Nix daemon check failed with exit code $EXIT_CODE"
        log_with_timestamp "Output: $OUTPUT"
        
        # Try one more time with a simple approach
        log_with_timestamp "Attempting simple daemon restart..."
        if sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null; then
            sudo launchctl enable system/org.nixos.nix-daemon 2>/dev/null
            log_with_timestamp "✅ Daemon restart completed"
        else
            log_with_timestamp "❌ Simple daemon restart also failed"
        fi
    fi
else
    log_with_timestamp "❌ Daemon check script not found at $DAEMON_CHECK_SCRIPT"
    
    # Fallback: basic daemon check and start
    if ! sudo launchctl list | grep -q "org.nixos.nix-daemon"; then
        log_with_timestamp "Daemon not running, attempting to start..."
        sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null
        sudo launchctl enable system/org.nixos.nix-daemon 2>/dev/null
        log_with_timestamp "✅ Basic daemon start completed"
    else
        log_with_timestamp "✅ Daemon already running"
    fi
fi

log_with_timestamp "=== Startup check completed ==="

# Don't fail the login process even if daemon setup fails
exit 0
