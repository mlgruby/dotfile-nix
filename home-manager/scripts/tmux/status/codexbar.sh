#!/usr/bin/env bash
# home-manager/scripts/tmux/status/codexbar.sh
# Non-blocking modular status line segment for CodexBar AI usage & quotas.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_FILE="/tmp/codexbar_status.cache"
CACHE_AGE_LIMIT=120 # 2 minutes

GREEN="#b8bb26"
AMBER="#fabd2f"
RED="#fb4934"
MUTED="#928374"
CLAUDE_COST_AMBER_THRESHOLD="${CLAUDE_COST_AMBER_THRESHOLD:-30}"
CLAUDE_COST_RED_THRESHOLD="${CLAUDE_COST_RED_THRESHOLD:-60}"

quota_color() {
  local remaining="${1:-}"
  if ! [[ "$remaining" =~ ^[0-9]+$ ]]; then
    echo "$MUTED"
  elif (( remaining > 60 )); then
    echo "$GREEN"
  elif (( remaining >= 30 )); then
    echo "$AMBER"
  else
    echo "$RED"
  fi
}

cost_color() {
  awk -v cost="${1:-0}" \
    -v amber="$CLAUDE_COST_AMBER_THRESHOLD" \
    -v red="$CLAUDE_COST_RED_THRESHOLD" \
    -v green="$GREEN" -v amber_color="$AMBER" -v red_color="$RED" \
    'BEGIN {
      if (cost > red) print red_color
      else if (cost >= amber) print amber_color
      else print green
    }'
}

read_claude_cost() {
  local today raw_cost

  today=$(date +%Y-%m-%d)
  raw_cost=$(codexbar cost --provider claude --format json --refresh 2>/dev/null |
    jq -r --arg today "$today" '
      [.[] | .daily[]? | select(.date == $today) | .totalCost] |
      add // 0
    ' 2>/dev/null || echo 0)

  awk -v cost="$raw_cost" 'BEGIN {
    if (cost !~ /^[0-9]+(\.[0-9]+)?$/) cost = 0
    printf "%.2f", cost + 0
  }'
}

update_cache() {
  local openai_logo gemini_logo claude_logo
  local cx_color agy_5h_color agy_week_color cc_color
  local codex_json codex_used codex_rem codex_str
  local agy_json gemini_5h_used gemini_w_used g5h_rem gw_rem agy_str
  local claude_cost claude_str full_status
  local codex_num g5h_num gw_num

  # Logos retain their provider colors; values indicate remaining quota/spend.
  openai_logo="#[fg=#10a37f]CX "
  gemini_logo="#[fg=#4285f4]AGY "
  claude_logo="#[fg=#d97757]CC "

  # Fetch Codex quota
  codex_json=$(codexbar usage --provider codex --format json 2>/dev/null || echo "[]")
  codex_used=$(echo "$codex_json" | jq -r '.[0].usage.secondary.usedPercent // .[0].usage.primary.usedPercent // empty' 2>/dev/null || true)
  if [ -n "$codex_used" ] && [ "$codex_used" != "null" ]; then
    codex_num=$(echo "$codex_used" | awk '{print int($1)}')
    codex_rem=$(( 100 - codex_num ))
    cx_color=$(quota_color "$codex_rem")
    codex_str="${openai_logo}#[fg=${cx_color}]${codex_rem}%#[fg=#ebdbb2]"
  else
    codex_str="${openai_logo}#[fg=${MUTED}]--%#[fg=#ebdbb2]"
  fi

  # Fetch Antigravity (Gemini) quota
  agy_json=$(codexbar usage --provider antigravity --format json 2>/dev/null || echo "[]")
  gemini_5h_used=$(echo "$agy_json" | jq -r '.[0].usage.extraRateWindows[]? | select(.id=="antigravity-quota-summary-gemini-5h") | .window.usedPercent' 2>/dev/null || true)
  gemini_w_used=$(echo "$agy_json" | jq -r '.[0].usage.primary.usedPercent // .[0].usage.secondary.usedPercent // empty' 2>/dev/null || true)

  if [ -n "$gemini_5h_used" ] && [ "$gemini_5h_used" != "null" ] && [ -n "$gemini_w_used" ] && [ "$gemini_w_used" != "null" ]; then
    g5h_num=$(echo "$gemini_5h_used" | awk '{print int($1)}')
    gw_num=$(echo "$gemini_w_used" | awk '{print int($1)}')
    g5h_rem=$(( 100 - g5h_num ))
    gw_rem=$(( 100 - gw_num ))
    agy_5h_color=$(quota_color "$g5h_rem")
    agy_week_color=$(quota_color "$gw_rem")
    agy_str="${gemini_logo}#[fg=#ebdbb2]5h:#[fg=${agy_5h_color}]${g5h_rem}%#[fg=#ebdbb2] W:#[fg=${agy_week_color}]${gw_rem}%#[fg=#ebdbb2]"
  else
    agy_str="${gemini_logo}#[fg=${MUTED}]--%#[fg=#ebdbb2]"
  fi

  # Use CodexBar's local-log scanner. It handles all sessions, model-specific
  # rates, cache tokens, streaming deduplication, Pi sessions, and daily totals.
  claude_cost=$(read_claude_cost)
  cc_color=$(cost_color "$claude_cost")
  claude_str="${claude_logo}#[fg=${cc_color}]\$${claude_cost}#[fg=#ebdbb2]"

  full_status="${codex_str} │ ${agy_str} │ ${claude_str}"
  echo "$full_status" > "${CACHE_FILE}.tmp" && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
}

tmux_status_collect_codexbar() {
  local now
  now=$(date +%s)
  local mtime=0

  if [ -f "$CACHE_FILE" ]; then
    mtime=$(python3 -c "import os; print(int(os.path.getmtime('$CACHE_FILE')))" 2>/dev/null || echo 0)
  fi

  # Synchronously populate if cache missing, or update in background if expired
  if [ ! -f "$CACHE_FILE" ]; then
    update_cache 2>/dev/null || true
  elif (( now - mtime > CACHE_AGE_LIMIT )); then
    ( update_cache ) &>/dev/null &
  fi

  if [ -f "$CACHE_FILE" ]; then
    codexbar_status=$(cat "$CACHE_FILE")
  else
    codexbar_status="#[fg=#10a37f]CX #[fg=${MUTED}]--%#[fg=#ebdbb2] │ #[fg=#4285f4]AGY #[fg=${MUTED}]--%#[fg=#ebdbb2] │ #[fg=#d97757]CC #[fg=${GREEN}]\$0.00#[fg=#ebdbb2]"
  fi
}
