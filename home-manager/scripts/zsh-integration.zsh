# Interactive Zsh helpers sourced by home-manager/modules/zsh.nix.

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

  [ -r "$uv_completion_cache" ] && source "$uv_completion_cache"
  unset uv_completion_cache uv_completion_meta uv_path uv_meta
fi

function tm() {
  tmux attach-session -t main 2>/dev/null || tmux new-session -s main herdr
}

function main() {
  tm "$@"
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
  local conversations_dir="$HOME/.gemini/antigravity-cli/conversations"
  local brain_dir="$HOME/.gemini/antigravity-cli/brain"
  local show_all=false

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

  local selected
  selected=$(
    for db_path in "$conversations_dir"/*.db; do
      [ -f "$db_path" ] || continue
      local uuid
      uuid=$(basename "$db_path" .db)

      # Extract CWD from sqlite db
      local session_cwd=""
      session_cwd=$(sqlite3 "$db_path" "select data from trajectory_metadata_blob;" 2>/dev/null | grep -oaE 'file:///[a-zA-Z0-9_/.-]+' | head -n 1 | sed 's/file:\/\///' || true)

      # Filter by current directory unless show_all is true
      if [ "$show_all" = "false" ] && [ "$session_cwd" != "$PWD" ]; then
        continue
      fi

      local transcript="$brain_dir/$uuid/.system_generated/logs/transcript.jsonl"
      local preview=""
      if [ -f "$transcript" ] && command -v jq >/dev/null 2>&1; then
        preview=$(jq -r 'select(.type == "USER_INPUT") | .content' "$transcript" 2>/dev/null | grep -v 'USER_REQUEST' | grep -v 'ADDITIONAL_METADATA' | grep -v 'USER_SETTINGS_CHANGE' | grep -v '^$' | head -n 1)
      fi
      local mtime
      mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$db_path")

      if [ "$show_all" = "true" ] && [ -n "$session_cwd" ]; then
        local short_cwd="${session_cwd/#$HOME/\~}"
        printf "%s | %-30s | %-50s | %s\n" "$mtime" "$short_cwd" "${preview:-(No preview available)}" "$uuid"
      else
        printf "%s | %-50s | %s\n" "$mtime" "${preview:-(No preview available)}" "$uuid"
      fi
    done |
    sort -r |
    fzf --header="Select Antigravity conversation to resume (use --all to show all)"
  )

  if [ -n "$selected" ]; then
    local uuid
    uuid=$(echo "$selected" | awk -F ' | ' '{print $NF}' | tr -d ' ')
    agy --conversation "$uuid"
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
      # Fallback to the first word if no UUID is found
      opencode -s "$(echo "$selected" | awk '{print $1}')"
    fi
  fi
}
