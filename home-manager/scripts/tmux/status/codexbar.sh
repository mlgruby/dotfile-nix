#!/usr/bin/env bash
# home-manager/scripts/tmux/status/codexbar.sh
# Non-blocking modular status line segment for CodexBar AI usage & quotas.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_FILE="/tmp/codexbar_status.cache"
CACHE_AGE_LIMIT=120 # 2 minutes

calculate_claude_todays_cost() {
  local today
  today=$(date +%Y-%m-%d)
  local cost_total="0.00"

  if [ -d "$HOME/.claude/projects" ]; then
    local matched_files
    matched_files=$(find "$HOME/.claude/projects" -type f -name "*.jsonl" -mtime -1 2>/dev/null || true)
    if [ -n "$matched_files" ]; then
      cost_total=$(echo "$matched_files" | xargs grep -h "$today" 2>/dev/null | jq -r '
        select(.message != null and .message.usage != null) |
        ((.message.usage.input_tokens // 0) * 0.000003) + ((.message.usage.output_tokens // 0) * 0.000015)
      ' 2>/dev/null | awk '{s+=$1} END {printf "%.2f", s}' 2>/dev/null || echo "0.00")
    fi
  fi

  if [ -z "$cost_total" ] || [ "$cost_total" == "" ]; then
    echo "0.00"
  else
    echo "$cost_total"
  fi
}

update_cache() {
  local openai_logo gemini_logo claude_logo
  local codex_json codex_used codex_rem codex_str
  local agy_json gemini_5h_used gemini_w_used g5h_rem gw_rem agy_str
  local claude_cost claude_str full_status
  local codex_num g5h_num gw_num

  # Clean, crisp text badges in brand colors
  openai_logo="#[fg=#10a37f]CX#[fg=#fe8019]"
  gemini_logo="#[fg=#4285f4]AGY#[fg=#fe8019]"
  claude_logo="#[fg=#d97757]CC#[fg=#fe8019]"

  # Fetch Codex quota
  codex_json=$(codexbar usage --provider codex --format json 2>/dev/null || echo "[]")
  codex_used=$(echo "$codex_json" | jq -r '.[0].usage.secondary.usedPercent // .[0].usage.primary.usedPercent // empty' 2>/dev/null || true)
  if [ -n "$codex_used" ] && [ "$codex_used" != "null" ]; then
    codex_num=$(echo "$codex_used" | awk '{print int($1)}')
    codex_rem=$(( 100 - codex_num ))
    codex_str="${openai_logo} ${codex_rem}%"
  else
    codex_str="${openai_logo} --%"
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
    agy_str="${gemini_logo} 5h:${g5h_rem}% W:${gw_rem}%"
  else
    agy_str="${gemini_logo} --%"
  fi

  # Calculate Claude today's cost
  claude_cost=$(calculate_claude_todays_cost)
  claude_str="${claude_logo} \$${claude_cost}"

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
    codexbar_status="#[fg=#10a37f]CX#[fg=#fe8019] --% │ #[fg=#4285f4]AGY#[fg=#fe8019] --% │ #[fg=#d97757]CC#[fg=#fe8019] \$0.00"
  fi
}
