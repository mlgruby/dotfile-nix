# Initialize Zsh completion without letting stale Homebrew links disable it.
# Casks can leave dangling completion symlinks behind when an app is removed
# outside Homebrew (for example, an organization-managed Docker uninstall).

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

autoload -U compinit
compinit
