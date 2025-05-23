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
{...}: {
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      sessionVariables = {
        PATH = "$HOME/.local/bin:$HOME/Library/Application Support/pypoetry/venv/bin:$PATH";
        NIX_PATH = "$HOME/.nix-defexpr/channels:$NIX_PATH";
        FPATH = "$HOME/.zsh/completion:$FPATH";
        AWS_DEFAULT_REGION = "us-west-2";
        AWS_REGION = "us-west-2";
      };

      initContent = ''
        # FZF Integration Widgets
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
          [ -n "$selections" ] && LBUFFER+="$(echo "$selections" | awk '{print $2}' | tr '\n' ' ')"
          zle reset-prompt
        }
        zle -N fzf-git-status

        function fzf-cd-with-hidden() {
          local dir=$(find "''${1:-$PWD}" -type d 2> /dev/null | fzf +m) && cd "$dir"
          zle reset-prompt
        }
        zle -N fzf-cd-with-hidden

        # History and Directory Navigation
        autoload -U up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        zle -N dirhistory_zle_dirhistory_up
        zle -N dirhistory_zle_dirhistory_down

        # Key Bindings - Word Navigation & Editing
        bindkey "^[f" forward-word                    # ALT-Right
        bindkey "^[b" backward-word                   # ALT-Left
        bindkey "^[[3;5~" kill-word                   # CTRL-Delete
        bindkey "^H" backward-kill-word               # CTRL-Backspace
        bindkey "^U" backward-kill-line               # CTRL-U
        bindkey "^[^?" backward-kill-word             # ALT-Backspace
        bindkey "^A" beginning-of-line                # CTRL-A
        bindkey "^E" end-of-line                      # CTRL-E
        bindkey "^[[1;3A" dirhistory_zle_dirhistory_up   # ALT-Up
        bindkey "^[[1;3B" dirhistory_zle_dirhistory_down # ALT-Down
        bindkey -s '^_' 'code $(fzf)^M'               # CTRL-_
        bindkey "^[d" fzf-cd-with-hidden              # ALT-d
        bindkey '^G' fzf-git-status                   # CTRL-G

        # Git & GitHub Helper Functions
        function gitdefaultbranch() {
          git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
        }

        function ghpr() { gh pr list --state "$1" --limit 1000 | fzf; }
        function ghprall() { gh pr list --state all --limit 1000 | fzf; }
        function ghpropen() { gh pr list --state open --limit 1000 | fzf; }
        function ghopr() {
          local pr=$(gh pr list --state all --limit 1000 | fzf --preview 'echo {} | awk "{print \$1}" | xargs gh pr view') &&
          [ -n "$pr" ] && echo "$pr" | awk '{print $1}' | xargs gh pr view --web
        }
        function ghprco() {
          local pr=$(gh pr list --state open | fzf --preview 'echo {} | awk "{print \$1}" | xargs gh pr view') &&
          [ -n "$pr" ] && echo "$pr" | awk '{print $1}' | xargs gh pr checkout
        }
        function ghprcr() {
          gh pr create --fill
        }
        function ghprcheck() {
          local pr=$(gh pr list --state open | fzf) &&
          [ -n "$pr" ] && echo "$pr" | awk '{print $1}' | xargs gh pr checks
        }
      '';

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "git-extras"
          "docker"
          "docker-compose"
          "extract"
          "mosh"
          "timer"
          "dirhistory"
          "web-search"
        ];
      };

      history = {
        size = 50000;
        save = 50000;
        share = true;
        ignoreDups = true;
        ignoreSpace = true;
        expireDuplicatesFirst = true;
      };
    };

    # FZF Configuration
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    # Zoxide Configuration
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  # Disable Nixpkgs release check for compatibility
  home.enableNixpkgsReleaseCheck = false;
}
