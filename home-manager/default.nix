# home/default.nix - Optimized Home Manager Configuration
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
{
  config,
  pkgs,
  username,
  userConfig,
  ...
}: {
  imports = [
    # Core modules
    ./modules/tmux.nix
    ./modules/zsh.nix
    ./modules/starship.nix
    ./modules/aws.nix
    ./modules/aws-sso.nix
    ./modules/git.nix
    ./modules/github.nix
    ./modules/lazygit.nix
    ./modules/alacritty
    ./modules/karabiner
    ./modules/rectangle.nix
    ./modules/services.nix
    ./modules/programs.nix
    ./modules/xdg.nix
    ./modules/fonts.nix
    ./modules/tool-configs.nix
    ./neovim.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "23.11";

    packages = with pkgs; [
      direnv
      pipx
      markdownlint-cli
      # Python Development Environment
      pyenv
      poetry
      # Scala Build Tool
      sbt
    ];
  };

  programs = {
    zsh = {
      enable = true;
      shellAliases = import ./aliases.nix {inherit pkgs config userConfig;};
    };

    home-manager.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };


}
