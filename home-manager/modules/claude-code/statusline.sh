#!/bin/bash
# Claude Code statusline template.
#
# Claude reads JSON status data on stdin and renders a two-line statusline with
# model, working directory, context usage, token counts, timing, and rate
# limits.
#
# Cost ownership (keep this separate from the tmux coding-agent bar):
# - This statusline must use Claude Code's native `.cost.total_cost_usd` input.
# - That value is the current Claude session's cumulative native cost and may be
#   $0.00 when Claude Code does not expose a cost for the user's billing plan.
#   On Bedrock it is always absent, so the segment hides itself rather than
#   rendering a meaningless zero.
# - Do not call `ccusage` here. Log-derived daily costs belong in the tmux bar
#   (`home-manager/scripts/tmux/status/codexbar.sh`) and the `cau-*` aliases.
#   The daily total is deliberately absent from this line: one bar owns it.
#
# Presentation: gruvbox truecolor with the same hex values as codexbar.sh, so
# the statusline and the tmux bar directly above it share one palette instead of
# stacking two different greens. Glyphs assume JetBrainsMono Nerd Font, which
# fonts.nix installs and ghostty.nix/alacritty select.
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
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')
TOTAL_DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
API_TIME=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0')
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
EXCEEDS_200K=$(echo "$input" | jq -r '.exceeds_200k_tokens // false')
RL5_RAW=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0')
RL7_RAW=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0')
RL5=$(printf '%.0f' "$RL5_RAW")
RL7=$(printf '%.0f' "$RL7_RAW")

# Colors: gruvbox, truecolor where the terminal advertises it, 256-color
# otherwise. `printf -v` keeps this to zero subshells.
COLOR_MODE=256
case "${COLORTERM:-}" in
  truecolor | 24bit) COLOR_MODE=truecolor ;;
esac
[ -n "${NO_COLOR:-}" ] && COLOR_MODE=none

set_fg() {
  local name="$1" triplet="$2" index="$3"
  case "$COLOR_MODE" in
    truecolor) printf -v "$name" '\033[38;2;%sm' "$triplet" ;;
    256) printf -v "$name" '\033[38;5;%sm' "$index" ;;
    *) printf -v "$name" '%s' '' ;;
  esac
}

set_fg FG '235;219;178' 223     # #ebdbb2
set_fg DIM '146;131;116' 245    # #928374
set_fg SEP '189;174;147' 250    # #bdae93
set_fg GREEN '184;187;38' 142   # #b8bb26
set_fg AMBER '250;189;47' 214   # #fabd2f
set_fg RED '251;73;52' 167      # #fb4934
set_fg BLUE '131;165;152' 109   # #83a598
set_fg PURPLE '211;134;155' 175 # #d3869b
set_fg AQUA '142;192;124' 108   # #8ec07c
set_fg CLAUDE '217;119;87' 173  # #d97757 - the Claude mark's own orange

if [ "$COLOR_MODE" = none ]; then
  R=""
  BOLD=""
  UL=""
else
  R=$'\033[0m'
  BOLD=$'\033[1m'
  UL=$'\033[4m'
fi

# Nerd Font glyphs. The model mark is the same codicon codexbar.sh uses for
# Claude, so both bars label the same thing with the same symbol.
G_MODEL=""
G_DIR=""
G_BRANCH=""
G_CLOCK=""
G_COST=""
G_MODE=""
G_WARN=""

# Separator: one dim interpunct, not a pipe fence.
S="${SEP} · ${R}"

# Context bar color.
if [ "$PCT" -ge 80 ]; then
  BAR_C="$RED"
elif [ "$PCT" -ge 50 ]; then
  BAR_C="$AMBER"
else
  BAR_C="$GREEN"
fi

# Progress bar (8 chars). Clamp so a >100% reading cannot produce a negative
# empty count and a malformed bar.
BAR_WIDTH=8
PCT_CLAMPED="$PCT"
[ "$PCT_CLAMPED" -gt 100 ] && PCT_CLAMPED=100
[ "$PCT_CLAMPED" -lt 0 ] && PCT_CLAMPED=0
FILLED=$(((PCT_CLAMPED * BAR_WIDTH + 50) / 100))
# Reserve the extremes for the extremes: an empty bar must mean 0% and a full
# bar must mean 100%, so 12% keeps one block and 87% keeps one gap.
[ "$FILLED" -eq 0 ] && [ "$PCT_CLAMPED" -gt 0 ] && FILLED=1
[ "$FILLED" -eq "$BAR_WIDTH" ] && [ "$PCT_CLAMPED" -lt 100 ] && FILLED=$((BAR_WIDTH - 1))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
i=0
while [ "$i" -lt "$FILLED" ]; do
  BAR="${BAR}▰"
  i=$((i + 1))
done
i=0
while [ "$i" -lt "$EMPTY" ]; do
  BAR="${BAR}▱"
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

# Claude Code's native cumulative cost for the current session.
COST_FMT=$(printf '$%.2f' "$COST_RAW")

# Publish Claude Code's authoritative session cost for the tmux daily total.
# Keep one local file per session so another Claude session cannot overwrite it.
# Fixed path: the tmux server may have a different TMPDIR inherited from when
# it started, so both processes must use an explicit shared location.
CLAUDE_COST_DIR="/tmp/claude-cost-cache"
mkdir -p "$CLAUDE_COST_DIR"
CLAUDE_COST_DAY=$(date +%Y-%m-%d)
CLAUDE_COST_CACHE="${CLAUDE_COST_DIR}/claude-${CLAUDE_COST_DAY}-${SESSION_ID:-unknown}.json"
CLAUDE_COST_LOCK="${CLAUDE_COST_CACHE}.lock"
CLAUDE_COST_TMP="${CLAUDE_COST_CACHE}.$$"
if mkdir "$CLAUDE_COST_LOCK" 2>/dev/null; then
  trap 'rmdir "$CLAUDE_COST_LOCK" 2>/dev/null || true' EXIT
  PREVIOUS_TOTAL=$(jq -r '.session_total // 0' "$CLAUDE_COST_CACHE" 2>/dev/null || echo 0)
  PREVIOUS_DAY_COST=$(jq -r '.cost // 0' "$CLAUDE_COST_CACHE" 2>/dev/null || echo 0)
  if [ ! -f "$CLAUDE_COST_CACHE" ]; then
    # If this session crossed midnight, use its last known cumulative total as
    # today's baseline so yesterday's spend is not counted again.
    PREVIOUS_TOTAL=$(find "$CLAUDE_COST_DIR" -maxdepth 1 -type f -name "claude-*-${SESSION_ID:-unknown}.json" -print 2>/dev/null \
      | while IFS= read -r previous_file; do jq -r '.session_total // 0' "$previous_file" 2>/dev/null; done \
      | sort -n | tail -1)
    PREVIOUS_TOTAL=${PREVIOUS_TOTAL:-0}
    PREVIOUS_DAY_COST=0
  fi
  if awk -v current="$COST_RAW" -v previous="$PREVIOUS_TOTAL" 'BEGIN { exit !(current >= previous) }'; then
    EFFECTIVE_TOTAL="$COST_RAW"
  else
    EFFECTIVE_TOTAL="$PREVIOUS_TOTAL"
  fi
  DELTA=$(awk -v current="$EFFECTIVE_TOTAL" -v previous="$PREVIOUS_TOTAL" 'BEGIN { d = current - previous; if (d < 0) d = 0; printf "%.10f", d }')
  COST_TO_PUBLISH=$(awk -v day="$PREVIOUS_DAY_COST" -v delta="$DELTA" 'BEGIN { printf "%.10f", day + delta }')
  if jq -n \
    --arg cost "$COST_TO_PUBLISH" \
    --arg total "$EFFECTIVE_TOTAL" \
    --arg session "$SESSION_ID" \
    --arg cwd "$CWD" \
    --arg day "$CLAUDE_COST_DAY" \
    --arg updated "$(date +%s)" \
    '{cost: ($cost | tonumber), session_total: ($total | tonumber), session_id: $session, cwd: $cwd, day: $day, updated_at: ($updated | tonumber)}' \
    > "$CLAUDE_COST_TMP" 2>/dev/null; then
    mv -f "$CLAUDE_COST_TMP" "$CLAUDE_COST_CACHE"
  else
    rm -f "$CLAUDE_COST_TMP"
  fi
  rmdir "$CLAUDE_COST_LOCK" 2>/dev/null || true
  trap - EXIT
fi

# Cost segment. Hidden when zero: on Bedrock the native cost is never populated,
# and a gold $0.00 spends the brightest colour on the least useful field.
COST_PART=""
if awk -v c="$COST_RAW" 'BEGIN { exit !(c > 0) }'; then
  COST_PART="${AMBER}${G_COST} ${COST_FMT}${R}"
fi

# Timing. Sub-hour durations keep their seconds so a 4m30s turn is not rounded
# to a flat 4m.
fmt_dur() {
  local s="$1"
  if [ "$s" -lt 60 ]; then
    printf '%ds' "$s"
  elif [ "$s" -lt 3600 ]; then
    if [ $((s % 60)) -gt 0 ]; then
      printf '%dm%ds' $((s / 60)) $((s % 60))
    else
      printf '%dm' $((s / 60))
    fi
  elif [ $(((s % 3600) / 60)) -gt 0 ]; then
    printf '%dh%dm' $((s / 3600)) $(((s % 3600) / 60))
  else
    printf '%dh' $((s / 3600))
  fi
}
ELAPSED_S=$(((TOTAL_DURATION_MS + 500) / 1000))
API_S=$(((API_TIME + 500) / 1000))
ELAPSED_FMT=$(fmt_dur "$ELAPSED_S")
# One clock only. The old `session <1m` segment reported the same
# TOTAL_DURATION_MS as this one, two segments apart.
TIME_PART="${DIM}${G_CLOCK} ${ELAPSED_FMT}${R}"
if [ "$API_S" -gt 0 ]; then
  TIME_PART="${TIME_PART}${DIM} (api $(fmt_dur "$API_S"))${R}"
fi

# Token counts. Hidden entirely while every counter is zero.
TOKENS_PART=""
if [ "$IN_TOK" -gt 0 ] || [ "$OUT_TOK" -gt 0 ] || [ "$CR_TOK" -gt 0 ] || [ "$CW_TOK" -gt 0 ]; then
  TOKENS_PART="${DIM}↑${IN_FMT} ↓${OUT_FMT}${R}"
  CACHE_PARTS=""
  [ "$CR_TOK" -gt 0 ] && CACHE_PARTS="cr ${CR_FMT}"
  if [ "$CW_TOK" -gt 0 ]; then
    if [ -n "$CACHE_PARTS" ]; then
      CACHE_PARTS="${CACHE_PARTS} cw ${CW_FMT}"
    else
      CACHE_PARTS="cw ${CW_FMT}"
    fi
  fi
  [ -n "$CACHE_PARTS" ] && TOKENS_PART="${TOKENS_PART} ${DIM}(${CACHE_PARTS})${R}"
fi

# Lines changed.
LINES_PART=""
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  LINES_PART="${GREEN}+${LINES_ADD}${R} ${RED}-${LINES_DEL}${R}"
fi

# Large context warning.
WARN_PART=""
if [ "$EXCEEDS_200K" = "true" ]; then
  WARN_PART="${RED}${BOLD}${G_WARN} >200k${R}"
fi

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
  RL_PART="${DIM}${RL_PARTS}${R}"
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
      PLUGIN_PART="${CLAUDE}${G_MODE} CAVEMAN FULL${R}"
      ;;
    ultra)
      PLUGIN_PART="${CLAUDE}${G_MODE} CAVEMAN ULTRA${R}"
      ;;
    lite)
      PLUGIN_PART="${CLAUDE}${G_MODE} CAVEMAN LITE${R}"
      ;;
    *)
      SUFFIX=$(printf '%s' "$MODE" | tr '[:lower:]' '[:upper:]')
      PLUGIN_PART="${CLAUDE}${G_MODE} CAVEMAN ${SUFFIX}${R}"
      ;;
  esac
fi

# Row 1: model | cwd | plugin.
MODEL_PART=""
[ -n "$MODEL" ] && MODEL_PART="${CLAUDE}${BOLD}${G_MODEL} ${MODEL}${R}"

CWD_PART=""
GIT_PART=""
if [ -n "$CWD" ]; then
  CWD_SHORT="${CWD/#$HOME/\~}"
  CWD_PART="${BLUE}${G_DIR} ${CWD_SHORT}${R}"
  BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || true)

  # `gh` resolves the repository from its own working directory, which is
  # whatever cwd Claude Code spawned this script with - not necessarily $CWD.
  # Pin it with -R so the lookup works from anywhere.
  REPO_URL=$(git -C "$CWD" remote get-url origin 2>/dev/null | sed 's|git@github.com:|https://github.com/|;s|\.git$||' || true)
  REPO_SLUG=""
  case "$REPO_URL" in
    https://github.com/*) REPO_SLUG="${REPO_URL#https://github.com/}" ;;
  esac

  # Active PR for current branch, cached briefly to avoid statusline latency.
  if [ -n "$BRANCH" ] && [ "$BRANCH" != "main" ] && [ "$BRANCH" != "develop" ] && [ "$BRANCH" != "HEAD" ] && [ -n "$REPO_SLUG" ] && command -v gh > /dev/null 2>&1; then
    CACHE_BRANCH=$(printf '%s' "$BRANCH" | tr '/:' '--')
    CACHE_FILE="/tmp/claude-pr-cache-${SESSION_ID:-default}-${CACHE_BRANCH}"
    NOW=$(date +%s)
    CACHE_AGE=999999
    if [ -f "$CACHE_FILE" ]; then
      # Prefer GNU stat (provided by Nix), then fall back to macOS/BSD stat.
      CACHE_MTIME=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || /usr/bin/stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
      CACHE_AGE=$((NOW - CACHE_MTIME))
    fi

    # Cache "no PR" as an explicit sentinel. A failed `gh` call (expired auth,
    # network blip) must not be cached as an authoritative absence, or the link
    # disappears for a minute for no visible reason.
    PR_NONE="none"
    if [ "$CACHE_AGE" -gt 60 ]; then
      if PR_NUM=$(gh pr list -R "$REPO_SLUG" --state open --head "$BRANCH" --json number -q '.[0].number' 2>/dev/null); then
        printf '%s' "${PR_NUM:-$PR_NONE}" > "$CACHE_FILE"
      else
        PR_NUM=$(cat "$CACHE_FILE" 2>/dev/null || true)
      fi
    else
      PR_NUM=$(cat "$CACHE_FILE" 2>/dev/null || true)
    fi
    [ "${PR_NUM:-}" = "$PR_NONE" ] && PR_NUM=""

    if [ -n "${PR_NUM:-}" ]; then
      PR_URL="${REPO_URL}/pull/${PR_NUM}"
      # OSC 8 hyperlink, built from real escapes so the final printf needs no
      # backslash interpretation (which would mangle paths containing one).
      OSC8_OPEN=$'\033]8;;'"${PR_URL}"$'\033\\'
      OSC8_CLOSE=$'\033]8;;\033\\'
      GIT_PART="${PURPLE}${G_BRANCH} ${BRANCH}${R} ${AQUA}${UL}${OSC8_OPEN}#${PR_NUM}${OSC8_CLOSE}${R}"
    fi
  fi

  if [ -n "$BRANCH" ] && [ -z "$GIT_PART" ]; then
    GIT_PART="${PURPLE}${G_BRANCH} ${BRANCH}${R}"
  fi
fi

ROW1=""
[ -n "$MODEL_PART" ] && ROW1="${MODEL_PART}"
[ -n "$CWD_PART" ] && ROW1="${ROW1}${S}${CWD_PART}"
[ -n "$GIT_PART" ] && ROW1="${ROW1}${S}${GIT_PART}"
[ -n "$PLUGIN_PART" ] && ROW1="${ROW1}${S}${PLUGIN_PART}"

# Row 2: usage, tokens, native session cost, timing, limits. Every segment
# beyond the context bar hides itself when it has nothing to report.
ROW2="${BAR_C}${BAR} ${PCT}%${R}"
[ -n "$WARN_PART" ] && ROW2="${ROW2} ${WARN_PART}"
for segment in "$TOKENS_PART" "$COST_PART" "$TIME_PART" "$LINES_PART" "$RL_PART"; do
  [ -n "$segment" ] && ROW2="${ROW2}${S}${segment}"
done

printf '%s\n%s\n' "$ROW1" "$ROW2"
