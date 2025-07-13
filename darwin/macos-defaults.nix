{...}: {
  # macOS System Defaults - Minimal configuration with only verified options

  system.defaults = {
    finder = {
      FXPreferredViewStyle = "clmv"; # Column view
      AppleShowAllFiles = true; # Show hidden files
      ShowPathbar = true; # Show path bar
      ShowStatusBar = true; # Show status bar
      _FXShowPosixPathInTitle = true; # Show full path
      CreateDesktop = true; # Show desktop icons
    };

    loginwindow = {
      GuestEnabled = false; # Disable guest login
    };

    NSGlobalDomain = {
      AppleICUForce24HourTime = true; # Use 24-hour time
      AppleInterfaceStyle = "Dark"; # Dark mode
      KeyRepeat = 2; # Fast key repeat
      InitialKeyRepeat = 15; # Initial key repeat delay
      ApplePressAndHoldEnabled = false; # Disable press and hold for accents
      NSAutomaticSpellingCorrectionEnabled = false; # Disable auto spelling correction
      NSDocumentSaveNewDocumentsToCloud = false; # Don't save to iCloud by default
    };

    dock = {
      show-recents = false; # Hide recent items section
      autohide = false; # Don't auto-hide dock
      magnification = true; # Enable dock magnification
      minimize-to-application = true; # Minimize windows to application
      orientation = "bottom"; # Dock position
      tilesize = 48; # Dock icon size
    };

    trackpad = {
      Clicking = true; # Enable tap to click
      TrackpadRightClick = true; # Right click
      TrackpadThreeFingerDrag = false; # Disable three finger drag to preserve swipes
    };

    screensaver = {
      askForPassword = true; # Require password after screensaver
      askForPasswordDelay = 0; # Immediate password requirement
    };
  };

  # 🇬🇧 UK-SPECIFIC NOTES:
  # The following need to be set manually in System Preferences:
  # - Language & Region → Region: United Kingdom
  # - Language & Region → First day of week: Monday
  # - Language & Region → Currency: British Pound (£)
  # - Language & Region → Temperature: Celsius
  # - Language & Region → Measurement system: Metric
  # - Date & Time → Time zone: Europe/London
  # - Trackpad → More Gestures → Configure three-finger swipes for Mission Control
  # - Trackpad → Point & Click → Enable drag lock if desired
}
