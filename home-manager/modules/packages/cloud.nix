# Cloud and infrastructure CLI tools managed by Home Manager.

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
