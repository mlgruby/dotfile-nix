{ pkgs, ... }:

let
  px0 = pkgs.stdenv.mkDerivation rec {
    pname = "px0";
    version = "0.1.1";

    src = pkgs.fetchurl {
      url = "https://github.com/px0-ai/px0/releases/download/v${version}/px0-${version}-darwin-arm64";
      sha256 = "18fgxzfymn1csgxa49075gva0hl9476plj3qdxch0zf32mp5w1vx";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/px0
      chmod +x $out/bin/px0
    '';

    meta = with pkgs.lib; {
      description = "Local code navigator and symbol call graph visualizer";
      homepage = "https://px0.ai";
      platforms = [ "aarch64-darwin" ];
    };
  };
in
{
  home.packages = with pkgs; [
    httpie # Modern HTTP client
    shellcheck # Shell script linting
    git-extras # Additional Git commands and utilities
    tokei # Code statistics and line counting
    hyperfine # Command-line benchmarking tool
    choose # Human-friendly cut/awk alternative
    sd # Modern sed alternative
    grex # Generate regular expressions from examples
    ccusage # Claude Code usage and cost reporting
    postgresql # PostgreSQL client tools (psql, pg_dump, pg_restore)
    delta # Syntax-highlighting pager for git and lazygit diffs
    px0 # Local code navigator and symbol visualizer
  ];
}
