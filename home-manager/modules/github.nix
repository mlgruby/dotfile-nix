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