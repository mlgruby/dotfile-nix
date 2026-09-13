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
{
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
    workspace_picker = "prefix+s"
    settings = "prefix+comma"
    split_vertical = "prefix+v"
    split_horizontal = "prefix+h"

    # Indexed Tab & Workspace Jumps with prefix (Ctrl+a 1..9)
    switch_tab = "prefix+1..9"
    switch_workspace = "prefix+shift+1..9"

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
