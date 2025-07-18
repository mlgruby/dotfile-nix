# home-manager/modules/btop.nix
#
# btop Configuration with Home Manager Integration
#
# Purpose:
# - Uses Home Manager's programs.btop module for declarative configuration
# - Migrated from manual config in tool-configs.nix
# - Provides resource monitoring with proper theming integration
#
# Features:
# - Comprehensive system monitoring (CPU, memory, network, disk, processes)
# - Vim-style key bindings
# - Modern braille graph symbols
# - Automatic theme integration with Stylix
# - Optimized update intervals and display options
#
# Integration:
# - Package managed by Home Manager
# - Configuration fully declarative
# - Theming handled by Stylix (color settings omitted)
#
# Note:
# - Replaces manual configuration from tool-configs.nix
# - All boolean values properly formatted for Nix
# - Settings match previous manual configuration
{...}: {
  programs.btop = {
    enable = true;
    
    settings = {
      # Main UI settings
      theme_background = false;
      truecolor = true;
      force_tty = false;
      presets = "cpu:1:default,proc:0:default mem:0:default,net:0:default";
      vim_keys = true;
      rounded_corners = true;
      graph_symbol = "braille";
      graph_symbol_cpu = "default";
      graph_symbol_mem = "default";
      graph_symbol_net = "default";
      graph_symbol_proc = "default";
      shown_boxes = "cpu mem net proc";
      update_ms = 1000;
      
      # Process settings
      proc_sorting = "cpu lazy";
      proc_reversed = false;
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      proc_info_smaps = false;
      proc_left = false;
      
      # CPU settings
      cpu_graph_upper = "total";
      cpu_graph_lower = "total";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = false;
      show_uptime = true;
      check_temp = true;
      cpu_sensor = "Auto";
      show_coretemp = true;
      cpu_core_map = "";
      temp_scale = "celsius";
      show_cpu_freq = true;
      
      # System settings
      base_10_sizes = false;
      clock_format = "%X";
      background_update = true;
      custom_cpu_name = "";
      
      # Disk settings
      disks_filter = "";
      show_disks = true;
      only_physical = true;
      use_fstab = false;
      zfs_hide_datasets = false;
      disk_free_priv = false;
      show_io_stat = true;
      io_mode = false;
      io_graph_combined = false;
      io_graph_speeds = "";
      
      # Memory settings
      mem_graphs = true;
      mem_below_net = false;
      zfs_arc_cached = true;
      show_swap = true;
      swap_disk = true;
      
      # Network settings
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = false;
      net_iface = "";
      
      # Battery settings
      show_battery = true;
      selected_battery = "Auto";
      
      # Logging
      log_level = "WARNING";
    };
  };
}
