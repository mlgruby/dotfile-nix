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
{
  lib,
  pkgs,
  ...
}: {
  programs.tmux = {
    enable = true;
    shortcut = "a"; # Prefix: Ctrl-a
    baseIndex = 1; # Start windows at 1
    escapeTime = 0; # Remove delay
    


    extraConfig = ''
      # Core Settings
      set -g mouse on
      set -g status on
      set -g status-position top
      set -g default-terminal "screen-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"

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

      # Plugins - using TPM (tmux plugin manager)
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-yank'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @plugin 'tmux-plugins/tmux-continuum'
      set -g @plugin 'b0o/tmux-autoreload'
      set -g @plugin 'egel/tmux-gruvbox'
      set -g @plugin '2kabhishek/tmux2k'

      # Plugin Settings
      set -g @tmux2k-theme 'gruvbox'
      set -g @continuum-restore 'on'
      set -g @resurrect-capture-pane-contents 'on'
      set -g @tmux2k-icons-only true
      set -g @tmux2k-git-display-status true
      set -g @tmux2k-refresh-rate 5

      # Initialize TPM (keep this line at the very bottom)
      run '~/.tmux/plugins/tpm/tpm'
    '';
  };

  # Optimized TPM and Plugin Management
  home.activation.tmuxPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Enhanced tmux plugin management with error handling and updates
    manage_tmux_plugins() {
      local plugins_dir="$HOME/.tmux/plugins"
      local tpm_dir="$plugins_dir/tpm"
      local tmux2k_dir="$plugins_dir/tmux2k"
      
      # Ensure plugins directory exists
      mkdir -p "$plugins_dir"
      
      # TPM (Tmux Plugin Manager) installation/update
      if [ ! -d "$tpm_dir" ]; then
        echo "🔌 Installing TPM (Tmux Plugin Manager)..."
        if ${pkgs.git}/bin/git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"; then
          echo "✅ TPM installed successfully!"
        else
          echo "❌ Failed to install TPM"
          return 1
        fi
      else
        echo "🔄 Updating TPM..."
        if cd "$tpm_dir" && ${pkgs.git}/bin/git pull --ff-only > /dev/null 2>&1; then
          echo "✅ TPM updated successfully!"
        else
          echo "⚠️  TPM update skipped (no changes or conflicts)"
        fi
      fi
      
      # tmux2k theme installation/update
      if [ ! -d "$tmux2k_dir" ]; then
        echo "🎨 Installing tmux2k theme..."
        if ${pkgs.git}/bin/git clone --depth 1 https://github.com/2kabhishek/tmux2k "$tmux2k_dir"; then
          echo "✅ tmux2k theme installed successfully!"
        else
          echo "❌ Failed to install tmux2k theme"
          return 1
        fi
      else
        echo "🔄 Updating tmux2k theme..."
        if cd "$tmux2k_dir" && ${pkgs.git}/bin/git pull --ff-only > /dev/null 2>&1; then
          echo "✅ tmux2k theme updated successfully!"
        else
          echo "⚠️  tmux2k update skipped (no changes or conflicts)"
        fi
      fi
      
      # Make TPM scripts executable
      if [ -f "$tpm_dir/tpm" ]; then
        chmod +x "$tpm_dir/tpm"
        chmod +x "$tpm_dir/scripts"/* 2>/dev/null || true
      fi
      
      echo "🎯 Run 'tmux' and press 'prefix + I' to install/update all plugins"
    }
    
    # Run plugin management with error handling  
    manage_tmux_plugins || echo "⚠️  Tmux plugin management encountered issues"
  '';
}
