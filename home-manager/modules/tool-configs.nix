# home-manager/modules/tool-configs.nix
#
# Configuration Files for Homebrew-installed Tools
#
# Purpose:
# - Provides configuration for tools installed via Homebrew
# - Manages dotfiles and settings for CLI tools
# - Ensures consistent configuration without package conflicts
#
# Tools Configured:
# - bat: Syntax highlighting with Gruvbox theme
# - btop: Resource monitor with Gruvbox theme
# - ripgrep: Search configuration
# - jq: JSON processor colors
# - GPG: Security-focused configuration
#
# Note:
# - These tools are installed via Homebrew (see homebrew.nix)
# - This module only manages their configuration files
# - No packages are installed here to avoid conflicts
{...}: {
  # Configuration files for Homebrew-installed tools
  home.file = {
    # bat configuration (installed via Homebrew)
    ".config/bat/config".text = ''
      # Set theme to Gruvbox dark
      --theme="gruvbox-dark"
      
      # Show line numbers, Git modifications and file header
      --style="numbers,changes,header"
      
      # Use less as pager with specific options
      --pager="less -FR"
      
      # Custom syntax mappings
      --map-syntax="*.jenkinsfile:Groovy"
      --map-syntax="*.props:Java Properties"
      --map-syntax="*.conf:INI"
      --map-syntax="*.toml:TOML"
      --map-syntax="*.lock:JSON"
    '';

    # btop configuration (installed via Homebrew)
    ".config/btop/btop.conf".text = ''
      # Main UI settings
      color_theme = "gruvbox_dark_v2"
      theme_background = False
      truecolor = True
      force_tty = False
      presets = "cpu:1:default,proc:0:default mem:0:default,net:0:default"
      vim_keys = True
      rounded_corners = True
      graph_symbol = "braille"
      graph_symbol_cpu = "default"
      graph_symbol_mem = "default"
      graph_symbol_net = "default"
      graph_symbol_proc = "default"
      shown_boxes = "cpu mem net proc"
      update_ms = 1000
      proc_sorting = "cpu lazy"
      proc_reversed = False
      proc_tree = False
      proc_colors = True
      proc_gradient = True
      proc_per_core = False
      proc_mem_bytes = True
      proc_cpu_graphs = True
      proc_info_smaps = False
      proc_left = False
      cpu_graph_upper = "total"
      cpu_graph_lower = "total"
      cpu_invert_lower = True
      cpu_single_graph = False
      cpu_bottom = False
      show_uptime = True
      check_temp = True
      cpu_sensor = "Auto"
      show_coretemp = True
      cpu_core_map = ""
      temp_scale = "celsius"
      base_10_sizes = False
      show_cpu_freq = True
      clock_format = "%X"
      background_update = True
      custom_cpu_name = ""
      disks_filter = ""
      mem_graphs = True
      mem_below_net = False
      zfs_arc_cached = True
      show_swap = True
      swap_disk = True
      show_disks = True
      only_physical = True
      use_fstab = False
      zfs_hide_datasets = False
      disk_free_priv = False
      show_io_stat = True
      io_mode = False
      io_graph_combined = False
      io_graph_speeds = ""
      net_download = 100
      net_upload = 100
      net_auto = True
      net_sync = False
      net_iface = ""
      show_battery = True
      selected_battery = "Auto"
      log_level = "WARNING"
    '';

    # ripgrep configuration (installed via Homebrew)
    ".config/ripgrep/config".text = ''
      # Search hidden files and directories
      --hidden
      
      # Follow symbolic links
      --follow
      
      # Smart case: case-insensitive if all lowercase, case-sensitive otherwise
      --smart-case
      
      # Exclude common directories
      --glob=!.git/*
      --glob=!node_modules/*
      --glob=!.direnv/*
      --glob=!target/*
      --glob=!dist/*
      --glob=!build/*
      --glob=!*.lock
      
      # Use colors
      --colors=line:none
      --colors=line:style:bold
      --colors=path:fg:green
      --colors=path:style:bold
      --colors=match:fg:black
      --colors=match:bg:yellow
      --colors=match:style:nobold
    '';

    # jq configuration (installed via Homebrew)
    ".jq".text = ''
      # Custom color settings for jq
      def colors: {
        "null":    "0;37",
        "false":   "0;37", 
        "true":    "0;37",
        "numbers": "0;37",
        "strings": "0;32", 
        "arrays":  "1;37",
        "objects": "1;37"
      };
    '';

    # GPG configuration (installed via Homebrew)
    ".gnupg/gpg.conf".text = ''
      # Security-focused GPG configuration
      
      # Cipher preferences
      personal-cipher-preferences AES256 AES192 AES
      personal-digest-preferences SHA512 SHA384 SHA256
      personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
      default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
      
      # Algorithm settings
      cert-digest-algo SHA512
      s2k-digest-algo SHA512
      s2k-cipher-algo AES256
      
      # General settings
      charset utf-8
      fixed-list-mode
      no-comments
      no-emit-version
      no-greeting
      keyid-format 0xlong
      list-options show-uid-validity
      verify-options show-uid-validity
      with-fingerprint
      require-cross-certification
      no-symkey-cache
      use-agent
      throw-keyids
      
      # Keyserver settings
      keyserver hkps://keys.openpgp.org
      keyserver-options no-honor-keyserver-url
      keyserver-options include-revoked
    '';

    # GPG agent configuration
    ".gnupg/gpg-agent.conf".text = ''
      # GPG agent configuration
      
      # Cache settings (in seconds)
      default-cache-ttl 7200
      default-cache-ttl-ssh 7200
      max-cache-ttl 86400
      max-cache-ttl-ssh 86400
      
      # Enable SSH support
      enable-ssh-support
      
      # Pinentry program (use system default)
      # pinentry-program /usr/local/bin/pinentry-mac
      
      # Logging
      log-file ~/.gnupg/gpg-agent.log
      debug-level basic
    '';

    # Eza configuration (installed via Homebrew)
    ".config/eza/config".text = ''
      # Default options for eza
      --long
      --group-directories-first
      --header
      --icons
      --git
      --time-style=long-iso
      --color=auto
      --classify
    '';

    # Bottom (btm) configuration (installed via Homebrew)
    ".config/bottom/bottom.toml".text = ''
      # Bottom configuration
      
      [flags]
      # Basic mode
      basic = false
      
      # Show temperatures
      celsius = true
      
      # Show processes
      tree = false
      
      # Color scheme
      color = "gruvbox"
      
      # Update rate (in ms)
      rate = 1000
      
      # Left legend for CPU
      left_legend = true
      
      # Use old network legend
      use_old_network_legend = false
      
      # Hide time
      hide_time = false
      
      # Show table headers
      show_table_scroll_position = true
      
      # Disable mouse
      disable_click = false
      
      # Group processes
      group_processes = false
      
      # Case sensitive
      case_sensitive = false
      
      # Whole word search
      whole_word = false
      
      # Regex search
      regex = false
      
      # Default widget type
      default_widget_type = "proc"
      
      # Expanded by default
      expanded_on_startup = true
      
      [colors]
      # Gruvbox color scheme
      table_header_color = "LightBlue"
      all_cpu_color = "LightBlue"
      avg_cpu_color = "Red"
      cpu_core_colors = ["LightMagenta", "LightYellow", "LightCyan", "LightGreen", "LightBlue", "LightRed", "Cyan", "Green", "Blue", "Red"]
      ram_color = "LightMagenta"
      swap_color = "LightYellow"
      arc_color = "LightCyan"
      gpu_core_colors = ["LightGreen", "LightBlue", "LightRed", "Cyan", "Green", "Blue", "Red", "LightMagenta"]
      rx_color = "LightCyan"
      tx_color = "LightGreen"
      widget_title_color = "Gray"
      border_color = "Gray"
      highlighted_border_color = "LightBlue"
      text_color = "Gray"
      selected_text_color = "Black"
      selected_bg_color = "LightBlue"
      high_battery_color = "green"
      medium_battery_color = "yellow"
      low_battery_color = "red"
    '';
  };

  # Environment variables for tool configuration
  home.sessionVariables = {
    # Ripgrep configuration file
    RIPGREP_CONFIG_PATH = "$HOME/.config/ripgrep/config";
    
    # bat configuration
    BAT_CONFIG_PATH = "$HOME/.config/bat/config";
    
    # btop configuration
    BTOP_CONFIG_PATH = "$HOME/.config/btop/btop.conf";
    
    # GPG configuration
    GNUPGHOME = "$HOME/.gnupg";
  };
}
