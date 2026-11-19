#!/bin/sh
# Antigravity hook: send the agent state to herdr-core as an OSC 7501 report.
# Claude Code and Codex send this report themselves. Without it, Herdr.app
# shows an Antigravity pane as a shell and leaves it out of Agents.
# Usage: hc-status.sh idle|working|done
cat >/dev/null 2>&1
# Antigravity reads a JSON object from hook stdout.
printf '{}\n'
[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
case "${1:-}" in idle | working | done) ;; *) exit 0 ;; esac
# Hook stdout goes to Antigravity, so write to the terminal directly.
{ printf '\033]7501;state=%s:app=agy\007' "$1" >/dev/tty; } 2>/dev/null
exit 0
