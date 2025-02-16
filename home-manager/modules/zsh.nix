# home-manager/modules/zsh.nix
#
# Zsh shell configuration
#
# Purpose:
# - Provides a fully-featured ZSH environment
# - Integrates development tools and utilities
# - Sets up consistent shell experience
#
# Manages:
# - Shell environment setup
# - PATH management
#   - pipx binaries ($HOME/.local/bin)
#   - poetry ($HOME/Library/Application Support/pypoetry/venv/bin)
#   - pyenv initialization
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
# - Works with aliases.nix for command shortcuts
# - Supports git.nix for Git functionality
# - Uses starship from shell.nix for prompt
# - Compatible with tmux configuration

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
    };

    initExtra = ''
      # Theme Setup
      # Set up Starship with Gruvbox Rainbow preset
      if [ ! -f ~/.config/starship.toml ] || ! grep -q "gruvbox" ~/.config/starship.toml; then
        starship preset gruvbox-rainbow -o ~/.config/starship.toml
      fi

      # Development Tools Setup
      # Initialize SDKMAN if installed
      if [ -d "$HOME/.sdkman" ]; then
        export SDKMAN_DIR="$HOME/.sdkman"
        [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
      fi

      # Initialize pyenv
      if command -v pyenv &> /dev/null; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
        eval "$(pyenv init --path)"
      fi

      # Ensure UV is in PATH
      if [ -d "$HOME/.local/bin" ]; then
        export PATH="$HOME/.local/bin:$PATH"
      fi

      if [ -d "$HOME/Library/Application Support/pypoetry/venv/bin" ]; then
        export PATH="$HOME/Library/Application Support/pypoetry/venv/bin:$PATH"
      fi

      # Initialize zoxide
      eval "$(zoxide init zsh)"
      
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

  # Explicitly enable home-manager to manage zsh
  home.enableNixpkgsReleaseCheck = false;
  programs.home-manager.enable = true;
} 
