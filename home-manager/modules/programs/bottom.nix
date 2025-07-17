# home-manager/modules/bottom.nix
#
# bottom Configuration with Home Manager Integration
#
# Purpose:
# - Uses Home Manager's programs.bottom module for declarative configuration
# - Migrated from manual config in tool-configs.nix
# - Cross-platform graphical process/system monitor
#
# Features:
# - Comprehensive system monitoring (CPU, memory, network, disk, processes)
# - Temperature display in Celsius
# - Optimized update intervals and display options
# - Process management and search capabilities
# - Automatic theme integration with Stylix
#
# Integration:
# - Package managed by Home Manager
# - Configuration fully declarative via programs.bottom.settings
# - Theming handled by Stylix (color settings omitted)
#
# Note:
# - Replaces manual configuration from tool-configs.nix
# - All bottom settings now managed through Home Manager
# - TOML structure matches previous manual configuration

{ config, lib, pkgs, ... }:

{
  programs.bottom = {
    enable = true;
    
    settings = {
      flags = {
        # Display settings
        basic = false;                          # Use full interface, not basic mode
        celsius = true;                         # Show temperatures in Celsius
        tree = false;                          # Don't show process tree by default
        
        # Update and performance
        rate = 1000;                           # Update rate in milliseconds (1 second)
        
        # Interface options
        left_legend = true;                    # Show legend on left side for CPU
        use_old_network_legend = false;       # Use new network legend format
        hide_time = false;                     # Show time information
        show_table_scroll_position = true;    # Show scroll position in tables
        disable_click = false;                 # Enable mouse interactions
        
        # Process management
        group_processes = false;               # Don't group processes by default
        case_sensitive = false;                # Case-insensitive search
        whole_word = false;                    # Allow partial word matching
        regex = false;                         # Use simple search, not regex
        
        # Default view settings
        default_widget_type = "proc";          # Start with process widget
        expanded_on_startup = true;            # Start with expanded view
      };
      
      # Note: Colors automatically managed by Stylix
      # Original color configuration removed to use system-wide theming
    };
  };
}
