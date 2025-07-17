# Cloud Platform Tools

Configuration and utilities for AWS and Google Cloud Platform.

> 💡 **For comprehensive AWS SSO setup**: See the [AWS SSO Setup Guide](../guides/aws-sso-setup.md) for detailed SSO configuration with cross-shell compatibility.

## AWS CLI

### Profile Management

```bash
# Profile Selection
awsp    # Switch AWS profile interactively
awsw    # Show current AWS profile
awsl    # List available profiles

# Quick Access
awsc    # Copy current credentials
awse    # Export credentials as env vars
```

### Credential Management

```nix
# Configuration in home-manager/modules/aws-cred.nix
programs.aws = {
  enable = true;
  settings = {
    region = "us-east-1";
    output = "json";
  };
};
```

## Google Cloud SDK

### Configuration Management

```bash
# Config Commands
gcl     # List configurations
gcs     # Switch configuration
gci     # Show current config info

# Project Management
gpl     # List projects
gps     # Set current project
```

### Installation & Setup

```nix
# Configuration in home-manager/modules/gcloud.nix
programs.gcloud = {
  enable = true;
  components = [
    "core"
    "gsutil"
    "kubectl"
  ];
};
```
