#!/bin/bash
set -euo pipefail
INPUT_JSON=$(cat)
SANDBOX_LOG="$HOME/.gemini/antigravity-cli/cli.log"

# ─── ANSI Helpers (Standard 16-color palette only) ───────────────────────────
R="\033[0m"         # Reset
B="\033[1m"         # Bold
D="\033[2m"         # Dim
I="\033[3m"         # Italic

# Foreground accents (Standard 16 colors)
FG_BLACK="\033[30m"
FG_RED="\033[31m"
FG_GREEN="\033[32m"
FG_YELLOW="\033[33m"
FG_BLUE="\033[34m"
FG_MAGENTA="\033[35m"
FG_CYAN="\033[36m"
FG_WHITE="\033[37m"

FG_GRAY="\033[90m"
FG_BRIGHT_RED="\033[91m"
FG_BRIGHT_GREEN="\033[92m"
FG_BRIGHT_YELLOW="\033[93m"
FG_BRIGHT_BLUE="\033[94m"
FG_BRIGHT_MAGENTA="\033[95m"
FG_BRIGHT_CYAN="\033[96m"
FG_BRIGHT_WHITE="\033[97m"

# Number Highlight Color
NUM_COLOR="${FG_BRIGHT_WHITE}${B}"

# ─── Parse JSON from stdin (Single jq pass for performance) ──────────────────
{
  read -r STATE
  read -r USED_PCT
  read -r VCS_BRANCH
  read -r VCS_DIRTY
  read -r VCS_TYPE
  read -r VCS_CLIENT
  read -r SANDBOX
  read -r SANDBOX_NET
  read -r ARTIFACTS
  read -r SUBAGENTS
  read -r BG_TASKS
  read -r MODEL_ID
  read -r MODEL_NAME
  read -r COLS
  read -r CWD
  read -r CONV_ID
  read -r PRODUCT
  read -r INPUT_TOKENS
  read -r OUTPUT_TOKENS
  read -r CTX_LIMIT
  read -r CTX_USED
  read -r REM_PCT
  read -r QUOTA_5H_FRAC
  read -r QUOTA_5H_RESET
} <<< "$(
  echo "$INPUT_JSON" | jq -r '
    (.agent_state // "idle"),
    (.context_window.used_percentage // 0),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.vcs.type // ""),
    (.vcs.client // ""),
    (.sandbox.enabled // false),
    (.sandbox.allow_network // false),
    (.artifact_count // 0),
    (if .subagents | type == "array" then (.subagents | length) else 0 end),
    (.task_count // 0),
    (.model.id // ""),
    (.model.display_name // ""),
    (.terminal_width // 80),
    (.cwd // ""),
    (.conversation_id // ""),
    (.product // ""),
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.context_window.context_window_size // 0),
    ((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0)),
    (.context_window.remaining_percentage // 100),
    (.quota["gemini-5h"].remaining_fraction // -1),
    (.quota["gemini-5h"].reset_in_seconds // 0)
  ' 2>/dev/null || printf "idle\n0\n\nfalse\n\n\nfalse\nfalse\n0\n0\n0\n\n\n80\n\n\n\n0\n0\n0\n0\n100\n-1\n0\n"
)"


# ─── Icons & Glyphs (Configurable Fallback) ──────────────────────────────────
USE_NERD_FONTS=${USE_NERD_FONTS:-true}

if [ "$USE_NERD_FONTS" = "true" ]; then
  # State icons
  ICON_READY=""
  ICON_THINKING="󰟷"
  ICON_WORKING=""
  ICON_TOOL=""
  ICON_UNKNOWN=""
  
  # Component icons
  ICON_FOLDER=""
  ICON_MODEL=""
  ICON_BRANCH=""
  ICON_CONV="󰍪"
  ICON_CTX="󱍏"
  ICON_TOK=""
  ICON_ART=""
  ICON_SUB="󱙺"
  ICON_BG=""
  
  # Sandbox icons
  ICON_SB_NET="󰒙"
  ICON_SB_NONET="󰴴"
  ICON_SB_OFF="󰦜"
else
  # Fallback standard emojis/unicode
  ICON_READY="🟢"
  ICON_THINKING="💭"
  ICON_WORKING="⚙"
  ICON_TOOL="⚒"
  ICON_UNKNOWN="⏳"
  
  ICON_FOLDER="📁"
  ICON_MODEL="💡"
  ICON_BRANCH="⎇"
  ICON_CONV="💬"
  ICON_CTX="📊"
  ICON_TOK="🪙"
  ICON_ART="📄"
  ICON_SUB="🤖"
  ICON_BG="📋"
  
  ICON_SB_NET="📦"
  ICON_SB_NONET="📦🔒"
  ICON_SB_OFF="🚫"
fi


# ─── Separators ──────────────────────────────────────────────────────────────
DOT="${FG_GRAY} | ${R}"


# ─── VCS directly from git (bypasses JSON parsing entirely) ──────────────────
GIT_DIR="${CWD:-.}"
VCS_BRANCH=$(git -C "$GIT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ -n "$VCS_BRANCH" ]; then
  VCS_TYPE="git"
  if git -C "$GIT_DIR" status --porcelain 2>/dev/null | grep -q .; then
    VCS_DIRTY="true"
  else
    VCS_DIRTY="false"
  fi
else
  VCS_TYPE=""
  VCS_DIRTY="false"
fi


# ─── Computed & Formatted Values ─────────────────────────────────────────────
PCT_FMT=$(LC_NUMERIC=C printf "%.1f" "$USED_PCT")
PCT_INT=${USED_PCT%.*}; PCT_INT=${PCT_INT:-0}

if [ "$PCT_INT" -ge 90 ]; then FILL_COLOR="$FG_BRIGHT_RED"
elif [ "$PCT_INT" -ge 60 ]; then FILL_COLOR="$FG_BRIGHT_YELLOW"
else                              FILL_COLOR="$FG_YELLOW"
fi

human_format() {
  local num=$1
  if [ -z "$num" ] || [ "$num" -eq 0 ] 2>/dev/null; then
    echo "0"
    return
  fi
  if [ "$num" -ge 1000000 ] 2>/dev/null; then
    echo "$((num / 1000000)).$(((num % 1000000) / 100000))M"
  elif [ "$num" -ge 1000 ] 2>/dev/null; then
    echo "$((num / 1000)).$(((num % 1000) / 100))K"
  else
    echo "$num"
  fi
}

fmt_seconds() {
  local s=$1
  if [ -z "$s" ] || [ "$s" -le 0 ] 2>/dev/null; then
    echo "0s"
    return
  fi
  if [ "$s" -ge 3600 ]; then
    echo "$((s / 3600))h$(( (s % 3600) / 60 ))m"
  elif [ "$s" -ge 60 ]; then
    echo "$((s / 60))m"
  else
    echo "${s}s"
  fi
}

float_to_pct() {
  local val=$1
  if [ -z "$val" ] || [ "$val" = "-1" ]; then
    echo "-1"
    return
  fi
  
  # Normalize .XX to 0.XX
  if [[ "$val" =~ ^\.[0-9]+$ ]]; then
    val="0$val"
  fi
  
  if [[ "$val" =~ ^1(\.0+)?$ ]]; then
    echo "100"
    return
  fi
  
  if [[ "$val" =~ ^0(\.0+)?$ ]]; then
    echo "0"
    return
  fi
  
  if [[ "$val" =~ ^0\.([0-9]+)$ ]]; then
    local frac="${BASH_REMATCH[1]}"
    if [ "${#frac}" -eq 1 ]; then
      echo "${frac}0"
    else
      local pct="${frac:0:2}"
      # Strip leading zero if it starts with 0 and is not just "0"
      if [[ "$pct" =~ ^0[1-9]$ ]]; then
        pct="${pct#0}"
      elif [ "$pct" = "00" ]; then
        pct="0"
      fi
      echo "$pct"
    fi
    return
  fi
  
  echo "-1"
}

format_quota() {
  local mode=$1
  local pct
  pct=$(float_to_pct "$QUOTA_5H_FRAC")
  
  if [ "$pct" = "-1" ]; then
    echo ""
    return
  fi
  
  local q_reset
  q_reset=$(fmt_seconds "$QUOTA_5H_RESET")
  
  if [ "$mode" = "narrow" ]; then
    echo -e "${FG_CYAN}${ICON_UNKNOWN} ${NUM_COLOR}${pct}%${R} ${FG_GRAY}${q_reset}${R}"
    return
  fi
  
  local len=10
  if [ "$mode" = "med" ]; then
    len=6
  fi
  
  local filled=$((pct * len / 100))
  local remainder=$(( (pct * len) % 100 ))
  
  local q_color
  if [ "$pct" -le 10 ]; then
    q_color="$FG_BRIGHT_RED"
  elif [ "$pct" -le 40 ]; then
    q_color="$FG_BRIGHT_CYAN"
  else
    q_color="$FG_CYAN"
  fi
  
  local bar=""
  local i
  for ((i = 0; i < len; i++)); do
    if [ "$i" -lt "$filled" ]; then
      bar="${bar}${q_color}█${R}"
    elif [ "$i" -eq "$filled" ]; then
      if [ "$remainder" -ge 75 ]; then bar="${bar}${q_color}▓${R}${FG_GRAY}"
      elif [ "$remainder" -ge 50 ]; then bar="${bar}${q_color}▒${R}${FG_GRAY}"
      else                               bar="${bar}${q_color}░${R}${FG_GRAY}"
      fi
    else
      bar="${bar}${FG_GRAY}░${R}"
    fi
  done
  
  echo -e "${FG_CYAN}${ICON_UNKNOWN}  ${R}${bar} ${NUM_COLOR}${pct}%${R} ${FG_GRAY}${q_reset}${R}"
}

INPUT_TOK_FMT=$(human_format "$INPUT_TOKENS")
OUTPUT_TOK_FMT=$(human_format "$OUTPUT_TOKENS")
CTX_LIMIT_FMT=$(human_format "$CTX_LIMIT")
CTX_USED_FMT=$(human_format "$CTX_USED")


# Width adjustment for Nerd Font icons (0 for single-width terminals, 1 for double-width)
ICON_WIDTH_ADJUST=${ICON_WIDTH_ADJUST:-0}

# ─── Strip ANSI escapes to measure visible length ────────────────────────────
visible_len() {
  # Strips ESC sequences and counts remaining characters
  local clean_str
  clean_str=$(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')
  
  local base_len=${#clean_str}
  
  # Count occurrences of Nerd Font icons or emojis
  local only_icons="${clean_str//[^󰟷󰒙󰴴󰦜󱍏󱙺󰍪🟢💭⚙⚒⏳📁💡⎇💬📦🔒🚫📊📄🤖📋🪙]/}"
  local icon_count=${#only_icons}
  
  echo $((base_len + icon_count * ICON_WIDTH_ADJUST))
}


# ─── State Indicator ─────────────────────────────────────────────────────────
case "$STATE" in
  idle)     S="${FG_BRIGHT_GREEN}${B}${ICON_READY} READY${R}" ;;
  thinking) S="${FG_BRIGHT_YELLOW}${B}${ICON_THINKING} THINKING${R}" ;;
  working)  S="${FG_BRIGHT_CYAN}${B}${ICON_WORKING} WORKING${R}" ;;
  tool_use) S="${FG_BRIGHT_MAGENTA}${B}${ICON_TOOL} TOOL${R}" ;;
  *)        S="${FG_WHITE}${B}${ICON_UNKNOWN} $(echo "$STATE" | tr '[:lower:]' '[:upper:]')${R}" ;;
esac


# ─── Dynamic Component Helpers ───────────────────────────────────────────────

shorten_path() {
  local path=$1
  local max_len=$2
  if [ -z "$path" ]; then
    echo ""
    return
  fi
  path="${path/#$HOME/\~}"
  if [ "$max_len" -eq 0 ]; then
    if [ "$path" = "~" ]; then
      echo "~"
    else
      basename "$path"
    fi
  elif [ "${#path}" -gt "$max_len" ]; then
    echo "...$(basename "$path")"
  else
    echo "$path"
  fi
}

format_branch() {
  local max_len=$1
  if [ -z "$VCS_BRANCH" ]; then
    echo ""
    return
  fi
  local name="$VCS_BRANCH"
  if [ "$max_len" -gt 0 ] && [ "${#name}" -gt "$max_len" ]; then
    name="${name:0:$max_len}.."
  fi
  if [ "$VCS_DIRTY" = "true" ]; then
    echo -e "${FG_BRIGHT_RED}${ICON_BRANCH} ${name}${FG_BRIGHT_YELLOW}*${R}"
  else
    echo -e "${FG_BRIGHT_BLUE}${ICON_BRANCH} ${name}${R}"
  fi
}

format_sandbox() {
  local mode=$1
  # ─── Sandbox State (workaround for unpopulated payload field) ────────────────
  # As of agy 1.0.6, `agy --sandbox` enables the terminal sandbox but does NOT set
  # .sandbox.enabled in the statusLine payload (it stays false), so the badge below
  # would always read "off". The flag is also not exported to this process's env,
  # and the process is reparented to init, so neither env nor the parent command
  # line can be inspected. The only reliable signal is the session log, which
  # cli.log symlinks to ("--sandbox: enabling terminal sandbox for this session").
  # .sandbox.enabled remains the primary source, so this self-corrects once the
  # payload field is populated upstream. See issue #321.
  if [ "$SANDBOX" != "true" ]; then
    if [ -r "$SANDBOX_LOG" ] && grep -q 'enabling terminal sandbox' "$SANDBOX_LOG" 2>/dev/null; then
      SANDBOX="true"
    fi
  fi

 if [ "$SANDBOX" = "true" ]; then
    local icon="$ICON_SB_NET"
    [ "$SANDBOX_NET" = "false" ] && icon="$ICON_SB_NONET"
    if [ "$mode" = "wide" ]; then
      local label="ON (net)"
      [ "$SANDBOX_NET" = "false" ] && label="ON (no-net)"
      echo -e "${FG_GREEN}${icon} ${FG_BRIGHT_GREEN}${B}${label}${R}"
    elif [ "$mode" = "med" ]; then
      echo -e "${FG_GREEN}${icon} ${FG_BRIGHT_GREEN}${B}ON${R}"
    else
      echo -e "${FG_GREEN}${icon}${R}"
    fi
  else
    if [ "$mode" = "wide" ] || [ "$mode" = "med" ]; then
      echo -e "${FG_RED}${ICON_SB_OFF} ${FG_BRIGHT_RED}${B}OFF${R}"
    else
      echo -e "${FG_RED}${ICON_SB_OFF}${R}"
    fi
  fi
}

make_bar() {
  local len=$1
  local filled=$((PCT_INT * len / 100))
  local remainder=$(( (PCT_INT * len) % 100 ))
  local bar=""
  local i
  for ((i = 0; i < len; i++)); do
    if [ "$i" -lt "$filled" ]; then
      bar="${bar}${FILL_COLOR}█${R}"
    elif [ "$i" -eq "$filled" ]; then
      if [ "$remainder" -ge 75 ]; then bar="${bar}${FILL_COLOR}▓${R}${FG_GRAY}"
      elif [ "$remainder" -ge 50 ]; then bar="${bar}${FILL_COLOR}▒${R}${FG_GRAY}"
      else                               bar="${bar}${FILL_COLOR}░${R}${FG_GRAY}"
      fi
    else
      bar="${bar}${FG_GRAY}░${R}"
    fi
  done
  echo -e "$bar"
}

join_with_dot() {
  local result=""
  local item
  for item in "$@"; do
    if [ -n "$item" ]; then
      if [ -z "$result" ] || [ "$result" = "$R" ]; then
        result="$item"
      else
        result="${result}${DOT}${item}"
      fi
    fi
  done
  echo -e "$result"
}

join_with_space() {
  local result=""
  local item
  for item in "$@"; do
    if [ -n "$item" ]; then
      if [ -z "$result" ]; then
        result="$item"
      else
        result="${result}  ${item}"
      fi
    fi
  done
  echo -e "$result"
}


# ─── Define Component Variants ───────────────────────────────────────────────

# --- CWD Path Variants ---
CWD_WIDE_VAL=$(shorten_path "$CWD" 25)
DIR_WIDE=""
[ -n "$CWD_WIDE_VAL" ] && DIR_WIDE="${FG_CYAN}${ICON_FOLDER} ${R}${CWD_WIDE_VAL}${R}"

CWD_MED_VAL=$(shorten_path "$CWD" 15)
DIR_MED=""
[ -n "$CWD_MED_VAL" ] && DIR_MED="${FG_CYAN}${ICON_FOLDER} ${R}${CWD_MED_VAL}${R}"

CWD_NARROW_VAL=$(shorten_path "$CWD" 0)
DIR_NARROW=""
[ -n "$CWD_NARROW_VAL" ] && DIR_NARROW="${FG_CYAN}${ICON_FOLDER} ${R}${CWD_NARROW_VAL}${R}"


# --- Model Name Variants ---
MODEL_RAW="${MODEL_NAME:-$MODEL_ID}"
MODEL_CLEAN=$(echo "$MODEL_RAW" | sed -E 's/^Gemini //; s/ \([^)]+\)//' || echo "")

M_WIDE=""
[ -n "$MODEL_RAW" ] && M_WIDE="${FG_BRIGHT_MAGENTA}${I}${ICON_MODEL} ${MODEL_RAW}${R}"

M_MED=""
[ -n "$MODEL_CLEAN" ] && M_MED="${FG_BRIGHT_MAGENTA}${I}${ICON_MODEL} ${MODEL_CLEAN}${R}"

M_NARROW=""
[ -n "$MODEL_CLEAN" ] && M_NARROW="${FG_BRIGHT_MAGENTA}${I}${ICON_MODEL} ${MODEL_CLEAN:0:10}${R}"


# --- VCS Branch Variants ---
V_WIDE=$(format_branch 15)
V_MED=$(format_branch 10)
V_NARROW=$(format_branch 6)


# --- Conversation ID Variants ---
CONV_WIDE=""
[ -n "$CONV_ID" ] && CONV_WIDE="${FG_GRAY}${ICON_CONV} ${CONV_ID:0:8}${R}"

CONV_MED=""
[ -n "$CONV_ID" ] && CONV_MED="${FG_GRAY}${ICON_CONV} ${CONV_ID:0:4}${R}"

CONV_NARROW="" # Omitted in narrow layout


# --- Sandbox Badge Variants ---
SB_WIDE=$(format_sandbox "wide")
SB_MED=$(format_sandbox "med")
SB_NARROW=$(format_sandbox "narrow")


# --- Context Bar & Token Variants ---
BAR_WIDE=$(make_bar 15)
BAR_MED=$(make_bar 10)
BAR_NARROW=$(make_bar 6)

CTX_BAR_WIDE="${FG_YELLOW}${ICON_CTX}  ${R}${BAR_WIDE} ${NUM_COLOR}${PCT_FMT}%${R}"
CTX_BAR_MED="${FG_YELLOW}${ICON_CTX}  ${R}${BAR_MED} ${NUM_COLOR}${PCT_FMT}%${R}"
CTX_BAR_NARROW="${FG_YELLOW}${ICON_CTX}  ${R}${BAR_NARROW} ${NUM_COLOR}${PCT_INT}%${R}"

# Tokens wide
TOK_DETAILS_WIDE=""
if [ "$CTX_USED" -gt 0 ] 2>/dev/null; then
  TOK_DETAILS_WIDE=" (${CTX_USED_FMT}/${CTX_LIMIT_FMT})${DOT}${FG_YELLOW}${ICON_TOK} ${R} (${INPUT_TOK_FMT} in/${OUTPUT_TOK_FMT} out)"
fi

# Tokens med
TOK_DETAILS_MED=""
if [ "$CTX_USED" -gt 0 ] 2>/dev/null; then
  TOK_DETAILS_MED=" (${CTX_USED_FMT}/${CTX_LIMIT_FMT})"
fi

# Tokens narrow (omitted)
TOK_DETAILS_NARROW=""


# --- Number Indicators Variants ---
ART_WIDE="${FG_BLUE}${ICON_ART} ${NUM_COLOR}${ARTIFACTS}${R}"
SUB_WIDE="${FG_CYAN}${ICON_SUB} ${NUM_COLOR}${SUBAGENTS}${R}"
BG_WIDE="${FG_MAGENTA}${ICON_BG} ${NUM_COLOR}${BG_TASKS}${R}"

ART_MED="${FG_BLUE}${ICON_ART} ${NUM_COLOR}${ARTIFACTS}${R}"
SUB_MED="${FG_CYAN}${ICON_SUB} ${NUM_COLOR}${SUBAGENTS}${R}"
BG_MED="${FG_MAGENTA}${ICON_BG} ${NUM_COLOR}${BG_TASKS}${R}"

ART_NARROW="${FG_BLUE}${ICON_ART}${NUM_COLOR}${ARTIFACTS}${R}"
SUB_NARROW="${FG_CYAN}${ICON_SUB}${NUM_COLOR}${SUBAGENTS}${R}"
BG_NARROW="${FG_MAGENTA}${ICON_BG}${NUM_COLOR}${BG_TASKS}${R}"


# --- Quota Indicator Variants ---
QUOTA_WIDE=$(format_quota "wide")
QUOTA_MED=$(format_quota "med")
QUOTA_NARROW=$(format_quota "narrow")


# --- Assemble Single Row Layouts ---
LINE1_WIDE=$(join_with_dot "$S" "$M_WIDE" "$DIR_WIDE" "$V_WIDE" "$CONV_WIDE")
LINE2_WIDE=$(join_with_dot "$ART_WIDE" "$SUB_WIDE" "$BG_WIDE" "$SB_WIDE" "${CTX_BAR_WIDE}${TOK_DETAILS_WIDE}" "$QUOTA_WIDE")

LINE1_MED=$(join_with_dot "$S" "$M_MED" "$DIR_MED" "$V_MED")
LINE2_MED=$(join_with_dot "$ART_MED" "$SUB_MED" "$BG_MED" "$SB_MED" "${CTX_BAR_MED}${TOK_DETAILS_MED}" "$QUOTA_MED")


# ─── Right-align helper ──────────────────────────────────────────────────────
# Prints LINE1 left-aligned and LINE2 right-aligned on the same terminal row.
print_right_aligned() {
  local left="$1"
  local right="$2"
  local total_cols="$3"

  local left_vis right_vis pad
  left_vis=$(visible_len "$left")
  right_vis=$(visible_len "$right")

  # How many spaces needed between left and right
  pad=$(( total_cols - left_vis - right_vis ))
  [ "$pad" -lt 1 ] && pad=1

  printf "%b%*s%b\n" "$left" "$pad" "" "$right"
}


# ─── Output Assembly ─────────────────────────────────────────────────────────
# Ensure COLS is a valid integer, fallback to 80
if ! [[ "$COLS" =~ ^[0-9]+$ ]] 2>/dev/null; then
  COLS=80
fi

# Safety margin to prevent automatic terminal wrapping (8 columns)
MARGIN=8

LEN1_WIDE=$(visible_len "$LINE1_WIDE")
LEN2_WIDE=$(visible_len "$LINE2_WIDE")

LEN1_MED=$(visible_len "$LINE1_MED")
LEN2_MED=$(visible_len "$LINE2_MED")

if [ "$COLS" -ge 135 ] && [ "$COLS" -ge $((LEN1_WIDE + LEN2_WIDE + MARGIN)) ]; then
  # 1. Single-row Wide Layout (with full details)
  print_right_aligned "$LINE1_WIDE" "$LINE2_WIDE" "$COLS"

elif [ "$COLS" -ge 100 ]; then
  # 2. Double-Row Parallel Wide Layout: left parts left-aligned, right parts right-aligned (full details)
  R1_LEFT=$(join_with_dot "$S" "$M_WIDE")
  R1_RIGHT=$(join_with_dot "$ART_WIDE" "$SUB_WIDE" "$BG_WIDE" "$SB_WIDE")
  R2_LEFT=$(join_with_dot "$DIR_WIDE" "$V_WIDE" "$CONV_WIDE")
  R2_RIGHT=$(join_with_dot "${CTX_BAR_WIDE}${TOK_DETAILS_WIDE}" "$QUOTA_WIDE")

  print_right_aligned "$R1_LEFT" "$R1_RIGHT" "$COLS"
  print_right_aligned "$R2_LEFT" "$R2_RIGHT" "$COLS"

elif [ "$COLS" -ge 75 ]; then
  # 3. Double-Row Parallel Medium Layout: left parts left-aligned, right parts right-aligned (compact details)
  R1_LEFT=$(join_with_dot "$S" "$M_MED")
  R1_RIGHT=$(join_with_dot "$ART_MED" "$SUB_MED" "$BG_MED" "$SB_MED")
  R2_LEFT=$(join_with_dot "$DIR_MED" "$V_MED" "$CONV_MED")
  R2_RIGHT=$(join_with_dot "${CTX_BAR_MED}${TOK_DETAILS_MED}" "$QUOTA_MED")

  print_right_aligned "$R1_LEFT" "$R1_RIGHT" "$COLS"
  print_right_aligned "$R2_LEFT" "$R2_RIGHT" "$COLS"

elif [ "$COLS" -ge 50 ]; then
  # 4. Double-Row Parallel Narrow Layout: left parts left-aligned, right parts right-aligned (highly compact details)
  R1_LEFT=$(join_with_dot "$S" "$M_NARROW")
  R1_RIGHT=$(join_with_space "$ART_NARROW" "$SUB_NARROW" "$BG_NARROW" "$SB_NARROW")
  R2_LEFT=$(join_with_dot "$DIR_NARROW" "$V_NARROW")
  R2_RIGHT=$(join_with_dot "${CTX_BAR_NARROW}" "$QUOTA_NARROW")

  print_right_aligned "$R1_LEFT" "$R1_RIGHT" "$COLS"
  print_right_aligned "$R2_LEFT" "$R2_RIGHT" "$COLS"

else
  # 5. Extreme Fallback: Extremely compact minimalist fallback (no wrapping, fits anywhere)
  M_SHORT=""
  if [ -n "$MODEL_CLEAN" ]; then
    M_SHORT="${FG_GRAY} ╱ ${FG_BRIGHT_MAGENTA}${MODEL_CLEAN:0:8}${R}"
  fi

  echo -e "${S}${M_SHORT}"
  echo -e "${CTX_BAR_NARROW}"
fi
