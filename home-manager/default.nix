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
    ./modules/aws-sso.nix
    ./modules/git.nix
    ./modules/github.nix
    ./modules/gpg.nix
    ./modules/programs/btop.nix
    ./modules/programs/eza.nix
    ./modules/programs/bat.nix
    ./modules/programs/ripgrep.nix
    ./modules/programs/jq.nix
    ./modules/programs/bottom.nix
    ./modules/lazygit.nix
    ./modules/alacritty
    ./modules/karabiner
    ./modules/rectangle.nix
    ./modules/ssh.nix
    ./modules/programs/terminal-tools.nix
    ./modules/directory-tools.nix
    ./modules/utility-packages.nix
    ./modules/xdg.nix
    ./modules/fonts.nix
    ./neovim.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "24.05";

    packages = with pkgs; [
      direnv
      pipx
      markdownlint-cli
      # Python Development Environment
      # System-wide Python 3.12 via Homebrew
      # Project-specific versions via uv
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

  # Optimized Stylix Target Configuration
  # Conservative approach using only confirmed working targets
  # Based on applications we have configured and Stylix documentation
  stylix.targets = {
    # Terminal Applications - Carefully managed due to custom configs
    alacritty.enable = false;        # DISABLED: Complex custom config conflicts with Stylix
    
    # Development Tools - Core supported targets
    neovim = {
      enable = true;                 # ENABLED: Well-supported by Stylix
      plugin = "mini.base16";        # Use recommended plugin
      transparentBackground = {
        main = false;                # Keep solid backgrounds for readability
        signColumn = false;
        numberLine = false;
      };
    };
    
    # System Monitoring - Confirmed supported
    btop.enable = true;              # ENABLED: Stylix has native btop support
    
    # Shell and Prompt - Manual configuration preferred
    starship.enable = false;         # DISABLED: Manual color configuration with Stylix integration
    
    # Text Tools - Core supported targets
    bat.enable = true;               # ENABLED: Native Stylix support
    
    # VCS Tools - Confirmed supported
    lazygit.enable = true;           # ENABLED: Good Stylix integration
    
    # Terminal Multiplexer - Core supported target
    tmux.enable = true;              # ENABLED: Native Stylix support
    
    # Disable unsupported or conflicting targets
    vim.enable = false;              # DISABLED: Using Neovim instead
    firefox.enable = false;          # DISABLED: Not our primary browser
  };
}
