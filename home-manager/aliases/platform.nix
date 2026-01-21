# home-manager/aliases/platform.nix
#
# Platform-Specific Aliases
#
# Purpose:
# - macOS system management (rebuild, update, cleanup)
# - Linux NixOS management
# - Platform-specific utilities
#
# macOS Features:
# - darwin-rebuild integration
# - Finder utilities
# - System maintenance
{
  config,
  userConfig,
  helpers,
  ...
}: let
  homeDir = config.home.homeDirectory;
  dotfileDir = "${homeDir}/${userConfig.directories.dotfiles}";
  inherit (helpers) mkPlatformAliases mkTemplateAlias;
in
  # ==========================================================================
  # macOS Aliases
  # ==========================================================================
  (mkPlatformAliases "darwin" {
    # --------------------------------------------------------------------------
    # System Rebuild
    # --------------------------------------------------------------------------
    rebuild = "cd ${dotfileDir} && echo '🔄 Building system configuration...' && sudo darwin-rebuild switch --flake .#\"$(hostname)\" && cd - && echo '✅ System rebuild complete!' && rl";  # Rebuild and activate system configuration

    rebuild-fast = mkTemplateAlias ''
      cd @dotfileDir@ && \
      echo "🚀 Fast rebuild with maximum performance..." && \
      sudo darwin-rebuild switch --flake .#"$(hostname)" --option max-jobs auto --option cores 0 --option keep-outputs true --option keep-derivations true && \
      cd - && \
      echo "⚡ Fast rebuild complete!" && \
      rl
    '' [
      {name = "dotfileDir"; value = dotfileDir;}
    ];  # Rebuild with parallel builds and caching optimizations

    rebuild-check = mkTemplateAlias ''
      cd @dotfileDir@ && \
      echo "🔍 Checking what will be built..." && \
      darwin-rebuild build --flake .#"$(hostname)" --dry-run --option max-jobs auto && \
      cd -
    '' [
      {name = "dotfileDir"; value = dotfileDir;}
    ];  # Dry run to preview what would be rebuilt

    # --------------------------------------------------------------------------
    # System Update
    # --------------------------------------------------------------------------
    update = "echo '🔄 Starting system update...' && cd ${dotfileDir} && nix flake update && rebuild && echo '✨ System update complete!'";  # Update flake lockfile and rebuild system

    # --------------------------------------------------------------------------
    # Rollback with Interactive Selection
    # --------------------------------------------------------------------------
    rollback = "${homeDir}/.config/home-manager/scripts/system-rollback.sh";  # Interactively select and rollback to previous system generation

    # --------------------------------------------------------------------------
    # System Cleanup
    # --------------------------------------------------------------------------
    cleanup = mkTemplateAlias ''
      echo "🧹 Starting comprehensive system cleanup..." && \
      echo "🗑️  Running Nix garbage collection..." && \
      nix-collect-garbage -d --option max-jobs auto --option cores 0 && \
      echo "✓ Nix garbage collection complete" && \
      echo "🧹 Cleaning macOS system files..." && \
      find @homeDir@ -type f -name '.DS_Store' -delete 2>/dev/null || true && \
      find @homeDir@ -type f -name '._*' -delete 2>/dev/null || true && \
      echo "🧹 Cleaning package caches..." && \
      command -v npm &> /dev/null && npm cache clean --force 2>/dev/null || true && \
      command -v brew &> /dev/null && brew cleanup 2>/dev/null || true && \
      command -v uv &> /dev/null && @homeDir@/.local/bin/uv cache clean 2>/dev/null || true && \
      echo "🧹 Optimizing Nix store..." && \
      nix store optimise --option max-jobs auto --option cores 0 && \
      echo "✨ Cleanup complete!" && \
      rl
    '' [
      {name = "homeDir"; value = homeDir;}
    ];  # Clean old Nix generations, package caches, and macOS temp files

    # --------------------------------------------------------------------------
    # Performance Analysis
    # --------------------------------------------------------------------------
    perf-analyze = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/analyze-build-performance.sh --report && \
      cd -
    '' [
      {name = "dotfileDir"; value = dotfileDir;}
    ];  # Generate build performance report

    perf-profile = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/analyze-build-performance.sh --profile && \
      cd -
    '' [
      {name = "dotfileDir"; value = dotfileDir;}
    ];  # Profile build performance with detailed metrics

    perf-optimize = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/analyze-build-performance.sh --optimize && \
      cd -
    '' [
      {name = "dotfileDir"; value = dotfileDir;}
    ];  # Run build optimization recommendations

    # --------------------------------------------------------------------------
    # Health Monitoring
    # --------------------------------------------------------------------------
    health-check = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/system-health-monitor.sh --check && \
      cd -
    '' [
      {name = "dotfileDir"; value = dotfileDir;}
    ];  # Run system health check

    health-report = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/system-health-monitor.sh --report && \
      cd -
    '' [
      {name = "dotfileDir"; value = dotfileDir;}
    ];  # Generate system health report

    health-maintain = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/system-health-monitor.sh --maintain && \
      cd -
    '' [
      {name = "dotfileDir"; value = dotfileDir;}
    ];  # Run automated maintenance tasks

    health-alert = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/system-health-monitor.sh --alert && \
      cd -
    '' [
      {name = "dotfileDir"; value = dotfileDir;}
    ];  # Check and show critical alerts

    # --------------------------------------------------------------------------
    # Log Viewing
    # --------------------------------------------------------------------------
    logs-health = "tail -f ~/.local/var/log/system-health-check.log";         # Follow health check logs
    logs-maintenance = "tail -f ~/.local/var/log/system-maintenance.log";     # Follow maintenance logs
    logs-performance = "tail -f ~/.local/var/log/performance-monitor.log";    # Follow performance logs
    logs-alerts = "tail -f ~/.local/var/log/critical-alerts.log";             # Follow critical alert logs

    # --------------------------------------------------------------------------
    # Service Management
    # --------------------------------------------------------------------------
    monitor-status = "launchctl list | grep system-";                         # Show status of monitoring services
    monitor-load = "launchctl load ~/Library/LaunchAgents/system-*.plist";    # Load monitoring services
    monitor-unload = "launchctl unload ~/Library/LaunchAgents/system-*.plist";  # Unload monitoring services

    # --------------------------------------------------------------------------
    # Finder Utilities
    # --------------------------------------------------------------------------
    showhidden = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";     # Show hidden files in Finder
    hidehidden = "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder";    # Hide hidden files in Finder
    showdesktop = "defaults write com.apple.finder CreateDesktop -bool true && killall Finder";        # Show desktop icons
    hidedesktop = "defaults write com.apple.finder CreateDesktop -bool false && killall Finder";       # Hide desktop icons

    # --------------------------------------------------------------------------
    # macOS System Utilities
    # --------------------------------------------------------------------------
    flushdns = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder";                               # Flush DNS cache
    sleepnow = "pmset sleepnow";                                                                                # Put Mac to sleep immediately
    lockscreen = "/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend";  # Lock screen immediately
  })
  //
  # ==========================================================================
  # Linux Aliases
  # ==========================================================================
  (mkPlatformAliases "linux" {
    rebuild = "sudo nixos-rebuild switch --flake ${dotfileDir}#$(hostname)";  # Rebuild NixOS system
    install = "nix-env -iA";                                                   # Install package
    search = "nix search nixpkgs";                                             # Search for packages
    services = "systemctl list-units --type=service";                          # List systemd services
    restart-service = "systemctl restart";                                     # Restart systemd service
    logs = "journalctl -f";                                                    # Follow systemd logs
  })
