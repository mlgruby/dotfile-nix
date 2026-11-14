# Speed up shell startup by caching compdump definitions.
# Bare `compinit` audits every directory in fpath and regenerates the dump on
# every single shell startup, which adds 1.5s+ of latency.
# With `-C`, compinit loads the existing dump without the expensive audit.
# We re-audit at most once every 20 hours, or whenever the dump file is missing.

typeset -g _zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"

_dotfiles_refresh_zcompdump() {
  local zcompdump="$1"
  local homebrew_completion_dir="${DOTFILES_HOMEBREW_COMPLETION_DIR:-/opt/homebrew/share/zsh/site-functions}"
  local homebrew_completion_usable=1
  local completion_file

  if [[ -d "$homebrew_completion_dir" ]]; then
    for completion_file in "$homebrew_completion_dir"/_*(N); do
      if [[ -L "$completion_file" && ! -e "$completion_file" ]]; then
        command rm -f -- "$completion_file" 2>/dev/null || homebrew_completion_usable=0
      fi
    done

    # Preserve completion for the rest of the system when Homebrew's directory
    # cannot be repaired by the current user.
    if (( ! homebrew_completion_usable )); then
      fpath=("${(@)fpath:#$homebrew_completion_dir}")
    fi
  fi

  autoload -Uz compinit
  compinit -d "$zcompdump"
  # Clean up stale temporary files left behind by interrupted subshells
  command rm -f -- "${zcompdump}."*(N) 2>/dev/null
  # Compile to wordcode (.zwc) for instantaneous memory-mapped loading
  zcompile "$zcompdump" 2>/dev/null
}

setopt localoptions extendedglob
if [[ ! -s "$_zcompdump" ]]; then
  _dotfiles_refresh_zcompdump "$_zcompdump"
elif [[ -n "$_zcompdump"(#qN.mh+20) ]]; then
  # Load cached dump immediately (~13ms), then refresh & compile in background
  autoload -Uz compinit
  compinit -C -d "$_zcompdump"
  (_dotfiles_refresh_zcompdump "$_zcompdump" &) >/dev/null 2>&1
else
  autoload -Uz compinit
  compinit -C -d "$_zcompdump"
fi

unfunction _dotfiles_refresh_zcompdump 2>/dev/null || true
unset _zcompdump

