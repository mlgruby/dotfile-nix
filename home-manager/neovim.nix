{
  pkgs,
  lib,
  ...
}: {
  # Optimized LazyVim Installation with Enhanced Error Handling
  home.activation.installLazyVim = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # LazyVim installation with improved error handling and cleanup
    install_lazyvim() {
      local config_dir="$HOME/.config/nvim"
      local backup_suffix=".bak.$(date +%Y%m%d_%H%M%S)"
      
      if [ ! -d "$config_dir" ]; then
        echo "🚀 Installing LazyVim..."
        
        # Create backup directory for safety
        local backup_dir="$HOME/.config/nvim-backups"
        mkdir -p "$backup_dir"
        
        # Backup existing configurations with timestamps
        for dir in "$HOME/.config/nvim" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
          if [ -e "$dir" ]; then
            echo "📦 Backing up $(basename "$dir") to $backup_dir/"
            mv "$dir" "$backup_dir/$(basename "$dir")$backup_suffix" 2>/dev/null || true
          fi
        done
        
        # Clone LazyVim starter with error handling
        if ${pkgs.git}/bin/git clone --depth 1 https://github.com/LazyVim/starter "$config_dir"; then
          # Remove git history to make it your own
          rm -rf "$config_dir/.git"
          echo "✅ LazyVim installed successfully!"
          echo "📁 Backups stored in: $backup_dir"
          echo "🎯 Run 'nvim' to complete the setup"
        else
          echo "❌ Failed to clone LazyVim starter"
          return 1
        fi
      else
        echo "✨ LazyVim is already installed."
      fi
    }
    
    # Run installation with error handling
    install_lazyvim || echo "⚠️  LazyVim installation encountered issues"
  '';
}
