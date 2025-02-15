# home-manager/modules/karabiner/default.nix
#
# Karabiner-Elements keyboard customization
#
# Features:
# - Custom key mappings
# - Complex modifications
# - Device-specific settings
# - Profile management

{ config, lib, pkgs, ... }:

{
  # Create a directory for our custom rules
  home.file.".config/karabiner/assets/complex_modifications/custom.json".text = builtins.toJSON {
    title = "Custom Rules";
    rules = [
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

  # Create initial configuration if it doesn't exist
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