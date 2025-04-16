# home-manager/modules/tmux.nix
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
# - tpm: Plugin manager
# - tmux-sensible: Better defaults
# - tmux-yank: Copy/paste support
# - tmux-resurrect: Session saving
# - tmux-continuum: Auto-save sessions
# - tmux-autoreload: Auto config reload
# - tmux-gruvbox: Theme integration
#
# Integration:
# - Works with shell config
# - Uses TPM for plugins
#
# Note:
# - Uses Ctrl+a prefix
# - Mouse mode enabled
# - Vi keys supported

{ config, lib, pkgs, ... }: {
  programs.tmux = {
    enable = true;
    # Core Configuration
    shortcut = "a";     # Prefix key (Ctrl-a)
    baseIndex = 1;      # Start window numbering at 1
    escapeTime = 0;     # Remove escape key delay
    
    extraConfig = ''
      # Mouse and Terminal Settings
      # Enable better interaction and color support
      set -g mouse on

      # Status Bar
      # Position and visibility settings
      set -g status on
      set -g status-position top

      # Terminal Color Support
      # Enable full color support in terminal
      set -g default-terminal "screen-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Pane Splitting
      # Intuitive split commands that preserve current path
      bind h split-window -h -c "#{pane_current_path}"  # Split horizontal
      bind v split-window -v -c "#{pane_current_path}"  # Split vertical

      # Session Management
      # Commands for closing panes, windows, and sessions
      bind x kill-pane      # Close current pane
      bind X kill-window    # Close current window
      bind q confirm-before -p "Kill session #S? (y/n)" kill-session  # Close session with confirmation

      # Pane Navigation
      # Use Alt-arrow keys without prefix key to switch panes
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Window Navigation
      # Shift arrow to switch windows
      bind -n S-Left  previous-window
      bind -n S-Right next-window

      # Pane Resizing
      # Alt-Shift-arrow keys to resize panes
      bind -n M-S-Left resize-pane -L 2
      bind -n M-S-Right resize-pane -R 2
      bind -n M-S-Up resize-pane -U 2
      bind -n M-S-Down resize-pane -D 2

      # Quick Split Commands
      # Alternative split bindings using Enter and Space
      bind Enter split-window -h -c "#{pane_current_path}"  # Split horizontal
      bind Space split-window -v -c "#{pane_current_path}"  # Split vertical

      # Configuration Management
      # Easy config reload
      bind r source-file $HOME/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Plugin Management
      # Core plugins for enhanced functionality
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-yank'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @plugin 'tmux-plugins/tmux-continuum'
      set -g @plugin 'b0o/tmux-autoreload'
      set -g @plugin 'egel/tmux-gruvbox'
      set -g @plugin '2kabhishek/tmux2k'

      # Theme Configuration
      # Gruvbox theme settings for consistent look
      # set -g @tmux-gruvbox 'dark' # or 'dark256', 'light', 'light256'
      set -g @tmux2k-theme 'gruvbox'

      # Plugin Settings
      # Configure plugin behavior
      set -g @continuum-restore 'on'
      set -g @resurrect-capture-pane-contents 'on'
      set -g @tmux2k-icons-only true
      set -g @tmux2k-git-display-status true
      set -g @tmux2k-refresh-rate 5

      # Plugin Initialization
      # Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
      run '~/.tmux/plugins/tpm/tpm'
    '';
  };

  # Plugin Manager Installation
  # Automatically installs Tmux Plugin Manager (TPM)
  # This runs after configuration files are written
  home.activation.tmuxPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Check if TPM is already installed
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
      # Create plugin directory if it doesn't exist
      mkdir -p "$HOME/.tmux/plugins"
      # Clone TPM repository
      ${pkgs.git}/bin/git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
  '';
}
