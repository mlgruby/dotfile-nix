# home-manager/modules/zsh.nix
#
# ZSH Configuration
#
# Purpose:
# - Sets up shell environment
# - Configures completions
# - Manages history
#
# Manages:
#
# Tool initializations:
# - SDKMAN for Java version management
# - pyenv for Python version management
# - Starship prompt with Gruvbox theme
#
# Features:
# - Oh My Zsh integration with plugins
# - Custom aliases for development workflow
# - Syntax highlighting and autosuggestions
# - Git integration
#
# Key Bindings:
# - ALT-Left/Right: Word navigation
# - CTRL-Delete/Backspace: Word deletion
# - CTRL-U: Clear line before cursor
# - CTRL-A/E: Start/end of line
# - ALT-Up/Down: Directory history
# - CTRL-_: Open file in VSCode with FZF
# - ALT-d: FZF directory navigation
# - CTRL-G: FZF git status
#
# Custom Functions:
# - fzf-git-status: Interactive git status
# - fzf-cd-with-hidden: Directory navigation with hidden files
#
# Plugins:
# - git: Enhanced git integration
# - git-extras: Additional git utilities
# - docker: Docker commands and completion
# - docker-compose: Docker Compose support
# - extract: Smart archive extraction
# - mosh: Mobile shell support
# - timer: Command execution timing
# - zsh-autosuggestions: Command suggestions
# - zsh-syntax-highlighting: Syntax highlighting
#
# Integration:
# - Works with starship
# - Uses fzf features
# - Manages plugins
#
# Note:
# - History sharing on
# - Auto-completion enabled
# - Syntax highlighting active

{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    
    # Add environment variables
    sessionVariables = {
      # Ensure all necessary paths are available
      PATH = "$HOME/.local/bin:$HOME/Library/Application Support/pypoetry/venv/bin:$PATH";
      NIX_PATH = "$HOME/.nix-defexpr/channels:$NIX_PATH";
      FPATH = "$HOME/.zsh/completion:$FPATH";
      # AWS Region Defaults
      AWS_DEFAULT_REGION = "us-west-2";
      AWS_REGION = "us-west-2";
    };

    initExtra = ''
      # Starship prompt configured via starship.nix
      
      # Development Tools Setup (Cleaned)

      # PATH additions are now handled primarily by sessionVariables

      # Initialize zoxide (Replaced by declarative option)
      # eval "$(zoxide init zsh)"
      
      # FZF Integration Widgets
      # Interactive git status with file preview
      function fzf-git-status() {
        local selections=$(
          git status --porcelain | \
          fzf --ansi \
              --preview 'if [ -f {2} ]; then
                          bat --color=always --style=numbers {2}
                        elif [ -d {2} ]; then
                          tree -C {2}
                        fi' \
              --preview-window right:70% \
              --multi
        )
        if [ -n "$selections" ]; then
          LBUFFER+="$(echo "$selections" | awk '{print $2}' | tr '\n' ' ')"
        fi
        zle reset-prompt
      }
      zle -N fzf-git-status
      
      # Directory navigation with hidden files
      function fzf-cd-with-hidden() {
        local dir
        dir=$(find "''${1:-$PWD}" -type d 2> /dev/null | fzf +m) && cd "$dir"
        zle reset-prompt
      }
      zle -N fzf-cd-with-hidden
      
      # History and Directory Navigation
      # Enable up/down arrow history search
      autoload -U up-line-or-beginning-search
      autoload -U down-line-or-beginning-search
      zle -N up-line-or-beginning-search
      zle -N down-line-or-beginning-search
      # Enable directory history navigation
      zle -N dirhistory_zle_dirhistory_up
      zle -N dirhistory_zle_dirhistory_down
      
      # Key Binding Configuration
      # Word Navigation
      # ALT-Left/Right for word navigation
      bindkey "^[f" forward-word
      bindkey "^[b" backward-word
      
      # Word Deletion
      # CTRL-Delete/Backspace for word deletion
      bindkey "^[[3;5~" kill-word
      bindkey "^H" backward-kill-word
      
      # Line Editing
      # CTRL-U clears line before cursor
      bindkey "^U" backward-kill-line
      
      # ALT-Backspace deletes word before cursor
      bindkey "^[^?" backward-kill-word
      
      # Cursor Movement
      # CTRL-A/E for start/end of line (like in Emacs)
      bindkey "^A" beginning-of-line
      bindkey "^E" end-of-line
      
      # Directory Navigation
      # ALT-Up/Down for directory history
      bindkey "^[[1;3A" dirhistory_zle_dirhistory_up
      bindkey "^[[1;3B" dirhistory_zle_dirhistory_down
      
      # FZF Enhanced Functions
      # Directory navigation with preview
      fzf-cd-with-hidden() {
        local dir
        dir=$(find "''${1:-$PWD}" -type d 2> /dev/null | fzf +m) && cd "$dir"
      }
      
      # Git status with preview
      fzf-git-status() {
        local selections=$(
          git status --porcelain | \
          fzf --ansi \
              --preview 'if [ -f {2} ]; then
                          bat --color=always --style=numbers {2}
                        elif [ -d {2} ]; then
                          tree -C {2}
                        fi' \
              --preview-window right:70% \
              --multi
        )
        if [ -n "$selections" ]; then
          echo "$selections" | awk '{print $2}' | tr '\n' ' '
        fi
      }
      
      # FZF Key Bindings
      # CTRL-_ to open file in VSCode
      bindkey -s '^_' 'code $(fzf)^M'
      # ALT-d for directory navigation
      bindkey "^[d" fzf-cd-with-hidden
      # CTRL-G for git status
      bindkey '^G' fzf-git-status

      # Function to determine default git branch (Moved from git.nix)
      function gitdefaultbranch() {
        git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
      }

      # Custom GitHub Workflow Functions (Moved from github.nix)
      # Basic PR listing with state filter
      function ghpr() {
        gh pr list --state "$1" --limit 1000 | fzf
      }
      # Comprehensive PR listing functions
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
          PR_NUM=$(gh pr list --state open | fzf | cut -f1)
          if [ -n "$PR_NUM" ]; then
            gh pr checkout "$PR_NUM"
          fi
        else
          case "$1" in
            -f|--force)
              gh pr checkout "$2" --force
              ;;
            -d|--detach)
              gh pr checkout "$2" --detach
              ;;
            *)
              gh pr checkout "$1"
              ;;
          esac
        fi
      }
    '';

    oh-my-zsh = {
      enable = true;
      # Core functionality plugins
      plugins = [
        "git"
        "git-extras"
        "docker"
        "docker-compose"
        "extract"
        "mosh"
        "timer"
      ];
      theme = "agnoster";
    };

    # Additional ZSH plugins
    plugins = [
      {
        # Command auto-completion suggestions
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.0";
          sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
        };
      }
      {
        # Syntax highlighting for commands
        name = "zsh-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          rev = "0.7.1";
          sha256 = "sha256-gOG0NLlaJfotJfs+SUhGgLTNOnGLjoqnUp54V9aFJg8=";
        };
      }
    ];
  };

  # FZF Configuration (Moved from shell.nix)
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # Note: Further FZF settings (defaultCommand, defaultOptions)
    # seem to be defined in home-manager/default.nix currently.
    # Consider moving them here or removing the block from default.nix
    # if this is intended to be the primary fzf config location.
  };

  # Zoxide Configuration
  programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
  };

  # Explicitly enable home-manager to manage zsh
  home.enableNixpkgsReleaseCheck = false;
  programs.home-manager.enable = true;
}
