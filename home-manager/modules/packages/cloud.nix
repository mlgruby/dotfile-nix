# Cloud and infrastructure CLI tools managed by Home Manager.
#
# Package-only module: prefer programs.* when Home Manager has a first-class
# configuration module for a tool.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    awscli2 # AWS CLI v2
    aws-iam-authenticator # AWS IAM authentication for Kubernetes
    kubernetes-helm # Kubernetes package manager
    terraform-docs # Generate docs from Terraform modules
    tflint # Terraform linter
  ];
}
