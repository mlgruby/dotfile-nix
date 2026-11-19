# Herdr.app tab spinner for shell commands.
#
# herdr-core shows a spinner on a tab while its terminal reports the OSC 7501
# state "working", and clears that state when the shell is in the foreground
# again. preexec reports "working" when a command runs for HC_BUSY_DELAY
# seconds (default 2), so short commands do not show in Agents. precmd stops
# the timer. Full-screen programs and agents (they report their own state)
# are skipped.

[[ -n ${HC_TERMINAL_ID:-} && -o interactive ]] || return 0
zmodload zsh/zselect 2>/dev/null || return 0

typeset -g _hc_busy_pid=
typeset -ga HC_BUSY_SKIP=(
  vi vim nvim nano emacs less more man bat htop top btop k9s
  ssh mosh lazygit lg tig gitui fzf yazi tmux hc watch
  claude codex agy ag agc agr cc cx
)

_hc_busy_preexec() {
  local -a words=(${(z)1})
  # Skip leading VAR=value words and "command", "builtin", "noglob", "sudo".
  while [[ ${words[1]} == *=* || ${words[1]} == (command|builtin|noglob|sudo|exec|time) ]]; do
    shift words
  done
  (( ${#words} )) || return 0
  (( ${HC_BUSY_SKIP[(Ie)${words[1]:t}]} )) && return 0
  (
    zselect -t $(( ${HC_BUSY_DELAY:-2} * 100 ))
    printf '\e]7501;state=working:app=shell\a' >/dev/tty
  ) 2>/dev/null &!
  _hc_busy_pid=$!
}

_hc_busy_precmd() {
  [[ -n $_hc_busy_pid ]] && kill $_hc_busy_pid 2>/dev/null
  _hc_busy_pid=
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _hc_busy_preexec
add-zsh-hook precmd _hc_busy_precmd
