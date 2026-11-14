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
}:
let
  homeDir = config.home.homeDirectory;
  dotfileDir = "${homeDir}/${userConfig.directories.dotfiles}";
  inherit (helpers) mkPlatformAliases mkTemplateAlias;
in
# ==========================================================================
# macOS Aliases
# ==========================================================================
let
  mkDotfileSubshell = script: "(cd ${dotfileDir} && ${script})";
in
(mkPlatformAliases "darwin" {
  # --------------------------------------------------------------------------
  # System Rebuild
  # --------------------------------------------------------------------------
  rebuild-fast = "rebuild && rl"; # Rebuild using rebuild-system.sh and reload shell

  rebuild-check =
    mkTemplateAlias
      ''
        (cd @dotfileDir@ && \
        echo "🔍 Checking what will be built..." && \
        darwin-rebuild build --flake .#"${userConfig.hostname}" --dry-run --option sandbox relaxed --option max-jobs auto)
      ''
      [
        {
          name = "dotfileDir";
          value = dotfileDir;
        }
      ]; # Dry run to preview what would be rebuilt

  # --------------------------------------------------------------------------
  # Rollback with Interactive Selection
  # --------------------------------------------------------------------------
  rollback = "bash ${../scripts/system-rollback.sh}"; # Interactively select and rollback to previous system generation

  # --------------------------------------------------------------------------
  # System Cleanup
  # --------------------------------------------------------------------------
  cleanup = "bash ${../scripts/cleanup-system.sh}"; # Confirmed cleanup command; supports --docker, --deep, and --help

  # --------------------------------------------------------------------------
  # Performance Analysis
  # --------------------------------------------------------------------------
  perf-analyze = mkDotfileSubshell "./scripts/monitoring/analyze-build-performance.sh --report"; # Generate build performance report
  perf-profile = mkDotfileSubshell "./scripts/monitoring/analyze-build-performance.sh --profile"; # Profile build performance with detailed metrics
  perf-optimize = mkDotfileSubshell "./scripts/monitoring/analyze-build-performance.sh --optimize"; # Run build optimization recommendations

  # --------------------------------------------------------------------------
  # Health Monitoring
  # --------------------------------------------------------------------------
  health-check = mkDotfileSubshell "./scripts/monitoring/system-health-monitor.sh --check"; # Run system health check
  health-report = mkDotfileSubshell "./scripts/monitoring/system-health-monitor.sh --report"; # Generate system health report
  health-maintain = mkDotfileSubshell "./scripts/monitoring/system-health-monitor.sh --maintain"; # Run manual maintenance tasks
  health-alert = mkDotfileSubshell "./scripts/monitoring/system-health-monitor.sh --alert"; # Check and show critical alerts

  # --------------------------------------------------------------------------
  # Finder Utilities
  # --------------------------------------------------------------------------
  showhidden = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"; # Show hidden files in Finder
  hidehidden = "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"; # Hide hidden files in Finder
  showdesktop = "defaults write com.apple.finder CreateDesktop -bool true && killall Finder"; # Show desktop icons
  hidedesktop = "defaults write com.apple.finder CreateDesktop -bool false && killall Finder"; # Hide desktop icons

  # --------------------------------------------------------------------------
  # macOS System Utilities
  # --------------------------------------------------------------------------
  flushdns = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"; # Flush DNS cache
  sleepnow = "pmset sleepnow"; # Put Mac to sleep immediately
  lockscreen = "pmset displaysleepnow"; # Lock screen / sleep display immediately
})
