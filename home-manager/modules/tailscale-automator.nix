# home-manager/modules/tailscale-automator.nix
#
# Tailscale Home Network Automator
#
# Purpose:
# - Monitors network changes on macOS via launchd WatchPaths.
# - Automatically disconnects Tailscale and quits Tailscale.app when on the home network.
# - Leaves Tailscale normal/manual when outside the home network.
#
{ config, lib, pkgs, ... }:

let
  script = pkgs.writeShellScript "tailscale-home-check" ''
    set -euo pipefail

    # Identify if on home network:
    # 1. Check default gateway router IP
    ROUTER_IP="$(/usr/sbin/ipconfig getoption en0 router 2>/dev/null || /sbin/route -n get default 2>/dev/null | /usr/bin/awk '/gateway:/ {print $2}')"
    # 2. Check Wi-Fi SSID
    WIFI_SSID="$(/usr/sbin/ipconfig getsummary en0 2>/dev/null | /usr/bin/awk -F' : ' '/  SSID :/ {print $2}')"

    IS_HOME=false

    if [ "$ROUTER_IP" = "192.168.10.1" ] || [ "$WIFI_SSID" = "Satyasheel" ]; then
      IS_HOME=true
    fi

    if [ "$IS_HOME" = true ]; then
      # Disconnect macOS Network Extension service
      if /usr/sbin/scutil --nc list 2>/dev/null | grep -Eiq '\(Connected\).*Tailscale'; then
        /usr/sbin/scutil --nc stop "Tailscale" 2>/dev/null || true
      fi

      # Disconnect CLI if connected
      if /opt/homebrew/bin/tailscale status &>/dev/null; then
        /opt/homebrew/bin/tailscale down 2>/dev/null || true
      fi

      # Quit Tailscale.app if running
      if /usr/bin/pgrep -xi "Tailscale" >/dev/null 2>&1; then
        /usr/bin/osascript -e 'quit app "Tailscale"' 2>/dev/null || true
        /bin/sleep 1
        # If still running, terminate gracefully
        if /usr/bin/pgrep -xi "Tailscale" >/dev/null 2>&1; then
          /usr/bin/pkill -xi "Tailscale" 2>/dev/null || true
        fi
      fi
    fi
  '';
in
{
  launchd.agents.tailscale-home-automator = {
    enable = true;
    domain = "user";
    config = {
      ProgramArguments = [
        "${script}"
      ];
      RunAtLoad = true;
      WatchPaths = [
        "/Library/Preferences/SystemConfiguration"
        "/var/run/resolv.conf"
      ];
      StandardOutPath = "/tmp/tailscale-automator.log";
      StandardErrorPath = "/tmp/tailscale-automator.log";
    };
  };
}
