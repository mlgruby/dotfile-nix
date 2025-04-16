{ config, pkgs, lib, userConfig, ... }:

{
  # macOS System Defaults extracted from flake.nix inline module

  system.defaults = {
    finder = {
      FXPreferredViewStyle = "clmv";        # Column view
      AppleShowAllFiles = true;             # Show hidden files
      ShowPathbar = true;                   # Show path bar
      ShowStatusBar = true;                 # Show status bar
      _FXShowPosixPathInTitle = true;       # Show full path
      CreateDesktop = true;                 # Show desktop icons
    };
    
    loginwindow = {
      GuestEnabled = false;                 # Disable guest login
    };
    
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;       # Use 24-hour time
      AppleInterfaceStyle = "Dark";         # Dark mode
      KeyRepeat = 2;                        # Fast key repeat
    };
  };
}
