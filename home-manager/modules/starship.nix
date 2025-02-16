# home-manager/modules/starship.nix
#
# Starship prompt configuration
#
# Purpose:
# - Configures a feature-rich shell prompt
# - Shows contextual development information
# - Provides visual workspace awareness
#
# Features:
# - Custom prompt segments:
#   - OS and username display
#   - Current directory with icons
#   - Git branch and status
#   - Language versions (Node, Python, etc.)
#   - Docker and Conda environments
#   - Time display
#
# Theme:
# - Uses Gruvbox Dark color palette
# - Custom icons for different segments
# - Powerline-style prompt separators
#
# Segments (left to right):
# 1. System     : OS icon and username
# 2. Path       : Current directory with custom icons
# 3. Git        : Branch and status information
# 4. Languages  : Active language versions
# 5. Tools      : Docker and Conda status
# 6. Time       : Current time display
#
# Integration:
# - Works with ZSH configuration
# - Supports Nerd Font icons
# - Compatible with version managers
#
# Note:
# - Requires a Nerd Font to be installed
# - Some icons may need terminal Unicode support
# - Color scheme matches Alacritty theme

{ config, pkgs, ... }: {
  programs.starship = {
    enable = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      # Main Prompt Format
      # Defines the layout and order of prompt segments
      # Uses custom separators () for Powerline style
      format = ''
        [](color_orange)\
        $os\
        $username\
        [](bg:color_yellow fg:color_orange)\
        $directory\
        [](fg:color_yellow bg:color_aqua)\
        $git_branch\
        $git_status\
        [](fg:color_aqua bg:color_blue)\
        $c\
        $rust\
        $golang\
        $nodejs\
        $php\
        $java\
        $kotlin\
        $haskell\
        $python\
        [](fg:color_blue bg:color_bg3)\
        $docker_context\
        $conda\
        [](fg:color_bg3 bg:color_bg1)\
        $time\
        [ ](fg:color_bg1)\
        $line_break$character'';

      # Color Palette
      # Gruvbox Dark theme colors for consistent styling
      palette.gruvbox_dark = {
        color_fg0 = "#fbf1c7";         # Light foreground
        color_bg1 = "#3c3836";         # Dark background
        color_bg3 = "#665c54";         # Medium background
        color_blue = "#458588";        # Programming languages
        color_aqua = "#689d6a";        # Git information
        color_green = "#98971a";       # Success indicators
        color_orange = "#d65d0e";      # System information
        color_purple = "#b16286";      # Vim mode indicators
        color_red = "#cc241d";         # Error indicators
        color_yellow = "#d79921";      # Directory information
      };

      # Operating System Segment
      # Shows OS-specific icons in the prompt
      os = {
        disabled = false;
        style = "bg:color_orange fg:color_fg0";
        symbols = {
          Windows = "󰍲";               # Windows icon
          Ubuntu = "󰕈";               # Ubuntu icon
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";               # macOS icon
          Manjaro = "";
          Linux = "󰌽";               # Generic Linux
          Gentoo = "󰣨";
          Fedora = "��";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          EndeavourOS = "";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
          Pop = "";
        };
      };

      # Username Display
      # Shows current user with consistent styling
      username = {
        show_always = true;
        style_user = "bg:color_orange fg:color_fg0";
        style_root = "bg:color_orange fg:color_fg0";
        format = "[ $user ]($style)";
      };

      # Directory Information
      # Shows current path with custom folder icons
      directory = {
        style = "fg:color_fg0 bg:color_yellow";
        format = "[ $path ]($style)";
        truncation_length = 3;          # Show 3 levels deep
        truncation_symbol = "…/";       # Indicator for truncated paths
        substitutions = {
          Documents = "󰈙 ";            # Documents folder icon
          Downloads = " ";             # Downloads folder icon
          Music = "�� ";               # Music folder icon
          Pictures = " ";              # Pictures folder icon
          Developer = "󰲋 ";            # Developer folder icon
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:color_aqua";
        format = "[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)";
      };

      git_status = {
        style = "bg:color_aqua";
        format = "[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      c = {
        symbol = " ";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      java = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      python = {
        symbol = "";
        style = "bg:color_blue";
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      docker_context = {
        symbol = "";
        style = "bg:color_bg3";
        format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      conda = {
        style = "bg:color_bg3";
        format = "[[ $symbol( $environment) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:color_bg1";
        format = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)";
      };

      line_break.disabled = false;

      character = {
        disabled = false;
        success_symbol = "[](bold fg:color_green)";
        error_symbol = "[](bold fg:color_red)";
        vimcmd_symbol = "[](bold fg:color_green)";
        vimcmd_replace_one_symbol = "[](bold fg:color_purple)";
        vimcmd_replace_symbol = "[](bold fg:color_purple)";
        vimcmd_visual_symbol = "[](bold fg:color_yellow)";
      };
    };
  };
} 
