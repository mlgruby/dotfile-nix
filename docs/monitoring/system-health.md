# System Health Monitoring

This document covers the automated system health monitoring and maintenance setup for your Nix Darwin environment.

## Overview

The system health monitoring provides comprehensive oversight of system performance, automated maintenance, and proactive issue detection. It integrates seamlessly with your Nix Darwin configuration.

## Features

### 🔍 **Health Monitoring**

- **CPU Usage**: Real-time CPU monitoring with configurable thresholds
- **Memory Pressure**: Memory usage tracking and pressure analysis
- **Disk Space**: Storage monitoring across all mounted filesystems
- **Network Connectivity**: Internet and DNS connectivity verification
- **Load Average**: System load monitoring with multi-core awareness
- **Temperature**: CPU temperature monitoring (if tools available)

### 🛠️ **System Maintenance**

- **Nix Store**: Automated garbage collection and store optimization
- **Homebrew**: Package updates, upgrades, and cleanup
- **System Cleanup**: Temporary files, caches, and log cleanup
- **macOS Maintenance**: Spotlight indexing and DNS cache refresh

### 📊 **Performance Analysis**

- **Build Performance**: Nix Darwin rebuild performance tracking
- **System Metrics**: Historical performance trending
- **Resource Utilization**: CPU, memory, and disk usage patterns
- **Process Monitoring**: Top resource-consuming processes

### 🚨 **Alert System**

- **Critical Issues**: Immediate detection of system-critical problems
- **Threshold Monitoring**: Configurable warning thresholds
- **Service Health**: Nix daemon and essential service monitoring
- **Automated Reporting**: Regular health status reports

## Automated Scheduling

The monitoring system runs on the following schedule:

### Daily Tasks

```text
9:00 AM  - System Health Check
12:00 PM - Performance Monitoring
8:00 AM, 2:00 PM, 8:00 PM - Critical Alerts Check
```

### Weekly Tasks

```text
Sunday 10:00 AM - System Maintenance
```

### Services Configuration

All services are managed via launchd and configured in `darwin/system-monitoring.nix`:

- **system-health-check**: Daily comprehensive health assessment
- **system-maintenance**: Weekly automated maintenance tasks
- **performance-monitor**: Daily performance analysis
- **critical-alerts**: Three-times-daily critical issue detection

## Manual Commands

### Health Monitoring Commands

```bash
# Quick health check
health-check

# Comprehensive health report
health-report

# Perform maintenance tasks
health-maintain

# Check for critical issues only
health-alert
```

### Performance Analysis Commands

```bash
# Performance analysis
perf-analyze

# Profile rebuild performance
perf-profile

# Run performance optimizations
perf-optimize
```

### Log Monitoring Commands

```bash
# View health check logs
logs-health

# View maintenance logs
logs-maintenance

# View performance logs
logs-performance

# View critical alerts logs
logs-alerts
```

### Service Management Commands

```bash
# Check monitoring service status
monitor-status

# Load monitoring services
monitor-load

# Unload monitoring services
monitor-unload
```

## Health Check Details

### System Metrics Monitored

#### CPU Usage

- **Threshold**: 80% (configurable)
- **Action**: Warning + top CPU processes display
- **Frequency**: Every health check

#### Memory Usage

- **Threshold**: 85% (configurable)
- **Metrics**: Used memory, memory pressure
- **Action**: Warning + top memory processes display

#### Disk Space

- **Threshold**: 90% per filesystem (configurable)
- **Monitoring**: All mounted filesystems + Nix store size
- **Action**: Warning with cleanup suggestions

#### Load Average

- **Threshold**: 8.0 (configurable, adjust based on CPU cores)
- **Metrics**: 1, 5, and 15-minute load averages
- **Action**: Warning with process analysis

#### Network Connectivity

- **Tests**: Internet connectivity (ping 8.8.8.8), DNS resolution
- **Action**: Error logging for failed connectivity

#### Nix System Health

- **Checks**: Nix daemon status, store integrity, current generation
- **Metrics**: Garbage collection potential
- **Action**: Error for daemon issues, info for GC opportunities

### Health Status Levels

- **EXCELLENT**: 0 issues detected
- **GOOD**: 1-2 minor issues
- **FAIR**: 3-4 issues requiring attention
- **POOR**: 5+ issues, immediate action recommended

## Maintenance Tasks

### Automated Maintenance (Weekly)

The system performs these maintenance tasks every Sunday:

#### Nix Maintenance

- Garbage collection with performance optimization
- Store optimization and deduplication
- Store integrity verification

#### Homebrew Maintenance

- Package updates and upgrades
- Cleanup of old versions
- Health check (brew doctor)

#### System Cleanup

- Temporary file cleanup (files older than 7 days)
- User cache cleanup (files older than 30 days)
- Log file cleanup (files older than 30 days)

#### macOS Maintenance

- Spotlight index rebuilding
- DNS cache flushing

### Manual Maintenance

Run maintenance manually when needed:

```bash
# Full maintenance suite
health-maintain

# Individual maintenance components
./scripts/system-health-monitor.sh --maintain
```

## Configuration

### Threshold Configuration

Edit thresholds in `scripts/system-health-monitor.sh`:

```bash
# Health check thresholds
CPU_THRESHOLD=80        # CPU usage percentage
MEMORY_THRESHOLD=85     # Memory usage percentage  
DISK_THRESHOLD=90       # Disk usage percentage
LOAD_THRESHOLD=8        # Load average threshold
```

### Service Scheduling

Modify schedules in `darwin/system-monitoring.nix`:

```nix
StartCalendarInterval = [
  {
    Hour = 9;      # Change hour
    Minute = 0;    # Change minute
  }
];
```

### Log Configuration

Logs are stored in `~/.local/var/log/`:

- `system-health-check.log` - Daily health checks
- `system-maintenance.log` - Weekly maintenance tasks
- `performance-monitor.log` - Performance analysis
- `critical-alerts.log` - Critical issue alerts

## Reports and Analysis

### Health Reports

Generated reports are stored in `.health-reports/`:

- **health_report_TIMESTAMP.txt** - Comprehensive health reports
- **maintenance_TIMESTAMP.log** - Maintenance task logs

### Performance Reports

Performance analysis reports in `.performance-reports/`:

- **system_analysis_TIMESTAMP.txt** - System configuration analysis
- **rebuild_profile_TIMESTAMP.txt** - Build performance profiles
- **cache_analysis_TIMESTAMP.txt** - Binary cache performance

### Report Analysis

Review reports regularly:

```bash
# View latest health report
ls -la .health-reports/ | tail -5

# View latest performance report  
ls -la .performance-reports/ | tail -5

# Quick health status
health-check
```

## Troubleshooting

### Service Issues

If monitoring services aren't running:

```bash
# Check service status
monitor-status

# Reload services
monitor-unload && monitor-load

# Check for errors
logs-health
```

### High Resource Usage

If system reports high resource usage:

1. **Check top processes**: Reports show top CPU/memory consumers
2. **Review maintenance**: Run `health-maintain` if maintenance is overdue
3. **Analyze trends**: Compare with previous reports
4. **Manual investigation**: Use `htop`, `activity monitor`

### Disk Space Issues

For disk space warnings:

1. **Run cleanup**: `health-maintain` includes comprehensive cleanup
2. **Check Nix store**: Large store size suggests need for garbage collection
3. **Manual cleanup**: Remove large files, empty trash
4. **Analyze usage**: Use `duf` or `du -sh *` to find large directories

### Network Issues

For connectivity problems:

1. **Check network settings**: Verify WiFi/Ethernet connection
2. **DNS issues**: Try alternative DNS servers
3. **Firewall**: Check macOS firewall settings
4. **VPN**: Verify VPN isn't causing issues

## Integration with Development Workflow

### Pre-deployment Checks

Add health checks to your workflow:

```bash
# Before major system changes
health-check

# After system updates
health-report

# Monitor performance impact
perf-analyze
```

### Continuous Monitoring

The automated system provides:

- **Proactive Issue Detection**: Catch problems before they become critical
- **Performance Trending**: Track system performance over time
- **Maintenance Automation**: Keep system optimized without manual intervention
- **Development Environment Health**: Ensure development tools are functioning optimally

## Advanced Configuration

### Custom Alerts

Extend the alert system by modifying `check_alerts()` in the monitoring script:

```bash
# Add custom critical checks
if custom_critical_condition; then
    log_error "CRITICAL: Custom condition detected"
    critical_issues=$((critical_issues + 1))
fi
```

### External Notifications

Integrate with notification systems:

```bash
# Add to check_alerts() function
if [ $critical_issues -gt 0 ]; then
    # Send Slack notification
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"System health critical issues detected"}' \
        YOUR_SLACK_WEBHOOK_URL
fi
```

### Monitoring Extensions

Add additional monitoring by extending the health check functions:

- Database connectivity monitoring
- External service health checks
- Application-specific monitoring
- Security scan integration

## Conclusion

The system health monitoring provides comprehensive oversight of your Nix Darwin environment with minimal manual intervention. Regular monitoring ensures optimal performance and early detection of potential issues.

For additional customization or troubleshooting, refer to the script source code and configuration files, or check the monitoring logs for detailed information.
