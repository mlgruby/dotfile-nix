# home-manager/modules/tmux.nix - Optimized Tmux Configuration
#
# Tmux Configuration
#
# Purpose:
# - Sets up tmux defaults
# - Configures plugins
# - Manages keybindings
#
# Features:
# - Custom key bindings for easy navigation
# - Mouse support and better colors
# - Session management and restoration
# - Gruvbox theme integration
#
# Key Bindings:
# Prefix: Ctrl-a
#
# Window Management:
#   h         : Split horizontal
#   v         : Split vertical
#   x         : Kill pane
#   X         : Kill window
#   q         : Kill session (with confirm)
#
# Navigation:
#   Alt + ←↑↓→       : Switch panes
#   Shift + ←→       : Switch windows
#   Alt + Shift + ←↑↓→: Resize panes
#
# Quick Actions:
#   Enter    : Split horizontal
#   Space    : Split vertical
#   r        : Reload config
#
# Plugins:
# - tmux-sensible: Better defaults
# - tmux-yank: Copy/paste support
# - tmux-resurrect: Session saving
# - tmux-continuum: Auto-save sessions
# - tmux-gruvbox: Theme integration
#
# Integration:
# - Works with shell config
# - Uses Nix-managed tmux plugins
#
# Note:
# - Uses Ctrl+a prefix
# - Mouse mode enabled
# - Vi keys supported
{ config, pkgs, ... }:
let
  statusScript = "${config.home.homeDirectory}/.config/tmux/status-right.sh";
in
{
  programs.tmux = {
    enable = true;
    shortcut = "a"; # Prefix: Ctrl-a
    baseIndex = 1; # Start windows at 1
    escapeTime = 0; # Remove delay

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
      gruvbox
    ];

    extraConfig = ''
      # Core Settings
      set -g mouse on
      set -g status on
      set -g status-position top
      set -g status-interval 5
      set -g status-right-length 220
      set -g default-terminal "screen-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -g allow-passthrough all
      set -g update-environment "DISPLAY KRB5CCNAME SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY DOCKER_CONFIG"

      # Pane Management
      bind h split-window -h -c "#{pane_current_path}"
      bind v split-window -v -c "#{pane_current_path}"
      bind Enter split-window -h -c "#{pane_current_path}"
      bind Space split-window -v -c "#{pane_current_path}"
      bind x kill-pane
      bind X kill-window
      bind q confirm-before -p "Kill session #S? (y/n)" kill-session

      # Navigation (no prefix needed)
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D
      bind -n S-Left previous-window
      bind -n S-Right next-window

      # Resizing
      bind -n M-S-Left resize-pane -L 2
      bind -n M-S-Right resize-pane -R 2
      bind -n M-S-Up resize-pane -U 2
      bind -n M-S-Down resize-pane -D 2

      # Config reload
      bind r source-file $HOME/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Plugin Settings
      set -g @tmux-gruvbox 'dark'
      set -g @continuum-restore 'on'
      set -g @resurrect-capture-pane-contents 'on'

      # Status modules
      set -g status-right "#(bash ${statusScript})"
    '';
  };

  home.file.".config/tmux/status-right.sh" = {
    executable = true;
    text = ''
            #!/usr/bin/env bash
            set -euo pipefail

            default_iface="$(route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }' || true)"
            wifi_active="no"
            lan_active="no"
            for iface in $(ifconfig -l 2>/dev/null); do
              case "$iface" in
                en0)
                  if ipconfig getifaddr "$iface" >/dev/null 2>&1; then
                    wifi_active="yes"
                  fi
                  ;;
                en*)
                  if ipconfig getifaddr "$iface" >/dev/null 2>&1; then
                    lan_active="yes"
                  fi
                  ;;
              esac
            done

            if [ "$wifi_active" = "yes" ] && [ "$lan_active" = "yes" ]; then
              if [ "$default_iface" = "en0" ]; then
                network_label="󰖩 wifi · 󰈀 lan"
              else
                network_label="󰈀 lan · 󰖩 wifi"
              fi
              network_color="#8ec07c"
            elif [ "$lan_active" = "yes" ]; then
              network_label="󰈀 lan"
              network_color="#83a598"
            elif [ "$wifi_active" = "yes" ]; then
              network_label="󰖩 wifi"
              network_color="#8ec07c"
            else
              network_label="󰖪 offline"
              network_color="#928374"
            fi

            # Show VPN as on when macOS reports any connected VPN service,
            # including Tailscale.
            vpn="$(
              if scutil --nc list 2>/dev/null \
                | awk '/\(Connected\)/ { found=1 } END { exit found ? 0 : 1 }'; then
                echo "on"
              else
                echo "off"
              fi
            )"

            disk="$(
              df -h /System/Volumes/Data / 2>/dev/null \
                | awk 'NR==2{print $5 " " $3 "/" $2; exit}' \
                || echo "n/a"
            )"
            [ -n "$disk" ] || disk="n/a"

            # Network throughput: delta bytes vs previous sample stored in /tmp
            net="$(DEFAULT_IFACE="$default_iface" python3 -c "
      import os, subprocess, time

      iface=os.environ.get('DEFAULT_IFACE') or 'en0'
      cache=f'/tmp/tmux_net_cache_{iface}'
      def get_bytes():
          out = subprocess.run(['netstat','-ib'], capture_output=True, text=True).stdout
          for line in out.split('\n'):
              if line.startswith(iface) and '<Link#' in line:
                  parts = line.split()
                  try: return int(parts[6]), int(parts[9]), time.time()
                  except: pass
          return 0, 0, time.time()

      rx2, tx2, t2 = get_bytes()
      try:
          with open(cache) as f:
              parts = f.read().split()
              rx1, tx1, t1 = int(parts[0]), int(parts[1]), float(parts[2])
          dt = max(t2 - t1, 1)
          rx_kb = max(rx2 - rx1, 0) / dt / 1024
          tx_kb = max(tx2 - tx1, 0) / dt / 1024
          def fmt(k):
              return f'{k/1024:.1f}M' if k >= 1024 else f'{k:.0f}K'
          result = f'↓{fmt(rx_kb)} ↑{fmt(tx_kb)}'
      except:
          result = '...'
      with open(cache, 'w') as f:
          f.write(f'{rx2} {tx2} {t2}')
      print(result)
      " 2>/dev/null || echo "n/a")"

            cpu="$(
              top -l 1 2>/dev/null \
                | awk -F'[:,%]' '/CPU usage/ { gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $4); printf "%.0f%%", $2 + $4; exit }' \
                || true
            )"
            [ -n "$cpu" ] || cpu="n/a"

            mem="$(
              vm_stat 2>/dev/null | awk '
                /page size of/ { pageSize = $8 }
                /Pages active/ { active = $3 }
                /Pages inactive/ { inactive = $3 }
                /Pages speculative/ { speculative = $3 }
                /Pages wired down/ { wired = $4 }
                END {
                  gsub(/\./, "", active);
                  gsub(/\./, "", inactive);
                  gsub(/\./, "", speculative);
                  gsub(/\./, "", wired);
                  used = (active + inactive + speculative + wired) * pageSize / 1024 / 1024 / 1024;
                  if (used > 0) {
                    printf "%.1fG", used;
                  }
                }
              ' \
              || true
            )"
            [ -n "$mem" ] || mem="n/a"

            battery="$(
              pmset -g batt 2>/dev/null \
                | awk -F';' '/%/ { gsub(/^ +| +$/, "", $1); sub(/^.*\t/, "", $1); print $1; exit }' \
                || true
            )"
            [ -n "$battery" ] || battery="n/a"

            battery_charging="$(
              pmset -g batt 2>/dev/null \
                | awk '/AC Power/ { ac=1 } /charged|charging/ { if (ac && !/dischar/) print "yes"; exit }' \
                || true
            )"

            cpu_color="#b8bb26"
            cpu_value="''${cpu%%%}"
            if [ "$cpu_value" != "$cpu" ] && [ "$cpu_value" -ge 80 ] 2>/dev/null; then
              cpu_color="#fb4934"
            elif [ "$cpu_value" != "$cpu" ] && [ "$cpu_value" -ge 50 ] 2>/dev/null; then
              cpu_color="#fabd2f"
            fi

            battery_color="#b8bb26"
            battery_value="''${battery%%%}"
            if [ "$battery_value" != "$battery" ] && [ "$battery_value" -le 20 ] 2>/dev/null; then
              battery_color="#fb4934"
            elif [ "$battery_value" != "$battery" ] && [ "$battery_value" -le 50 ] 2>/dev/null; then
              battery_color="#fabd2f"
            fi

            if [ "$battery_charging" = "yes" ]; then
              batt_icon="󰂄"
            else
              batt_icon="󰁹"
            fi

            vpn_icon="󰖂"  # 󰖂 VPN lock icon
            vpn_color="#928374"
            if [ "$vpn" = "on" ]; then
              vpn_color="#b8bb26"
            fi

            segment() {
              local bg="$1"
              local fg="$2"
              local prev_bg="$3"
              local text="$4"
              printf '#[fg=%s,bg=%s,nobold,nounderscore,noitalics]#[fg=%s,bg=%s] %s ' "$bg" "$prev_bg" "$fg" "$bg" "$text"
            }

            printf '%s%s%s%s%s%s%s%s%s#[default]' \
              "$(segment "#3c3836" "#83a598" "#1d2021" "$net")" \
              "$(segment "#504945" "$network_color" "#3c3836" "$network_label")" \
              "$(segment "#3c3836" "$vpn_color" "#504945" "$vpn_icon $vpn")" \
              "$(segment "#504945" "#a89984" "#3c3836" " $disk")" \
              "$(segment "#3c3836" "$cpu_color" "#504945" " $cpu")" \
              "$(segment "#504945" "#ebdbb2" "#3c3836" " $mem")" \
              "$(segment "#3c3836" "$battery_color" "#504945" "$batt_icon $battery")" \
              "$(segment "#504945" "#d5c4a1" "#3c3836" "$(date "+%H:%M")")" \
              "$(segment "#bdae93" "#3c3836" "#504945" "$(hostname -s)")"
    '';
  };
}
