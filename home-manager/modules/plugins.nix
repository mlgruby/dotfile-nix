# home-manager/modules/plugins.nix
#
# Claude Code plugin configuration.
#
# Uses programs.claude-code.plugins (--plugin-dir wrapper flag) so every
# listed plugin is active on every session without manual /install.
#
# Update pins:
#   cd home-manager/agent-extras && nix flake update claude-plugins-official codex-plugin-cc
#   nix flake update agent-extras
{ agentSources, ... }:
let
  official = agentSources.claude-plugins-official;
  codex = agentSources.codex-plugin-cc;
  caveman = agentSources.caveman-skill;
in
{
  programs.claude-code.plugins = {
    # anthropics/claude-plugins-official
    official-claude-code-setup = "${official}/plugins/claude-code-setup";
    official-claude-md-management = "${official}/plugins/claude-md-management";
    official-code-review = "${official}/plugins/code-review";
    official-code-simplifier = "${official}/plugins/code-simplifier";
    official-frontend-design = "${official}/plugins/frontend-design";
    official-pr-review-toolkit = "${official}/plugins/pr-review-toolkit";
    official-pyright-lsp = "${official}/plugins/pyright-lsp";
    official-ralph-loop = "${official}/plugins/ralph-loop";
    official-rust-analyzer-lsp = "${official}/plugins/rust-analyzer-lsp";
    official-security-guidance = "${official}/plugins/security-guidance";
    official-skill-creator = "${official}/plugins/skill-creator";
    official-context7 = "${official}/external_plugins/context7";

    # openai/codex-plugin-cc
    openai-codex = "${codex}/plugins/codex";

    # JuliusBrussee/caveman (reuses skill input)
    caveman = "${caveman}/plugins/caveman";
  };
}
