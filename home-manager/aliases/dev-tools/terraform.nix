# home-manager/aliases/dev-tools/terraform.nix
#
# Terraform workflow aliases.
{ ... }:
{
  tf = "terraform"; # Terraform shorthand
  tfin = "terraform init"; # Initialize Terraform
  tfp = "terraform plan"; # Show execution plan
  tfa = "terraform apply"; # Apply changes
  tfd = "terraform destroy"; # Destroy infrastructure

  # Workspace management
  tfwst = "terraform workspace select"; # Switch workspace
  tfwsw = "terraform workspace show"; # Show current workspace
  tfwls = "terraform workspace list"; # List workspaces
  tfwsn = "terraform workspace new"; # Create new workspace

  # State and planning
  tfpd = "terraform plan -destroy"; # Plan infrastructure destruction
  tfsh = "terraform show"; # Show state or plan
  tfst = "terraform state list"; # List resources in state
}
