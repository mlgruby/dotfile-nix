# home-manager/modules/git.nix - Optimized Git Configuration
#
# Git Configuration and Aliases
#
# Purpose:
# - Sets up Git user identity
# - Configures Git defaults
# - Provides Git aliases
#
# Configuration:
# - User identity (name, email)
# - Default branch name
# - Pull/push behavior
# - Common aliases
#
# Integration:
# - Uses user settings from config
# - Works with shell aliases
#
# Note:
# - Identity from user-config
# - Additional aliases in aliases.nix
{...} @ args: let
  inherit (args) fullName email;
in {
  programs.git = {
    enable = true;

    # User Identity
    # Used for commit authorship
    userName = fullName;
    userEmail = email;

    # Git Core Configuration
    # Global settings for all repositories
    extraConfig = {
      # Branch Configuration
      init.defaultBranch = "develop"; # Default for new repositories
      # Pull/Push Behavior
      pull.rebase = true; # Avoid merge commits on pull
      push.autoSetupRemote = true; # Auto-configure upstream
      # Editor and File Handling
      core = {
        editor = "vim"; # Default editor for commits
        autocrlf = "input"; # Line ending management
      };
      # UI Configuration
      color.ui = true; # Colorized output
    };

    # Built-in Git Aliases
    # Shorter versions of common commands
    aliases = {
      st = "status"; # Quick status check
      ci = "commit"; # Shorter commit command
      br = "branch"; # Branch management
      co = "checkout"; # Branch switching
      df = "diff"; # Change viewing
    };

    # Global Ignores
    # Files to ignore in all repositories
    ignores = [
      ".DS_Store" # macOS metadata
      "*.swp" # Vim swap files
      ".env" # Environment variables
      ".direnv" # Direnv cache
      "node_modules" # Node.js dependencies
      ".vscode" # VS Code settings
      ".idea" # IntelliJ settings
    ];
  };

  # Shell Integration Aliases moved to aliases.nix
  # ZSH functions moved to zsh.nix
}
