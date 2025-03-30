# home-manager/modules/git.nix
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

{ config, pkgs, lib, ... }@args: let
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
      init.defaultBranch = "develop";    # Default for new repositories
      # Pull/Push Behavior
      pull.rebase = true;                # Avoid merge commits on pull
      push.autoSetupRemote = true;       # Auto-configure upstream
      # Editor and File Handling
      core = {
        editor = "vim";                  # Default editor for commits
        autocrlf = "input";              # Line ending management
      };
      # UI Configuration
      color.ui = true;                   # Colorized output
    };

    # Built-in Git Aliases
    # Shorter versions of common commands
    aliases = {
      st = "status";                     # Quick status check
      ci = "commit";                     # Shorter commit command
      br = "branch";                     # Branch management
      co = "checkout";                   # Branch switching
      df = "diff";                       # Change viewing
      # Enhanced Log View
      # Shows commit graph with colors and author info
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };

    # Global Ignores
    # Files to ignore in all repositories
    ignores = [
      ".DS_Store"                        # macOS metadata
      "*.swp"                           # Vim swap files
      ".env"                            # Environment variables
      ".direnv"                         # Direnv cache
      "node_modules"                    # Node.js dependencies
      ".vscode"                         # VS Code settings
      ".idea"                           # IntelliJ settings
    ];
  };

  # Shell Integration
  # ZSH aliases for Git workflows
  programs.zsh.shellAliases = {
    # Basic Operations
    # Quick access to common Git commands
    gp = "git push";                     # Push to remote
    gl = "git pull";                     # Pull from remote
    gs = "git status";                   # Check status
    gd = "git diff";                     # View changes

    # Advanced Operations
    # Complex Git workflows simplified
    gpush = "git add . && git commit -m";            # Stage and commit
    gpushf = "git add . && git commit --amend --no-edit && git push -f";  # Amend and force push
    gpushnew = "git push -u origin HEAD";            # Push new branch

    # Remote Management
    # Handle remote repository operations
    gare = "git remote add upstream";               # Add upstream
    gre = "git remote -v";                          # List remotes
    gcan = "git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit -v -a --no-edit --amend";  # Amend changes
    gfa = "git fetch --all";                        # Fetch all remotes
    gfap = "git fetch --all --prune";               # Fetch and clean

    # Development Tools
    # External tool integration
    lg = "lazygit";                                 # Terminal UI
  };

  # Utility Functions
  # Custom Git helper functions
  programs.zsh.initExtra = ''
    # Branch Detection
    # Determine default branch name
    function gitdefaultbranch() {
      git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
    }
  '';
}
