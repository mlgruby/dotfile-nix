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
{ claude-plugins-official, codex-plugin-cc, caveman-skill, ... }:
let
  official = claude-plugins-official;
  codex = codex-plugin-cc;
  caveman = caveman-skill;
in
{
  programs.claude-code.plugins = [
    # anthropics/claude-plugins-official
    "${official}/plugins/claude-code-setup"
    "${official}/plugins/claude-md-management"
    "${official}/plugins/code-review"
    "${official}/plugins/code-simplifier"
    "${official}/plugins/frontend-design"
    "${official}/plugins/pr-review-toolkit"
    "${official}/plugins/pyright-lsp"
    "${official}/plugins/ralph-loop"
    "${official}/plugins/rust-analyzer-lsp"
    "${official}/plugins/security-guidance"
    "${official}/plugins/skill-creator"
    "${official}/external_plugins/context7"

    # openai/codex-plugin-cc
    "${codex}/plugins/codex"

    # JuliusBrussee/caveman (reuses skill input)
    "${caveman}/plugins/caveman"
  ];
}
