# System, filesystem, networking, and archive tools managed by Home Manager.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nmap # Network scanner and security tool
    netcat # Network utility for reading/writing network connections
    unzip # ZIP file extraction
    p7zip # 7-Zip compression tool
    fd # Modern replacement for find
    duf # Modern replacement for df
    dust # Modern replacement for du
    procs # Modern replacement for ps
    watch # Execute commands periodically
    parallel # Execute commands in parallel
    rsync # File synchronization and transfer
    lsof # List open files and processes
    file # File type identification
    tree # Directory structure visualization
    fastfetch # System information display
    screen # Terminal multiplexer fallback
  ];
}
