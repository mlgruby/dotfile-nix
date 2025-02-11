# home-manager/modules/git.nix
#
# Comprehensive Git configuration module.
#
# Features:
# - Personal identity configuration
# - Core Git settings:
#   - Default branch: develop
#   - Pull with rebase
#   - Auto setup remote on push
#   - Input line ending handling
# 
# Git Command Aliases:
#   st = status              # Quick status check
#   ci = commit              # Shorter commit command
#   br = branch              # List or create branches
#   co = checkout            # Switch branches
#   df = diff                # View changes
#   lg = log --graph ...     # Pretty log with branch graph
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

{ config, pkgs, ... }: {
  programs.git = {
    enable = true;
    
    # Your identity
    userName = "Satyasheel";
    userEmail = "satyasheel@lightricks.com";

    # Default settings
    extraConfig = {
      init.defaultBranch = "develop";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      color.ui = true;
    };

    # Git command aliases
    aliases = {
      # Quick status check
      st = "status";

      # Shorter commit command
      ci = "commit";

      # List or create branches
      br = "branch";

      # Switch branches
      co = "checkout";

      # View changes
      df = "diff";

      # Pretty log with branch graph
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      ".env"
      ".direnv"
      "node_modules"
      ".vscode"
      ".idea"
    ];
  };

  # Git-specific shell aliases
  programs.zsh.shellAliases = {
    # Basic git operations
    # Push current branch to origin
    # Example: gp
    gp = "git push";

    # Pull latest changes from current branch
    # Example: gl
    gl = "git pull";

    # Check repository status
    # Example: gs
    gs = "git status";

    # View uncommitted changes
    # Example: gd file.txt
    gd = "git diff";
    
    # Quick add and push operations
    # Stage all changes and commit with message
    # Example: gpush "feat: add new button"
    gpush = "git add . && git commit -m";

    # Amend current commit and force push
    # Example: gpushf
    # CAUTION: Only use on personal branches!
    gpushf = "git add . && git commit --amend --no-edit && git push -f";

    # Push new branch and set upstream
    # Example: gpushnew
    gpushnew = "git push -u origin HEAD";
    
    # Remote operations
    # Add upstream remote for forks
    # Example: gare https://github.com/org/repo.git
    gare = "git remote add upstream";

    # List all remotes and their URLs
    # Example: gre
    gre = "git remote -v";

    # Add all changes to previous commit
    # Example: gcan
    gcan = "git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit -v -a --no-edit --amend";

    # Fetch all remotes
    # Example: gfa
    gfa = "git fetch --all";

    # Fetch all remotes and prune deleted branches
    # Example: gfap
    gfap = "git fetch --all --prune";
    
    # Tools
    # Open LazyGit terminal UI
    # Example: lg
    lg = "lazygit";
  };

  # Git utility functions
  programs.zsh.initExtra = ''
    # Get the default branch (main/master) of the repository
    # Example: git checkout $(gitdefaultbranch)
    function gitdefaultbranch() {
      git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
    }
  '';
} 