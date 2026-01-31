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
# - uv for Python version management
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
{
  lib,
  pkgs,
  config,
  ...
}: {
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      # Explicitly set dotDir to lock in current behavior (home directory)
      # This silences the warning about future default changes
      dotDir = "/Users/${config.home.username}";

      sessionVariables = {
        NIX_PATH = "$HOME/.nix-defexpr/channels:$NIX_PATH";
        FPATH = "$HOME/.zsh/completion:$FPATH";
        # Note: AWS_DEFAULT_REGION and AWS_REGION are set in aws-sso.nix
        # Python environment
        PYTHON_CONFIGURE_OPTS = "--enable-framework";
        UV_PYTHON_PREFERENCE = "system";
        # Rust environment - override Nix's read-only defaults
        CARGO_HOME = "$HOME/.cargo";
        RUSTUP_HOME = "$HOME/.rustup";
        # Add Rust, Python 3.12 generic symlinks and TeX binaries to PATH
        PATH = "$HOME/.docker/bin:$HOME/.cargo/bin:/Library/TeX/texbin:/opt/homebrew/opt/gnu-getopt/bin:/opt/homebrew/opt/python@3.12/libexec/bin:$HOME/bin:$PATH";
      };

      initContent = ''
        # Python Environment Management
        # System-wide Python 3.12 via Homebrew
        # Project-specific Python versions via uv
        # UV environment initialization
        if command -v uv > /dev/null 2>&1; then
          # UV completions
          eval "$(uv generate-shell-completion zsh)"
        fi

        # Tmux Auto-start
        # Auto-attach to existing session or create new one
        # Skip in IDE terminals (VSCode, IntelliJ, Antigravity) to keep sessions separate
        if command -v tmux > /dev/null 2>&1; then
          # Only auto-start if not already in tmux and not in any IDE terminal
          if [ -z "$TMUX" ] && [ -z "$VSCODE_INJECTION" ] && [ -z "$ANTIGRAVITY_TERMINAL" ] && [ -z "$TERMINAL_EMULATOR" ] && [ -z "$INTELLIJ_ENVIRONMENT_READER" ]; then
            # Try to attach to existing session, or create new one
            tmux attach-session -t main 2>/dev/null || tmux new-session -s main
          fi
        fi

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
          gh pr create --web --fill
        }
        function ghprcheck() {
          local pr=$(gh pr list --state open | fzf) &&
          [ -n "$pr" ] && echo "$pr" | awk '{print $1}' | xargs gh pr checks
        }

        # Kubernetes Context Setup
        function setup-vortexa-kube() {
          echo "Setting up Vortexa Kubernetes contexts..."
          
          # Unset env vars that might override the profile
          unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

          # Develop
          echo "Configuring Develop cluster..."
          export AWS_PROFILE=default-sso
          aws eks --region eu-west-1 update-kubeconfig --name KubeCluster --role-arn arn:aws:iam::045251666112:role/EKSUserRole --alias vortexa-develop

          # Production
          echo "Configuring Production cluster..."
          export AWS_PROFILE=production-sso
          aws eks --region eu-west-1 update-kubeconfig --name KubeCluster --role-arn arn:aws:iam::501857513371:role/EKSUserRole --alias vortexa-production

          echo "Done! Use ksd/ksp to switch contexts."
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
