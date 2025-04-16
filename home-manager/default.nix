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
    # ./shell.nix # Removed - Contents merged into zsh.nix / starship.nix
    ./modules/tmux.nix
    # Cloud Platform Tools
    ./modules/aws.nix
    ./modules/aws-cred.nix
    # ./modules/gcloud.nix # Deleted
    # Development Toolswok
    ./modules/git.nix
    ./modules/github.nix
    # Core Environment
    ./modules/zsh.nix
    ./modules/alacritty
    ./modules/karabiner
    ./modules/lazygit.nix
    ./modules/starship.nix
    ./modules/rectangle.nix
    ./neovim.nix
  ];

  # List of packages managed by Home Manager
  home.packages = with pkgs; [
    # Cloud SDKs (Managed via Homebrew now)
    
    # Core packages required for basic functionality (Example: oh-my-zsh)
    # oh-my-zsh # Managed via programs.zsh.oh-my-zsh.enable
    # Other non-migrated packages if any were here...
  ];

  programs = {
    # Shell Configuration
    zsh = {
      enable = true;
      # Import aliases from central location
      shellAliases = import ./aliases.nix { inherit pkgs config userConfig; };
    };
    # FZF settings moved to zsh.nix
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
