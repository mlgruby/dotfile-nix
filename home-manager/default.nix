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
    ./modules/tmux.nix
    ./modules/zsh.nix
    ./modules/starship.nix
    
    # Cloud Platform Tools
    ./modules/aws.nix
    ./modules/aws-cred.nix
    
    # Development Tools
    ./modules/git.nix
    ./modules/github.nix
    ./modules/lazygit.nix
    
    # Terminal & UI
    ./modules/alacritty
    ./modules/karabiner
    ./modules/rectangle.nix
    
    # Editor
    ./neovim.nix
  ];

  # List of packages managed by Home Manager
  home.packages = with pkgs; [
    # Development Environment
    direnv  # Automatic environment switching
    pipx    # Python package manager
  ];

  programs = {
    # Shell Configuration
    zsh = {
      enable = true;
      shellAliases = import ./aliases.nix { inherit pkgs config userConfig; };
    };
    
    # Home Manager
    home-manager.enable = true;

    # Direnv Configuration for Flake Integration
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
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
