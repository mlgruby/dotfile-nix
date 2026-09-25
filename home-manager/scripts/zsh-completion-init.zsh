# Speed up shell startup by caching compdump definitions.
# Bare `compinit` audits every directory in fpath and regenerates the dump on
# every single shell startup, which adds 1.5s+ of latency.
# With `-C`, compinit loads the existing dump without the expensive audit.
# We re-audit at most once every 20 hours, or whenever the dump file is missing.

typeset -g _zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"

setopt localoptions extendedglob
if [[ -n "$_zcompdump"(#qN.mh+20) || ! -s "$_zcompdump" ]]; then
  homebrew_completion_dir="${DOTFILES_HOMEBREW_COMPLETION_DIR:-/opt/homebrew/share/zsh/site-functions}"
  homebrew_completion_usable=1

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

  unset homebrew_completion_dir homebrew_completion_usable completion_file

  autoload -Uz compinit
  compinit -d "$_zcompdump"
  # Clean up stale temporary files left behind by interrupted subshells
  command rm -f -- "${_zcompdump}."*(N) 2>/dev/null
  # Compile to wordcode (.zwc) for instantaneous memory-mapped loading
  zcompile "$_zcompdump" 2>/dev/null
else
  autoload -Uz compinit
  compinit -C -d "$_zcompdump"
fi

unset _zcompdump

