# home-manager/config.nix
#
# Compatibility aggregator for domain-specific defaults. Import this file when a
# module needs more than one config area; otherwise prefer importing from
# ./config/<domain>.nix directly.
let
  aws = import ./config/aws.nix;
  claude = import ./config/claude.nix;
  sshConfig = import ./config/ssh.nix;
  shell = import ./config/shell.nix;
in
{
  inherit aws claude;
}
// sshConfig
// shell
