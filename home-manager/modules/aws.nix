{ config, pkgs, ... }: {
  programs.zsh = {
    initExtra = ''
      # AWS CLI completions
      complete -C '${pkgs.awscli2}/bin/aws_completer' aws
      
      # Set default AWS region
      export AWS_DEFAULT_REGION=us-west-2
      export AWS_REGION=us-west-2
    '';
  };
} 