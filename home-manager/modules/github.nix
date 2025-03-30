# home-manager/modules/github.nix
#
# GitHub CLI Configuration
#
# Purpose:
# - Sets up GitHub CLI aliases
# - Configures common workflows
#
# Aliases:
# - Pull Requests
# - Issues
# - Repositories
# - Workflows
#
# Integration:
# - Works with git.nix
# - Uses GitHub username from config
#
# Note:
# - Auth via 'gh auth login'
# - Additional git config in git.nix

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
