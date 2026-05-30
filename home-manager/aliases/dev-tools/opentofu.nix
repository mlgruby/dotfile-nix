# home-manager/aliases/dev-tools/opentofu.nix
#
# OpenTofu workflow aliases.
{ ... }:
{
  tofu = "tofu"; # OpenTofu command
  tf = "tofu"; # Short OpenTofu shorthand
  tfin = "tofu init"; # Initialize OpenTofu
  tfp = "tofu plan"; # Show execution plan
  tfa = "tofu apply"; # Apply changes
  tfd = "tofu destroy"; # Destroy infrastructure

  # Workspace management
  tfwst = "tofu workspace select"; # Switch workspace
  tfwsw = "tofu workspace show"; # Show current workspace
  tfwls = "tofu workspace list"; # List workspaces
  tfwsn = "tofu workspace new"; # Create new workspace

  # State and planning
  tfpd = "tofu plan -destroy"; # Plan infrastructure destruction
  tfsh = "tofu show"; # Show state or plan
  tfst = "tofu state list"; # List resources in state
}
