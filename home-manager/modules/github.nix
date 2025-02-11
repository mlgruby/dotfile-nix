# home-manager/modules/github.nix
#
# GitHub CLI (gh) configuration and workflow automation.
#
# Core Features:
# - GitHub CLI setup with SSH protocol
# - Vim as default editor
#
# Interactive Functions:
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
      # GitHub CLI settings
      git_protocol = "ssh";
      editor = "vim";
    };
  };

  # GitHub specific functions
  programs.zsh.initExtra = ''
    # GitHub PR functions
    function ghpr() {
      gh pr list --state "$1" --limit 1000 | fzf
    }

    # Interactive PR selection and action functions
    function ghprall() {
      gh pr list --state all --limit 1000 | fzf
    }

    function ghpropen() {
      gh pr list --state open --limit 1000 | fzf
    }

    function ghopr() {
      id="$(ghprall | cut -f1)"
      [ -n "$id" ] && gh pr view "$id" --web
    }

    function ghprcheck() {
      id="$(ghpropen | cut -f1)"
      [ -n "$id" ] && gh pr checks "$id"
    }

    # Enhanced PR checkout function
    function ghprco() {
      if [ $# -eq 0 ]; then
        # Interactive mode: list PRs and checkout selected one
        PR_NUM=$(gh pr list --state open | fzf | cut -f1)
        if [ -n "$PR_NUM" ]; then
          gh pr checkout "$PR_NUM"
        fi
      else
        case "$1" in
          -f|--force)
            # Force checkout
            gh pr checkout "$2" --force
            ;;
          -d|--detach)
            # Detached HEAD checkout
            gh pr checkout "$2" --detach
            ;;
          *)
            # Normal checkout with PR number/URL/branch
            gh pr checkout "$1"
            ;;
        esac
      fi
    }
  '';

  # GitHub aliases
  programs.zsh.shellAliases = {
    ghprcr = "gh pr create --web";      # Create PR in web browser
    ghprv = "ghopr";                    # Interactive select and view PR in browser
    ghprl = "ghprall";                  # List all PRs with fzf
    ghpro = "ghpropen";                 # List open PRs with fzf
    ghprc = "ghprco";                   # Interactive checkout PR using the function
    ghprch = "ghprcheck";               # Check PR status
    
    # Repository management
    ghrv = "gh repo view --web";        # View repo in browser
    ghrc = "gh repo clone";             # Clone repo
    ghrf = "gh repo fork";              # Fork repo
    
    # Issues
    ghil = "gh issue list";             # List issues
    ghic = "gh issue create --web";     # Create issue in browser
    ghiv = "gh issue view --web";       # View issue in browser
    
    # Workflows/Actions
    ghrl = "gh run list";               # List workflow runs
    ghrw = "gh run watch";              # Watch workflow run
    
    # Search
    ghrs = "gh repo search";            # Search repositories
    ghis = "gh issue search";           # Search issues
    ghps = "gh pr search";              # Search PRs
  };
} 