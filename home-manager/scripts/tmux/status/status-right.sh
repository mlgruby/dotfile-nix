#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$script_dir/lib.sh"
source "$script_dir/network.sh"
source "$script_dir/vpn.sh"
source "$script_dir/aws.sh"
source "$script_dir/system.sh"

tmux_status_collect_network
tmux_status_collect_vpn
tmux_status_collect_aws
tmux_status_collect_system

status_output=""
status_prev_bg="#1d2021"

append_segment "#3c3836" "#83a598" "$net"
append_segment "#504945" "$network_color" "$network_label"

if [ -n "$vpn_label" ]; then
  append_segment "#b8bb26" "#1d2021" "$vpn_label"
fi

append_segment "#3c3836" "$aws_color" "$aws_status"
append_segment "#504945" "#83a598" "$k8s_status"
append_segment "#3c3836" "#d5c4a1" "$nix_status"
append_segment "#504945" "$load_color" "$load_status"
append_segment "#3c3836" "#a89984" "󰋊 $disk"
append_segment "#504945" "$cpu_color" " $cpu"
append_segment "#3c3836" "#ebdbb2" " $mem"
append_segment "#504945" "$battery_color" "$batt_icon $battery"
append_segment "#3c3836" "#d5c4a1" "$datetime"
append_segment "#bdae93" "#3c3836" "$(hostname -s)"

printf '%s#[default]' "$status_output"
