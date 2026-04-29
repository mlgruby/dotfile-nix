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
  models = {
    default = "eu.anthropic.claude-sonnet-4-6";
    fast = "eu.anthropic.claude-haiku-4-5-20251001-v1:0";
    opus = "global.anthropic.claude-opus-4-6-v1";
  };
}
