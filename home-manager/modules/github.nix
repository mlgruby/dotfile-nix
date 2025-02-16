# home-manager/modules/github.nix
#
# GitHub CLI (gh) configuration and workflow automation.
#
# Purpose:
# - Streamlines GitHub workflows via CLI
# - Provides interactive PR management
# - Automates common GitHub tasks
#
# Core Features:
# - GitHub CLI setup with SSH protocol
# - Vim as default editor
# - Interactive fuzzy search integration
# - Comprehensive PR management
# - Repository and issue handling
#
# Integration:
# - Works with git.nix for version control
# - Uses FZF for interactive selection
# - Complements LazyGit workflow
# - Installed via Homebrew (homebrew.nix)
#
# Interactive Functions:
# PR Management:
# ghpr [state]
#   Lists PRs with fuzzy search
#   Example: ghpr open     # List open PRs
#           ghpr closed   # List closed PRs
#
# ghprall
#   Lists all PRs with fuzzy search
#   Example: ghprall      # Shows all PRs for selection
#
# ghpropen
#   Lists only open PRs
#   Example: ghpropen     # Shows only open PRs
#
# ghprco [options] [PR-number]
#   Interactive PR checkout with options:
#   Example: ghprco           # Interactive PR selection
#           ghprco 123       # Checkout PR #123
#           ghprco -f 123    # Force checkout PR #123
#           ghprco -d 123    # Checkout PR #123 in detached mode
#
# Workflow Organization:
# 1. PR Management - Create, view, list, checkout PRs
# 2. Repository Ops - View, clone, fork repositories
# 3. Issue Tracking - List, create, view issues
# 4. CI/CD Integration - Monitor workflow runs
# 5. Search Operations - Find repos, issues, PRs
#
# Shell Aliases:
# PR Management:
#   ghprcr = "gh pr create --web"
#     Example: ghprcr
#     # Opens browser to create new PR from current branch
#
#   ghprv = "ghopr"
#     Example: ghprv
#     # Interactively select and view PR in browser
#
#   ghprl = "ghprall"
#     Example: ghprl
#     # Lists all PRs with fuzzy search
#
#   ghpro = "ghpropen"
#     Example: ghpro
#     # Lists only open PRs with fuzzy search
#
#   ghprc = "ghprco"
#     Example: ghprc
#     # Interactive PR checkout
#
#   ghprch = "ghprcheck"
#     Example: ghprch
#     # Shows CI status for selected PR
#
# Repository Operations:
#   ghrv = "gh repo view --web"
#     Example: ghrv
#     # Opens current repo in browser
#
#   ghrc = "gh repo clone"
#     Example: ghrc owner/repo
#     # Clones repository
#
#   ghrf = "gh repo fork"
#     Example: ghrf
#     # Forks current repository
#
# Issue Management:
#   ghil = "gh issue list"
#     Example: ghil
#     # Lists all issues
#
#   ghic = "gh issue create --web"
#     Example: ghic
#     # Opens browser to create new issue
#
#   ghiv = "gh issue view --web"
#     Example: ghiv 123
#     # Views issue #123 in browser
#
# CI/CD Operations:
#   ghrl = "gh run list"
#     Example: ghrl
#     # Lists recent workflow runs
#
#   ghrw = "gh run watch"
#     Example: ghrw 123456
#     # Watches workflow run #123456
#
# Search Operations:
#   ghrs = "gh repo search"
#     Example: ghrs "nix config"
#     # Searches for repositories
#
#   ghis = "gh issue search"
#     Example: ghis "is:open label:bug"
#     # Searches for open bug issues
#
#   ghps = "gh pr search"
#     Example: ghps "is:open review-requested:@me"
#     # Searches for PRs requesting your review

{ config, pkgs, ... }: {
  programs.gh = {
    enable = true;
    settings = {
      # Use SSH for better security and no password prompts
      git_protocol = "ssh";
      # Default editor for PR/Issue descriptions
      editor = "vim";
    };
  };

  # Custom GitHub Workflow Functions
  programs.zsh.initExtra = ''
    # Basic PR listing with state filter
    function ghpr() {
      gh pr list --state "$1" --limit 1000 | fzf
    }

    # Comprehensive PR listing functions
    # Shows all PRs regardless of state
    function ghprall() {
      gh pr list --state all --limit 1000 | fzf
    }

    # Shows only open PRs for active work
    function ghpropen() {
      gh pr list --state open --limit 1000 | fzf
    }

    # Open selected PR in browser
    function ghopr() {
      id="$(ghprall | cut -f1)"
      [ -n "$id" ] && gh pr view "$id" --web
    }

    # Check CI status for selected PR
    function ghprcheck() {
      id="$(ghpropen | cut -f1)"
      [ -n "$id" ] && gh pr checks "$id"
    }

    # Enhanced PR checkout function
    function ghprco() {
      if [ $# -eq 0 ]; then
        # Interactive mode:
        # 1. List open PRs with fuzzy search
        # 2. Extract PR number from selection
        # 3. Checkout selected PR
        PR_NUM=$(gh pr list --state open | fzf | cut -f1)
        if [ -n "$PR_NUM" ]; then
          gh pr checkout "$PR_NUM"
        fi
      else
        case "$1" in
          -f|--force)
            # Force checkout: Overwrite local changes
            # Useful when PR branch has diverged
            gh pr checkout "$2" --force
            ;;
          -d|--detach)
            # Detached HEAD checkout:
            # Review PR without creating local branch
            gh pr checkout "$2" --detach
            ;;
          *)
            # Standard checkout:
            # Accepts PR number, URL, or branch name
            # Creates local branch tracking PR
            gh pr checkout "$1"
            ;;
        esac
      fi
    }
  '';

  # GitHub Command Aliases
  # Organized by workflow category
  programs.zsh.shellAliases = {
    # Pull Request Workflow
    # Quick actions for PR management
    ghprcr = "gh pr create --web";      # Create PR in web browser
    ghprv = "ghopr";                    # Interactive select and view PR in browser
    ghprl = "ghprall";                  # List all PRs with fzf
    ghpro = "ghpropen";                 # List open PRs with fzf
    ghprc = "ghprco";                   # Interactive checkout PR using the function
    ghprch = "ghprcheck";               # Check PR status
    
    # Repository Operations
    # Quick access to repo-level actions
    ghrv = "gh repo view --web";        # View repo in browser
    ghrc = "gh repo clone";             # Clone repo
    ghrf = "gh repo fork";              # Fork repo
    
    # Issue Tracking
    # Streamlined issue management
    ghil = "gh issue list";             # List issues
    ghic = "gh issue create --web";     # Create issue in browser
    ghiv = "gh issue view --web";       # View issue in browser
    
    # CI/CD Monitoring
    # GitHub Actions workflow management
    ghrl = "gh run list";               # List workflow runs
    ghrw = "gh run watch";              # Watch workflow run
    
    # Search Operations
    # Quick access to GitHub search
    ghrs = "gh repo search";            # Search repositories
    ghis = "gh issue search";           # Search issues
    ghps = "gh pr search";              # Search PRs
  };
} 