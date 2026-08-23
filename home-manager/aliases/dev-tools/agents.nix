# home-manager/aliases/dev-tools/agents.nix
#
# Aliases for interactive coding agents and agent CLIs.
{ pkgs, ... }:
let
  aws = import ../../config/aws.nix;
  ccusageSummary = "${pkgs.python3}/bin/python3 ${../../scripts/ccusage-summary.py}";
in
{
  # Claude Code
  ccc = "claude --continue"; # Continue the latest Claude Code conversation

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

  # Antigravity (Google) — ag and agc are defined as interactive functions in zsh-integration.zsh
  agr = "agy-resume"; # Resume an Antigravity session

  # Coding-agent usage (ccusage; reports use current pricing when available)
  cau-t = "ccusage daily --since \"$(date +%Y-%m-%d)\" --until \"$(date +%Y-%m-%d)\" --by-agent"; # Today across all supported agents
  cau-w = "ccusage weekly --since \"$(date -v-6d +%Y-%m-%d 2>/dev/null || date -d '6 days ago' +%Y-%m-%d)\" --until \"$(date +%Y-%m-%d)\" --by-agent"; # Rolling 7 days across all supported agents
  cau-m = "ccusage monthly --since \"$(date -v1d +%Y-%m-%d 2>/dev/null || date -d \"$(date +%Y-%m-01)\" +%Y-%m-%d)\" --until \"$(date +%Y-%m-%d)\" --by-agent"; # This month across all supported agents
  cau-tt = "${ccusageSummary} today"; # Today totals per agent plus grand total
  cau-wt = "${ccusageSummary} week"; # Rolling 7-day totals per agent plus grand total
  cau-mt = "${ccusageSummary} month"; # This-month totals per agent plus grand total
  cau-s = "ccusage session"; # Usage grouped by conversation/session
  cau-cc = "ccusage claude daily --since \"$(date +%Y-%m-%d)\" --until \"$(date +%Y-%m-%d)\" --breakdown"; # Claude today by model
  cau-cx = "ccusage codex daily --since \"$(date -v-6d +%Y-%m-%d 2>/dev/null || date -d '6 days ago' +%Y-%m-%d)\" --until \"$(date +%Y-%m-%d)\" --breakdown"; # Codex rolling 7 days by model
  cau-ag = "ccusage gemini daily --since \"$(date -v-6d +%Y-%m-%d 2>/dev/null || date -d '6 days ago' +%Y-%m-%d)\" --until \"$(date +%Y-%m-%d)\" --breakdown"; # Gemini/AGY rolling 7 days by model
  cau-pi = "ccusage pi daily --since \"$(date -v-6d +%Y-%m-%d 2>/dev/null || date -d '6 days ago' +%Y-%m-%d)\" --until \"$(date +%Y-%m-%d)\" --breakdown"; # Pi rolling 7 days by model
  cau-b = "ccusage claude blocks --active"; # Active Claude 5-hour block

  # Herdr (Agent Multiplexer)
  he = "herdr"; # Launch/attach herdr session
  hrld = "herdr server reload-config"; # Reload herdr configuration
  hstat = "herdr status"; # Show herdr status
}
