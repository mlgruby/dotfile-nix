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
  herdrCoreVersion = "0.1.21";
  herdrCoreAssets = {
    aarch64-darwin = {
      target = "macos-aarch64";
      sha256 = "1ab38dd9270f63a8f794d6d60e8702eb0d1c85a72bda85d735e5eea43f05ffed";
    };
    x86_64-darwin = {
      target = "macos-x86_64";
      sha256 = "e377e1d342cddce0346da5b2f3c281b9701e4731c00024c7c5028265e77a217f";
    };
  };
  herdrCoreAsset = herdrCoreAssets.${pkgs.stdenv.hostPlatform.system} or null;
  herdrCore = lib.optionalAttrs (herdrCoreAsset != null) (
    pkgs.stdenvNoCC.mkDerivation {
      pname = "herdr-core-bundle";
      version = herdrCoreVersion;

      src = pkgs.fetchurl {
        url = "https://releases.herdr.dev/core/${herdrCoreVersion}/herdr-core-${herdrCoreAsset.target}.tar.gz";
        inherit (herdrCoreAsset) sha256;
      };

      sourceRoot = ".";
      dontConfigure = true;
      dontBuild = true;
      # Keep Apple's Developer ID code signature intact inside Herdr Core.app.
      dontFixup = true;

      installPhase = ''
        runHook preInstall
        mkdir -p "$out/share/herdr-core"
        cp -a "Herdr Core.app" "$out/share/herdr-core/"
        runHook postInstall
      '';
    }
  );
  ghDash = pkgs.gh-dash.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ./herdr/gh-dash-mouse.patch ./herdr/gh-dash-markdown.patch ];
    postCheck = (old.postCheck or "") + ''
      go test ./internal/tui/components/sidebar ./internal/tui/markdown ./internal/tui
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
  home.activation.installHerdrCore = lib.mkIf (herdrCoreAsset != null) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ "$(id -u)" -ne 0 ]; then
        hc_bin="${config.home.homeDirectory}/.local/bin/herdr-core"
        need_install=1
        if [ -x "$hc_bin" ]; then
          installed="$("$hc_bin" --version 2>/dev/null || true)"
          # Install/upgrade only when missing or older than the pinned Nix version;
          # Herdr.app manages newer auto-updates via `hc update`.
          if [ -n "$installed" ] && awk -v old="$installed" -v new="${herdrCoreVersion}" 'BEGIN {
            sub(/^hc /, "", old);
            split(old, a, /[.-]/); split(new, b, /[.-]/);
            for (i = 1; i <= 3; i++) {
              if ((a[i] + 0) > (b[i] + 0)) exit 0;
              if ((a[i] + 0) < (b[i] + 0)) exit 1;
            }
            exit 0;
          }'; then
            need_install=0
          fi
        fi
        if [ "$need_install" -eq 1 ]; then
          run mkdir -p "${config.home.homeDirectory}/.local/bin"
          if [ -d "${config.home.homeDirectory}/.local/share/herdr-core/versions" ]; then
            chmod -R u+w "${config.home.homeDirectory}/.local/share/herdr-core/versions" 2>/dev/null || true
          fi
          tmp_bundle_dir="$(mktemp -d)"
          # Nix store inputs are 0555; Herdr Core's installer expects a user-writable source bundle.
          cp -R "${herdrCore}/share/herdr-core/Herdr Core.app" "$tmp_bundle_dir/Herdr Core.app"
          chmod -R u+w "$tmp_bundle_dir/Herdr Core.app"
          staged_hc="$tmp_bundle_dir/Herdr Core.app/Contents/MacOS/herdr-core"
          run "$staged_hc" --hc-install-bundle "$staged_hc" "$hc_bin"
          rm -rf "$tmp_bundle_dir"
        fi
      fi
    ''
  );
  home.activation.herdrProjectLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x /opt/homebrew/bin/herdr ]; then
      run /opt/homebrew/bin/herdr plugin link ${projectPlugin}
      # Ensure chmarax.gitview plugin is installed if missing
      if ! /opt/homebrew/bin/herdr plugin list 2>/dev/null | grep -q "chmarax.gitview"; then
        run /opt/homebrew/bin/herdr plugin install ChmaraX/herdr-gitview || true
      fi
      # The long-running session must refresh paths into the new Nix generation.
      if [ -S "${config.home.homeDirectory}/.config/herdr/herdr.sock" ]; then
        run /opt/homebrew/bin/herdr server reload-config
      fi
    fi
  '';
  home.file = {
    ".agents/skills/herdr/SKILL.md".source = ./herdr/skill/SKILL.md;
    ".codex/skills/herdr/SKILL.md".source = ./herdr/skill/SKILL.md;
    ".claude/skills/herdr/SKILL.md".source = ./herdr/skill/SKILL.md;
  };

  xdg.configFile."herdr/plugins/config/chmarax.gitview/config.toml".text = ''
    theme = "dark"
    editor = ["nvim"]
    view_width_percent = 50
    list_width_percent = 29
    context_lines = 3
  '';

  xdg.configFile."herdr/workflow.md".source = ../../docs/guides/herdr-workflow.md;

  # Herdr.app (desktop): a "dev" layout (clone of the shipped "main") whose
  # top bar is the dev-status mod. The mod draws the agent states and the
  # tmux status-right.sh segments.
  # Files are linked one by one so the mod folder stays writable (the app
  # writes jsconfig.json/.d.ts into it).
  # Select it with: herdr-app do layout.switch '{"name":"dev"}'
  xdg.configFile."herdr-app/layouts/dev.json".source = ./herdr/app/dev-layout.json;
  # The dev layout's theme: Ghostty's "Gruvbox Dark Hard" (#1d2021 ground), as
  # in the Herdr TUI, with the app's Gruvbox panel colours.
  xdg.configFile."herdr-app/themes/gruvbox-hard.json".source = ./herdr/app/gruvbox-hard.json;
  xdg.configFile."herdr-app/mods/dev-status/main.js".source = ./herdr/app/dev-status/main.js;
  xdg.configFile."herdr-app/mods/dev-status/mod.json".source = ./herdr/app/dev-status/mod.json;
  xdg.configFile."herdr-app/mods/dev-status/sep.svg".source = ./herdr/app/dev-status/sep.svg;
  xdg.configFile."herdr-app/mods/dev-status/sep-right.svg".source = ./herdr/app/dev-status/sep-right.svg;
  # Clones of the shipped "spaces" and "agents" sidebars (Herdr 0.1.16): a
  # machine icon per row (aqua local, purple remote) and agent state colours.
  xdg.configFile."herdr-app/mods/dev-spaces/main.js".source = ./herdr/app/dev-spaces/main.js;
  xdg.configFile."herdr-app/mods/dev-spaces/mod.json".source = ./herdr/app/dev-spaces/mod.json;
  xdg.configFile."herdr-app/mods/dev-agents/main.js".source = ./herdr/app/dev-agents/main.js;
  xdg.configFile."herdr-app/mods/dev-agents/mod.json".source = ./herdr/app/dev-agents/mod.json;
  # Clone of the shipped "pane" header: the agent state tints the header.
  xdg.configFile."herdr-app/mods/dev-pane/main.js".source = ./herdr/app/dev-pane/main.js;
  xdg.configFile."herdr-app/mods/dev-pane/mod.json".source = ./herdr/app/dev-pane/mod.json;
  xdg.configFile."herdr-app/mods/dev-pane/close.svg".source = ./herdr/app/dev-pane/close.svg;
  xdg.configFile."herdr-app/mods/dev-pane/zoom.svg".source = ./herdr/app/dev-pane/zoom.svg;
  xdg.configFile."herdr-app/mods/dev-pane/unzoom.svg".source = ./herdr/app/dev-pane/unzoom.svg;
  xdg.configFile."herdr-app/mods/dev-pane/split-right.svg".source = ./herdr/app/dev-pane/split-right.svg;
  xdg.configFile."herdr-app/mods/dev-pane/split-down.svg".source = ./herdr/app/dev-pane/split-down.svg;
  # Ctrl+A prefix popup with the same keys as the Herdr TUI config below.
  xdg.configFile."herdr-app/mods/tmux-prefix/main.js".source = ./herdr/app/tmux-prefix/main.js;
  xdg.configFile."herdr-app/mods/tmux-prefix/mod.json".source = ./herdr/app/tmux-prefix/mod.json;
  # Ctrl+A a: start an agent on a task (own worktree and space).
  xdg.configFile."herdr-app/mods/agent-launch/main.js".source = ./herdr/app/agent-launch/main.js;
  xdg.configFile."herdr-app/mods/agent-launch/mod.json".source = ./herdr/app/agent-launch/mod.json;
  # Ctrl+A o or Cmd+O: pick a Work, Personal or dotfile project; open or go to its space.
  xdg.configFile."herdr-app/mods/project-open/main.js".source = ./herdr/app/project-open/main.js;
  xdg.configFile."herdr-app/mods/project-open/mod.json".source = ./herdr/app/project-open/mod.json;
  # Ctrl+A l, d, i, f: the tool in a popup terminal, as in the TUI.
  xdg.configFile."herdr-app/mods/tool-popup/main.js".source = ./herdr/app/tool-popup/main.js;
  xdg.configFile."herdr-app/mods/tool-popup/mod.json".source = ./herdr/app/tool-popup/mod.json;
  # Drawer on the panes' right edge: agents that are blocked or done.
  xdg.configFile."herdr-app/mods/needs-me/main.js".source = ./herdr/app/needs-me/main.js;
  xdg.configFile."herdr-app/mods/needs-me/mod.json".source = ./herdr/app/needs-me/mod.json;
  # App shortcuts, with Ctrl+A bound to the tmux-prefix popup. Read-only:
  # change keys here, not in Settings > Keyboard.
  xdg.configFile."herdr-app/keys.json".source = ./herdr/app/keys.json;
  # Clone of the shipped "changes" panel (Herdr 0.1.16) with solid diff line
  # colours, coloured gutter/sign and changed-word highlight.
  xdg.configFile."herdr-app/mods/dev-changes/main.js".source = ./herdr/app/dev-changes/main.js;
  xdg.configFile."herdr-app/mods/dev-changes/mod.json".source = ./herdr/app/dev-changes/mod.json;
  xdg.configFile."herdr-app/mods/dev-changes/changes.svg".source = ./herdr/app/dev-changes/changes.svg;

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
        name = "Queue AI review (keep working; q closes inbox)";
        command = "${workflow}/bin/hpr {{.PrNumber}} --repo {{.RepoName}} --ai-review --background";
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

    # Panes & Agents
    focus_pane_left = "prefix+left"
    focus_pane_right = "prefix+right"
    focus_pane_up = "prefix+up"
    focus_pane_down = "prefix+down"
    cycle_pane_next = "prefix+tab"
    cycle_pane_previous = "prefix+shift+tab"
    previous_agent = "alt+up"
    next_agent = "alt+down"

    # Pane Resizing (Ctrl + Option + Arrow keys without prefix)
    resize_pane_left = "ctrl+alt+left"
    resize_pane_right = "ctrl+alt+right"
    resize_pane_up = "ctrl+alt+up"
    resize_pane_down = "ctrl+alt+down"

    # System & Panes
    goto = "prefix+alt+g"
    workspace_picker = "prefix+s"
    settings = "prefix+comma"
    split_vertical = "prefix+v"
    split_horizontal = "prefix+h"

    # Indexed Tab & Workspace Jumps with prefix (Ctrl+a 1..9)
    switch_tab = "prefix+1..9"
    switch_workspace = "prefix+shift+1..9"

    # GitView: Native interactive diffs & agent review panel (ChmaraX/herdr-gitview)
    [[keys.command]]
    key = "prefix+g"
    type = "plugin_action"
    command = "chmarax.gitview.toggle"
    description = "git view sidebar"

    [[keys.command]]
    key = "prefix+shift+g"
    type = "plugin_action"
    command = "chmarax.gitview.toggle-tab"
    description = "git view tab"

    # Lazygit popup: Full commit history, rebasing, branches, and stashes
    [[keys.command]]
    key = "prefix+l"
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
