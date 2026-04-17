# home-manager/modules/tmux.nix - Optimized Tmux Configuration
#
# Tmux Configuration
#
# Purpose:
# - Sets up tmux defaults
# - Configures plugins
# - Manages keybindings
#
# Features:
# - Custom key bindings for easy navigation
# - Mouse support and better colors
# - Session management and restoration
# - Gruvbox theme integration
#
# Key Bindings:
# Prefix: Ctrl-a
#
# Window Management:
#   h         : Split horizontal
#   v         : Split vertical
#   x         : Kill pane
#   X         : Kill window
#   q         : Kill session (with confirm)
#
# Navigation:
#   Alt + ←↑↓→       : Switch panes
#   Shift + ←→       : Switch windows
#   Alt + Shift + ←↑↓→: Resize panes
#
# Quick Actions:
#   Enter    : Split horizontal
#   Space    : Split vertical
#   r        : Reload config
#
# Plugins:
# - tmux-sensible: Better defaults
# - tmux-yank: Copy/paste support
# - tmux-resurrect: Session saving
# - tmux-continuum: Auto-save sessions
# - tmux-gruvbox: Theme integration
#
# Integration:
# - Works with shell config
# - Uses Nix-managed tmux plugins
#
# Note:
# - Uses Ctrl+a prefix
# - Mouse mode enabled
# - Vi keys supported
{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    shortcut = "a"; # Prefix: Ctrl-a
    baseIndex = 1; # Start windows at 1
    escapeTime = 0; # Remove delay

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
      gruvbox
    ];

    extraConfig = ''
      # Core Settings
      set -g mouse on
      set -g status on
      set -g status-position top
      set -g default-terminal "screen-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -g update-environment "DISPLAY KRB5CCNAME SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY DOCKER_CONFIG"

      # Pane Management
      bind h split-window -h -c "#{pane_current_path}"
      bind v split-window -v -c "#{pane_current_path}"
      bind Enter split-window -h -c "#{pane_current_path}"
      bind Space split-window -v -c "#{pane_current_path}"
      bind x kill-pane
      bind X kill-window
      bind q confirm-before -p "Kill session #S? (y/n)" kill-session

      # Navigation (no prefix needed)
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D
      bind -n S-Left previous-window
      bind -n S-Right next-window

      # Resizing
      bind -n M-S-Left resize-pane -L 2
      bind -n M-S-Right resize-pane -R 2
      bind -n M-S-Up resize-pane -U 2
      bind -n M-S-Down resize-pane -D 2

      # Config reload
      bind r source-file $HOME/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Plugin Settings
      set -g @tmux-gruvbox 'dark'
      set -g @continuum-restore 'on'
      set -g @resurrect-capture-pane-contents 'on'
    '';
  };
}
