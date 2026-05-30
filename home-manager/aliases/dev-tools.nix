# home-manager/aliases/dev-tools.nix
#
# Development tool aliases.
#
# This file is intentionally only an aggregator. Keep each tool family in its
# own module so daily aliases stay easy to scan and refactor safely.
{ helpers, ... }:
let
  modernCliAliases = import ./dev-tools/modern-cli.nix { };
  agentAliases = import ./dev-tools/agents.nix { };
  tmuxAliases = import ./dev-tools/tmux.nix { };
  fzfAliases = import ./dev-tools/fzf.nix { };
  dockerAliases = import ./dev-tools/docker.nix { };
  opentofuAliases = import ./dev-tools/opentofu.nix { };
  kubernetesAliases = import ./dev-tools/kubernetes.nix { };
in
modernCliAliases
// agentAliases
// tmuxAliases
// fzfAliases
// dockerAliases
// opentofuAliases
// kubernetesAliases
