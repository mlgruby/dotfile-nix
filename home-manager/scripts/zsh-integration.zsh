# Interactive Zsh helpers sourced by home-manager/modules/zsh.nix.
setopt interactive_comments

# Match filesystem paths and command names regardless of letter case.
# For example, `cd wo<Tab>` completes a directory named `Work`.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Prefer Bitwarden SSH Agent when enabled. The Desktop app owns this socket, so
# fall back to macOS launchd ssh-agent if the vault is locked or the app is not running.
if [ "${DOTFILES_BITWARDEN_SSH_AGENT:-0}" = "1" ]; then
  bitwarden_ssh_sock="${BITWARDEN_SSH_AUTH_SOCK:-~/.bitwarden-ssh-agent.sock}"
  bitwarden_ssh_sock="${bitwarden_ssh_sock/#\~/$HOME}"
  if [ -n "$bitwarden_ssh_sock" ] && [ -S "$bitwarden_ssh_sock" ]; then
    export SSH_AUTH_SOCK="$bitwarden_ssh_sock"
  fi
  unset bitwarden_ssh_sock
fi

# Ensure shells use macOS launchd ssh-agent socket when Bitwarden is unavailable.
if [ -z "${SSH_AUTH_SOCK:-}" ] && command -v launchctl > /dev/null 2>&1; then
  launchd_ssh_sock="$(launchctl getenv SSH_AUTH_SOCK 2>/dev/null || true)"
  if [ -n "$launchd_ssh_sock" ] && [ -S "$launchd_ssh_sock" ]; then
    export SSH_AUTH_SOCK="$launchd_ssh_sock"
  fi
  unset launchd_ssh_sock
fi

# uv completions. Generating them dynamically is surprisingly expensive, so
# cache the generated file and source it on later shell starts.
if command -v uv > /dev/null 2>&1; then
  uv_completion_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/uv-completion.zsh"
  uv_completion_meta="${uv_completion_cache}.meta"
  uv_path="$(command -v uv)"
  uv_meta="$uv_path:$(uv --version 2>/dev/null)"

  if [ ! -r "$uv_completion_cache" ] || [ "$(cat "$uv_completion_meta" 2>/dev/null)" != "$uv_meta" ]; then
    mkdir -p "${uv_completion_cache:h}"
    uv generate-shell-completion zsh > "$uv_completion_cache" 2>/dev/null &&
      printf '%s\n' "$uv_meta" > "$uv_completion_meta"
  fi

  if (( $+functions[compdef] )) && [ -r "$uv_completion_cache" ]; then
    source "$uv_completion_cache"
  fi
  unset uv_completion_cache uv_completion_meta uv_path uv_meta
fi

function tm() {
  tmux attach-session -t main 2>/dev/null || tmux new-session -s main herdr
}

function main() {
  tm "$@"
}

# Claude Code launchers. Keep the dangerous permission bypass opt-in for every
# session, including resumed sessions, and default to the normal permission
# checks when stdin is not interactive.
function _claude_permission_args() {
  CLAUDE_PERMISSION_ARGS=()

  if [ ! -t 0 ] || [ ! -t 1 ]; then
    return 0
  fi

  local answer
  printf 'Run Claude with --dangerously-skip-permissions? [y/N] '
  read -r answer
  case "$answer" in
    y | Y | yes | YES)
      CLAUDE_PERMISSION_ARGS=(--dangerously-skip-permissions)
      ;;
  esac
}

function cc() {
  local -a CLAUDE_PERMISSION_ARGS
  _claude_permission_args
  command claude "${CLAUDE_PERMISSION_ARGS[@]}" "$@"
}

function ccr() {
  local -a CLAUDE_PERMISSION_ARGS
  _claude_permission_args
  command claude --resume "${CLAUDE_PERMISSION_ARGS[@]}" "$@"
}

# Antigravity launchers. Keep the dangerous permission bypass opt-in for every
# session, including resumed sessions, and default to the normal permission
# checks when stdin is not interactive.
function _agy_permission_args() {
  AGY_PERMISSION_ARGS=()

  if [ ! -t 0 ] || [ ! -t 1 ]; then
    return 0
  fi

  local answer
  printf 'Run Antigravity with --dangerously-skip-permissions? [y/N] '
  read -r answer
  case "$answer" in
    y | Y | yes | YES)
      AGY_PERMISSION_ARGS=(--dangerously-skip-permissions)
      ;;
  esac
}

function ag() {
  local -a AGY_PERMISSION_ARGS
  _agy_permission_args
  command agy "${AGY_PERMISSION_ARGS[@]}" "$@"
}

function agc() {
  local -a AGY_PERMISSION_ARGS
  _agy_permission_args
  command agy --continue "${AGY_PERMISSION_ARGS[@]}" "$@"
}

# Auto-attach only for terminals that explicitly opt in, such as Alacritty.
if [ "$DOTFILES_AUTO_TMUX" = "1" ] && command -v tmux > /dev/null 2>&1; then
  if [ -z "$TMUX" ]; then
    tm
  fi
fi

# Auto-launch Herdr only for terminals that explicitly opt in.
# Herdr can spawn child shells, so guard against recursively launching it again.
if [ "$DOTFILES_AUTO_HERDR" = "1" ] && command -v herdr > /dev/null 2>&1; then
  if [ -z "${DOTFILES_AUTO_HERDR_STARTED:-}" ]; then
    export DOTFILES_AUTO_HERDR_STARTED="1"
    herdr
  fi
fi

function dotfiles-sync-tmux-env() {
  [ -n "$TMUX" ] || return 0
  command -v tmux > /dev/null 2>&1 || return 0

  if [ -n "${AWS_PROFILE:-}" ]; then
    tmux set-environment -g AWS_PROFILE "$AWS_PROFILE" 2>/dev/null || true
  else
    tmux set-environment -gu AWS_PROFILE 2>/dev/null || true
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd dotfiles-sync-tmux-env

function bwp() {
  if ! command -v bw > /dev/null 2>&1; then
    echo "bw is required for bwp" >&2
    return 127
  fi
  if ! command -v jq > /dev/null 2>&1; then
    echo "jq is required for bwp" >&2
    return 127
  fi
  if ! command -v fzf > /dev/null 2>&1; then
    echo "fzf is required for bwp" >&2
    return 127
  fi
  if ! command -v pbcopy > /dev/null 2>&1; then
    echo "pbcopy is required for bwp" >&2
    return 127
  fi

  local bw_status selected item_id item_name password
  bw_status="$(bw status 2> /dev/null | jq -r '.status // "unknown"' 2> /dev/null)"
  if [ "$bw_status" != "unlocked" ]; then
    echo "Bitwarden vault is $bw_status. Run: bw unlock" >&2
    return 1
  fi

  selected="$(
    bw list items --search "${*:-}" 2> /dev/null |
      jq -r '.[] | select(.login.password != null and .login.password != "") |
        [
          .id,
          (.name // ""),
          (.login.username // ""),
          ((.login.uris // []) | map(.uri // "") | join(", "))
        ] | @tsv' |
      fzf --with-nth=2,3,4 --delimiter=$'\t' --header="Copy Bitwarden password"
  )"

  [ -n "$selected" ] || return 130

  item_id="$(printf '%s\n' "$selected" | cut -f1)"
  item_name="$(printf '%s\n' "$selected" | cut -f2)"
  password="$(bw get password "$item_id" 2> /dev/null)"

  if [ -z "$password" ]; then
    echo "No password found for selected item" >&2
    return 1
  fi

  printf '%s' "$password" | pbcopy
  unset password
  echo "Copied password for: $item_name"
}

function fzf-git-status() {
  local selections
  selections=$(
    git status --porcelain |
      fzf --ansi \
        --preview 'path=$(printf "%s\n" {q} | sed "s/^...//; s/.* -> //")
                  if [ -f "$path" ]; then
                    bat --color=always --style=numbers "$path"
                  elif [ -d "$path" ]; then
                    tree -C "$path"
                  fi' \
        --preview-window right:70% \
        --multi
  )
  if [ -n "$selections" ]; then
    local line path quoted_paths=""
    while IFS= read -r line; do
      path="${line:3}"
      [[ "$path" == *" -> "* ]] && path="${path##* -> }"
      quoted_paths+="${(q)path} "
    done <<< "$selections"
    LBUFFER+="$quoted_paths"
  fi
  zle reset-prompt
}
zle -N fzf-git-status

function fzf-cd-with-hidden() {
  local dir
  dir=$(find "${1:-$PWD}" -type d 2> /dev/null | fzf +m) && cd "$dir"
  zle reset-prompt
}
zle -N fzf-cd-with-hidden

autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "^[f" forward-word
bindkey "^[b" backward-word
bindkey "^[[3;5~" kill-word
bindkey "^H" backward-kill-word
bindkey "^U" backward-kill-line
bindkey "^[^?" backward-kill-word
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey -s '^_' 'code $(fzf)^M'
bindkey "^[d" fzf-cd-with-hidden
bindkey '^G' fzf-git-status

function extract() {
  if [ $# -eq 0 ]; then
    echo "Usage: extract <archive> [archive ...]" >&2
    return 1
  fi

  local archive
  for archive in "$@"; do
    if [ ! -f "$archive" ]; then
      echo "extract: not a file: $archive" >&2
      continue
    fi

    case "$archive" in
      *.tar.bz2 | *.tbz2) tar xjf "$archive" ;;
      *.tar.gz | *.tgz) tar xzf "$archive" ;;
      *.tar.xz | *.txz) tar xJf "$archive" ;;
      *.tar) tar xf "$archive" ;;
      *.bz2) bunzip2 "$archive" ;;
      *.gz) gunzip "$archive" ;;
      *.xz) unxz "$archive" ;;
      *.zip) unzip "$archive" ;;
      *.rar) unrar x "$archive" ;;
      *.7z) 7z x "$archive" ;;
      *) echo "extract: unsupported archive: $archive" >&2 ;;
    esac
  done
}

function zsh-startup-time() {
  local runs="${1:-5}"
  local total=0
  local elapsed

  for _ in $(seq 1 "$runs"); do
    elapsed=$({ time zsh -i -c exit >/dev/null; } 2>&1 | awk '/total/ { print $1 }' | sed 's/s$//')
    printf '%.3fs\n' "$elapsed"
    total=$(awk -v total="$total" -v elapsed="$elapsed" 'BEGIN { print total + elapsed }')
  done

  awk -v total="$total" -v runs="$runs" 'BEGIN { printf "avg %.3fs\n", total / runs }'
}

function gitdefaultbranch() {
  git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
}

function ghpr() { gh pr list --state "$1" --limit 1000 | fzf; }
function ghprall() { gh pr list --state all --limit 1000 | fzf; }
function ghpropen() { gh pr list --state open --limit 1000 | fzf; }
function ghopr() {
  local pr
  pr=$(gh pr list --state all --limit 1000 | fzf --preview 'echo {} | awk "{print \$1}" | xargs gh pr view') &&
    [ -n "$pr" ] && echo "$pr" | awk '{print $1}' | xargs gh pr view --web
}
function ghprco() {
  local pr
  pr=$(gh pr list --state open | fzf --preview 'echo {} | awk "{print \$1}" | xargs gh pr view') &&
    [ -n "$pr" ] && echo "$pr" | awk '{print $1}' | xargs gh pr checkout
}
function ghprcr() {
  gh pr create --web --fill
}
function ghprcheck() {
  local pr
  pr=$(gh pr list --state open | fzf) &&
    [ -n "$pr" ] && echo "$pr" | awk '{print $1}' | xargs gh pr checks
}

function agy-resume() {
  setopt local_options typesetsilent interactive_comments
  local conversations_dir="$HOME/.gemini/antigravity-cli/conversations"
  local brain_dir="$HOME/.gemini/antigravity-cli/brain"
  local show_all=false
  local arg selected uuid db_path transcript preview session_cwd mtime_epoch mtime_fmt clean_preview short_cwd

  for arg in "$@"; do
    if [ "$arg" = "-a" ] || [ "$arg" = "--all" ]; then
      show_all=true
    fi
  done

  if [ ! -d "$conversations_dir" ] || [ -z "$(ls -A "$conversations_dir"/*.db 2>/dev/null)" ]; then
    echo "No Antigravity conversations found." >&2
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is required to resume conversations interactively." >&2
    return 127
  fi

  selected=$(
    for db_path in "$conversations_dir"/*.db; do
      [ -f "$db_path" ] || continue
      uuid=$(basename "$db_path" .db)

      transcript="$brain_dir/$uuid/.system_generated/logs/transcript.jsonl"
      [ -f "$transcript" ] || continue

      preview=""
      if command -v jq >/dev/null 2>&1; then
        preview=$(jq -r 'select(.type == "USER_INPUT") | .content' "$transcript" 2>/dev/null | grep -v 'USER_REQUEST' | grep -v 'ADDITIONAL_METADATA' | grep -v 'USER_SETTINGS_CHANGE' | grep -v '^$' | head -n 1)
      fi
      [ -n "$preview" ] || continue

      session_cwd=$(sqlite3 "$db_path" "select data from trajectory_metadata_blob;" 2>/dev/null | grep -oaE 'file:///[a-zA-Z0-9_/.-]+' | head -n 1 | sed 's/file:\/\///' || true)

      if [ "$show_all" = "false" ] && [ "$session_cwd" != "$PWD" ]; then
        continue
      fi

      if stat --version >/dev/null 2>&1; then
        mtime_epoch=$(stat -c "%Y" "$db_path" 2>/dev/null || echo 0)
        mtime_fmt=$(stat -c "%y" "$db_path" 2>/dev/null | cut -c 1-16)
      else
        mtime_epoch=$(/usr/bin/stat -f "%m" "$db_path" 2>/dev/null || echo 0)
        mtime_fmt=$(/usr/bin/stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$db_path" 2>/dev/null || echo "Unknown")
      fi
      [ -n "$mtime_fmt" ] || mtime_fmt="Unknown"
      clean_preview=$(printf "%s" "$preview" | tr -d '\r\n' | tr '\t' ' ' | cut -c 1-80)

      if [ "$show_all" = "true" ] && [ -n "$session_cwd" ]; then
        short_cwd="${session_cwd/#$HOME/\~}"
        printf "%s\t%s | %-25s | %-60s | %s\n" "$mtime_epoch" "$mtime_fmt" "$short_cwd" "$clean_preview" "$uuid"
      else
        printf "%s\t%s | %-75s | %s\n" "$mtime_epoch" "$mtime_fmt" "$clean_preview" "$uuid"
      fi
    done |
    sort -k1,1nr |
    cut -f2- |
    fzf --no-sort --prompt="Resume Antigravity > " --header="Select conversation (use -a / --all to show all directories)"
  )

  if [ -n "$selected" ]; then
    uuid="${selected##*| }"
    uuid="${uuid## }"
    uuid="${uuid%% }"
    local -a AGY_PERMISSION_ARGS
    _agy_permission_args
    command agy --conversation "$uuid" "${AGY_PERMISSION_ARGS[@]}"
  fi
}

function opencode-resume() {
  if ! command -v opencode >/dev/null 2>&1; then
    echo "opencode CLI is not installed." >&2
    return 127
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf is required to resume sessions interactively." >&2
    return 127
  fi

  local selected
  selected=$(opencode session list | fzf --header="Select OpenCode session to resume")
  if [ -n "$selected" ]; then
    local uuid
    uuid=$(echo "$selected" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' | head -n 1)
    if [ -n "$uuid" ]; then
      opencode -s "$uuid"
    else
      opencode -s "$(echo "$selected" | awk '{print $1}')"
    fi
  fi
}

# Herdr Workspace launcher:
# Opens or creates a Herdr space for a project with an automatic split layout:
# - Left pane: Interactive shell
# - Right pane: Context-specific agent (Claude for Work, Codex or Antigravity for Personal)
function p() {
  if ! command -v herdr >/dev/null 2>&1; then
    echo "herdr CLI is not installed." >&2
    return 127
  fi

  local target_dir="$1"

  if [ -z "$target_dir" ]; then
    if command -v fzf >/dev/null 2>&1; then
      target_dir=$(
        {
          find "$HOME/Documents/Work" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's|^|Work: |'
          find "$HOME/Documents/Personal" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's|^|Personal: |'
          [ -d "$HOME/dotfile" ] && echo "Personal: $HOME/dotfile"
        } |
        fzf --prompt="Open Project in Herdr > " --header="Select project repository (Work or Personal)" |
        sed -E 's/^(Work|Personal): //'
      )
    else
      target_dir="$PWD"
    fi
  fi

  [ -z "$target_dir" ] && return 0

  local abs_path
  abs_path="$(cd "$target_dir" 2>/dev/null && pwd)"
  if [ -z "$abs_path" ] || [ ! -d "$abs_path" ]; then
    echo "Directory not found: $target_dir" >&2
    return 1
  fi

  local label
  label="$(basename "$abs_path")"

  # Create Herdr workspace (Tab 1 is created automatically)
  local ws_json
  ws_json="$(herdr workspace create --cwd "$abs_path" --label "$label")"
  local ws_id
  ws_id="$(echo "$ws_json" | jq -r '.result.workspace.workspace_id // empty')"
  local tab1_id
  tab1_id="$(echo "$ws_json" | jq -r '.result.tab.tab_id // empty')"

  # Tab 1: Always dev shell
  if [ -n "$tab1_id" ]; then
    herdr tab rename "$tab1_id" "dev" >/dev/null 2>&1
  fi

  if [[ "$abs_path" == *"/Documents/Work"* ]]; then
    # =========================================================================
    # WORK REPO LAYOUT (3 Tabs)
    # =========================================================================
    # Tab 2: Claude Code (resumes latest session)
    local tab2_json
    tab2_json="$(herdr tab create --workspace "$ws_id" --cwd "$abs_path" --label "cc" --focus)"
    local tab2_pane
    tab2_pane="$(echo "$tab2_json" | jq -r '.result.root_pane.pane_id // empty')"
    local tab2_id
    tab2_id="$(echo "$tab2_json" | jq -r '.result.tab.tab_id // empty')"
    if [ -n "$tab2_pane" ]; then
      herdr pane run "$tab2_pane" "claude --continue"

      # Check if an active open PR exists on this branch
      local has_pr
      has_pr="$(cd "$abs_path" && gh pr view --json number -q .number 2>/dev/null || true)"
      if [ -n "$has_pr" ]; then
        # Split right pane for GitHub PR Preview (status & live CI checks)
        herdr plugin pane open \
          --plugin "juninaba.herdr-pr-preview" \
          --entrypoint "preview" \
          --target-pane "$tab2_pane" \
          --placement split \
          --direction right \
          --no-focus \
          --env "HERDR_WORKSPACE_ID=$ws_id" \
          --env "HERDR_PR_STATUS_WORKTREE_PATH=$abs_path" >/dev/null 2>&1
      fi
      # Keep focus on Claude's input pane
      herdr pane focus "$tab2_pane" >/dev/null 2>&1
    fi

    # Tab 3: Lazygit
    local tab3_json
    tab3_json="$(herdr tab create --workspace "$ws_id" --cwd "$abs_path" --label "git" --no-focus)"
    local tab3_pane
    tab3_pane="$(echo "$tab3_json" | jq -r '.result.root_pane.pane_id // empty')"
    if [ -n "$tab3_pane" ]; then
      herdr pane run "$tab3_pane" "lazygit"
    fi

    # Focus Tab 2 (Claude Code) by default
    if [ -n "$tab2_id" ]; then
      herdr tab focus "$tab2_id" >/dev/null 2>&1
    fi

  else
    # =========================================================================
    # PERSONAL REPO LAYOUT (4 Tabs)
    # Tab 1: dev shell (already renamed above)
    # Tab 2: AGY (Antigravity session resume via agr)
    # Tab 3: CXR (Codex resume session)
    # Tab 4: lg (Lazygit)
    # =========================================================================

    # Check if an active open PR exists on this branch
    local has_pr
    has_pr="$(cd "$abs_path" && gh pr view --json number -q .number 2>/dev/null || true)"

    # Tab 2: Antigravity (AGY resume)
    local tab2_json
    tab2_json="$(herdr tab create --workspace "$ws_id" --cwd "$abs_path" --label "agy" --focus)"
    local tab2_pane
    tab2_pane="$(echo "$tab2_json" | jq -r '.result.root_pane.pane_id // empty')"
    local tab2_id
    tab2_id="$(echo "$tab2_json" | jq -r '.result.tab.tab_id // empty')"
    if [ -n "$tab2_pane" ]; then
      herdr pane run "$tab2_pane" "agr"

      if [ -n "$has_pr" ]; then
        herdr plugin pane open \
          --plugin "juninaba.herdr-pr-preview" \
          --entrypoint "preview" \
          --target-pane "$tab2_pane" \
          --placement split \
          --direction right \
          --no-focus \
          --env "HERDR_WORKSPACE_ID=$ws_id" \
          --env "HERDR_PR_STATUS_WORKTREE_PATH=$abs_path" >/dev/null 2>&1
      fi
      herdr pane focus "$tab2_pane" >/dev/null 2>&1
    fi

    # Tab 3: Codex (CXR)
    local tab3_json
    tab3_json="$(herdr tab create --workspace "$ws_id" --cwd "$abs_path" --label "cxr" --no-focus)"
    local tab3_pane
    tab3_pane="$(echo "$tab3_json" | jq -r '.result.root_pane.pane_id // empty')"
    if [ -n "$tab3_pane" ]; then
      herdr pane run "$tab3_pane" "cxr"

      if [ -n "$has_pr" ]; then
        herdr plugin pane open \
          --plugin "juninaba.herdr-pr-preview" \
          --entrypoint "preview" \
          --target-pane "$tab3_pane" \
          --placement split \
          --direction right \
          --no-focus \
          --env "HERDR_WORKSPACE_ID=$ws_id" \
          --env "HERDR_PR_STATUS_WORKTREE_PATH=$abs_path" >/dev/null 2>&1
      fi
      herdr pane focus "$tab3_pane" >/dev/null 2>&1
    fi

    # Tab 4: Lazygit (lg)
    local tab4_json
    tab4_json="$(herdr tab create --workspace "$ws_id" --cwd "$abs_path" --label "lg" --no-focus)"
    local tab4_pane
    tab4_pane="$(echo "$tab4_json" | jq -r '.result.root_pane.pane_id // empty')"
    if [ -n "$tab4_pane" ]; then
      herdr pane run "$tab4_pane" "lazygit"
    fi

    # Focus Tab 2 (Antigravity) by default
    if [ -n "$tab2_id" ]; then
      herdr tab focus "$tab2_id" >/dev/null 2>&1
    fi
  fi

  if [ -n "$ws_id" ]; then
    herdr workspace focus "$ws_id" >/dev/null 2>&1
  fi
}

# ==============================================================================
# Agent Ergonomics: Command Buffer & Re-run to Clipboard
# ==============================================================================

# Run any command, display output live on screen, and copy ANSI-stripped output to macOS clipboard.
function cb() {
  if [ $# -eq 0 ]; then
    echo "Usage: cb <command...>"
    return 1
  fi

  local tmpfile
  tmpfile="$(mktemp /tmp/cb_output.XXXXXX)"

  # Run command live and tee to temporary file
  "$@" 2>&1 | tee "$tmpfile"
  local exit_code="${pipestatus[1]:-${PIPESTATUS[0]:-0}}"

  # Strip ANSI color/escape sequences and copy clean text to clipboard
  sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$tmpfile" | pbcopy
  local lines
  lines="$(wc -l < "$tmpfile" | tr -d ' ')"
  rm -f "$tmpfile"

  echo "📋 Output copied to clipboard ($lines lines)"
  return "$exit_code"
}

# Re-run the last command from history, display live, and copy ANSI-stripped output to macOS clipboard.
function rc() {
  local last_cmd
  # Look backwards in history for the last command that wasn't rc, r, or rl
  local i=1
  while [ $i -le 10 ]; do
    last_cmd="$(fc -ln -$i -$i 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [ -n "$last_cmd" ] && [ "$last_cmd" != "rc" ] && [ "$last_cmd" != "r" ] && [ "$last_cmd" != "rl" ] && [ "$last_cmd" != "r && rl" ]; then
      break
    fi
    i=$((i + 1))
  done

  if [ -z "$last_cmd" ]; then
    echo "No previous command to re-run."
    return 1
  fi

  echo "➜ Re-running: $last_cmd"

  local tmpfile
  tmpfile="$(mktemp /tmp/rc_output.XXXXXX)"

  eval "$last_cmd" 2>&1 | tee "$tmpfile"
  local exit_code="${pipestatus[1]:-${PIPESTATUS[0]:-0}}"

  sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$tmpfile" | pbcopy
  local lines
  lines="$(wc -l < "$tmpfile" | tr -d ' ')"
  rm -f "$tmpfile"

  echo "📋 Output copied to clipboard ($lines lines)"
  return "$exit_code"
}

