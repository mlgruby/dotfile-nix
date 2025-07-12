# home-manager/modules/fonts.nix
#
# Comprehensive Font Configuration & Management
#
# Purpose:
# - Centralizes ALL font-related configurations
# - Manages font installation, rendering, and application-specific settings
# - Ensures consistent typography across the entire system
#
# Features:
# - Font installation (non-Homebrew fonts only)
# - Font rendering optimization
# - Default font families configuration
# - Nerd Font support for icons and terminal
# - Application-specific font configurations
# - Font-related environment variables
#
# Integration:
# - Works with Homebrew-installed fonts (JetBrains Mono, Fira Code, etc.)
# - Configures Alacritty terminal fonts
# - Supports Starship prompt icons
# - Provides system-wide font consistency
#
# Note:
# - Primary fonts (JetBrains Mono, Fira Code, Hack, Meslo) installed via Homebrew
# - This module handles configuration and additional fonts
{pkgs, ...}: {
  # Home Manager font configuration
  fonts = {
    fontconfig = {
      enable = true;
      
      # Default font families (prioritize Homebrew-installed fonts)
      defaultFonts = {
        sansSerif = [ 
          "Inter" 
          "SF Pro Display" 
          "Helvetica Neue" 
          "Source Sans Pro"
          "Ubuntu"
          "DejaVu Sans"
          "Arial" 
        ];
        serif = [ 
          "Iowan Old Style" 
          "Source Serif Pro"
          "Georgia" 
          "DejaVu Serif"
          "Times New Roman" 
        ];
        monospace = [ 
          "JetBrains Mono"           # Primary (via Homebrew)
          "JetBrainsMono Nerd Font"  # With icons (via Homebrew)
          "Fira Code"                # Alternative (via Homebrew)
          "FiraCode Nerd Font"       # With icons (via Homebrew)
          "Hack Nerd Font"           # Clean option (via Homebrew)
          "SF Mono" 
          "Menlo" 
          "Monaco" 
          "Consolas"
          "Source Code Pro"
          "Ubuntu Mono"
        ];
        emoji = [ 
          "Apple Color Emoji"  # macOS native
          "Noto Color Emoji"   # Cross-platform fallback
          "Segoe UI Emoji"     # Windows compatibility
        ];
      };
    };
  };

  # Install fonts NOT already available via Homebrew
  # Note: JetBrains Mono, Fira Code, Hack, and Meslo Nerd Fonts are via Homebrew
  home.packages = with pkgs; [
    # System fonts (not available via Homebrew)
    inter                 # Modern UI font
    source-sans-pro       # Adobe's sans-serif
    source-serif-pro      # Adobe's serif
    ubuntu_font_family    # Ubuntu system fonts
    
    # Icon fonts (for applications that need them)
    font-awesome          # Web icons
    material-icons        # Google Material icons
    material-design-icons # Extended Material icons
    
    # International and fallback fonts
    liberation_ttf        # LibreOffice fonts
    dejavu_fonts          # Comprehensive Unicode
    noto-fonts            # Google's Unicode fonts
    noto-fonts-cjk-sans   # Chinese, Japanese, Korean
    noto-fonts-emoji      # Emoji fallback
    
    # Additional Nerd Fonts (not in Homebrew or as backup)
    nerd-fonts.sauce-code-pro    # Adobe's Source Code Pro (Nerd Font)
    nerd-fonts.ubuntu-mono       # Ubuntu monospace
    nerd-fonts.dejavu-sans-mono  # DejaVu monospace
    nerd-fonts.inconsolata       # Google's monospace
    # Note: JetBrainsMono, FiraCode, Hack, Meslo already via Homebrew
  ];

  # Font-related environment variables
  home.sessionVariables = {
    # Font paths and configuration
    FONTCONFIG_PATH = "$HOME/.nix-profile/etc/fonts";
    FONTCONFIG_FILE = "$HOME/.config/fontconfig/fonts.conf";
    
    # Application font preferences
    TERMINAL_FONT = "JetBrainsMono Nerd Font";
    EDITOR_FONT = "JetBrains Mono";
    UI_FONT = "Inter";
    
    # Font rendering hints
    FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
  };

  # Comprehensive fontconfig configuration
  home.file.".config/fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Global font rendering settings -->
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

      <!-- Monospace font preferences (for terminals, code editors) -->
      <alias>
        <family>monospace</family>
        <prefer>
          <family>JetBrains Mono</family>
          <family>JetBrainsMono Nerd Font</family>
          <family>Fira Code</family>
          <family>FiraCode Nerd Font</family>
          <family>Hack Nerd Font</family>
          <family>SF Mono</family>
          <family>Menlo</family>
          <family>Source Code Pro</family>
          <family>Ubuntu Mono</family>
          <family>Monaco</family>
          <family>Consolas</family>
          <family>DejaVu Sans Mono</family>
        </prefer>
      </alias>

      <!-- Sans-serif font preferences (for UI, web) -->
      <alias>
        <family>sans-serif</family>
        <prefer>
          <family>Inter</family>
          <family>SF Pro Display</family>
          <family>Helvetica Neue</family>
          <family>Source Sans Pro</family>
          <family>Ubuntu</family>
          <family>DejaVu Sans</family>
          <family>Liberation Sans</family>
          <family>Arial</family>
        </prefer>
      </alias>

      <!-- Serif font preferences (for documents) -->
      <alias>
        <family>serif</family>
        <prefer>
          <family>Iowan Old Style</family>
          <family>Source Serif Pro</family>
          <family>Georgia</family>
          <family>DejaVu Serif</family>
          <family>Liberation Serif</family>
          <family>Times New Roman</family>
        </prefer>
      </alias>

      <!-- Font substitutions for better compatibility -->
      <!-- Common font name mappings -->
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
        <edit name="family" mode="assign" binding="same"><string>JetBrains Mono</string></edit>
      </match>

      <match target="pattern">
        <test qual="any" name="family"><string>Monaco</string></test>
        <edit name="family" mode="assign" binding="same"><string>JetBrains Mono</string></edit>
      </match>

      <match target="pattern">
        <test qual="any" name="family"><string>Courier New</string></test>
        <edit name="family" mode="assign" binding="same"><string>JetBrains Mono</string></edit>
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

      <!-- Emoji font configuration -->
      <match target="pattern">
        <test name="family"><string>Apple Color Emoji</string></test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Noto Color Emoji</string>
        </edit>
      </match>

      <!-- Disable bitmap fonts for better quality -->
      <selectfont>
        <rejectfont>
          <pattern>
            <patelt name="scalable"><bool>false</bool></patelt>
          </pattern>
        </rejectfont>
      </selectfont>

      <!-- Improve font loading performance -->
      <match target="scan">
        <test name="family">
          <string>JetBrains Mono</string>
        </test>
        <edit name="charset" mode="assign">
          <charset>
            <int>0x0020</int>
            <int>0x007E</int>
          </charset>
        </edit>
      </match>
    </fontconfig>
  '';

  # Application-specific font configurations
  home.file = {
    # Alacritty font configuration (reference)
    # Note: Actual configuration is in alacritty/config.toml
    # Font settings: JetBrainsMono NF, size 16.0, all variants
    ".config/fonts/alacritty-fonts.md".text = ''
      # Alacritty Font Configuration
      
      Current font settings in alacritty/config.toml:
      - Family: JetBrainsMono NF (Nerd Font variant)
      - Size: 16.0
      - Variants: Regular, Bold, Italic, Bold Italic
      - Source: Installed via Homebrew (font-jetbrains-mono-nerd-font)
      
      Alternative fonts available:
      - FiraCode Nerd Font (ligatures)
      - Hack Nerd Font (clean)
      - SF Mono (system font)
      - Menlo (system font)
    '';

    # Starship font requirements (reference)
    ".config/fonts/starship-fonts.md".text = ''
      # Starship Prompt Font Requirements
      
      Starship uses Nerd Font icons for:
      - OS symbols (e.g., 󰀵 for macOS)
      - Git branch symbols ()
      - Language symbols (, , , etc.)
      - Directory symbols (󰈙, , etc.)
      
      Required fonts (installed via Homebrew):
      - JetBrainsMono Nerd Font (primary terminal font)
      - FiraCode Nerd Font (alternative with ligatures)
      - Hack Nerd Font (clean alternative)
      
      Fallback fonts (installed via Nix):
      - Source Code Pro Nerd Font
      - Ubuntu Mono Nerd Font
      - DejaVu Sans Mono Nerd Font
    '';

    # Font testing utilities
    ".config/fonts/test-fonts.sh".text = ''
      #!/usr/bin/env bash
      # Font testing utilities
      
      echo "=== Font Configuration Test ==="
      echo
      
      echo "🔤 Unicode Coverage Test:"
      echo "  Basic: Hello, World! 123"
      echo "  Symbols: → ← ↑ ↓ ✓ ✗ ★ ♠ ♥ ♦ ♣"
      echo "  Math: ∀ ∃ ∅ ∈ ∉ ∩ ∪ ⊂ ⊃ ≤ ≥ ≠ ≈ ∞"
      echo "  Arrows: ⇒ ⇐ ⇑ ⇓ ⇔ ↗ ↘ ↙ ↖"
      echo
      
      echo "💻 Programming Symbols:"
      echo "  Operators: == != <= >= && || ?? ?. ?:"
      echo "  Brackets: () [] {} <>"
      echo "  Quotes: single, double, backtick"
      echo "  Comments: // /* */ # <!-- -->"
      echo
      
      echo "🎨 Nerd Font Icons:"
      echo "  Files:     "
      echo "  Folders:   "
      echo "  Git:      "
      echo "  Languages:       "
      echo "  OS:       "
      echo
      
      echo "Available Fonts:"
      fc-list : family | grep -E "(JetBrains|Fira|Hack|Inter|Source)" | sort | uniq
    '';

    # Make test script executable
    ".config/fonts/test-fonts.sh".executable = true;
  };
}
