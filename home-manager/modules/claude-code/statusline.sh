#!/bin/bash
# Claude Code statusline template.
#
# Claude reads JSON status data on stdin and renders a compact statusline with
# branch, context usage, cost, cache hit rate, rate limit, and caveman mode.
set -euo pipefail

input=$(cat)

PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
COST_FMT=$(printf '$%.2f' "$COST")
RL5=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0' | cut -d. -f1)
CACHE_READ=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
INPUT=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
BRANCH=$(git branch --show-current 2>/dev/null || true)

# Mini context bar.
FILLED=$((PCT * 6 / 100))
EMPTY=$((6 - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v F "%${FILLED}s" && BAR="${F// /█}"
[ "$EMPTY" -gt 0 ] && printf -v E "%${EMPTY}s" && BAR="${BAR}${E// /░}"

# Context color.
if [ "$PCT" -ge 80 ]; then
  C=$'\033[31m'
elif [ "$PCT" -ge 50 ]; then
  C=$'\033[33m'
else
  C=$'\033[32m'
fi
R=$'\033[0m'
DIM=$'\033[2m'
CYAN=$'\033[36m'

# Rate limit: only show if >40%.
RL_PART=""
[ "$RL5" -ge 40 ] && RL_PART="  ${C}rl:${RL5}%${R}"

# Cache hit: only show if >0 cache reads.
CACHE_PART=""
if [ "$INPUT" -gt 0 ] && [ "$CACHE_READ" -gt 0 ]; then
  CACHE_PCT=$((CACHE_READ * 100 / (INPUT + CACHE_READ)))
  CACHE_PART="  ${DIM}cache:${CACHE_PCT}%${R}"
fi

# Branch: only show if in git repo.
BR_PART=""
[ -n "$BRANCH" ] && BR_PART="  ${CYAN}${BRANCH}${R}"

echo -e "${BR_PART}  ${C}${BAR} ${PCT}%${R}  ${DIM}${COST_FMT}${R}${CACHE_PART}${RL_PART}" | sed 's/^  //'
