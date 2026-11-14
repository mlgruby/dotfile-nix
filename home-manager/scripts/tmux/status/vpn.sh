#!/usr/bin/env bash

tmux_status_collect_vpn() {
  local cache_file="${TMPDIR:-/tmp}/tmux_vpn_${UID:-0}_${DOTFILES_TMUX_SHOW_AWS_VPN:-no}.cache"
  if declare -F tmux_status_cache_fresh >/dev/null 2>&1 && tmux_status_cache_fresh "$cache_file" 15; then
    IFS= read -r vpn_label < "$cache_file" 2>/dev/null || true
    return 0
  fi

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

  # `tailscale status` can print a preferences error while still returning
  # exit code 0. Require valid JSON and an actually running backend before
  # showing MESH. Guard with pgrep so we skip CLI IPC + jq when Tailscale is inactive.
  if command -v tailscale >/dev/null 2>&1 && pgrep -xi "Tailscale" >/dev/null 2>&1; then
    if tailscale status --json 2>/dev/null \
      | jq -e '.BackendState == "Running"' >/dev/null 2>&1; then
      vpn_label="${vpn_label:+$vpn_label · }󰖂 MESH"
    fi
  fi

  if [ -z "$vpn_label" ] && [ -n "$connected_vpns" ] && printf '%s\n' "$connected_vpns" | grep -v -Eiq 'tailscale'; then
    vpn_label="󰖂 VPN"
  fi
  printf '%s\n' "$vpn_label" > "$cache_file" 2>/dev/null || true
}
