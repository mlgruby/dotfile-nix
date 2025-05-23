# home-manager/modules/aws.nix
#
# AWS CLI Basic Setup
#
# Purpose:
# - Enables AWS CLI command completion manually.
# - Sets default AWS region (handled elsewhere now).
#
# Integration:
# - AWS CLI installed via Homebrew (homebrew.nix)
# - Credentials managed by aws-sso.nix
{pkgs, ...}: {
  programs.zsh = {
    # Use initContent for manual completion setup
    initContent = ''
      # Enable AWS CLI command completion
      # Uses aws_completer from awscli2 package
      if command -v aws_completer &> /dev/null; then
         complete -C aws_completer aws
      elif [ -x "${pkgs.awscli2}/bin/aws_completer" ]; then # Check Nix pkg path
         complete -C "${pkgs.awscli2}/bin/aws_completer" aws
      fi
    '';
  };
}
