# home-manager/git.nix
#
# Git Configuration and Helper Functions
#
# Purpose:
# - Provides Git utility functions for shell use
# - Extends Git functionality with custom commands
# - Integrates with other Git tools (LazyGit, GitHub CLI)
#
# Functions:
# - gitdefaultbranch: 
#   - Gets the default branch (main/master) from remote
#   - Used for branch synchronization
#   - Handles different default branch names
#
# Integration:
# - Works with LazyGit configuration (lazygit.nix)
# - Supports aliases defined in aliases.nix
# - Used by ZSH git plugins (zsh.nix)
#
# Note:
# - Git package is installed via Homebrew (homebrew.nix)
# - Additional Git configurations may be in GitHub module

{
  programs.zsh.initExtra = ''
    # Get the default branch name from remote
    # Usage: gitdefaultbranch
    # Returns: The name of the default branch (e.g., main, master)
    function gitdefaultbranch() {
      git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
    }
    # ... other git functions ...
  '';
}
