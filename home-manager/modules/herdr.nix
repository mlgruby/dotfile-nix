# home-manager/modules/herdr.nix
#
# Herdr.app (desktop) configuration
#
# Purpose:
# - Installs herdr-core (`hc`), which runs the app's terminals and agents
# - Links the "dev" layout, theme, keys and mods into ~/.config/herdr-app
# - Installs the helper commands that the mods start (herdr-review, hinbox,
#   hfind, hcheck, htask, herdr-project-layout)
#
# Integration:
# - Herdr.app is a Homebrew cask (darwin/homebrew-packages/casks)
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
    runtimeInputs = [ pkgs.git pkgs.less config.programs.lazygit.package ];
    text = builtins.readFile ./herdr/herdr-review.sh;
  };
  projectLayout = pkgs.writeShellApplication {
    name = "herdr-project-layout";
    runtimeInputs = [ pkgs.python3 pkgs.git ];
    text = ''
      # -P: no script folder on sys.path. Here that is /nix/store (40k+ entries),
      # which Python lists on each stdlib import (~40 ms a call).
      exec python3 -P ${./herdr/project-layout.py} "$@"
    '';
  };
  workflowMain = pkgs.writeShellApplication {
    name = "herdr-workflow";
    runtimeInputs = [ pkgs.python3 pkgs.git pkgs.gh ghDash pkgs.delta pkgs.fzf pkgs.ripgrep config.programs.neovim.finalPackage ];
    text = ''
      exec python3 -P ${./herdr/workflow.py} "$@"
    '';
  };
  workflowCommands = {
    hinbox = "inbox";
    hcheck = "check";
    hfind = "find";
    htask = "task";
  };
  workflow = pkgs.symlinkJoin {
    name = "herdr-workflow-tools";
    paths = [ workflowMain ] ++ lib.mapAttrsToList (name: subcommand:
      pkgs.writeShellScriptBin name ''
        exec ${workflowMain}/bin/herdr-workflow ${subcommand} "$@"
      ''
    ) workflowCommands;
  };
  # Redline: GitHub PR / GitLab MR review mod (https://github.com/iampedii/herdr-redline).
  redline = pkgs.fetchFromGitHub {
    owner = "iampedii";
    repo = "herdr-redline";
    rev = "cac2ee1bacdcfb9a7c6bcf9e05f09b8196c55f55";
    hash = "sha256-0Wy+Iy/gYMSBrMOzjzE+1Zi57S2DPKHZVBmnXZdQxFo=";
  };
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
          if [ -n "$installed" ] && ${pkgs.gawk}/bin/awk -v old="$installed" -v new="${herdrCoreVersion}" 'BEGIN {
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

  # Herdr.app (desktop): a "dev" layout (clone of the shipped "main") whose
  # top bar is the dev-status mod. The mod draws the agent states and the
  # tmux status-right.sh segments.
  # Files are linked one by one so the mod folder stays writable (the app
  # writes jsconfig.json/.d.ts into it).
  # Select it with: herdr-app do layout.switch '{"name":"dev"}'
  xdg.configFile."herdr-app/layouts/dev.json".source = ./herdr/app/dev-layout.json;
  # The dev layout's theme: Ghostty's "Gruvbox Dark Hard" (#1d2021 ground),
  # with the app's Gruvbox panel colours.
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
  # Ctrl+A prefix popup (tmux-style keys).
  xdg.configFile."herdr-app/mods/tmux-prefix/main.js".source = ./herdr/app/tmux-prefix/main.js;
  xdg.configFile."herdr-app/mods/tmux-prefix/mod.json".source = ./herdr/app/tmux-prefix/mod.json;
  # Ctrl+A a: start an agent on a task (own worktree and space).
  xdg.configFile."herdr-app/mods/agent-launch/main.js".source = ./herdr/app/agent-launch/main.js;
  xdg.configFile."herdr-app/mods/agent-launch/mod.json".source = ./herdr/app/agent-launch/mod.json;
  # Ctrl+A o or Cmd+O: pick a Work, Personal or dotfile project; open or go to its space.
  xdg.configFile."herdr-app/mods/project-open/main.js".source = ./herdr/app/project-open/main.js;
  xdg.configFile."herdr-app/mods/project-open/mod.json".source = ./herdr/app/project-open/mod.json;
  # Ctrl+A l, d, i, f: the tool in a popup terminal.
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
  # Redline (Cmd+Shift+F, Ctrl+A P): PR/MR list, CI, review in its own worktree.
  # Each file is linked, so the app can write jsconfig.json into the folder.
  xdg.configFile."herdr-app/mods/redline/main.js".source = "${redline}/mods/redline/main.js";
  xdg.configFile."herdr-app/mods/redline/mod.json".source = "${redline}/mods/redline/mod.json";
  xdg.configFile."herdr-app/mods/redline/diff.js".source = "${redline}/mods/redline/diff.js";
  xdg.configFile."herdr-app/mods/redline/highlight.js".source = "${redline}/mods/redline/highlight.js";
  xdg.configFile."herdr-app/mods/redline/hosting.js".source = "${redline}/mods/redline/hosting.js";
  xdg.configFile."herdr-app/mods/redline/launcher.js".source = "${redline}/mods/redline/launcher.js";
  xdg.configFile."herdr-app/mods/redline/lib.js".source = "${redline}/mods/redline/lib.js";
  xdg.configFile."herdr-app/mods/redline/logo.ans".source = "${redline}/mods/redline/logo.ans";
  xdg.configFile."herdr-app/mods/redline/logo.js".source = "${redline}/mods/redline/logo.js";
  xdg.configFile."herdr-app/mods/redline/panels.js".source = "${redline}/mods/redline/panels.js";
  xdg.configFile."herdr-app/mods/redline/watch.js".source = "${redline}/mods/redline/watch.js";

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
    pager.diff = "delta";
  };
}
