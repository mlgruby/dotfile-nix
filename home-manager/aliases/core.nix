# home-manager/aliases/core.nix
#
# Core Shell Aliases
#
# Purpose:
# - Essential shell navigation and utilities
# - File operations and quick shortcuts
# - Documentation tools (tldr, glow)
# - Network and system utilities
{
  config,
  userConfig,
  helpers,
  ...
}: let
  homeDir = config.home.homeDirectory;
  dotfileDir = "${homeDir}/${userConfig.directories.dotfiles}";
  inherit (helpers) mkTemplateAlias mkUserDirAliases;
in {
  # ==========================================================================
  # Shell Basics
  # ==========================================================================
  c = "clear";                    # Clear terminal screen
  x = "exit";                     # Exit shell
  h = "history";                  # Show command history
  r = "source ~/.zshrc";          # Reload zsh config
  rl = "exec zsh";                # Full shell reload (new process)
  q = "exit";                     # Quick exit

  # ==========================================================================
  # Navigation
  # ==========================================================================
  ".." = "cd ..";                 # Go up one directory
  "..." = "cd ../..";             # Go up two directories
  "...." = "cd ../../..";         # Go up three directories
  "....." = "cd ../../../..";     # Go up four directories
  "~" = "cd ~";                   # Go to home directory
  "-" = "cd -";                   # Go to previous directory

  # ==========================================================================
  # File Listing (basic - eza variants in dev-tools.nix)
  # ==========================================================================
  l = "eza -la --icons";          # List all files with details
  ll = "eza -l --icons";          # List files with details
  la = "eza -la --icons";         # List all files including hidden
  ls = "eza --icons";             # Use eza with icons by default

  # ==========================================================================
  # File Operations
  # ==========================================================================
  cp = "cp -i";                   # Confirm before overwrite
  mv = "mv -i";                   # Confirm before overwrite
  rm = "rm -i";                   # Confirm before delete
  mkdir = "mkdir -pv";            # Create parents, verbose
  backup = "cp -R";               # Quick backup - usage: backup source dest
  xtract = "tar -xzvf";           # Quick tar extract - usage: xtract file.tar.gz
  compress = "tar -czvf";         # Quick tar compress - usage: compress archive.tar.gz files/

  # ==========================================================================
  # Viewing Files
  # ==========================================================================
  cat = "bat";                    # Use bat for syntax highlighting
  less = "bat --paging=always";

  # ==========================================================================
  # Documentation Tools
  # ==========================================================================
  rtfm = "tldr";                  # Quick command examples (Read The Friendly Manual)
  cheat = "tldr";                 # Command cheatsheet lookup
  tldr-update = "tldr --update";  # Update tldr cache
  md = "glow";                    # Render markdown in terminal
  readme = "glow README.md";      # View README with formatting
  changes = "glow CHANGELOG.md";  # View CHANGELOG with formatting

  # ==========================================================================
  # Network Utilities
  # ==========================================================================
  ipp = "curl https://ipecho.net/plain; echo";        # Show public IP address
  myip = "curl https://ipecho.net/plain; echo";       # Show public IP address
  ping1 = "ping -c 1";                                # Ping once
  ping10 = "ping -c 10";                              # Ping 10 times
  ports-open = "netstat -tuln";                       # Show open network ports
  ports = "lsof -iTCP -sTCP:LISTEN -n -P";            # Show listening TCP ports

  # ==========================================================================
  # Time and Date
  # ==========================================================================
  now = "date '+%Y-%m-%d %H:%M:%S'";     # Current date and time
  today = "date '+%Y-%m-%d'";            # Current date (ISO format)
  week = "date '+%Y-W%U'";               # Current week number

  # ==========================================================================
  # Process Management
  # ==========================================================================
  psg = "ps aux | grep";          # Search running processes - usage: psg nginx
  killall = "pkill -f";           # Kill processes by name pattern - usage: killall node

  # ==========================================================================
  # Disk and Size
  # ==========================================================================
  size = "du -sh";                # Show directory/file size - usage: size /path/to/dir
  recent = "ls -lt | head -20";   # Show 20 most recently modified files

  # ==========================================================================
  # Clipboard (macOS)
  # ==========================================================================
  copy = "pbcopy";                # Copy to clipboard - usage: echo "text" | copy
  paste = "pbpaste";              # Paste from clipboard - usage: paste > file.txt

  # ==========================================================================
  # PATH Utilities
  # ==========================================================================
  path = "echo $PATH | tr ':' '\n'";     # Show PATH entries (one per line)

  # ==========================================================================
  # JSON/YAML Processing
  # ==========================================================================
  json = "python3 -m json.tool";         # Pretty-print JSON - usage: cat file.json | json
  yaml = "yq eval '.' -";                # Pretty-print YAML - usage: cat file.yaml | yaml

  # ==========================================================================
  # Dotfile Shortcuts
  # ==========================================================================
  lazydot = "cd ${dotfileDir} && lazygit";       # Open lazygit in dotfiles directory

  # Smart editor for dotfiles (cursor or code)
  codedot = mkTemplateAlias ''
    if command -v cursor &> /dev/null; then
      cursor "@dotfileDir@"
    else
      code "@dotfileDir@"
    fi
  '' [
    {name = "dotfileDir"; value = dotfileDir;}
  ];

  # ==========================================================================
  # Workspace Navigation
  # ==========================================================================
  work = "cd ${homeDir}/${userConfig.directories.workspace}";    # Navigate to workspace directory

  # ==========================================================================
  # Alias Discovery & Help
  # ==========================================================================
  alias-find = "alias | fzf --preview 'echo {}' --preview-window=right:50% | cut -d'=' -f1";  # Fuzzy find aliases
  alias-search = "alias | grep -i";                                                            # Search aliases by keyword - usage: alias-search docker
  alias-help = "${homeDir}/.config/home-manager/scripts/alias-cheatsheet.sh";                 # Show alias documentation - usage: alias-help [category]
  alias-quick = "${homeDir}/.config/home-manager/scripts/alias-cheatsheet.sh quick";          # Show quick reference of most used aliases
  alias-list = "alias | sort";                                                                 # List all aliases alphabetically
  alias-count = "alias | wc -l";                                                               # Count total aliases
} // (mkUserDirAliases userConfig.directories homeDir)
