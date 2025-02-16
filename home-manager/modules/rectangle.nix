# home-manager/modules/rectangle.nix
#
# Rectangle window management configuration
#
# Purpose:
# - Configures window management shortcuts
# - Provides precise window positioning
# - Enables multi-display window control
#
# Features:
# - Window positioning shortcuts
# - Multi-monitor support
# - Thirds and halves layouts
# - Window resizing controls
#
# Shortcuts (Command + Option +):
# Window Halves:
#   ←  Left half              →  Right half
#   ↑  Top half              ↓  Bottom half
#
# Window Corners:
#   U  Top left              I  Top right
#   J  Bottom left           K  Bottom right
#
# Window Thirds:
#   1  First third           2  Center third
#   3  Last third            Q  First two thirds
#   W  Last two thirds
#
# Window Controls:
#   Return  Maximize         C  Center
#   -      Smaller           =  Larger
#   ↑+Shift Height only
#
# Display Management:
# Command + Control + Option +
#   →  Next display
#   ←  Previous display
#
# Integration:
# - Works with macOS window system
# - Compatible with multiple displays
# - Supports application switching
#
# Note:
# - Requires Rectangle.app (installed via homebrew.nix)
# - Configuration stored in ~/Library/Application Support/Rectangle/

{ config, pkgs, ... }: {
  # Rectangle Configuration
  # Manages window positions and shortcuts
  home.file."Library/Application Support/Rectangle/RectangleConfig.json" = {
    text = ''
      {
        # Application Identity
        "bundleId": "com.knollsoft.Rectangle",
        # Application Settings
        "defaults": {
          "SUEnableAutomaticChecks": {
            "bool": false
          },
          "allowAnyShortcut": {
            "bool": true
          },
          "alternateDefaultShortcuts": {
            "bool": true
          },
          "enhancedUI": {
            "int": 1
          },
          "launchOnLogin": {
            "bool": true
          },
          "subsequentExecutionMode": {
            "int": 1
          }
        },
        # Keyboard Shortcuts Configuration
        "shortcuts": {
          # Basic Window Positions
          "bottomHalf": {
            "keyCode": 125,              # Down Arrow
            "modifierFlags": 786432      # Command + Option
          },
          "bottomLeft": {
            "keyCode": 38,               # J key
            "modifierFlags": 786432
          },
          "bottomRight": {
            "keyCode": 40,               # K key
            "modifierFlags": 786432
          },
          "center": {
            "keyCode": 8,                # C key
            "modifierFlags": 786432
          },
          # Thirds Management
          "centerThird": {
            "keyCode": 3,                # 2 key
            "modifierFlags": 786432
          },
          "firstThird": {
            "keyCode": 2,                # 1 key
            "modifierFlags": 786432
          },
          "firstTwoThirds": {
            "keyCode": 14,               # Q key
            "modifierFlags": 786432
          },
          # Window Sizing
          "larger": {
            "keyCode": 24,               # = key
            "modifierFlags": 786432
          },
          "lastThird": {
            "keyCode": 5,                # 3 key
            "modifierFlags": 786432
          },
          "lastTwoThirds": {
            "keyCode": 17,               # W key
            "modifierFlags": 786432
          },
          # Basic Halves
          "leftHalf": {
            "keyCode": 123,              # Left Arrow
            "modifierFlags": 786432
          },
          # Full Window Controls
          "maximize": {
            "keyCode": 36,               # Return key
            "modifierFlags": 786432
          },
          "maximizeHeight": {
            "keyCode": 126,              # Up Arrow
            "modifierFlags": 917504      # Command + Option + Shift
          },
          # Multi-Display Controls
          "nextDisplay": {
            "keyCode": 124,              # Right Arrow
            "modifierFlags": 1835008     # Command + Control + Option
          },
          "previousDisplay": {
            "keyCode": 123,              # Left Arrow
            "modifierFlags": 1835008     # Command + Control + Option
          },
          "rightHalf": {
            "keyCode": 124,              # Right Arrow
            "modifierFlags": 786432
          },
          "smaller": {
            "keyCode": 27,               # - key
            "modifierFlags": 786432
          },
          "topHalf": {
            "keyCode": 126,              # Up Arrow
            "modifierFlags": 786432
          },
          "topLeft": {
            "keyCode": 32,               # U key
            "modifierFlags": 786432
          },
          "topRight": {
            "keyCode": 34,               # I key
            "modifierFlags": 786432
          }
        },
        # Configuration Version
        "version": "92"
      }
    '';
  };
} 