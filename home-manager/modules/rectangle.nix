# home-manager/modules/rectangle.nix
#
# Rectangle Window Manager
#
# Purpose:
# - Sets up window shortcuts
# - Configures window layouts
#
# Integration:
# - App from Homebrew
# - System-wide shortcuts
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
        "bundleId": "com.knollsoft.Rectangle",
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
        "shortcuts": {
          "bottomHalf": {
            "keyCode": 125,
            "modifierFlags": 786432
          },
          "bottomLeft": {
            "keyCode": 38,
            "modifierFlags": 786432
          },
          "bottomRight": {
            "keyCode": 40,
            "modifierFlags": 786432
          },
          "center": {
            "keyCode": 8,
            "modifierFlags": 786432
          },
          "centerThird": {
            "keyCode": 3,
            "modifierFlags": 786432
          },
          "firstThird": {
            "keyCode": 2,
            "modifierFlags": 786432
          },
          "firstTwoThirds": {
            "keyCode": 14,
            "modifierFlags": 786432
          },
          "larger": {
            "keyCode": 24,
            "modifierFlags": 786432
          },
          "lastThird": {
            "keyCode": 5,
            "modifierFlags": 786432
          },
          "lastTwoThirds": {
            "keyCode": 17,
            "modifierFlags": 786432
          },
          "leftHalf": {
            "keyCode": 123,
            "modifierFlags": 786432
          },
          "maximize": {
            "keyCode": 36,
            "modifierFlags": 786432
          },
          "maximizeHeight": {
            "keyCode": 126,
            "modifierFlags": 917504
          },
          "nextDisplay": {
            "keyCode": 124,
            "modifierFlags": 1835008
          },
          "previousDisplay": {
            "keyCode": 123,
            "modifierFlags": 1835008
          },
          "rightHalf": {
            "keyCode": 124,
            "modifierFlags": 786432
          },
          "smaller": {
            "keyCode": 27,
            "modifierFlags": 786432
          },
          "topHalf": {
            "keyCode": 126,
            "modifierFlags": 786432
          },
          "topLeft": {
            "keyCode": 32,
            "modifierFlags": 786432
          },
          "topRight": {
            "keyCode": 34,
            "modifierFlags": 786432
          }
        },
        "version": "92"
      }
    '';
  };
}
