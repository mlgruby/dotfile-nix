# Interactive Zsh helpers for Dev Container shell environment

# Ensure SSH agent forwarding works correctly on macOS host/Linux guest
if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
  # Look for forwarded ssh agent socket in typical devcontainer mounts
  for sock in $(find /tmp -type s -path "/tmp/ssh-*/agent.*" 2>/dev/null); do
    if [ -S "$sock" ]; then
      export SSH_AUTH_SOCK="$sock"
      break
    fi
  done
fi

# uv completions. Cache generated completions for faster shell startup
if command -v uv > /dev/null 2>&1; then
  uv_completion_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/uv-completion.zsh"
  uv_completion_meta="${uv_completion_meta:-$uv_completion_cache.meta}"
  uv_path="$(command -v uv)"
  uv_meta="$uv_path:$(uv --version 2>/dev/null)"

  if [ ! -r "$uv_completion_cache" ] || [ "$(cat "$uv_completion_meta" 2>/dev/null)" != "$uv_meta" ]; then
    mkdir -p "$(dirname "$uv_completion_cache")"
    uv generate-shell-completion zsh > "$uv_completion_cache" 2>/dev/null &&
      printf '%s\n' "$uv_meta" > "$uv_completion_meta"
  fi

  [ -r "$uv_completion_cache" ] && source "$uv_completion_cache"
  unset uv_completion_cache uv_completion_meta uv_path uv_meta
fi

# FZF Interactive Git functions (Fuzzy branch/log/status navigation)
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
      [[ "$path" == *" -> *" ]] && path="${path##* -> }"
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

# Keybindings matching standard terminal setup
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

# Archive extraction utility
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

# Zsh startup time profiler
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

# Git default branch checker
function gitdefaultbranch() {
  git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
}

# GitHub PR interactive wrappers
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
