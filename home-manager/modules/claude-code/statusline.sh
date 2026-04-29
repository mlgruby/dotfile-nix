#!/bin/bash
# Claude Code statusline template.
#
# Claude reads JSON status data on stdin and renders a two-line statusline with
# model, working directory, context usage, token counts, timing, and rate
# limits.
set -euo pipefail

input=$(cat)

# Raw values from JSON.
MODEL=$(echo "$input" | jq -r '.model.display_name // empty')
CWD=$(echo "$input" | jq -r '.workspace.current_dir // empty')
PCT_RAW=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
PCT=$(printf '%.0f' "$PCT_RAW")
IN_TOK=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
OUT_TOK=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
CR_TOK=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
CW_TOK=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
COST_RAW=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
TOTAL_DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
API_TIME=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0')
RL5_RAW=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0')
RL7_RAW=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0')
RL5=$(printf '%.0f' "$RL5_RAW")
RL7=$(printf '%.0f' "$RL7_RAW")

# Colors.
R=$'\033[0m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
GOLD=$'\033[38;5;220m'
ORANGE=$'\033[38;5;172m'
CYAN=$'\033[36m'

# Context bar color.
if [ "$PCT" -ge 80 ]; then
  BAR_C="$RED"
elif [ "$PCT" -ge 50 ]; then
  BAR_C="$YELLOW"
else
  BAR_C="$GREEN"
fi

# Progress bar (10 chars).
FILLED=$((PCT * 10 / 100))
EMPTY=$((10 - FILLED))
BAR=""
i=0
while [ "$i" -lt "$FILLED" ]; do
  BAR="${BAR}█"
  i=$((i + 1))
done
i=0
while [ "$i" -lt "$EMPTY" ]; do
  BAR="${BAR}░"
  i=$((i + 1))
done

# Format token counts with k suffix.
fmt_k() {
  local n="$1"
  if [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN { printf "%.1fk", n / 1000 }'
  else
    printf '%d' "$n"
  fi
}
IN_FMT=$(fmt_k "$IN_TOK")
OUT_FMT=$(fmt_k "$OUT_TOK")
CR_FMT=$(fmt_k "$CR_TOK")
CW_FMT=$(fmt_k "$CW_TOK")

# Cost.
COST_FMT=$(printf '$%.2f' "$COST_RAW")

# Timing.
fmt_dur() {
  local s="$1"
  if [ "$s" -lt 60 ]; then
    printf '%ds' "$s"
  elif [ "$s" -lt 3600 ]; then
    printf '%dm' $((s / 60))
  else
    printf '%dh %dm' $((s / 3600)) $(((s % 3600) / 60))
  fi
}
ELAPSED_S=$(((TOTAL_DURATION_MS + 500) / 1000))
API_S=$(((API_TIME + 500) / 1000))
ELAPSED_FMT=$(fmt_dur "$ELAPSED_S")
API_FMT=$(fmt_dur "$API_S")
TIME_PART="${DIM}⊙${R} ${ELAPSED_FMT} ${DIM}(api ${API_FMT})${R}"

# Rate limits (only show when >0%).
RL_PART=""
if [ "$RL5" -gt 0 ] || [ "$RL7" -gt 0 ]; then
  RL_PARTS=""
  [ "$RL5" -gt 0 ] && RL_PARTS="5h:${RL5}%"
  if [ "$RL7" -gt 0 ]; then
    if [ -n "$RL_PARTS" ]; then
      RL_PARTS="${RL_PARTS} 7d:${RL7}%"
    else
      RL_PARTS="7d:${RL7}%"
    fi
  fi
  RL_PART=" | ${DIM}${RL_PARTS}${R}"
fi

# Caveman badge (active plugin name).
FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
PLUGIN_PART=""
if [ -f "$FLAG" ] && [ ! -L "$FLAG" ]; then
  MODE=$(head -c 64 "$FLAG" 2>/dev/null | tr -d '\n\r' | tr -cd 'a-z0-9-')
  case "$MODE" in
    off)
      PLUGIN_PART=""
      ;;
    full | "")
      PLUGIN_PART="${ORANGE}Caveman: FULL${R}"
      ;;
    ultra)
      PLUGIN_PART="${ORANGE}Caveman: ULTRA${R}"
      ;;
    lite)
      PLUGIN_PART="${ORANGE}Caveman: LITE${R}"
      ;;
    *)
      SUFFIX=$(printf '%s' "$MODE" | tr '[:lower:]' '[:upper:]')
      PLUGIN_PART="${ORANGE}Caveman: ${SUFFIX}${R}"
      ;;
  esac
fi

# Row 1: model | cwd | plugin.
MODEL_PART=""
[ -n "$MODEL" ] && MODEL_PART="${BOLD}[${MODEL}]${R}"

CWD_PART=""
GIT_PART=""
if [ -n "$CWD" ]; then
  CWD_SHORT="${CWD/#$HOME/\~}"
  CWD_PART="${CYAN}${CWD_SHORT}${R}"
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  [ -n "$BRANCH" ] && GIT_PART="${DIM}(${BRANCH})${R}"
fi

ROW1=""
[ -n "$MODEL_PART" ] && ROW1="${MODEL_PART}"
[ -n "$CWD_PART" ] && ROW1="${ROW1} | ${CWD_PART}"
[ -n "$GIT_PART" ] && ROW1="${ROW1} ${GIT_PART}"
[ -n "$PLUGIN_PART" ] && ROW1="${ROW1} | ${PLUGIN_PART}"

# Row 2: usage, tokens, cost, timing, limits.
ROW2="${BAR_C}${BAR}${R} ${BAR_C}${PCT}%${R} | ${DIM}in:${IN_FMT} out:${OUT_FMT} cr:${CR_FMT} cw:${CW_FMT}${R} | ${GOLD}${COST_FMT}${R}"
ROW2="${ROW2} | ${TIME_PART}${RL_PART}"

printf '%b\n%b\n' "$ROW1" "$ROW2"
