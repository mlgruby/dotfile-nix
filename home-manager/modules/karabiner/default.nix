# home-manager/modules/karabiner/default.nix
#
# Karabiner-Elements keyboard customization
#
# Purpose:
# - Provides custom keyboard shortcuts for application launching
# - Manages Karabiner-Elements configuration
# - Creates consistent keyboard behavior across apps
#
# Features:
# - Custom key mappings
# - Complex modifications
# - Device-specific settings
# - Profile management
#
# Shortcuts:
# Command + Shift +
#   Enter -> Alacritty (Terminal)
#   I     -> IntelliJ IDEA
#   P     -> PyCharm
#   S     -> Slack
#   C     -> Cursor
#   G     -> Google Chrome
#   B     -> Brave Browser
#
# Integration:
# - Works with macOS application management
# - Compatible with other keyboard customizations
# - Supports multiple profiles and devices
#
# Note:
# - Requires Karabiner-Elements to be installed (homebrew.nix)
# - Configuration stored in ~/.config/karabiner/

{ config, lib, pkgs, ... }:

{
  # Custom Modification Rules
  # Defines application launching shortcuts
  home.file.".config/karabiner/assets/complex_modifications/custom.json".text = builtins.toJSON {
    title = "Custom Rules";
    rules = [
      # Terminal Emulator
      {
        description = "Open Alacritty with Command + Shift + Enter";
        manipulators = [{
          type = "basic";
          from = {
            key_code = "return_or_enter";
            modifiers = {
              mandatory = ["command" "shift"];
              optional = ["any"];
            };
          };
          to = [{
            shell_command = "osascript -e 'tell application \"Alacritty\" to activate'";
          }];
        }];
      }
      # Development IDEs
      {
        description = "Open IntelliJ with Command + Shift + I";
        manipulators = [{
          type = "basic";
          from = {
            key_code = "i";
            modifiers = {
              mandatory = ["command" "shift"];
              optional = ["any"];
            };
          };
          to = [{
            shell_command = "osascript -e 'tell application \"IntelliJ IDEA\" to activate'";
          }];
        }];
      }
      {
        description = "Open PyCharm with Command + Shift + P";
        manipulators = [{
          type = "basic";
          from = {
            key_code = "p";
            modifiers = {
              mandatory = ["command" "shift"];
              optional = ["any"];
            };
          };
          to = [{
            shell_command = "osascript -e 'tell application \"PyCharm\" to activate'";
          }];
        }];
      }
      # Communication Tools
      {
        description = "Open Slack with Command + Shift + S";
        manipulators = [{
          type = "basic";
          from = {
            key_code = "s";
            modifiers = {
              mandatory = ["command" "shift"];
              optional = ["any"];
            };
          };
          to = [{
            shell_command = "osascript -e 'tell application \"Slack\" to activate'";
          }];
        }];
      }
      # Development Tools
      {
        description = "Open Cursor with Command + Shift + C";
        manipulators = [{
          type = "basic";
          from = {
            key_code = "c";
            modifiers = {
              mandatory = ["command" "shift"];
              optional = ["any"];
            };
          };
          to = [{
            shell_command = "osascript -e 'tell application \"Cursor\" to activate'";
          }];
        }];
      }
      # Web Browsers
      {
        description = "Open Google Chrome with Command + Shift + G";
        manipulators = [{
          type = "basic";
          from = {
            key_code = "g";
            modifiers = {
              mandatory = ["command" "shift"];
              optional = ["any"];
            };
          };
          to = [{
            shell_command = "osascript -e 'tell application \"Google Chrome\" to activate'";
          }];
        }];
      }
      {
        description = "Open Brave Browser with Command + Shift + B";
        manipulators = [{
          type = "basic";
          from = {
            key_code = "b";
            modifiers = {
              mandatory = ["command" "shift"];
              optional = ["any"];
            };
          };
          to = [{
            shell_command = "osascript -e 'tell application \"Brave Browser\" to activate'";
          }];
        }];
      }
    ];
  };

  # Karabiner Initial Configuration
  # Sets up default configuration if none exists
  # This ensures a consistent starting point
  home.activation.setupKarabiner = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.config/karabiner/karabiner.json" ]; then
      mkdir -p "$HOME/.config/karabiner"
      cat > "$HOME/.config/karabiner/karabiner.json" << 'EOF'
      {
        "global": {
          "check_for_updates_on_startup": true,
          "show_in_menu_bar": true,
          "show_profile_name_in_menu_bar": false
        },
        "preferences": {
          "keyboard_type_if_empty": "iso"
        },
        "profiles": [
          {
            "name": "Default",
            "selected": true,
            "simple_modifications": [],
            "complex_modifications": {
              "parameters": {
                "basic.simultaneous_threshold_milliseconds": 50
              },
              "rules": []
            }
          }
        ]
      }
EOF
    fi
  '';
}
