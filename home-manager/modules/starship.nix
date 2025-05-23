# home-manager/modules/starship.nix
#
# Starship Prompt Theme
#
# Purpose:
# - Sets up shell prompt
# - Configures Gruvbox theme
#
# Integration:
# - Works with ZSH
# - Uses Nerd Font icons
#
# Note:
# - Requires Nerd Font
# - Uses Gruvbox colors
{...}: {
  programs.starship = {
    enable = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = ''[](color_orange)$os$username[](bg:color_yellow fg:color_orange)$directory[](fg:color_yellow bg:color_aqua)$git_branch$git_status[](fg:color_aqua bg:color_blue)$c$rust$golang$nodejs$php$java$kotlin$haskell$python[](fg:color_blue bg:color_bg3)$docker_context$conda[](fg:color_bg3 bg:color_bg1)[ ](fg:color_bg1)$line_break$character'';

      palette = "gruvbox_dark";

      palettes = {
        gruvbox_dark = {
          color_fg0 = "#fbf1c7"; # white
          color_bg1 = "#3c3836"; # dark gray
          color_bg3 = "#665c54"; # gray
          color_blue = "#458588"; # blue
          color_aqua = "#689d6a"; # green
          color_green = "#98971a"; # yellow
          color_orange = "#d65d0e"; # orange
          color_purple = "#b16286"; # purple
          color_red = "#cc241d"; # red
          color_yellow = "#d79921"; # yellow
        };
      };

      os = {
        disabled = false;
        style = "bg:color_orange fg:color_fg0";
        symbols = {
          Windows = "󰍲";
          Ubuntu = "󰕈";
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          EndeavourOS = "";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
          Pop = "";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:color_orange fg:color_fg0"; # Gruvbox orange
        style_root = "bg:color_orange fg:color_fg0"; # Gruvbox orange
        format = "[ $user ]($style)";
      };

      directory = {
        style = "fg:color_fg0 bg:color_yellow"; # Gruvbox yellow
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          # Gruvbox substitutions for text to icons
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = "󰝚 ";
          "Pictures" = " ";
          "Developer" = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:color_aqua"; # Gruvbox aqua
        format = "[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)";
      };

      git_status = {
        style = "bg:color_aqua"; # Gruvbox aqua
        format = "[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:color_blue"; # Gruvbox blue
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      c = {
        symbol = "";
        style = "bg:color_blue"; # Gruvbox blue
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      rust = {
        symbol = "";
        style = "bg:color_blue"; # Gruvbox blue
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      golang = {
        symbol = "";
        style = "bg:color_blue"; # Gruvbox blue
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      php = {
        symbol = "";
        style = "bg:color_blue"; # Gruvbox blue
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      java = {
        symbol = "";
        style = "bg:color_blue"; # Gruvbox blue
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      kotlin = {
        symbol = "";
        style = "bg:color_blue"; # Gruvbox blue
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      haskell = {
        symbol = "";
        style = "bg:color_blue"; # Gruvbox blue
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      python = {
        symbol = "";
        style = "bg:color_blue"; # Gruvbox blue
        format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
      };

      docker_context = {
        symbol = "";
        style = "bg:color_bg3"; # Gruvbox bg3
        format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      conda = {
        style = "bg:color_bg3"; # Gruvbox bg3
        format = "[[ $symbol( $environment) ](fg:#83a598 bg:color_bg3)]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:color_bg1"; # Gruvbox bg1
        format = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)";
      };

      line_break = {
        disabled = false;
      };

      character = {
        disabled = false;
        success_symbol = "[](bold fg:color_green)"; # Gruvbox green
        error_symbol = "[](bold fg:color_red)"; # Gruvbox red
        vimcmd_symbol = "[](bold fg:color_green)"; # Gruvbox green
        vimcmd_replace_one_symbol = "[](bold fg:color_purple)"; # Gruvbox purple
        vimcmd_replace_symbol = "[](bold fg:color_purple)"; # Gruvbox purple
        vimcmd_visual_symbol = "[](bold fg:color_yellow)"; # Gruvbox yellow
      };
    };
  };
}
