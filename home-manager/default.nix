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
# - User-specific settings in hosts.nix profile entries
# - Some features need manual setup
# - Check module docs for details
# - Configuration is declarative
# - Changes require rebuild
{
  config,
  lib,
  pkgs,
  username,
  userConfig,
  ...
}:
let
  compatibilityPackages = import ./lib/compatibility-packages.nix { inherit lib pkgs; };

  mkRebuildWrapper = name: args: {
    inherit name;
    value = {
      text = ''
        #!/usr/bin/env bash
        DOTFILE_DIR="$HOME/${userConfig.directories.dotfiles}"
        CURRENT_CONFIG_HOST="${userConfig.hostname}"
        export DOTFILE_DIR CURRENT_CONFIG_HOST
        exec bash "${./scripts/rebuild-system.sh}" ${args} "$@"
      '';
      executable = true;
    };
  };
in
{
  imports = [
    # Core modules
    ./modules/profile.nix
    ./modules/tmux.nix
    ./modules/zsh.nix
    ./modules/starship.nix
    ./modules/aws-sso.nix
    ./modules/git.nix
    ./modules/github.nix
    ./modules/gpg.nix
    ./modules/claude-code.nix
    ./modules/plugins.nix
    ./modules/opencode.nix
    ./modules/pi.nix
    ./modules/antigravity.nix
    ./modules/programs/btop.nix
    ./modules/programs/eza.nix
    ./modules/programs/bat.nix
    ./modules/programs/ripgrep.nix
    ./modules/programs/jq.nix
    ./modules/programs/bottom.nix
    ./modules/lazygit.nix
    ./modules/alacritty
    ./modules/ghostty.nix
    ./modules/herdr.nix
    ./modules/karabiner
    ./modules/rectangle.nix
    ./modules/ssh.nix
    ./modules/programs/terminal-tools.nix
    ./modules/directory-tools.nix
    ./modules/time-machine.nix
    ./modules/tailscale-automator.nix
    ./modules/package-groups.nix
    ./modules/xdg.nix
    ./modules/fonts.nix
    ./neovim.nix
    ./modules/lazywarden
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "24.05";

    packages = with pkgs; [
      compatibilityPackages.direnv
      compatibilityPackages.pipx
      markdownlint-cli
      # Python Development Environment
      # System-wide Python 3.12 via Homebrew
      # Project-specific versions via uv
      # Scala Build Tool
      sbt
    ];
  };

  programs = {
    ssh.custom = let
      sshConfig = import ./config/ssh.nix;
    in {
      inherit (sshConfig.ssh) bitwardenAgent homelabIdentityFile homelabUser;
      inherit (sshConfig) homelabHosts;
    };

    zsh = {
      enable = true;
      shellAliases = import ./aliases { inherit pkgs config userConfig; };
    };

    home-manager.enable = true;

    direnv = {
      enable = true;
      package = compatibilityPackages.direnv;
      nix-direnv.enable = true;
    };

    claude-code.enable = true;
  };

  gtk.gtk4.theme = null;

  # Stylix currently reports release 26.05 while Home Manager reports 26.11.
  # Keep the targets enabled, but avoid noisy release warnings until Stylix
  # publishes matching 26.11 release metadata.
  stylix.enableReleaseChecks = false;

  # Optimized Stylix Target Configuration
  # Conservative approach using only confirmed working targets
  # Based on applications we have configured and Stylix documentation
  stylix.targets = {
    # Terminal Applications - Carefully managed due to custom configs
    alacritty.enable = false; # DISABLED: Complex custom config conflicts with Stylix

    # Development Tools - Core supported targets
    neovim = {
      enable = true; # ENABLED: Well-supported by Stylix
      plugin = "mini.base16"; # Use recommended plugin
      transparentBackground = {
        main = false; # Keep solid backgrounds for readability
        signColumn = false;
        numberLine = false;
      };
    };

    # System Monitoring - Confirmed supported
    btop.enable = true; # ENABLED: Stylix has native btop support

    # Shell and Prompt - Manual configuration preferred
    starship.enable = false; # DISABLED: Manual color configuration with Stylix integration

    # Text Tools - Core supported targets
    bat.enable = true; # ENABLED: Native Stylix support

    # VCS Tools - Confirmed supported
    lazygit.enable = true; # ENABLED: Good Stylix integration

    # Terminal Multiplexer - Core supported target
    tmux.enable = true; # ENABLED: Native Stylix support

    # Disable unsupported or conflicting targets
    gtk.enable = false; # DISABLED: Keep gtk.gtk4.theme explicitly unmanaged
    vim.enable = false; # DISABLED: Using Neovim instead
    firefox.enable = false; # DISABLED: Not our primary browser
    rofi.enable = false; # DISABLED: Linux launcher, unused on macOS
  };

  # Install shell helper scripts and profile-aware rebuild wrappers.
  home.file = (builtins.listToAttrs [
    (mkRebuildWrapper "bin/rebuild" "")
    (mkRebuildWrapper "bin/rebuild-work" "--work")
    (mkRebuildWrapper "bin/rebuild-personal" "--personal")
  ]);

  # Build the native screenshot utility after Home Manager has written files.
  # Keep the Bash implementation available if this Mac has no working Swift
  # compiler (for example, when Xcode Command Line Tools are not installed).
  home.activation.buildScreenshotUtility = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/bin"
    SWIFT_COMPILER=""
    SWIFT_SDK=""
    if [ -d /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk ]; then
      SWIFT_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
    elif [ -d /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk ]; then
      SWIFT_SDK=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
    fi

    if [ -x /Library/Developer/CommandLineTools/usr/bin/swiftc ]; then
      SWIFT_COMPILER=/Library/Developer/CommandLineTools/usr/bin/swiftc
    elif [ -x /usr/bin/swiftc ]; then
      SWIFT_COMPILER=/usr/bin/swiftc
    elif command -v swiftc >/dev/null 2>&1; then
      SWIFT_COMPILER=$(command -v swiftc)
    fi

    COMPILED=0
    if [ -n "$SWIFT_COMPILER" ]; then
      SDK_ARG=()
      if [ -n "$SWIFT_SDK" ]; then
        SDK_ARG=(-sdk "$SWIFT_SDK")
      fi
      if env -u DEVELOPER_DIR -u SDKROOT "$SWIFT_COMPILER" "''${SDK_ARG[@]}" -O ${./scripts/screenshots/capture-and-copy-screenshot.swift} \
        -o "$HOME/bin/capture-and-copy-screenshot" 2>/dev/null; then
        chmod +x "$HOME/bin/capture-and-copy-screenshot"
        COMPILED=1
      fi
    fi

    if [ "$COMPILED" -ne 1 ]; then
      echo "warning: Swift compiler unavailable or compilation failed; installing shell screenshot fallback"
      cat <<'EOF' > "$HOME/bin/capture-and-copy-screenshot"
#!/usr/bin/env bash
set -euo pipefail
SHOT_DIR="$HOME/Screenshots"
mkdir -p "$SHOT_DIR"
FILE="$SHOT_DIR/Screenshot $(date '+%Y-%m-%d at %H.%M.%S').png"
if /usr/sbin/screencapture -i -x "$FILE" && [ -s "$FILE" ]; then
  osascript -e "set the clipboard to (read (POSIX file \"$FILE\") as «class PNG »)" 2>/dev/null || true
  afplay "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif" 2>/dev/null || true
fi
EOF
      chmod +x "$HOME/bin/capture-and-copy-screenshot"
    fi
  '';
}
