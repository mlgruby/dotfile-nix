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
}: {
  # System health monitoring with launchd
  launchd.user.agents = {
    # Nix daemon startup check - runs at login to ensure daemon is working
    nix-daemon-startup = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "/Users/${userConfig.username}/${userConfig.directories.dotfiles}/scripts/utils/nix-daemon-startup.sh"
        ];
        RunAtLoad = true; # Run when user logs in
        StandardOutPath = "/Users/${userConfig.username}/.local/var/log/nix-daemon-startup.out.log";
        StandardErrorPath = "/Users/${userConfig.username}/.local/var/log/nix-daemon-startup.error.log";
      };
    };
    # Daily health check service
    system-health-check = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "cd /Users/${userConfig.username}/${userConfig.directories.dotfiles} && ./scripts/system-health-monitor.sh --check"
        ];
        StartCalendarInterval = [
          {
            Hour = 9;
            Minute = 0;
          } # 9:00 AM daily
        ];
        RunAtLoad = false;
        StandardOutPath = "/Users/${userConfig.username}/.local/var/log/system-health-check.log";
        StandardErrorPath = "/Users/${userConfig.username}/.local/var/log/system-health-check.error.log";
      };
    };

    # Weekly maintenance service
    system-maintenance = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "cd /Users/${userConfig.username}/${userConfig.directories.dotfiles} && ./scripts/monitoring/system-health-monitor.sh --maintain"
        ];
        StartCalendarInterval = [
          {
            Weekday = 0; # Sunday
            Hour = 10;
            Minute = 0;
          } # 10:00 AM every Sunday
        ];
        RunAtLoad = false;
        StandardOutPath = "/Users/${userConfig.username}/.local/var/log/system-maintenance.log";
        StandardErrorPath = "/Users/${userConfig.username}/.local/var/log/system-maintenance.error.log";
      };
    };

    # Performance monitoring service (lightweight, frequent)
    performance-monitor = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "cd /Users/${userConfig.username}/${userConfig.directories.dotfiles} && ./scripts/monitoring/analyze-build-performance.sh --profile"
        ];
        StartCalendarInterval = [
          {
            Hour = 12;
            Minute = 0;
          } # Noon daily
        ];
        RunAtLoad = false;
        StandardOutPath = "/Users/${userConfig.username}/.local/var/log/performance-monitor.log";
        StandardErrorPath = "/Users/${userConfig.username}/.local/var/log/performance-monitor.error.log";
      };
    };

    # Critical alerts check (more frequent for urgent issues)
    critical-alerts = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "cd /Users/${userConfig.username}/${userConfig.directories.dotfiles} && ./scripts/monitoring/system-health-monitor.sh --alert"
        ];
        StartCalendarInterval = [
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
        RunAtLoad = false;
        StandardOutPath = "/Users/${userConfig.username}/.local/var/log/critical-alerts.log";
        StandardErrorPath = "/Users/${userConfig.username}/.local/var/log/critical-alerts.error.log";
      };
    };
  };

  # Create log directories
  system.activationScripts.createMonitoringDirectories = {
    text = ''
      echo "Setting up system monitoring directories..."
      
      # Create log directories
      mkdir -p "/Users/${userConfig.username}/.local/var/log"
      chown ${userConfig.username}:staff "/Users/${userConfig.username}/.local/var/log"
      
      # Create health reports directory
      mkdir -p "/Users/${userConfig.username}/${userConfig.directories.dotfiles}/.health-reports"
      chown ${userConfig.username}:staff "/Users/${userConfig.username}/${userConfig.directories.dotfiles}/.health-reports"
      
      # Create performance reports directory if it doesn't exist
      mkdir -p "/Users/${userConfig.username}/${userConfig.directories.dotfiles}/.performance-reports"
      chown ${userConfig.username}:staff "/Users/${userConfig.username}/${userConfig.directories.dotfiles}/.performance-reports"
      
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
    HEALTH_REPORTS_DIR = "/Users/${userConfig.username}/${userConfig.directories.dotfiles}/.health-reports";
    PERFORMANCE_REPORTS_DIR = "/Users/${userConfig.username}/${userConfig.directories.dotfiles}/.performance-reports";
    SYSTEM_LOG_DIR = "/Users/${userConfig.username}/.local/var/log";
  };

  # Warning for manual setup
  warnings = [
    "System monitoring services have been configured"
    "Check logs in ~/.local/var/log/ for monitoring output"
    "Use 'launchctl list | grep system-' to verify services are running"
  ];
}
