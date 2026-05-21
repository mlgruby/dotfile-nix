# home-manager/aliases/dev-tools/modern-cli.nix
#
# Aliases for modern replacements of common Unix tools.
{ ... }:
{
  # eza (modern ls replacement)
  lsa = "eza -la"; # List all with details
  lst = "eza -T"; # Tree view
  lsta = "eza -Ta"; # Tree view including hidden files
  lsr = "eza -R"; # Recursive listing
  lsg = "eza -l --git"; # List with git status indicators
  lsm = "eza -l --sort=modified"; # Sort by modification time
  lss = "eza -l --sort=size"; # Sort by file size
  lsh = "eza -la --header"; # List with column headers
  lstree = "eza -T --level=3"; # Tree view (3 levels deep)

  # fd (modern find replacement)
  fdh = "fd -H"; # Include hidden files - usage: fdh pattern
  fa = "fd -a"; # Show absolute paths - usage: fa pattern
  ft = "fd -tf --changed-within 1d"; # Find files modified in last 24h
  fdir = "fd -td"; # Find directories only - usage: fdir pattern
  ff = "fd -tf"; # Find files only - usage: ff pattern
  fsym = "fd -tl"; # Find symlinks only
  fconf = "fd -e conf -e config"; # Find config files

  # File type shortcuts
  fpy = "fd -e py"; # Find Python files - usage: fpy pattern
  fjs = "fd -e js"; # Find JavaScript files - usage: fjs pattern
  fnix = "fd -e nix"; # Find Nix files - usage: fnix pattern
  fsh = "fd -e sh"; # Find shell scripts
  fmd = "fd -e md"; # Find markdown files
  fjson = "fd -e json"; # Find JSON files
  fyaml = "fd -e yaml"; # Find YAML files
  ftoml = "fd -e toml"; # Find TOML files

  # duf (modern df replacement)
  dfa = "duf --all"; # Show all filesystems
  dfh = "duf --hide-fs tmpfs,devtmpfs,efivarfs"; # Hide temporary filesystems
  dfi = "duf --only local,network"; # Show only local and network disks
  dfs = "duf --sort size"; # Sort by disk size

  # btm (modern top replacement)
  bm = "btm --basic"; # Basic system monitor view
  bmp = "btm --process_command"; # Show full process commands
  bmt = "btm --tree"; # Show process tree
  bmb = "btm --battery"; # Show battery info
  bmn = "btm --network_legend"; # Show network legend
}
