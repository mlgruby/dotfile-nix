# Cloud and infrastructure CLI tools managed by Home Manager.
#
# Package-only module: prefer programs.* when Home Manager has a first-class
# configuration module for a tool.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ansible # Automation and configuration management
    awscli2 # AWS CLI v2
    aws-iam-authenticator # AWS IAM authentication for Kubernetes
    kubernetes-helm # Kubernetes package manager
    opentofu # OpenTofu infrastructure as code CLI
    terraform-docs # Generate docs from Terraform/OpenTofu modules
    tflint # Terraform/OpenTofu linter
    infisical # Secrets management CLI
    kubevela # KubeVela application platform CLI
  ];
}
