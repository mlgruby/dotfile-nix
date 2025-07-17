# home-manager/modules/directory-tools.nix
#
# Directory and File Visualization Tools
#
# Purpose:
# - Configures tools for directory navigation and file listing
# - Provides consistent Gruvbox theming for file operations
# - Enhances terminal file management experience
#
# Tools Configured:
# - broot: Interactive directory tree navigator with Git integration
# - dircolors: Color scheme for ls and file listings
#
# Features:
# - Comprehensive Gruvbox color schemes
# - Git status integration
# - File type recognition with icons
# - Terminal-optimized color support
# - Interactive navigation modes
#
# Integration:
# - Works with shell configuration (zsh.nix)
# - Compatible with eza and other listing tools
# - Matches overall system theming

{ config, lib, ... }:

{
  programs = {
    # Broot - Interactive directory tree navigator
    broot = {
      enable = true;
      enableZshIntegration = true;
      
      settings = {
        # Display settings
        modal = false;                 # Use immediate mode instead of modal
        show_selection_mark = true;    # Show selection indicators
        true_colors = true;           # Enable full color support
        icon_theme = "vscode";        # Use VS Code-style icons
        
        # Column layout for file information
        cols_order = [
          "mark"        # Selection mark
          "name"        # File/directory name
          "date"        # Modification date
          "size"        # File size
          "count"       # Directory item count
          "branch"      # Git branch
          "git"         # Git status
        ];
        
        # Gruvbox Dark theme for broot
        skin = {
          default = "rgb(235, 219, 178) none";              # Default text
          tree = "rgb(146, 131, 116) none";                 # Tree lines
          parent = "rgb(235, 219, 178) none";               # Parent directory
          file = "rgb(251, 241, 199) none";                 # Regular files
          directory = "rgb(131, 165, 152) none bold";       # Directories
          exe = "rgb(184, 187, 38) none";                   # Executable files
          link = "rgb(104, 157, 106) none";                 # Symbolic links
          pruning = "rgb(124, 111, 100) none italic";       # Pruned content
          
          # Permission indicators
          perm__ = "rgb(124, 111, 100) none";               # No permission
          perm_r = "rgb(215, 153, 33) none";                # Read permission
          perm_w = "rgb(204, 36, 29) none";                 # Write permission
          perm_x = "rgb(152, 151, 26) none";                # Execute permission
          
          # File metadata
          owner = "rgb(215, 153, 33) none";                 # File owner
          group = "rgb(215, 153, 33) none";                 # File group
          count = "rgb(69, 133, 136) none";                 # Directory count
          dates = "rgb(168, 153, 132) none";                # Date information
          sparse = "rgb(250, 189, 47) none";                # Sparse files
          
          # Content preview
          content_extract = "rgb(250, 189, 47) none";       # Content extract
          content_match = "rgb(250, 189, 47) none";         # Content matches
          
          # Git integration
          git_branch = "rgb(251, 241, 199) none";           # Git branch
          git_insertions = "rgb(152, 151, 26) none";        # Git insertions
          git_deletions = "rgb(190, 15, 23) none";          # Git deletions
          git_status_current = "rgb(60, 56, 54) none";      # Current git status
          git_status_modified = "rgb(152, 151, 26) none";   # Modified files
          git_status_new = "rgb(104, 187, 38) none";        # New files
          git_status_ignored = "rgb(124, 111, 100) none";   # Ignored files
          git_status_conflicted = "rgb(204, 36, 29) none";  # Conflicted files
          git_status_other = "rgb(204, 36, 29) none";       # Other git status
          
          # Selection and matching
          selected_line = "none rgb(60, 56, 54)";           # Selected line background
          char_match = "rgb(250, 189, 47) none";            # Character matches
          file_error = "rgb(251, 73, 52) none";             # File errors
          
          # Interface elements
          flag_label = "rgb(189, 174, 147) none";           # Flag labels
          flag_value = "rgb(211, 134, 155) none";           # Flag values
          input = "rgb(251, 241, 199) none";                # Input text
          
          # Status bar
          status_error = "rgb(213, 196, 161) rgb(204, 36, 29)";     # Error status
          status_job = "rgb(250, 189, 47) rgb(60, 56, 54)";         # Job status
          status_normal = "rgb(235, 219, 178) rgb(40, 40, 40)";     # Normal status
          status_italic = "rgb(211, 134, 155) rgb(40, 40, 40)";     # Italic status
          status_bold = "rgb(211, 134, 155) rgb(40, 40, 40)";       # Bold status
          status_code = "rgb(251, 241, 199) rgb(40, 40, 40)";       # Code status
          status_ellipsis = "rgb(251, 241, 199) rgb(40, 40, 40)";   # Ellipsis
          
          # Purpose/help text
          purpose_normal = "rgb(235, 219, 178) none";        # Normal purpose text
          purpose_italic = "rgb(178, 153, 132) none";        # Italic purpose text
          purpose_bold = "rgb(211, 134, 155) none";          # Bold purpose text
          purpose_ellipsis = "rgb(124, 111, 100) none";      # Purpose ellipsis
          
          # Scrollbar
          scrollbar_track = "rgb(80, 73, 69) none";          # Scrollbar track
          scrollbar_thumb = "rgb(213, 196, 161) none";       # Scrollbar thumb
          
          # Help system
          help_paragraph = "rgb(235, 219, 178) none";        # Help paragraphs
          help_bold = "rgb(211, 134, 155) none";             # Help bold text
          help_italic = "rgb(211, 134, 155) none";           # Help italic text
          help_code = "rgb(251, 241, 199) rgb(40, 40, 40)";  # Help code blocks
          help_headers = "rgb(250, 189, 47) none";           # Help headers
          help_table_border = "rgb(124, 111, 100) none";     # Help table borders
          
          # Preview pane
          preview = "rgb(235, 219, 178) rgb(40, 40, 40)";            # Preview background
          preview_title = "rgb(235, 219, 178) rgb(40, 40, 40)";      # Preview title
          preview_separator = "rgb(168, 153, 132) none";             # Preview separator
          preview_match = "None rgb(178, 153, 132)";                 # Preview matches
          
          # Hex viewer
          hex_null = "rgb(189, 174, 147) none";              # Hex null bytes
          hex_ascii_graphic = "rgb(213, 196, 161) none";     # Hex ASCII graphic
          hex_ascii_whitespace = "rgb(152, 151, 26) none";   # Hex ASCII whitespace
          hex_ascii_other = "rgb(254, 128, 25) none";        # Hex ASCII other
        };
      };
    };

    # Dircolors - Color scheme for ls and file listings
    dircolors = {
      enable = true;
      enableZshIntegration = true;
      
      extraConfig = ''
        # Gruvbox color scheme for ls and file listings
        # Terminal type definitions
        TERM Eterm
        TERM ansi
        TERM color-xterm
        TERM con132x25
        TERM con132x30
        TERM con132x43
        TERM con132x60
        TERM con80x25
        TERM con80x28
        TERM con80x30
        TERM con80x43
        TERM con80x50
        TERM con80x60
        TERM cons25
        TERM console
        TERM cygwin
        TERM dtterm
        TERM dvtm
        TERM dvtm-256color
        TERM Eterm-color
        TERM eterm-color
        TERM fbterm
        TERM gnome
        TERM gnome-256color
        TERM jfbterm
        TERM konsole
        TERM kterm
        TERM linux
        TERM linux-c
        TERM mach-color
        TERM mlterm
        TERM putty
        TERM putty-256color
        TERM rxvt
        TERM rxvt-256color
        TERM rxvt-cygwin
        TERM rxvt-cygwin-native
        TERM rxvt-unicode
        TERM rxvt-unicode256
        TERM rxvt-unicode-256color
        TERM screen
        TERM screen-256color
        TERM screen-256color-bce
        TERM screen-256color-s
        TERM screen-256color-bce-s
        TERM screen-bce
        TERM screen-w
        TERM screen.linux
        TERM screen.xterm-256color
        TERM st
        TERM st-256color
        TERM st-meta
        TERM st-meta-256color
        TERM tmux
        TERM tmux-256color
        TERM vt100
        TERM vt220
        TERM vt52
        TERM xterm
        TERM xterm-16color
        TERM xterm-256color
        TERM xterm-88color
        TERM xterm-color
        TERM xterm-debian
        TERM xterm-termite
        
        # Gruvbox color definitions
        NORMAL 00;38;5;244                    # Normal text
        FILE 00                               # Regular files
        RESET 0                               # Reset to normal
        DIR 01;38;5;109                       # Directories (bright blue)
        LINK 01;38;5;108                      # Symbolic links (bright cyan)
        MULTIHARDLINK 00                      # Multiple hard links
        FIFO 48;5;230;38;5;136;01            # Named pipes (FIFOs)
        SOCK 48;5;230;38;5;136;01            # Sockets
        DOOR 48;5;230;38;5;136;01            # Doors (Solaris)
        BLK 48;5;230;38;5;244;01             # Block devices
        CHR 48;5;230;38;5;244;01             # Character devices
        ORPHAN 48;5;235;38;5;167             # Orphaned symlinks
        SETUID 48;5;160;38;5;230             # SETUID files
        SETGID 48;5;136;38;5;230             # SETGID files
        CAPABILITY 30;41                      # Files with capabilities
        STICKY_OTHER_WRITABLE 48;5;64;38;5;230   # Sticky and other-writable
        OTHER_WRITABLE 48;5;235;38;5;109     # Other-writable files
        STICKY 48;5;33;38;5;230              # Sticky bit files
        EXEC 01;38;5;142                     # Executable files (bright green)
      '';
    };
  };
}
