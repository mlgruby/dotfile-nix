# home/default.nix
#
# Main Home Manager configuration
#
# Purpose:
# - Manages user environment and dotfiles
# - Configures development tools and shells
# - Sets up personal preferences and aliases
#
# Configuration Areas:
# 1. Shell Environment:
#    - Modern shell setup
#    - Custom prompt configuration
#    - Command-line completion
#    - Directory navigation
#
# 2. Development Tools:
#    - Version control configuration
#    - Code editing and IDE setup
#    - Language-specific tooling
#    - Build and debug tools
#
# 3. Terminal Enhancement:
#    - GPU-accelerated terminal
#    - Session management
#    - Search and filtering
#    - Text processing
#
# 4. Cloud & Infrastructure:
#    - Cloud provider configurations
#    - Infrastructure as Code tools
#    - Credential management
#    - Platform SDKs
#
# 5. System Integration:
#    - Keyboard customization
#    - Window management
#    - Application shortcuts
#    - System utilities
#
# Features:
# - Modular configuration system
# - Consistent tool configuration
# - Cross-platform compatibility
# - Automated environment setup
#
# Integration:
# - Works with nix-darwin system config
# - Complements Homebrew packages
# - Manages dotfiles and configs
#
# Note:
# - User-specific settings in user-config.nix
# - Some features need manual setup
# - Check module docs for details
# - Configuration is declarative
# - Changes require rebuild
{ config, pkgs, lib, username, fullName, email, githubUsername, userConfig, ... }: {
  imports = [
    # Shell Environment
    ./shell.nix
    ./modules/tmux.nix
    # Cloud Platform Tools
    ./modules/aws.nix
    ./modules/aws-cred.nix
    ./modules/gcloud.nix
    # Development Tools
    ./modules/git.nix
    ./modules/github.nix
    # Core Environment
    ./modules/zsh.nix
    ./modules/alacritty
    ./modules/karabiner
    ./modules/lazygit.nix
    ./modules/starship.nix
    ./neovim.nix
  ];

  # Core packages required for basic functionality
  home.packages = with pkgs; [
    oh-my-zsh
  ];

  programs = {
    # Shell Configuration
    zsh = {
      enable = true;
      # Import aliases from central location
      shellAliases = import ./aliases.nix { inherit pkgs config userConfig; };
    };
    # Fuzzy Finder Configuration
    fzf = {
      enable = true;
      enableZshIntegration = true;
      # Use fd for file finding (respects .gitignore)
      defaultCommand = "fd --type f";
      # Default appearance and behavior
      defaultOptions = ["--height 40%" "--border"];
    };
    home-manager.enable = true;
  };

  # Enable font configuration
  fonts.fontconfig.enable = true;

  # User Environment Settings
  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    # Version for home-manager
    stateVersion = "23.11";
  };
}
