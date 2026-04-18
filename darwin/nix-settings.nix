{
  lib,
  userConfig,
  pkgs,
  ...
}:
{
  # Nix daemon, cache, garbage collection, and rebuild performance settings.

  nix.enable = true;

  nix.settings = {
    # Performance tuning - OPTIMIZED
    max-jobs = "auto"; # Let Nix determine optimal job count based on CPU cores
    cores = 0; # Use all available cores per job (0 = all cores)

    # Build acceleration
    keep-derivations = true; # Keep build dependencies for faster rebuilds
    keep-outputs = true; # Keep build outputs to avoid rebuilds
    keep-failed = false; # Don't keep failed builds (saves space)

    # Evaluation caching for faster flake evaluation
    eval-cache = true; # Enable evaluation cache (default, but explicit)

    # Network optimization
    # 5s is too aggressive for real-world cache DNS/network jitter and causes
    # rebuilds to fail even when the cache is healthy.
    connect-timeout = 15;
    download-attempts = 5;
    download-buffer-size = 536870912; # 512 MiB for large binary cache fetches

    # Substituters for binary cache (performance critical)
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];

    # Trust specific users
    trusted-users = [
      "root"
      userConfig.username
    ];

    # Modern features for better performance
    experimental-features = [
      "nix-command"
      "flakes"
      "auto-allocate-uids" # Better sandbox performance
      "cgroups" # Better resource management
    ];

    # Sandbox settings for better isolation and caching
    sandbox = true; # Enable sandboxing (macOS default)

    # Build optimization
    builders-use-substitutes = true; # Allow builders to use substitutes

    # Memory and disk optimization
    min-free = 1073741824; # Keep 1GB free (1024^3 bytes)
    max-free = 3221225472; # Keep max 3GB free (3 * 1024^3 bytes)

    # Log settings for debugging performance issues
    log-lines = 50; # Show more log lines for build failures

    # Additional performance settings
    build-timeout = 86400; # 24 hours build timeout (generous for large builds)
    stalled-download-timeout = 300; # 5 minutes for stalled downloads

    # Automatic store optimization
    # auto-optimise-store = true; # Deprecated - use nix.optimise.automatic instead
  };

  # Garbage collection optimization
  nix.gc = {
    automatic = true;
    interval = {
      Day = 1;
    }; # Daily garbage collection
    options = "--delete-older-than 7d"; # Keep builds from last 7 days
  };

  # Auto-upgrade for security and performance improvements
  nix.optimise = {
    automatic = true;
    interval = {
      Day = 1;
    }; # Daily store optimization
  };

  # nix-darwin's default kickstart path can fail if launchd briefly unloads the
  # daemon during service reload. Bootstrap the plist again before retrying.
  system.activationScripts.nix-daemon.text = lib.mkForce ''
    if [[ -e /etc/nix/nix.custom.conf ]]; then
      mv /etc/nix/nix.custom.conf{,.before-nix-darwin}
    fi

    if ! diff /etc/nix/nix.conf /run/current-system/etc/nix/nix.conf &> /dev/null || ! diff /etc/nix/machines /run/current-system/etc/nix/machines &> /dev/null; then
      echo "reloading nix-daemon..." >&2
      launchctl kill HUP system/org.nixos.nix-daemon 2>/dev/null || true
    fi

    while ! nix-store --store daemon -q --hash ${pkgs.stdenv.shell} &>/dev/null; do
      echo "waiting for nix-daemon" >&2
      if ! launchctl kickstart system/org.nixos.nix-daemon 2>/dev/null; then
        launchctl bootstrap system /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
        launchctl enable system/org.nixos.nix-daemon 2>/dev/null || true
        launchctl kickstart system/org.nixos.nix-daemon 2>/dev/null || true
      fi
      sleep 1
    done
  '';
}
