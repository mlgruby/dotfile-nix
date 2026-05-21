#!/usr/bin/env bash

tmux_status_collect_vpn() {
  connected_vpns="$(scutil --nc list 2>/dev/null | awk '/\(Connected\)/' || true)"
  vpn_label=""

  aws_vpn_connected="no"
  if [ "${DOTFILES_TMUX_SHOW_AWS_VPN:-no}" = "yes" ]; then
    if printf '%s\n' "$connected_vpns" | grep -Eiq 'aws|amazon|client vpn|vortexa.*vpn|vortexa_.*_vpn'; then
      aws_vpn_connected="yes"
    elif ifconfig 2>/dev/null | awk '
      /^utun[0-9]+:/ { in_utun=1; next }
      /^[a-z0-9]+:/ { in_utun=0 }
      in_utun && /inet 10\.250\./ { found=1 }
      END { exit found ? 0 : 1 }
    '; then
      aws_vpn_connected="yes"
    elif netstat -rn -f inet 2>/dev/null | awk '
      $2 ~ /^10\.250\./ && $NF ~ /^utun[0-9]+$/ { found=1 }
      END { exit found ? 0 : 1 }
    '; then
      aws_vpn_connected="yes"
    fi
  fi

  if [ "$aws_vpn_connected" = "yes" ]; then
    vpn_label="󰸏 VPN"
  fi

  if printf '%s\n' "$connected_vpns" | grep -Eiq 'tailscale'; then
    vpn_label="${vpn_label:+$vpn_label · }󰖂 MESH"
  fi

  if [ -z "$vpn_label" ] && [ -n "$connected_vpns" ]; then
    vpn_label="󰖂 VPN"
  fi
}
