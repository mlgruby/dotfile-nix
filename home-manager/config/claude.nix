{
  awsProfile = "default-sso";

  useBedrock = "1";
  maxOutputTokens = "8192";
  maxThinkingTokens = "4096";

  # EU geo inference endpoints keep the default model path GDPR-friendly.
  models = {
    default = "eu.anthropic.claude-sonnet-4-6";
    fast = "eu.anthropic.claude-haiku-4-5-20251001-v1:0";
    opus = "global.anthropic.claude-opus-4-6-v1";
  };
}
