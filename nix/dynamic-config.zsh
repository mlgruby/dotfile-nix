# Dynamic configurations and functions that are harder to manage in Nix

# FZF functions
fzf-z-search() {
  local res=$(history -n 1 | tail -f | fzf)
  if [ -n "$res" ]; then
      BUFFER+="$res"
      zle accept-line
  else
      return 0
  fi
}
zle -N fzf-z-search
bindkey '^s' fzf-z-search

select-history() {
  BUFFER=$(history -n -r 1 \
      | awk 'length($0) > 2' \
      | rg -v "^...$" \
      | rg -v "^....$" \
      | rg -v "^.....$" \
      | rg -v "^......$" \
      | rg -v "^exit$" \
      | uniq -u \
      | fzf-tmux --no-sort +m --query "$LBUFFER" --prompt="History > ")
  CURSOR=$#BUFFER
}
zle -N select-history
bindkey '^r' select-history

# Docker functions
function da() {
  local cid
  cid=$(docker ps -a | sed 1d | fzf -1 -q "$1" | awk '{print $1}')
  [ -n "$cid" ] && docker start "$cid" && docker attach "$cid"
}

function ds() {
  local cid
  cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')
  [ -n "$cid" ] && docker stop "$cid"
}

function drm() {
  local cid
  cid=$(docker ps -a | sed 1d | fzf -q "$1" | awk '{print $1}')
  [ -n "$cid" ] && docker rm "$cid"
}

# Git functions
function ghpr() {
  gh pr list --state "$1" --limit 1000 | fzf
}

# AWS credential management
function aws-switch() {
  osascript -e 'tell application "System Events" to keystroke "k" using command down'
  source "/opt/aws_cred_copy/copy_and_unset $1"
}

function gitdefaultbranch(){
  git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
}

function gitcurrentbranch() {
  git symbolic-ref --short HEAD | tr -d "\n"
}

# iTerm2 integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Local configurations that might change frequently
[[ -f "$HOME/.aws_cred" ]] && source "$HOME/.aws_cred"
