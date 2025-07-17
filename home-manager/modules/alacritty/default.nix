# home-manager/modules/alacritty/default.nix
#
# Alacritty Configuration (Declarative)
#
# Purpose:
# - Manages Alacritty themes via activation script
# - Manages main config via programs.alacritty.settings
#
# Integration:
# - Imports config.toml
# - Uses Home Manager activation for themes
#
# Note:
# - Package from Homebrew
{
  lib,
  pkgs,
  ...
}: {
  programs.alacritty = {
    enable = true;
    # Read settings directly from the TOML file
    settings = builtins.fromTOML (builtins.readFile ./config.toml);
  };

  # Optimized Theme Repository Management
  home.activation.alacrittyThemes = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Enhanced Alacritty theme management with error handling and smart updates
    manage_alacritty_themes() {
      local themes_dir="$HOME/.config/alacritty/themes"
      local config_dir="$HOME/.config/alacritty"
      
      # Ensure config directory exists
      mkdir -p "$config_dir"
      
    # Clone or update alacritty-theme repository
      if [ ! -d "$themes_dir" ]; then
        echo "🎨 Installing Alacritty themes repository..."
        if ${pkgs.git}/bin/git clone --depth 1 https://github.com/alacritty/alacritty-theme "$themes_dir"; then
          echo "✅ Alacritty themes installed successfully!"
          echo "📁 Available themes: $(find "$themes_dir/themes" -name "*.toml" | wc -l) themes"
        else
          echo "❌ Failed to clone Alacritty themes repository"
          return 1
        fi
      else
        # Only update if it's actually a git repository and has remote changes
        if [ -d "$themes_dir/.git" ]; then
          echo "🔄 Checking for Alacritty theme updates..."
          cd "$themes_dir"
          
          # Fetch to check for updates without pulling
          if ${pkgs.git}/bin/git fetch --dry-run > /dev/null 2>&1; then
            # Check if we're behind remote
            local local_commit=$(${pkgs.git}/bin/git rev-parse HEAD)
            local remote_commit=$(${pkgs.git}/bin/git rev-parse @{u} 2>/dev/null || echo "$local_commit")
            
            if [ "$local_commit" != "$remote_commit" ]; then
              echo "📥 Updating Alacritty themes..."
              if ${pkgs.git}/bin/git pull --ff-only > /dev/null 2>&1; then
                echo "✅ Alacritty themes updated successfully!"
              else
                echo "⚠️  Theme update skipped (conflicts or non-fast-forward)"
              fi
            else
              echo "✨ Alacritty themes are already up to date"
            fi
          else
            echo "⚠️  Unable to check for theme updates (network or permission issue)"
          fi
        else
          echo "⚠️  Themes directory exists but is not a git repository"
        fi
      fi
      
      # Verify theme availability
      if [ -d "$themes_dir/themes" ]; then
        local theme_count=$(find "$themes_dir/themes" -name "*.toml" | wc -l)
        echo "🎨 $theme_count themes available in: $themes_dir/themes/"
      fi
    }
    
    # Run theme management with error handling
    manage_alacritty_themes || echo "⚠️  Alacritty theme management encountered issues"
  '';
}
