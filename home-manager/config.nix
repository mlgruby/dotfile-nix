# home-manager/config.nix
#
# Central Configuration Defaults
#
# Purpose:
# - Single source of truth for repeated values
# - Eliminates magic strings across modules
# - Makes configuration changes easier
#
# Usage:
# - Import in modules: defaults = import ../config.nix;
# - Access values: defaults.aws.region
#
# Sections:
# - AWS: Region, SSO, accounts, profiles
# - Claude: Bedrock model IDs and settings
# - SSH: Homelab connection defaults
# - Tmux: Terminal multiplexer settings
# - Starship: Prompt language icons
{
  # ==========================================================================
  # AWS Configuration
  # ==========================================================================
  aws = {
    # Default region for all AWS operations
    region = "eu-west-1";

    # SSO authentication settings
    ssoStartUrl = "https://vortexa.awsapps.com/start";
    ssoRoleName = "PMMT";

    # AWS account IDs
    accounts = {
      production = "501857513371";
      staging = "045251666112";
    };

    # Profile names used across shell functions and configs
    profiles = {
      default = "default-sso";
      production = "production-sso";
      staging = "staging-sso";
    };
  };

  # ==========================================================================
  # Claude Code / Bedrock Configuration
  # ==========================================================================
  claude = {
    # AWS profile for Bedrock API access
    awsProfile = "default-sso";

    # Bedrock settings
    useBedrock = "1";
    maxOutputTokens = "4096";
    maxThinkingTokens = "1024";

    # Model IDs - Using EU region endpoints for GDPR compliance
    # Format: eu.anthropic.<model>-<version>-v1:0
    # Available models: https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html
    models = {
      # Default model for general tasks (balanced speed/capability)
      default = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0";
      # Fast model for simple tasks (lower latency, lower cost)
      fast = "eu.anthropic.claude-haiku-4-5-20251001-v1:0";
      # Most capable model for complex reasoning
      opus = "eu.anthropic.claude-opus-4-5-20251101-v1:0";
    };
  };

  # ==========================================================================
  # SSH Configuration
  # ==========================================================================
  ssh = {
    # Default identity file for homelab servers
    homelabIdentityFile = "~/.ssh/nuc_homelab_id_ed25519";
    # Default user for homelab connections
    homelabUser = "root";
  };

  # Homelab hosts (name -> IP mapping)
  # Add new servers here - SSH config auto-generates
  homelabHosts = {
    # Proxmox cluster nodes
    pve1 = "192.168.10.12";
    pve2 = "192.168.10.13";
    pve3 = "192.168.10.14";

    # Pi-hole instances
    pi1 = "192.168.10.5";
    pi2 = "192.168.10.6";
    pi3 = "192.168.10.7";

    # Application servers
    servarr = "192.168.10.21";          # Media management
    glance = "192.168.10.22";           # Dashboard
    audiobookshelf = "192.168.10.26";   # Audiobook server
    lazywarden = "192.168.10.28";       # Bitwarden backup
    ha = "192.168.10.24";               # Home Assistant
    linkwarden = "192.168.10.29";       # Bookmark manager
    wazuh = "192.168.10.27";            # Wazuh

    # Monitoring stack
    metric-exporter = "192.168.10.32";
    prometheus = "192.168.10.17";

    # Utilities
    warracker = "192.168.10.19";     # Warranty tracker
    netspeed = "192.168.10.25";      # Network speed test
  };

  # ==========================================================================
  # Tmux Configuration
  # ==========================================================================
  tmux = {
    # Prefix key (Ctrl + this key)
    prefix = "a";
    # Window/pane numbering starts at 1 (not 0)
    baseIndex = 1;
    # No delay after pressing escape (important for vim)
    escapeTime = 0;
  };

  # ==========================================================================
  # Starship Prompt Icons
  # ==========================================================================
  # Nerd Font icons for programming languages
  # Used in starship prompt to show detected language
  languageSymbols = {
    nodejs = "";
    c = "";
    rust = "";
    golang = "";
    php = "";
    java = "";
    kotlin = "";
    haskell = "";
    python = "";
  };
}
