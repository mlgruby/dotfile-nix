# home-manager/modules/claude-code.nix
#
# Claude Code CLI Configuration
#
# Purpose:
# - Configures Claude Code CLI for AWS Bedrock integration
# - Manages automatic AWS SSO credential refresh
# - Sets environment variables for Bedrock API access
#
# How it works:
# - Creates ~/.claude/settings.default.json with Bedrock/statusline configuration
# - Creates ~/.claude/statusline.default.sh with the default statusline script
# - Bootstraps mutable Claude files only if missing so Claude can mutate them
# - Uses EU region endpoints for GDPR compliance
# - Auto-refreshes AWS SSO credentials when they expire
#
# Integration:
# - Requires AWS SSO login (aws sso login --profile default-sso)
# - Works with aws-sso.nix for credential management
# - Model IDs are centralized in ../config/claude.nix
#
# Usage:
# - Run 'claude' in terminal to start Claude Code
# - Credentials auto-refresh via awsAuthRefresh command
{
  config,
  lib,
  pkgs,
  ...
}:
let
  claude = import ../config/claude.nix;
  aws = import ../config/aws.nix;
  inherit (aws) region;
  statuslinePath = "${config.home.homeDirectory}/.claude/statusline.sh";
  settings = builtins.toJSON {
    # AWS SSO auto-refresh command
    # Runs automatically when Bedrock returns credential errors
    awsAuthRefresh = "aws sso login --profile ${claude.awsProfile}";

    # Environment variables scoped to Claude Code only
    # These don't leak to other processes or shells
    env = {
      # AWS profile for Bedrock API calls
      AWS_PROFILE = claude.awsProfile;
      # Region must support the selected Bedrock inference profile
      AWS_REGION = region;

      # Enable Bedrock as the backend (instead of direct Anthropic API)
      CLAUDE_CODE_USE_BEDROCK = claude.useBedrock;
      # Max tokens in model response
      CLAUDE_CODE_MAX_OUTPUT_TOKENS = claude.maxOutputTokens;
      # Max tokens for extended thinking/reasoning
      MAX_THINKING_TOKENS = claude.maxThinkingTokens;
      # Compact proactively instead of waiting for a provider-specific context limit.
      CLAUDE_CODE_AUTO_COMPACT_WINDOW = "200000";
      CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "90";

      # Model selection - defaults use EU endpoints for GDPR compliance
      # Pin sonnet family explicitly — alias otherwise resolves to CC's built-in Bedrock default
      ANTHROPIC_DEFAULT_SONNET_MODEL = claude.models.default;
      ANTHROPIC_DEFAULT_SONNET_MODEL_NAME = claude.modelNames.default;
      # Haiku-class model for background/fast operations
      ANTHROPIC_DEFAULT_HAIKU_MODEL = claude.models.fast;
      ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME = claude.modelNames.fast;
      # Opus-class model for complex reasoning tasks
      ANTHROPIC_DEFAULT_OPUS_MODEL = claude.models.opus;
      ANTHROPIC_DEFAULT_OPUS_MODEL_NAME = claude.modelNames.opus;
      # Claude Code 2.1.153 does not yet recognize a native Fable family alias.
      # Expose Fable through the supported custom-model picker slot instead.
      ANTHROPIC_CUSTOM_MODEL_OPTION = claude.models.fable;
      ANTHROPIC_CUSTOM_MODEL_OPTION_NAME = claude.modelNames.fable;
      ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION = "EU Bedrock Fable model";
    };

    model = claude.model;
    effortLevel = claude.effortLevel;
    autoCompactEnabled = true;
    availableModels = claude.availableModels;

    # Plugins managed by nix so they survive settings.json resets.
    # Claude Code mutates this file when installing/removing plugins.
    enabledPlugins = claude.enabledPlugins;
    extraKnownMarketplaces = claude.extraKnownMarketplaces;

    statusLine = {
      type = "command";
      command = "bash \"${statuslinePath}\"";
      refreshInterval = 30;
    };
  };
in
{
  # Claude Code default settings template.
  # The live settings file remains mutable because Claude plugins edit it.
  # Activation merges only Nix-owned Bedrock defaults into that live file.
  # Location: ~/.claude/settings.default.json
  # Docs: https://docs.anthropic.com/claude-code/configuration
  programs.claude-code.enable = true;

  home.file.".claude/settings.default.json".text = settings;
  home.activation.ensureClaudeMutableSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.claude"

    if [ -L "$HOME/.claude/settings.json" ]; then
      rm "$HOME/.claude/settings.json"
    fi

    if [ ! -e "$HOME/.claude/settings.json" ]; then
      install -m 600 "$HOME/.claude/settings.default.json" "$HOME/.claude/settings.json"
    fi

    settings_tmp="$(mktemp)"
    ${pkgs.jq}/bin/jq --slurpfile defaults "$HOME/.claude/settings.default.json" '
      .awsAuthRefresh = $defaults[0].awsAuthRefresh
      | .env = ((.env // {}) + $defaults[0].env)
      | del(.env.ANTHROPIC_MODEL)
      | del(.env.ANTHROPIC_DEFAULT_FABLE_MODEL)
      | del(.env.ANTHROPIC_DEFAULT_FABLE_MODEL_NAME)
      | .model = $defaults[0].model
      | .effortLevel = $defaults[0].effortLevel
      | .autoCompactEnabled = $defaults[0].autoCompactEnabled
      | .availableModels = $defaults[0].availableModels
      | del(.modelOverrides)
      | del(.skipDangerousModePermissionPrompt)
    ' "$HOME/.claude/settings.json" > "$settings_tmp"
    install -m 600 "$settings_tmp" "$HOME/.claude/settings.json"
    rm -f "$settings_tmp"

    if [ ! -e "$HOME/.claude/statusline.sh" ]; then
      install -m 755 "${./claude-code/statusline.sh}" "$HOME/.claude/statusline.sh"
    fi
  '';
}
