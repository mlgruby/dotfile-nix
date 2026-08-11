# home-manager/modules/claude-code.nix
#
# Claude Code CLI Configuration
#
# Purpose:
# - Configures Claude Code CLI for AWS Bedrock integration
# - Manages automatic AWS SSO credential refresh
# - Sets environment variables for Bedrock API access
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.claude-code.bedrock;
  statuslinePath = "${config.home.homeDirectory}/.claude/statusline.sh";
  settings = builtins.toJSON {
    # AWS SSO auto-refresh command
    awsAuthRefresh = "aws sso login --profile ${cfg.awsProfile}";

    env = {
      AWS_PROFILE = cfg.awsProfile;
      AWS_REGION = cfg.awsRegion;

      CLAUDE_CODE_USE_BEDROCK = "1";
      CLAUDE_CODE_MAX_OUTPUT_TOKENS = "16384";
      # Keep large shell logs from consuming the conversation context.
      BASH_MAX_OUTPUT_LENGTH = "10000";
      # Bound parallel and repeated work so one session cannot fan out
      # indefinitely and multiply token usage.
      CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS = "2";
      CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION = "6";
      CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION = "25";
      MAX_THINKING_TOKENS = "8192";
      # Keep Claude Code on the standard context and compact before sessions
      # become large. The percentage is applied to this 200K calculation window.
      CLAUDE_CODE_DISABLE_1M_CONTEXT = "1";
      CLAUDE_CODE_AUTO_COMPACT_WINDOW = "200000";
      # Compact at 60% of the standard context, around 120K tokens.
      CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "60";

      ANTHROPIC_DEFAULT_SONNET_MODEL = cfg.models.default;
      ANTHROPIC_DEFAULT_SONNET_MODEL_NAME = cfg.modelNames.default;
      ANTHROPIC_DEFAULT_HAIKU_MODEL = cfg.models.fast;
      ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME = cfg.modelNames.fast;
      ANTHROPIC_DEFAULT_OPUS_MODEL = cfg.models.opus;
      ANTHROPIC_DEFAULT_OPUS_MODEL_NAME = cfg.modelNames.opus;
      ANTHROPIC_CUSTOM_MODEL_OPTION = cfg.models.fable;
      ANTHROPIC_CUSTOM_MODEL_OPTION_NAME = cfg.modelNames.fable;
      ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION = "EU Bedrock Fable model";
    };

    model = cfg.model;
    effortLevel = "low";
    autoCompactEnabled = true;
    availableModels = [ "sonnet" "opus" "haiku" ];

    enabledPlugins = {
      "superpowers@claude-plugins-official" = true;
      "frontend-design@claude-plugins-official" = true;
      "context7@claude-plugins-official" = true;
      "code-review@claude-plugins-official" = true;
      "code-simplifier@claude-plugins-official" = true;
      "skill-creator@claude-plugins-official" = true;
      "claude-md-management@claude-plugins-official" = true;
      "ralph-loop@claude-plugins-official" = true;
      "security-guidance@claude-plugins-official" = true;
      "claude-code-setup@claude-plugins-official" = true;
      "pr-review-toolkit@claude-plugins-official" = true;
      "codex@openai-codex" = true;
      "caveman@caveman" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
      "pyright-lsp@claude-plugins-official" = true;
    };
    extraKnownMarketplaces = {
      openai-codex = {
        source = {
          source = "github";
          repo = "openai/codex-plugin-cc";
        };
      };
      caveman = {
        source = {
          source = "github";
          repo = "JuliusBrussee/caveman";
        };
      };
    };

    statusLine = {
      type = "command";
      command = "bash \"${statuslinePath}\"";
      refreshInterval = 30;
    };
  };
in
{
  options.programs.claude-code.bedrock = {
    awsProfile = lib.mkOption {
      type = lib.types.str;
      default = "default-sso";
      description = "AWS SSO profile name for Bedrock access";
    };
    awsRegion = lib.mkOption {
      type = lib.types.str;
      default = "eu-west-1";
      description = "AWS Region for Bedrock access";
    };
    model = lib.mkOption {
      type = lib.types.str;
      default = "sonnet";
      description = "Selected model family";
    };
    models = {
      default = lib.mkOption {
        type = lib.types.str;
        default = "eu.anthropic.claude-sonnet-5";
        description = "Bedrock model ID for Sonnet";
      };
      fast = lib.mkOption {
        type = lib.types.str;
        default = "eu.anthropic.claude-haiku-4-5-20251001-v1:0";
        description = "Bedrock model ID for Haiku";
      };
      opus = lib.mkOption {
        type = lib.types.str;
        default = "eu.anthropic.claude-opus-5";
        description = "Bedrock model ID for Opus";
      };
      fable = lib.mkOption {
        type = lib.types.str;
        default = "eu.anthropic.claude-fable-5";
        description = "Bedrock model ID for Fable";
      };
    };
    modelNames = {
      default = lib.mkOption {
        type = lib.types.str;
        default = "Sonnet 5";
        description = "Friendly name for Sonnet";
      };
      fast = lib.mkOption {
        type = lib.types.str;
        default = "Haiku 4.5";
        description = "Friendly name for Haiku";
      };
      opus = lib.mkOption {
        type = lib.types.str;
        default = "Opus 5";
        description = "Friendly name for Opus";
      };
      fable = lib.mkOption {
        type = lib.types.str;
        default = "Fable 5";
        description = "Friendly name for Fable";
      };
    };
  };

  config = lib.mkIf config.programs.claude-code.enable {
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

      install -m 755 "${./claude-code/statusline.sh}" "$HOME/.claude/statusline.sh"
    '';
  };
}
