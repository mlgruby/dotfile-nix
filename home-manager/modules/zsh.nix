# home-manager/modules/zsh.nix
#
# Zsh shell configuration
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

{ config, pkgs, ... }:

let
  generateAliases = pkgs: {
    # VS Code
    c = "code .";
    ce = "code . && exit";
    cdf = "cd $(ls -d */ | fzf)";

    # Nix commands
    rebuild = "cd ~/Documents/dotfile && darwin-rebuild switch --flake .#ss-mbp && cd -";
    update = ''
      echo "🔄 Updating Nix flake..." && \
      cd ~/Documents/dotfile && \
      nix flake update && \
      echo "🔄 Rebuilding system..." && \
      darwin-rebuild switch --flake .#ss-mbp && \
      cd - && \
      echo "✨ System update complete!"
    '';

    # Directory operations
    mkdir = "mkdir -p";
    rm = "rm -rf";
    cp = "cp -r";
    mv = "mv -i";
    dl = "cd $HOME/Downloads";
    docs = "cd $HOME/Documents";

    # Editor
    v = "nvim";
    vim = "nvim";

    # exa aliases
    ls = "exa -l";
    lsa = "exa -l -a";
    lst = "exa -l -T";
    lsr = "exa -l -R";

    # Terraform aliases
    tf = "terraform";
    tfin = "terraform init";
    tfp = "terraform plan";
    tfwst = "terraform workspace select";
    tfwsw = "terraform workspace show";
    tfwls = "terraform workspace list";

    # Docker aliases
    d = "docker";
    dc = "docker-compose";

    # Common utilities
    ipp = "curl https://ipecho.net/plain; echo";

    # macOS specific aliases
    cleanup = if pkgs.stdenv.isDarwin then ''
      echo "🧹 Cleaning up system..." && \
      echo "🗑️  Removing .DS_Store files..." && \
      find . -type f -name '*.DS_Store' -ls -delete && \
      echo "📝 Cleaning system logs..." && \
      sudo rm -rf /private/var/log/asl/*.asl 2>/dev/null || echo "⚠️  Could not clean system logs (permission denied)" && \
      echo "🧹 Cleaning quarantine events..." && \
      sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent' 2>/dev/null || echo "⚠️  Could not clean quarantine events" && \
      echo "✨ Cleanup complete!"
    '' else "";

    # Shell commands
    restart = "clear && exec zsh";       # Restart the shell
    re = "clear && exec zsh";            # Short alias for restart
    reload = "clear && source ~/.zshrc"; # Reload config
    rl = "clear && source ~/.zshrc";     # Short alias for reload
  };
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    
    # Add environment variables
    sessionVariables = {
      PATH = "$HOME/.local/bin:$HOME/Library/Application Support/pypoetry/venv/bin:$PATH";
      NIX_PATH = "$HOME/.nix-defexpr/channels:$NIX_PATH";
    };

    initExtra = ''
      # Set up Starship with Gruvbox Rainbow preset
      if [ ! -f ~/.config/starship.toml ] || ! grep -q "gruvbox" ~/.config/starship.toml; then
        starship preset gruvbox-rainbow -o ~/.config/starship.toml
      fi

      # Initialize SDKMAN if installed
      if [ -d "$HOME/.sdkman" ]; then
        export SDKMAN_DIR="$HOME/.sdkman"
        [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
      fi

      # Initialize pyenv
      if [ -d "$HOME/.pyenv" ]; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
      fi

      # Ensure pipx and poetry paths are available
      if [ -d "$HOME/.local/bin" ]; then
        export PATH="$HOME/.local/bin:$PATH"
      fi

      if [ -d "$HOME/Library/Application Support/pypoetry/venv/bin" ]; then
        export PATH="$HOME/Library/Application Support/pypoetry/venv/bin:$PATH"
      fi
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
      ];
      theme = "agnoster";
    };

    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.0";
          sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
        };
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          rev = "0.7.1";
          sha256 = "sha256-gOG0NLlaJfotJfs+SUhGgLTNOnGLjoqnUp54V9aFJg8=";
        };
      }
    ];

    shellAliases = generateAliases pkgs;
  };

  # Explicitly enable home-manager to manage zsh
  home.enableNixpkgsReleaseCheck = false;
  programs.home-manager.enable = true;
} 
