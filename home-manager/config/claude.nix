{
  awsProfile = "default-sso";

  useBedrock = "1";
  # Keep repo defaults conservative. Temporary live experiments can override
  # ~/.claude/settings.json without changing these template values.
  maxOutputTokens = "16384";
  maxThinkingTokens = "8192";
  model = "sonnet";
  effortLevel = "low";

  # EU geo inference endpoints keep the default model path GDPR-friendly.
  # These map to env vars (ANTHROPIC_MODEL, ANTHROPIC_DEFAULT_HAIKU_MODEL,
  # ANTHROPIC_DEFAULT_OPUS_MODEL) — runtime wiring for which model handles each role.
  models = {
    default = "eu.anthropic.claude-sonnet-4-6";
    fast = "eu.anthropic.claude-haiku-4-5-20251001-v1:0";
    opus = "eu.anthropic.claude-opus-4-8";
    fable = "eu.anthropic.claude-fable-5";
  };

  # Allowlist for the /model picker UI in Claude Code.
  # Must use standard Claude model IDs (not Bedrock IDs) — picker won't recognize eu.* IDs.
  # Family aliases — Claude Code resolves these against its internal model registry.
  # Full version IDs (claude-opus-4-5) only work if CC knows them; aliases always work.
  availableModels = [
    "sonnet"
    "opus"
    "haiku"
  ];

  # Friendly names for Bedrock-pinned model families in the /model picker.
  modelNames = {
    default = "Sonnet 4.6";
    fast = "Haiku 4.5";
    opus = "Opus 4.8";
    fable = "Fable 5";
  };

  # Plugins restored on every nix rebuild — survive settings.json resets.
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
}
