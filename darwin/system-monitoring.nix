# darwin/system-monitoring.nix
#
# System Health Monitoring Configuration
#
# Purpose:
# - Automated system health monitoring
# - Scheduled maintenance tasks
# - Performance monitoring and alerts
# - Integration with Nix Darwin
#
# Features:
# - Daily health checks
# - Weekly maintenance automation
# - Critical issue alerts
# - Performance trending
#
# Services:
# - Health monitoring (daily)
# - System maintenance (weekly)
# - Performance analysis (daily)
# - Critical alerts (continuous)
{
  config,
  pkgs,
  userConfig,
  ...
}:
let
  homeDir = "/Users/${userConfig.username}";
  dotfileDir = "${homeDir}/${userConfig.directories.dotfiles}";
  logDir = "${homeDir}/.local/var/log";
  healthReportsDir = "${dotfileDir}/.health-reports";
  performanceReportsDir = "${dotfileDir}/.performance-reports";

  mkLogPath = name: "${logDir}/${name}.log";
  mkScriptCommand = script: args: "cd ${dotfileDir} && ./${script} ${args}";
  mkAgent =
    {
      command,
      logName,
      calendar ? null,
      runAtLoad ? false,
    }:
    {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          command
        ];
        RunAtLoad = runAtLoad;
        StandardOutPath = mkLogPath logName;
        StandardErrorPath = mkLogPath "${logName}.error";
      }
      // (if calendar == null then { } else { StartCalendarInterval = calendar; });
    };
in
{
  # System health monitoring with launchd
  launchd.user.agents = {
    # Nix daemon startup check - runs at login to ensure daemon is working
    nix-daemon-startup = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "${dotfileDir}/scripts/utils/nix-daemon-startup.sh"
        ];
        RunAtLoad = true; # Run when user logs in
        StandardOutPath = mkLogPath "nix-daemon-startup";
        StandardErrorPath = mkLogPath "nix-daemon-startup.error";
      };
    };

    # Daily health check service
    system-health-check = mkAgent {
      command = mkScriptCommand "scripts/monitoring/system-health-monitor.sh" "--check";
      logName = "system-health-check";
      calendar = [
        {
          Hour = 9;
          Minute = 0;
        } # 9:00 AM daily
      ];
    };

    # Weekly report service. Mutating maintenance stays manual via health-maintain.
    system-health-report = mkAgent {
      command = mkScriptCommand "scripts/monitoring/system-health-monitor.sh" "--report";
      logName = "system-health-report";
      calendar = [
        {
          Weekday = 0; # Sunday
          Hour = 10;
          Minute = 0;
        } # 10:00 AM every Sunday
      ];
    };

    # Performance monitoring service (lightweight, frequent)
    performance-monitor = mkAgent {
      command = mkScriptCommand "scripts/monitoring/analyze-build-performance.sh" "--profile";
      logName = "performance-monitor";
      calendar = [
        {
          Hour = 12;
          Minute = 0;
        } # Noon daily
      ];
    };

    # Critical alerts check (more frequent for urgent issues)
    critical-alerts = mkAgent {
      command = mkScriptCommand "scripts/monitoring/system-health-monitor.sh" "--alert";
      logName = "critical-alerts";
      calendar = [
        {
          Hour = 8;
          Minute = 0;
        } # 8:00 AM
        {
          Hour = 14;
          Minute = 0;
        } # 2:00 PM
        {
          Hour = 20;
          Minute = 0;
        } # 8:00 PM
      ];
    };
  };

  # Create log directories
  system.activationScripts.createMonitoringDirectories = {
    text = ''
      echo "Setting up system monitoring directories..."

      # Create log directories
      mkdir -p "${logDir}"
      chown ${userConfig.username}:staff "${logDir}"

      # Create health reports directory
      mkdir -p "${healthReportsDir}"
      chown ${userConfig.username}:staff "${healthReportsDir}"

      # Create performance reports directory if it doesn't exist
      mkdir -p "${performanceReportsDir}"
      chown ${userConfig.username}:staff "${performanceReportsDir}"

      echo "✓ Monitoring directories created"
    '';
  };

  # System packages for monitoring
  environment.systemPackages = with pkgs; [
    # Basic monitoring tools
    htop # Interactive process viewer
    # iotop # I/O monitoring - not available on macOS ARM64
    # iostat # I/O statistics - built-in macOS command
    lsof # List open files

    # Network monitoring
    nmap # Network scanner
    netcat # Network utility

    # System utilities
    tree # Directory structure
    watch # Command monitoring

    # Log analysis
    jq # JSON processing for log parsing

    # Performance analysis
    hyperfine # Command-line benchmarking
  ];

  # Environment variables for monitoring
  environment.variables = {
    # Monitoring configuration
    HEALTH_REPORTS_DIR = healthReportsDir;
    PERFORMANCE_REPORTS_DIR = performanceReportsDir;
    SYSTEM_LOG_DIR = logDir;
  };

  # Warning for manual setup
  warnings = [
    "System monitoring services have been configured"
    "Check logs in ~/.local/var/log/ for monitoring output"
    "Use 'launchctl list | grep system-' to verify services are running"
  ];
}
