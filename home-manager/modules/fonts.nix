# home-manager/modules/fonts.nix
#
# Font Configuration & Management (Homebrew-Consolidated)
#
# Purpose:
# - Configures font rendering and fallbacks for Homebrew-installed fonts
# - Provides font aliases and substitutions
# - Manages font-related environment variables
#
# Philosophy:
# - ALL fonts installed via Homebrew for better macOS integration
# - This module only handles configuration, not installation
# - Focuses on font rendering optimization and fallbacks
#
# Homebrew Fonts Managed:
# - JetBrains Mono Nerd Font (primary coding)
# - Fira Code Nerd Font (ligatures)
# - Hack Nerd Font (clean)
# - Inter (UI font)
# - Source Serif Pro (documents)
# - Additional Nerd Fonts for compatibility
#
# Integration:
# - Works with Stylix (uses system fonts)
# - Optimized for Alacritty terminal
# - Supports Starship prompt icons
#
# Note:
# - No packages installed here (all via Homebrew)
# - Focus on configuration and optimization

{ config, lib, pkgs, ... }:

{
  # Home Manager font configuration
  fonts = {
    fontconfig = {
      enable = true;
      
      # Default font families (all fonts installed via Homebrew)
      defaultFonts = {
        sansSerif = [ 
            "Inter"                    # Primary UI font (via Homebrew)
            "Source Sans 3"            # Adobe sans-serif (via Homebrew)
            "SF Pro Display"           # macOS system font
            "Helvetica Neue"           # macOS fallback
            "Arial"                    # Universal fallback
        ];
        serif = [ 
            "Source Serif 4"           # Primary serif (via Homebrew)
            "Iowan Old Style"          # macOS serif
            "Georgia"                  # Universal serif
            "Times New Roman"          # Universal fallback
        ];
        monospace = [ 
          "JetBrainsMonoNL Nerd Font Mono" # Primary coding, no ligatures
          "FiraCode Nerd Font"       # Alternative with ligatures (via Homebrew)
          "Hack Nerd Font"           # Clean option (via Homebrew)
          "SauceCodePro Nerd Font"   # Adobe Source Code Pro (via Homebrew)
          "SF Mono"                  # macOS system mono
          "Menlo"                    # macOS fallback mono
          "Monaco"                   # Classic macOS mono
        ];
        emoji = [ 
          "Apple Color Emoji"        # macOS native emoji
          "Noto Color Emoji"         # Cross-platform fallback
        ];
      };
    };
  };

  # Font-related environment variables
  home.sessionVariables = {
    # Font configuration paths
    FONTCONFIG_PATH = "$HOME/.nix-profile/etc/fonts";
    
    # Application font preferences (using Homebrew fonts)
    TERMINAL_FONT = "JetBrainsMonoNL Nerd Font Mono";
    EDITOR_FONT = "JetBrainsMonoNL Nerd Font Mono";
    UI_FONT = "Inter";
    
    # Font rendering optimization
    FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
  };

  # Optimized fontconfig configuration
  home.file.".config/fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Font rendering optimization for macOS -->
      <match target="font">
        <edit name="antialias" mode="assign">
          <bool>true</bool>
        </edit>
        <edit name="hinting" mode="assign">
          <bool>true</bool>
        </edit>
        <edit name="hintstyle" mode="assign">
          <const>hintslight</const>
        </edit>
        <edit name="rgba" mode="assign">
          <const>rgb</const>
        </edit>
        <edit name="lcdfilter" mode="assign">
          <const>lcddefault</const>
        </edit>
        <edit name="embeddedbitmap" mode="assign">
          <bool>false</bool>
        </edit>
      </match>

      <!-- Monospace font preferences (Homebrew Nerd Fonts) -->
      <alias>
        <family>monospace</family>
        <prefer>
          <family>JetBrainsMonoNL Nerd Font Mono</family>
          <family>FiraCode Nerd Font</family>
          <family>Hack Nerd Font</family>
          <family>SauceCodePro Nerd Font</family>
          <family>UbuntuMono Nerd Font</family>
          <family>SF Mono</family>
          <family>Menlo</family>
          <family>Monaco</family>
        </prefer>
      </alias>

      <!-- Sans-serif font preferences (Homebrew + system) -->
      <alias>
        <family>sans-serif</family>
        <prefer>
          <family>Inter</family>
            <family>Source Sans 3</family>
          <family>SF Pro Display</family>
          <family>Helvetica Neue</family>
          <family>Arial</family>
        </prefer>
      </alias>

        <!-- Serif font preferences (Homebrew + system) -->
      <alias>
        <family>serif</family>
        <prefer>
            <family>Source Serif 4</family>
          <family>Iowan Old Style</family>
          <family>Georgia</family>
          <family>Times New Roman</family>
        </prefer>
      </alias>

      <!-- Font substitutions for better compatibility -->
      <match target="pattern">
        <test qual="any" name="family"><string>Helvetica</string></test>
        <edit name="family" mode="assign" binding="same"><string>Inter</string></edit>
      </match>

      <match target="pattern">
        <test qual="any" name="family"><string>Arial</string></test>
        <edit name="family" mode="assign" binding="same"><string>Inter</string></edit>
      </match>

      <match target="pattern">
        <test qual="any" name="family"><string>Consolas</string></test>
        <edit name="family" mode="assign" binding="same"><string>JetBrainsMonoNL Nerd Font Mono</string></edit>
      </match>

      <match target="pattern">
        <test qual="any" name="family"><string>Monaco</string></test>
        <edit name="family" mode="assign" binding="same"><string>JetBrainsMonoNL Nerd Font Mono</string></edit>
      </match>

      <!-- System font mappings -->
      <match target="pattern">
        <test qual="any" name="family"><string>system-ui</string></test>
        <edit name="family" mode="assign" binding="same"><string>Inter</string></edit>
      </match>

      <match target="pattern">
        <test qual="any" name="family"><string>-apple-system</string></test>
        <edit name="family" mode="assign" binding="same"><string>SF Pro Display</string></edit>
      </match>
    </fontconfig>
  '';

  # Font documentation and testing utilities
  home.file = {
    # Font reference documentation
    ".config/fonts/homebrew-fonts.md".text = ''
      # Homebrew Font Collection
      
      All fonts managed via Homebrew for optimal macOS integration.
      
             ## Primary Fonts:
       - JetBrainsMonoNL Nerd Font Mono (coding/terminal)
       - Inter (UI/sans-serif)  
       - Source Serif 4 (documents)
      
      ## Alternative Coding Fonts:
      - FiraCode Nerd Font (ligatures)
      - Hack Nerd Font (clean)
      - SauceCodePro Nerd Font
      - UbuntuMono Nerd Font
      
      ## Installation:
      All fonts installed automatically via darwin-rebuild through Homebrew casks.
      
      ## Configuration:
      - Stylix: Uses system fonts (package = null)
      - Fontconfig: Optimized for macOS rendering
      - Applications: Reference fonts by name
    '';

    # Font testing script
    ".config/fonts/test-fonts.sh".text = ''
      #!/usr/bin/env bash
      # Font testing for Homebrew-installed fonts
      
      echo "=== Homebrew Font Test ==="
      echo "🎨 Nerd Font Icons:"
      echo "  Files:     "
      echo "  Git:      "
      echo "  Languages:       "
      echo
      
      echo "💻 Coding Symbols:"
      echo "  Operators: == != <= >= && || ??"
      echo "  Arrows: → ← ↑ ↓ ⇒ ⇐"
      echo
      
             echo "📝 Typography:"
       echo "  Sans: Inter font sample (UI)"
       echo "  Serif: Source Serif 4 sample (documents)"
       echo "  Mono: JetBrainsMonoNL Nerd Font Mono sample (code)"
      echo
      
      echo "Available Homebrew Fonts:"
      ls /opt/homebrew/Caskroom/ | grep font | head -10
    '';

    # Make test script executable
    ".config/fonts/test-fonts.sh".executable = true;
  };
}
