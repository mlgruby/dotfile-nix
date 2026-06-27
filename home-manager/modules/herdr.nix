# home-manager/modules/herdr.nix
#
# Herdr (Agent Multiplexer) Configuration
#
# Purpose:
# - Configures theme and custom colors (Gruvbox)
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
    [theme]
    name = "gruvbox"

    [theme.custom]
    surface_dim = "#504945"
    accent = "#a89984"

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
  '';
}
