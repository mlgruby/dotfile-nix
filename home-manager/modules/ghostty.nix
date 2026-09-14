# home-manager/modules/ghostty.nix
#
# Ghostty Terminal Emulator Configuration
#
# Purpose:
# - Configures Ghostty with Gruvbox dark theme and JetBrains Mono Nerd Font
# - Sets fullscreen launch behavior
# - Directly attaches to Herdr on startup
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

    # Auto-launch tmux + Herdr (matching main session workflow)
    command = /bin/zsh -l -c "tmux attach-session -t main 2>/dev/null || tmux new-session -s main herdr"
  '';
}
