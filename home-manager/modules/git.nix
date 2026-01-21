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
  inherit (args) fullName email signingKey;
in {
  programs.git = {
    enable = true;

    # Git Configuration using new settings structure
    # All configuration now under 'settings' namespace
    settings = {
      # User Identity
      user = {
        name = fullName;
        email = email;
      } // (if signingKey != "" then {
        signingkey = signingKey; # GPG key ID for signing commits
      } else {});

      # Built-in Git Aliases
      alias = {
        st = "status";   # Quick status check
        ci = "commit";   # Shorter commit command
        br = "branch";   # Branch management
        co = "checkout"; # Branch switching
        df = "diff";     # Change viewing
      };

      # Branch Configuration
      init.defaultBranch = "develop"; # Default for new repositories

      # Pull/Push Behavior
      pull.rebase = true;           # Avoid merge commits on pull
      push.autoSetupRemote = true;  # Auto-configure upstream

      # Editor and File Handling
      core = {
        editor = "vim";        # Default editor for commits
        autocrlf = "input";    # Line ending management
      };

      # UI Configuration
      color.ui = true; # Colorized output

      # GPG Configuration (only enabled if signingKey is set)
      gpg.program = "gpg";   # GPG program to use
    } // (if signingKey != "" then {
      commit.gpgsign = true; # Automatically sign commits
    } else {});

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
