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
      echo "🗑️  Emptying trash..." && \
      sudo rm -rfv /Volumes/*/.Trashes && \
      sudo rm -rfv ~/.Trash && \
      echo "📝 Cleaning system logs..." && \
      sudo rm -rfv /private/var/log/asl/*.asl && \
      echo "🧹 Cleaning quarantine events..." && \
      sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent' && \
      echo "✨ Cleanup complete!"
    '' else "";

    # Shell commands
    restart = "exec zsh";      # Restart the shell
    re = "exec zsh";          # Short alias for restart
    reload = "source ~/.zshrc"; # Reload config
    rl = "source ~/.zshrc";    # Short alias for reload
  };
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    
    # Add environment variables
    sessionVariables = {
      PATH = "$HOME/Library/Application Support/pypoetry/venv/bin:$HOME/.local/bin:$PATH";
      NIX_PATH = "$HOME/.nix-defexpr/channels:$NIX_PATH";
    };

    initExtra = ''
      # Set up Starship with Gruvbox Rainbow preset
      if [ ! -f ~/.config/starship.toml ] || ! grep -q "gruvbox" ~/.config/starship.toml; then
        starship preset gruvbox-rainbow -o ~/.config/starship.toml
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
