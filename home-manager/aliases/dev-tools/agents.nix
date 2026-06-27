# home-manager/aliases/dev-tools/agents.nix
#
# Aliases for interactive coding agents and agent CLIs.
{ ... }:
let
  aws = import ../../config/aws.nix;
in
{
  # Claude Code
  cc = "claude"; # Claude Code shorthand
  ccc = "claude --continue"; # Continue the latest Claude Code conversation
  ccr = "claude --resume"; # Resume a Claude Code conversation

  # OpenCode
  oc = "opencode"; # OpenCode shorthand
  occ = "opencode run --continue"; # Continue last OpenCode session
  ocx = "opencode run"; # Execute opencode with a message (non-interactive)
  ocr = "opencode-resume"; # Resume an OpenCode session

  # Pi Coding Agent
  pil = "pi --provider lmstudio --model google/gemma-4-26b-a4b"; # Use Gemma 4 26B from LM Studio
  pig = "pi --provider lmstudio --model google/gemma-4-26b-a4b"; # Gemma shorthand
  pib = "AWS_PROFILE=${aws.profiles.default} AWS_REGION=${aws.region} pi --provider amazon-bedrock --model eu.anthropic.claude-sonnet-4-6"; # Use Anthropic Claude Sonnet via Bedrock
  pic = "pi --continue"; # Continue previous pi session
  pir = "pi --resume"; # Resume a pi session

  # Codex (OpenAI)
  cx = "codex"; # Codex shorthand
  cxr = "codex resume"; # Resume a Codex session

  # Antigravity (Google) — binary is agy
  ag = "agy"; # Antigravity shorthand
  agc = "agy --continue"; # Continue last Antigravity conversation
  agr = "agy-resume"; # Resume an Antigravity session

  # Herdr (Agent Multiplexer)
  he = "herdr"; # Launch/attach herdr session
  hrld = "herdr server reload-config"; # Reload herdr configuration
  hstat = "herdr status"; # Show herdr status
}
