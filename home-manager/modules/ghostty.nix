# home-manager/modules/ghostty.nix
#
# Ghostty Terminal Emulator Configuration
#
# Purpose:
# - Configures Ghostty with Gruvbox dark theme and JetBrains Mono Nerd Font
# - Sets fullscreen launch behavior
# - Attaches to the tmux "main" session on startup
#
{ config, lib, pkgs, ... }:
{
  xdg.configFile."ghostty/config".text = ''
    # Theme & Appearance (Hard contrast Gruvbox)
    theme = "Gruvbox Dark Hard"
    background-opacity = 0.92
    background-blur-radius = 20

    # Window Management (Native macOS Space Fullscreen)
    fullscreen = true
    window-decoration = true
    macos-titlebar-style = hidden
    window-padding-x = 0
    window-padding-y = 0

    # Keyboard & macOS Option handling (British layout support)
    # Explicitly map Alt+3 to '#' so British layout '#' is never hijacked
    keybind = alt+3=text:#
    macos-option-as-alt = left
    font-family = "JetBrainsMono NFM"
    font-size = 16
    adjust-box-thickness = 1
    font-thicken = true

    # Auto-launch tmux, but keep a shell available if it exits or fails.
    # Herdr runs in Herdr.app, so Ghostty does not start the Herdr TUI.
    command = /run/current-system/sw/bin/zsh -l -c "tmux attach-session -t main 2>/dev/null || tmux new-session -s main; exec /run/current-system/sw/bin/zsh -l"
  '';
}
