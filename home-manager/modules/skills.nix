{ agentSources, ... }:
let
  ce = agentSources.compound-engineering;
  hf = agentSources.hyperframes-skills;
  mp = agentSources.mattpocock-skills;

  sharedSkills = {
    # compound-engineering
    ce-brainstorm = "${ce}/skills/ce-brainstorm";
    ce-code-review = "${ce}/skills/ce-code-review";
    ce-commit = "${ce}/skills/ce-commit";
    ce-commit-push-pr = "${ce}/skills/ce-commit-push-pr";
    ce-compound = "${ce}/skills/ce-compound";
    ce-compound-refresh = "${ce}/skills/ce-compound-refresh";
    ce-debug = "${ce}/skills/ce-debug";
    ce-doc-review = "${ce}/skills/ce-doc-review";
    ce-dogfood = "${ce}/skills/ce-dogfood";
    ce-ideate = "${ce}/skills/ce-ideate";
    ce-optimize = "${ce}/skills/ce-optimize";
    ce-plan = "${ce}/skills/ce-plan";
    ce-proof = "${ce}/skills/ce-proof";
    ce-resolve-pr-feedback = "${ce}/skills/ce-resolve-pr-feedback";
    ce-riffrec-feedback-analysis = "${ce}/skills/ce-riffrec-feedback-analysis";
    ce-setup = "${ce}/skills/ce-setup";
    ce-simplify-code = "${ce}/skills/ce-simplify-code";
    ce-strategy = "${ce}/skills/ce-strategy";
    ce-test-browser = "${ce}/skills/ce-test-browser";
    ce-test-xcode = "${ce}/skills/ce-test-xcode";
    ce-work = "${ce}/skills/ce-work";
    ce-worktree = "${ce}/skills/ce-worktree";
    lfg = "${ce}/skills/lfg";

    # hyperframes
    hyperframes = "${hf}/skills/hyperframes";
    hyperframes-cli = "${hf}/skills/hyperframes-cli";
    media-use = "${hf}/skills/media-use";
    hyperframes-registry = "${hf}/skills/hyperframes-registry";
    animejs = "${hf}/skills/hyperframes-animation";
    remotion-to-hyperframes = "${hf}/skills/remotion-to-hyperframes";

    # mattpocock engineering
    grill-with-docs = "${mp}/skills/engineering/grill-with-docs";
    improve-codebase-architecture = "${mp}/skills/engineering/improve-codebase-architecture";
    prototype = "${mp}/skills/engineering/prototype";
    setup-matt-pocock-skills = "${mp}/skills/engineering/setup-matt-pocock-skills";
    tdd = "${mp}/skills/engineering/tdd";
    to-issues = "${mp}/skills/engineering/to-tickets";
    to-prd = "${mp}/skills/engineering/to-spec";
    triage = "${mp}/skills/engineering/triage";

    # mattpocock productivity
    grill-me = "${mp}/skills/productivity/grill-me";
    handoff = "${mp}/skills/productivity/handoff";

    # caveman
    caveman = "${agentSources.caveman-skill}/skills/caveman";
  };
  disabledCodexSkills = [
    "hyperframes"
    "hyperframes-cli"
    "media-use"
    "hyperframes-registry"
    "animejs"
    "remotion-to-hyperframes"
    "to-prd"
    "to-issues"
    "triage"
    "setup-matt-pocock-skills"
  ];
in
{
  programs.claude-code.skills = removeAttrs sharedSkills [
    # Also installed for Claude Code via programs.claude-code.plugins.
    "caveman"
  ];
  programs.codex.skills = removeAttrs sharedSkills disabledCodexSkills;
  programs.opencode.skills = sharedSkills;
  programs.antigravity-cli.skills = sharedSkills;
}
