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

      # Model selection - defaults use EU endpoints for GDPR compliance
      # Primary model for agentic tasks (overridable via --model or /model)
      ANTHROPIC_MODEL = claude.models.default;
      # Haiku-class model for background/fast operations
      ANTHROPIC_DEFAULT_HAIKU_MODEL = claude.models.fast;
      # Opus-class model for complex reasoning tasks
      ANTHROPIC_DEFAULT_OPUS_MODEL = claude.models.opus;
    };

    model = claude.model;
    effortLevel = claude.effortLevel;
    autoCompactEnabled = true;
    availableModels = claude.availableModels;
    modelOverrides = claude.modelOverrides;

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
  # The live settings file must remain mutable because Claude plugins edit it.
  # Location: ~/.claude/settings.default.json
  # Docs: https://docs.anthropic.com/claude-code/configuration
  home.file.".claude/settings.default.json".text = settings;
  home.activation.ensureClaudeMutableSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.claude"

    if [ -L "$HOME/.claude/settings.json" ]; then
      rm "$HOME/.claude/settings.json"
    fi

    if [ ! -e "$HOME/.claude/settings.json" ]; then
      install -m 600 "$HOME/.claude/settings.default.json" "$HOME/.claude/settings.json"
    fi

    if [ ! -e "$HOME/.claude/statusline.sh" ]; then
      install -m 755 "${./claude-code/statusline.sh}" "$HOME/.claude/statusline.sh"
    fi
  '';
}
