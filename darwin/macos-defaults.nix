{ ... }:
{
  # macOS System Defaults - Minimal configuration with only verified options

  system.defaults = {
    finder = {
      FXPreferredViewStyle = "clmv"; # Column view
      AppleShowAllFiles = true; # Show hidden files
      AppleShowAllExtensions = true; # Show file extensions
      ShowPathbar = true; # Show path bar
      ShowStatusBar = true; # Show status bar
      _FXShowPosixPathInTitle = true; # Show full path
      _FXSortFoldersFirst = true; # Keep folders first when sorting
      CreateDesktop = true; # Show desktop icons
      FXDefaultSearchScope = "SCcf"; # Search current folder by default
      FXEnableExtensionChangeWarning = false; # Do not warn when changing extensions
      ShowExternalHardDrivesOnDesktop = true; # Show external disks on desktop
      ShowHardDrivesOnDesktop = false; # Hide internal disks on desktop
      ShowRemovableMediaOnDesktop = true; # Show removable media on desktop
    };

    loginwindow = {
      GuestEnabled = false; # Disable guest login
    };

    NSGlobalDomain = {
      AppleICUForce24HourTime = true; # Use 24-hour time
      AppleInterfaceStyle = "Dark"; # Dark mode
      AppleMeasurementUnits = "Centimeters"; # Metric measurement units
      AppleMetricUnits = 1; # Use metric units
      AppleTemperatureUnit = "Celsius"; # Use Celsius
      KeyRepeat = 2; # Fast key repeat
      InitialKeyRepeat = 15; # Initial key repeat delay
      ApplePressAndHoldEnabled = false; # Disable press and hold for accents
      NSAutomaticCapitalizationEnabled = false; # Disable auto capitalization
      NSAutomaticDashSubstitutionEnabled = false; # Disable dash substitution
      NSAutomaticPeriodSubstitutionEnabled = false; # Disable double-space period substitution
      NSAutomaticQuoteSubstitutionEnabled = false; # Disable smart quotes
      NSAutomaticSpellingCorrectionEnabled = false; # Disable auto spelling correction
      NSDocumentSaveNewDocumentsToCloud = false; # Don't save to iCloud by default
      "com.apple.swipescrolldirection" = false; # Disable natural scrolling
      "com.apple.trackpad.forceClick" = true; # Enable Force Click
      "com.apple.trackpad.scaling" = 2.5; # Match current trackpad speed
    };

    dock = {
      show-recents = false; # Hide recent items section
      autohide = false; # Don't auto-hide dock
      expose-group-apps = true; # Group Mission Control windows by app
      mru-spaces = false; # Keep Spaces order stable
      magnification = true; # Enable dock magnification
      largesize = 72; # Magnified icon size
      minimize-to-application = true; # Minimize windows to application
      orientation = "bottom"; # Dock position
      show-process-indicators = true; # Show running app indicators
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

    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleLanguages = [ "en-GB" ];
        AppleLocale = "en_GB";
        AppleFirstWeekday = {
          gregorian = 2; # Monday
        };
      };
    };
  };

  # 🇬🇧 UK-SPECIFIC NOTES:
  # The following are owned declaratively above:
  # - Language & Region → Region: United Kingdom
  # - Language & Region → First day of week: Monday
  # - Language & Region → Temperature: Celsius
  # - Language & Region → Measurement system: Metric
  # The following still need to be set manually if they drift:
  # - Language & Region → Currency: British Pound (£)
  # - Date & Time → Time zone: Europe/London
  # - Trackpad → More Gestures → Configure three-finger swipes for Mission Control
  # - Trackpad → Point & Click → Enable drag lock if desired
}
