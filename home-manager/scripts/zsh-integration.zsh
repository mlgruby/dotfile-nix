# Interactive Zsh helpers sourced by home-manager/modules/zsh.nix.
setopt interactive_comments auto_cd auto_pushd pushd_ignore_dups pushd_silent

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
  local current_profile="${AWS_PROFILE:-}"
  if [ "${_DOTFILES_LAST_SYNCED_AWS_PROFILE-__UNSET__}" = "$current_profile" ]; then
    return 0
  fi
  command -v tmux > /dev/null 2>&1 || return 0

  if [ -n "$current_profile" ]; then
    tmux set-environment -g AWS_PROFILE "$current_profile" 2>/dev/null || true
  else
    tmux set-environment -gu AWS_PROFILE 2>/dev/null || true
  fi
  _DOTFILES_LAST_SYNCED_AWS_PROFILE="$current_profile"
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
        --preview 'path=$(printf "%s\n" {} | sed "s/^...//; s/.* -> //")
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

# History search by typed prefix (falls back to normal history if prompt is empty)
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^P' up-line-or-beginning-search
bindkey '^N' down-line-or-beginning-search

# Edit current command line in full $EDITOR (Neovim) with Ctrl+X Ctrl+E
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Sub-word / Path-aware navigation and deletion
# Pressing Ctrl+W or Alt+Backspace deletes one path segment (e.g. `file` in `/path/to/file`) instead of the whole path
autoload -U select-word-style
select-word-style bash

# macOS & Linux terminal word navigation (Option+Left / Option+Right across Ghostty, Alacritty, iTerm2, macOS Terminal)
bindkey "^[f" forward-word
bindkey "^[b" backward-word
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[[3;5~" kill-word
bindkey "^H" backward-kill-word
bindkey "^U" backward-kill-line
bindkey "^W" backward-kill-word
bindkey "^[^?" backward-kill-word
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey -s '^_' 'zed $(fzf)^M'
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
  git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' ||
    git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
}

function ghprs-state() { gh pr list --state "$1" --limit 1000 | fzf; }
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

      session_cwd="$(herdr-project-layout --agy-cwd "$db_path" 2>/dev/null || true)"

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

# Herdr Workspace launcher:
# Keep p as a stable shim. The external launcher updates with the Nix profile,
# including in shells that were already open during a rebuild.
function p() {
  command herdr-project-open "$@"
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



# Agent startup is deferred until the first prompt, after all shell setup and
# aliases have loaded. Consume the marker before starting any child process.
function _dotfiles_herdr_project_agent() {
  add-zsh-hook -d precmd _dotfiles_herdr_project_agent
  local project_agent="${DOTFILES_HERDR_PROJECT_AGENT:-}"
  unset DOTFILES_HERDR_PROJECT_AGENT
  case "$project_agent" in
    # These names are allowlisted. eval resolves aliases defined later in .zshrc.
    cc|ccr|agr|cxr|hpr-view|hpr-ci|hpr-ai-review) eval "$project_agent" ;;
  esac
}
if [[ "${HERDR_ENV:-}" == "1" && "${DOTFILES_HERDR_PROJECT_AGENT:-}" == (cc|ccr|agr|cxr|hpr-view|hpr-ci|hpr-ai-review) ]]; then
  add-zsh-hook precmd _dotfiles_herdr_project_agent
fi
