# home-manager/modules/herdr.nix
#
# Herdr (Agent Multiplexer) Configuration
#
# Purpose:
# - Configures the built-in Gruvbox theme
# - Defines navigation, layout, and workspace keybindings
#
# Integration:
# - Tool installed via Homebrew / development list
#
# Note:
# - Configuration stored in ~/.config/herdr/config.toml
{
  config,
  lib,
  pkgs,
  ...
}:
let
  ghDash = pkgs.gh-dash.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ./herdr/gh-dash-mouse.patch ];
    postCheck = (old.postCheck or "") + ''
      go test ./internal/tui/components/sidebar ./internal/tui
    '';
  });
  review = pkgs.writeShellApplication {
    name = "herdr-review";
    runtimeInputs = [ pkgs.git pkgs.jq pkgs.less config.programs.lazygit.package ];
    text = builtins.readFile ./herdr/herdr-review.sh;
  };
  projectLayout = pkgs.writeShellApplication {
    name = "herdr-project-layout";
    runtimeInputs = [ pkgs.python3 pkgs.git ];
    text = ''
      exec python3 ${./herdr/project-layout.py} "$@"
    '';
  };
  workflowMain = pkgs.writeShellApplication {
    name = "herdr-workflow";
    runtimeInputs = [ projectLayout pkgs.python3 pkgs.git pkgs.gh ghDash pkgs.delta pkgs.fzf pkgs.ripgrep config.programs.neovim.finalPackage ];
    text = ''
      exec python3 ${./herdr/workflow.py} "$@"
    '';
  };
  workflowCommands = {
    hinbox = "inbox";
    herdr-project-open = "project";
    hpr = "pr";
    hpr-view = "pr-view";
    hpr-ci = "pr-ci";
    hpr-ai-review = "pr-ai-review";
    hcheck = "check";
    hfind = "find";
    htask = "task";
    hreview-agent = "reviewer";
  };
  workflow = pkgs.symlinkJoin {
    name = "herdr-workflow-tools";
    paths = [ workflowMain ] ++ lib.mapAttrsToList (name: subcommand:
      pkgs.writeShellScriptBin name ''
        exec ${workflowMain}/bin/herdr-workflow ${subcommand} "$@"
      ''
    ) workflowCommands;
  };
  projectPlugin = pkgs.writeTextDir "herdr-plugin.toml" ''
    id = "dotfiles.work-project-layout"
    name = "Work project tabs"
    version = "0.1.0"
    min_herdr_version = "0.9.5"
    description = "Create Shell and CC tabs for new work repositories"
    platforms = ["macos"]

    [[events]]
    on = "workspace.created"
    command = ["${projectLayout}/bin/herdr-project-layout"]
  '';
in
{
  home.packages = [ review projectLayout workflow ghDash ];
  home.activation.herdrProjectLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x /opt/homebrew/bin/herdr ]; then
      run /opt/homebrew/bin/herdr plugin link ${projectPlugin}
    fi
  '';
  home.file = {
    ".agents/skills/herdr/SKILL.md".source = ./herdr/skill/SKILL.md;
    ".codex/skills/herdr/SKILL.md".source = ./herdr/skill/SKILL.md;
    ".claude/skills/herdr/SKILL.md".source = ./herdr/skill/SKILL.md;
  };

  xdg.configFile."herdr/workflow.md".source = ../../docs/guides/herdr-workflow.md;

  xdg.configFile."gh-dash/config.yml".source = (pkgs.formats.yaml {}).generate "gh-dash.yml" {
    prSections = [
      { title = "Needs my review"; filters = "is:open review-requested:@me -author:app/dependabot"; }
      { title = "My PRs"; filters = "is:open author:@me"; }
      { title = "Involved"; filters = "is:open involves:@me -author:@me -author:app/dependabot"; }
      {
        title = "Dependabot";
        filters = "is:open author:app/dependabot user:mlgruby org:VorTECHsa org:bodhispace-xyz";
        limit = 20;
      }
    ];
    keybindings.prs = [
      {
        key = "V";
        name = "Review in Herdr (q closes inbox)";
        command = "${workflow}/bin/hpr {{.PrNumber}} --repo {{.RepoName}}";
      }
      {
        key = "A";
        name = "AI review in Herdr (q closes inbox)";
        command = "${workflow}/bin/hpr {{.PrNumber}} --repo {{.RepoName}} --ai-review";
      }
    ];
    pager.diff = "delta";
  };

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [theme]
    name = "gruvbox"

    # UI Settings
    [ui]
    agent_panel_sort = "priority"
    status_indicators = "symbols"
    tab_bar_position = "top"
    tab_bar_right = []
    hide_tab_bar_when_single_tab = true

    # Notifications when background agents finish or request approval
    [ui.toast]
    delivery = "terminal"

    # Persistent agent conversations & terminal history
    [session]
    resume_agents_on_restore = true

    [experimental]
    pane_history = true

    [keys]
    prefix = "ctrl+a"

    # Spaces (Workspaces) & Tabs - plain vs Shift
    new_workspace = "prefix+n"
    new_tab = "prefix+shift+n"
    close_workspace = "prefix+w"
    close_tab = "prefix+shift+w"
    rename_workspace = "prefix+r"
    rename_tab = "prefix+shift+r"

    # Navigation (Alt-based Consistency)
    # Large elements (Spaces & Tabs) use Alt + Shift
    previous_workspace = "alt+shift+up"
    next_workspace = "alt+shift+down"
    previous_tab = "alt+shift+left"
    next_tab = "alt+shift+right"

    # Small elements (Panes & Agents) use Alt (no Shift)
    focus_pane_left = "alt+left"
    focus_pane_right = "alt+right"
    previous_agent = "alt+up"
    next_agent = "alt+down"

    # System & Panes
    goto = "prefix+alt+g"
    workspace_picker = "prefix+s"
    settings = "prefix+comma"
    split_vertical = "prefix+v"
    split_horizontal = "prefix+h"

    # Indexed Tab & Workspace Jumps with prefix (Ctrl+a 1..9)
    switch_tab = "prefix+1..9"
    switch_workspace = "prefix+shift+1..9"

    # Local Git review from the action's pane context, including existing workspaces.
    [[keys.command]]
    key = "prefix+g"
    type = "popup"
    command = "${review}/bin/herdr-review"
    width = "95%"
    height = "90%"

    [[keys.command]]
    key = "prefix+d"
    type = "popup"
    command = "${review}/bin/herdr-review diff"
    width = "95%"
    height = "90%"

    [[keys.command]]
    key = "prefix+i"
    type = "popup"
    command = "${workflow}/bin/hinbox"
    width = "95%"
    height = "90%"

    [[keys.command]]
    key = "prefix+f"
    type = "popup"
    command = "${workflow}/bin/hfind"
    width = "95%"
    height = "90%"

    # Shortcut: prefix + p to toggle/open GitHub PR Preview split pane
    [[keys.command]]
    key = "prefix+p"
    type = "shell"
    command = "herdr plugin action invoke juninaba.herdr-pr-preview open"

    # Shortcut: prefix + u to open Agents Usage (costs & token burns) modal popup
    [[keys.command]]
    key = "prefix+u"
    type = "popup"
    command = "herdr plugin pane open --plugin gecm.agents-usage --entrypoint usage"
    width = "85%"
    height = "80%"
  '';
}
