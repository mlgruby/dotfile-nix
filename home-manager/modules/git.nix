# home-manager/modules/git.nix
#
# Comprehensive Git configuration module.
#
# Purpose:
# - Manages Git configuration and workflows
# - Provides convenient aliases and shortcuts
# - Streamlines common Git operations
#
# Features:
# - Secure identity management
# - Customized Git aliases
# - Shell integration
# - Workflow automation
# - Repository management
#
# Git Command Aliases:
#   st = status              # Quick status check
#   ci = commit              # Shorter commit command
#   br = branch              # List or create branches
#   co = checkout            # Switch branches
#   df = diff                # View changes
#   lg = log --graph ...     # Pretty log with branch graph
#
# Integration:
# - Works with GitHub CLI (github.nix)
# - Uses LazyGit for TUI operations
# - Compatible with ZSH configuration
# - Supports multiple remote workflows
#
# Shell Aliases:
# Basic Operations:
#   gp = "git push"         # Push current branch
#     Example: gp           # Pushes current branch to origin
#
#   gl = "git pull"         # Pull current branch
#     Example: gl           # Pulls latest changes
#
#   gs = "git status"       # Check repository status
#     Example: gs           # Shows modified/staged files
#
#   gd = "git diff"         # View uncommitted changes
#     Example: gd file.txt  # Shows changes in file.txt
#
# Quick Workflows:
#   gpush = "git add . && git commit -m"
#     Example: gpush "feat: add new button"
#     # Stages all changes and commits with message
#
#   gpushf = "git add . && git commit --amend --no-edit && git push -f"
#     Example: gpushf
#     # Amends last commit with current changes and force pushes
#     # CAUTION: Only use on your personal branches!
#
#   gpushnew = "git push -u origin HEAD"
#     Example: gpushnew
#     # Pushes new local branch and sets up tracking
#
# Remote Operations:
#   gare = "git remote add upstream"
#     Example: gare https://github.com/org/repo.git
#     # Adds upstream remote for forked repositories
#
#   gre = "git remote -v"
#     Example: gre
#     # Lists all configured remotes and their URLs
#
#   gcan = "git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit -v -a --no-edit --amend"
#     Example: gcan
#     # Adds all changes to the previous commit
#     # Useful for fixups before pushing
#
#   gfa = "git fetch --all"
#     Example: gfa
#     # Fetches all remotes
#
#   gfap = "git fetch --all --prune"
#     Example: gfap
#     # Fetches all remotes and removes deleted references
#
# Tools:
#   lg = "lazygit"
#     Example: lg
#     # Opens the LazyGit terminal UI
#
# Functions:
#   gitdefaultbranch
#     Example: gitdefaultbranch
#     # Returns 'main' or 'master' depending on repository
#     # Usage: git checkout $(gitdefaultbranch)

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