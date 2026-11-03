#!/usr/bin/env bash
# home-manager/scripts/tmux/status/codexbar.sh
# Non-blocking modular status line segment for AI usage & quotas.
#
# Quota ownership:
# - CX is read from Codex's native app-server rate-limit endpoint.
# - AGY is read directly from Antigravity's read-only `/usage` JSON command.
# - CodexBar is deliberately not used as a quota source here.
#
# Cost ownership (keep this separate from Claude Code's native statusline):
# - This terminal-wide bar uses `ccusage` to calculate log-derived daily cost.
# - Claude Code's own statusline instead uses its native session cost from the
#   `.cost.total_cost_usd` payload; never substitute that session value here.
# - Pricing is fetched online first, with ccusage's embedded offline pricing as
#   fallback. These estimates can differ from Claude's native billing payload.

export PATH="/Users/satyasheel/.local/bin:/Users/satyasheel/.nix-profile/bin:/etc/profiles/per-user/satyasheel/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux"
mkdir -p "$CACHE_DIR" && chmod 700 "$CACHE_DIR" 2>/dev/null || true
CACHE_FILE="${CODEXBAR_STATUS_CACHE_FILE:-$CACHE_DIR/codexbar_status.cache}"
LOCK_DIR="${CACHE_FILE}.lock"
CACHE_AGE_LIMIT=60 # 1 minute; the refresh itself runs asynchronously

GREEN="#b8bb26"
AMBER="#fabd2f"
RED="#fb4934"
MUTED="#928374"
AI_SEPARATOR="#bdae93"
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

file_mtime() {
  local out
  if stat --version >/dev/null 2>&1; then
    out=$(stat -c %Y "$1" 2>/dev/null || echo 0)
  else
    out=$(/usr/bin/stat -f %m "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0)
  fi
  if [[ "$out" =~ ^[0-9]+$ ]]; then
    echo "$out"
  else
    echo 0
  fi
}

parse_epoch_seconds() {
  local raw="$1"
  [ -n "$raw" ] && [ "$raw" != "null" ] || return 1

  if [[ "$raw" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "${raw%.*}"
    return 0
  fi

  if [[ "$raw" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})(\.[0-9]+)?(Z|[+-][0-9]{2}:?[0-9]{2})?$ ]]; then
    local dt="${BASH_REMATCH[1]}"
    local tz="${BASH_REMATCH[3]}"
    if [[ -z "$tz" || "$tz" == "Z" ]]; then
      local epoch
      epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$dt" "+%s" 2>/dev/null) && {
        echo "$epoch"
        return 0
      }
    fi
  fi

  local fallback
  fallback=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$raw" "+%s" 2>/dev/null || date -d "$raw" "+%s" 2>/dev/null) && {
    echo "$fallback"
    return 0
  }

  return 1
}

reset_countdown() {
  local resets_at="${1:-}"

  if [ -z "$resets_at" ] || [ "$resets_at" = "null" ]; then
    printf '?'
    return
  fi

  local reset_epoch
  reset_epoch=$(parse_epoch_seconds "$resets_at") || {
    printf '?'
    return
  }

  local now
  now=$(date +%s)
  local seconds=$(( reset_epoch - now ))
  if (( seconds <= 0 )); then
    printf 'now'
    return
  fi

  local total_minutes=$(( (seconds + 59) / 60 ))
  local days=$(( total_minutes / 1440 ))
  local rem_min=$(( total_minutes % 1440 ))
  local hours=$(( rem_min / 60 ))
  local minutes=$(( rem_min % 60 ))

  if (( days > 0 )); then
    printf '%dd %dh' "$days" "$hours"
  elif (( hours > 0 )); then
    printf '%dh %dm' "$hours" "$minutes"
  elif (( minutes > 0 )); then
    printf '%dm' "$minutes"
  else
    printf 'now'
  fi
}

reset_is_within() {
  local resets_at="${1:-}"
  local threshold_seconds="${2:-0}"

  [ -n "$resets_at" ] && [ "$resets_at" != "null" ] || return 1
  [[ "$threshold_seconds" =~ ^[0-9]+$ ]] || return 1

  local reset_epoch
  reset_epoch=$(parse_epoch_seconds "$resets_at") || return 1
  local now
  now=$(date +%s)
  local remaining=$(( reset_epoch - now ))
  (( remaining >= 0 && remaining <= threshold_seconds ))
}

quota_value() {
  local remaining="${1:-}"
  local resets_at="${2:-}"
  local reset_horizon_seconds="${3:-0}"

  if [ "$remaining" = "0" ]; then
    printf '↻%s' "$(reset_countdown "$resets_at")"
  elif reset_is_within "$resets_at" "$reset_horizon_seconds"; then
    printf '%s%% ↻%s' "$remaining" "$(reset_countdown "$resets_at")"
  elif [ "$remaining" -lt 20 ] 2>/dev/null; then
    printf '%s%% ↻%s' "$remaining" "$(reset_countdown "$resets_at")"
  else
    printf '%s%%' "$remaining"
  fi
}

read_codex_weekly_window() {
  # Codex exposes this through its local app-server JSON-RPC protocol. It is
  # an account read only: no agent turn is started and no quota is consumed.
  python3 - <<'PY'
import json
import select
import subprocess
import sys
import time

process = subprocess.Popen(
    ["codex", "app-server"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True,
)

def send(message):
    process.stdin.write(json.dumps(message) + "\n")
    process.stdin.flush()

try:
    send({
        "id": 1,
        "method": "initialize",
        "params": {
            "clientInfo": {"name": "tmux-status", "version": "1.0"},
            "capabilities": {"experimentalApi": True},
        },
    })

    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        ready, _, _ = select.select([process.stdout], [], [], deadline - time.monotonic())
        if not ready:
            break
        line = process.stdout.readline()
        if not line:
            break
        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            continue

        if message.get("id") == 1:
            send({"method": "initialized", "params": {}})
            send({"id": 2, "method": "account/rateLimits/read", "params": None})
        elif message.get("id") == 2:
            result = message.get("result", {})
            limits = result.get("rateLimitsByLimitId", {}).get("codex") or result.get("rateLimits", {})
            for window in (limits.get("primary"), limits.get("secondary"), limits.get("tertiary")):
                if window and window.get("windowDurationMins") == 10080:
                    print(json.dumps(window))
                    raise SystemExit(0)
            raise SystemExit(1)
finally:
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            process.kill()
PY
}

read_agy_usage() {
  # `/usage` is a read-only Antigravity command that refreshes the provider's
  # quota snapshot. It emits structured data without starting an agent turn.
  agy -p '/usage' --output-format json 2>/dev/null || printf '{}'
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
  local today since_date raw_json raw_cost

  today=$(date +%Y-%m-%d)
  since_date="${today//-/}"
  # Pass --since so ccusage only scans today's JSONL entries (~0.5s instead of
  # scanning the entire multi-GB history and hitting the timeout).
  # Prefer current pricing while online; fall back to embedded pricing +
  # token-based estimate for newer models (e.g. claude-opus-5-5 / sonnet-5-5)
  # when offline.
  if command -v timeout >/dev/null 2>&1; then
    raw_json=$(timeout 12 ccusage claude daily --json --since "$since_date" 2>/dev/null || true)
  else
    raw_json=$(ccusage claude daily --json --since "$since_date" 2>/dev/null || true)
  fi
  if [ -z "$raw_json" ] || ! printf '%s' "$raw_json" | jq -e . >/dev/null 2>&1; then
    raw_json=$(ccusage claude daily --json --offline --since "$since_date" 2>/dev/null || echo '{}')
  fi
  raw_cost=$(printf '%s' "$raw_json" |
    jq -r --arg today "$today" '
      def model_cost:
        if (.cost // 0) > 0 then .cost
        elif (.modelName // "" | test("opus"; "i")) then
          ((.inputTokens // 0) * 5 + (.cacheCreationTokens // 0) * 6.25 + (.cacheReadTokens // 0) * 0.5 + (.outputTokens // 0) * 25) / 1000000
        elif (.modelName // "" | test("sonnet"; "i")) then
          ((.inputTokens // 0) * 3 + (.cacheCreationTokens // 0) * 3.75 + (.cacheReadTokens // 0) * 0.3 + (.outputTokens // 0) * 15) / 1000000
        elif (.modelName // "" | test("haiku"; "i")) then
          ((.inputTokens // 0) * 1 + (.cacheCreationTokens // 0) * 1.25 + (.cacheReadTokens // 0) * 0.1 + (.outputTokens // 0) * 5) / 1000000
        else 0 end;
      def day_cost:
        if (.totalCost // .costUSD // .cost // 0) > 0 then
          (.totalCost // .costUSD // .cost // 0)
        elif (.modelBreakdowns | type) == "array" then
          ([.modelBreakdowns[] | model_cost] | add // 0)
        else 0 end;
      if (.data | type) == "array" then
        ([.data[] | select(.date == $today) | day_cost] | add // 0)
      elif (.daily | type) == "array" then
        ([.daily[] | select(.date == $today) | day_cost] | add // 0)
      else 0 end
    ' 2>/dev/null || echo 0)

  awk -v cost="$raw_cost" 'BEGIN {
    if (cost !~ /^[0-9]+(\.[0-9]+)?$/) cost = 0
    printf "%.2f", cost + 0
  }'
}

update_cache() {
  local openai_logo gemini_logo claude_logo
  local cx_color agy_5h_color agy_week_color cc_color
  local codex_window codex_used codex_reset codex_rem codex_value codex_str
  local agy_json agy_5h_window agy_w_window agy_argon_window
  local gemini_5h_used gemini_5h_reset gemini_w_used gemini_w_reset
  local argon_used argon_reset argon_str
  local g5h_rem gw_rem g5h_value gw_value agy_str
  local claude_cost claude_str full_status
  local codex_num g5h_num gw_num

  # JetBrains Mono Nerd Font Mono glyphs: Codicons provide the official
  # OpenAI/Claude marks; Antigravity has no dedicated glyph, so use Google.
  openai_logo="#[fg=#10a37f] "
  gemini_logo="#[fg=#4285f4] "
  claude_logo="#[fg=#d97757] "

  # Codex only has a weekly limit; read its native local rate-limit telemetry.
  codex_window=$(read_codex_weekly_window)
  codex_used=$(echo "$codex_window" | jq -r '.used_percent // .usedPercent // empty' 2>/dev/null || true)
  codex_reset=$(echo "$codex_window" | jq -r '.resets_at // .resetsAt // empty' 2>/dev/null || true)
  if [ -n "$codex_used" ] && [ "$codex_used" != "null" ]; then
    codex_num=$(echo "$codex_used" | awk '{print int($1)}')
    codex_rem=$(( 100 - codex_num ))
    cx_color=$(quota_color "$codex_rem")
    # Weekly capacity is worth surfacing before it expires unused.
    codex_value=$(quota_value "$codex_rem" "$codex_reset" 129600)
    codex_str="${openai_logo}#[fg=#ebdbb2]W:#[fg=${cx_color}]${codex_value}#[fg=#ebdbb2]"
  else
    codex_str="${openai_logo}#[fg=#ebdbb2]W:#[fg=${MUTED}]--#[fg=#ebdbb2]"
  fi

  # Fetch Antigravity's Gemini quota directly from its native usage command.
  agy_json=$(read_agy_usage)
  agy_5h_window=$(echo "$agy_json" | jq -c '
    [ .command.data.groups[]?
      | select(.name == "Gemini Models")
      | .buckets[]?
      | select(.id == "gemini-5h")
      | {
          usedPercent: ((1 - (.remaining_fraction // 0)) * 100),
          resetsAt: .reset_time
        }
    ][0] // empty
  ' 2>/dev/null || true)
  agy_w_window=$(echo "$agy_json" | jq -c '
    [ .command.data.groups[]?
      | select(.name == "Gemini Models")
      | .buckets[]?
      | select(.id == "gemini-weekly")
      | {
          usedPercent: ((1 - (.remaining_fraction // 0)) * 100),
          resetsAt: .reset_time
        }
    ][0] // empty
  ' 2>/dev/null || true)
  agy_argon_window=$(echo "$agy_json" | jq -c '
    [ .command.data.groups[]?
      | select(.name | test("argon"; "i"))
      | .buckets[]?
      | select((.id | test("argon"; "i")) or .window == "weekly")
      | {
          usedPercent: ((1 - (.remaining_fraction // 0)) * 100),
          resetsAt: .reset_time
        }
    ][0] // empty
  ' 2>/dev/null || true)
  gemini_5h_used=$(echo "$agy_5h_window" | jq -r '.usedPercent // empty' 2>/dev/null || true)
  gemini_5h_reset=$(echo "$agy_5h_window" | jq -r '.resetsAt // empty' 2>/dev/null || true)
  gemini_w_used=$(echo "$agy_w_window" | jq -r '.usedPercent // empty' 2>/dev/null || true)
  gemini_w_reset=$(echo "$agy_w_window" | jq -r '.resetsAt // empty' 2>/dev/null || true)
  argon_used=$(echo "$agy_argon_window" | jq -r '.usedPercent // empty' 2>/dev/null || true)
  argon_reset=$(echo "$agy_argon_window" | jq -r '.resetsAt // empty' 2>/dev/null || true)

  argon_str=""
  if [ -n "$argon_used" ] && [ "$argon_used" != "null" ]; then
    local argon_num argon_rem argon_color argon_value
    argon_num=$(echo "$argon_used" | awk '{print int($1)}')
    argon_rem=$(( 100 - argon_num ))
    argon_color=$(quota_color "$argon_rem")
    argon_value=$(quota_value "$argon_rem" "$argon_reset" 129600)
    argon_str=" Ar:#[fg=${argon_color}]${argon_value}#[fg=#ebdbb2]"
  fi

  if [ -n "$gemini_5h_used" ] && [ "$gemini_5h_used" != "null" ] && [ -n "$gemini_w_used" ] && [ "$gemini_w_used" != "null" ]; then
    g5h_num=$(echo "$gemini_5h_used" | awk '{print int($1)}')
    gw_num=$(echo "$gemini_w_used" | awk '{print int($1)}')
    g5h_rem=$(( 100 - g5h_num ))
    gw_rem=$(( 100 - gw_num ))
    agy_5h_color=$(quota_color "$g5h_rem")
    agy_week_color=$(quota_color "$gw_rem")
    # Show upcoming resets even with quota remaining: 1h for the short AGY
    # bucket, 36h for weekly capacity that would otherwise go unused.
    g5h_value=$(quota_value "$g5h_rem" "$gemini_5h_reset" 3600)
    gw_value=$(quota_value "$gw_rem" "$gemini_w_reset" 129600)
    if [ "$gw_rem" -eq 0 ]; then
      # A depleted weekly quota blocks Flash/Pro regardless of the 5-hour window.
      agy_str="${gemini_logo}#[fg=#ebdbb2]W:#[fg=${agy_week_color}]${gw_value}#[fg=#ebdbb2]${argon_str}"
    else
      agy_str="${gemini_logo}#[fg=#ebdbb2]5h:#[fg=${agy_5h_color}]${g5h_value}#[fg=#ebdbb2] W:#[fg=${agy_week_color}]${gw_value}#[fg=#ebdbb2]${argon_str}"
    fi
  else
    if [ -n "$argon_str" ]; then
      agy_str="${gemini_logo}#[fg=${MUTED}]--%#[fg=#ebdbb2]${argon_str}"
    else
      agy_str="${gemini_logo}#[fg=${MUTED}]--%#[fg=#ebdbb2]"
    fi
  fi

  # ccusage aggregates Claude's local session logs for terminal-wide daily cost.
  claude_cost=$(read_claude_cost)
  cc_color=$(cost_color "$claude_cost")
  claude_str="${claude_logo}#[fg=${cc_color}]\$${claude_cost}#[fg=#ebdbb2]"

  full_status="${codex_str} #[fg=${AI_SEPARATOR}]⋮#[fg=#ebdbb2] ${agy_str} #[fg=${AI_SEPARATOR}]⋮#[fg=#ebdbb2] ${claude_str}"
  echo "$full_status" > "${CACHE_FILE}.tmp" && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
}

tmux_status_collect_codexbar() {
  local now
  now=$(date +%s)
  local mtime=0

  if [ -f "$CACHE_FILE" ]; then
    mtime=$(file_mtime "$CACHE_FILE")
  fi

  # Quota refreshes can make provider calls, so tmux always returns immediately.
  # The lock prevents its five-second redraw from spawning duplicate refreshes.
  if [ ! -f "$CACHE_FILE" ] || (( now - mtime > CACHE_AGE_LIMIT )); then
    if [ -d "$LOCK_DIR" ]; then
      local lock_mtime
      lock_mtime=$(file_mtime "$LOCK_DIR")
      if (( now - lock_mtime > 120 )); then
        rmdir "$LOCK_DIR" 2>/dev/null || true
      fi
    fi
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      (
        trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
        update_cache
      ) &>/dev/null &
    fi
  fi

  if [ -f "$CACHE_FILE" ]; then
    codexbar_status=$(cat "$CACHE_FILE")
  else
    codexbar_status="#[fg=#10a37f]CX #[fg=#ebdbb2]W:#[fg=${MUTED}]--#[fg=#ebdbb2] │ #[fg=#4285f4]AGY #[fg=${MUTED}]--#[fg=#ebdbb2] │ #[fg=#d97757]CC #[fg=${GREEN}]\$0.00#[fg=#ebdbb2]"
  fi
}
