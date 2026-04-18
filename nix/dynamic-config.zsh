# nix/dynamic-config.zsh
#
# Minimal bootstrap helpers for the first terminal sessions before Home Manager
# has activated. The full shell environment lives in home-manager/modules/zsh.nix
# and home-manager/scripts/zsh-integration.zsh.

# FZF-enhanced history search. Only bind when running interactively with ZLE.
if [[ -o interactive ]] && command -v fzf >/dev/null 2>&1; then
  fzf-z-search() {
    local selected
    selected=$(history -n 1 | fzf)
    if [ -n "$selected" ]; then
      BUFFER+="$selected"
      zle accept-line
    fi
  }
  zle -N fzf-z-search
  bindkey '^s' fzf-z-search
fi

# Lightweight git helper kept for bootstrap compatibility.
gitcurrentbranch() {
  git symbolic-ref --short HEAD 2>/dev/null | tr -d "\n"
}
