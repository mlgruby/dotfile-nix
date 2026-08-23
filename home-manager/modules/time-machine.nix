# Keep purgeable local Time Machine snapshots from consuming the internal disk.
# The remote Time Machine destination remains configured and untouched.
{ ... }:
{
  launchd.agents.tm-local-snapshot-cleanup = {
    enable = true;
    domain = "user";
    config = {
      ProgramArguments = [
        "/usr/bin/tmutil"
        "deletelocalsnapshots"
        "/"
      ];
      RunAtLoad = true;
      StartInterval = 3600;
    };
  };
}
