#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$script_dir/lib.sh"
source "$script_dir/network.sh"
source "$script_dir/github.sh"
source "$script_dir/vpn.sh"
source "$script_dir/aws.sh"
source "$script_dir/system.sh"
source "$script_dir/codexbar.sh"

tmux_status_collect_network
tmux_status_collect_github
tmux_status_collect_vpn
tmux_status_collect_aws
tmux_status_collect_system
tmux_status_collect_codexbar

status_output=""
status_prev_bg="#1d2021"

if [ -n "$network_label" ]; then
  append_segment "#fb4934" "#1d2021" "$network_label"
fi

if [ -n "$github_status" ]; then
  append_segment "$github_bg" "$github_fg" "$github_status"
fi

if [ -n "$vpn_label" ]; then
  append_segment "#b8bb26" "#1d2021" "$vpn_label"
fi

if [ -n "$aws_status" ]; then
  append_segment "#3c3836" "$aws_color" "$aws_status"
fi

append_segment "#504945" "#fe8019" "$codexbar_status"
append_segment "#3c3836" "$disk_color" "󰋊 $disk"
append_segment "#504945" "$cpu_color" "$cpu_status"
append_segment "#3c3836" "$mem_color" " $mem"
append_segment "#504945" "$battery_color" "$batt_icon $battery"
append_segment "#3c3836" "#d5c4a1" "$datetime"
short_host="${HOSTNAME%%.*}"
[ -n "$short_host" ] || short_host="$(hostname -s 2>/dev/null || echo 'localhost')"
append_segment "#bdae93" "#3c3836" "$short_host"

printf '%s#[default]' "$status_output"
