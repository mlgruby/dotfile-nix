# home-manager/modules/aws-sso.nix
#
# AWS SSO configuration. Shell workflows live in ../scripts/aws-sso.zsh so this
# module stays declarative and easy to scan.
{ pkgs, ... }:
let
  aws = import ../config/aws.nix;
  inherit (aws) region ssoStartUrl ssoRoleName;
  inherit (aws) accounts;
  defaultProfile = aws.profiles.default;
  productionProfile = aws.profiles.production;
  stagingProfile = aws.profiles.staging;

  mkTraditionalProfile =
    name:
    let
      header = if name == "default" then "[default]" else "[profile ${name}]";
    in
    ''
      ${header}
      region = ${region}
      output = json
    '';

  mkSsoProfile =
    profile:
    let
      accountId = accounts.${profile.account};
    in
    ''
      [profile ${profile.name}]
      sso_start_url = ${ssoStartUrl}
      sso_region = ${region}
      sso_account_id = ${accountId}
      sso_role_name = ${ssoRoleName}
      region = ${region}
      output = json
    '';

  awsConfigText = builtins.concatStringsSep "\n" (
    (map mkTraditionalProfile aws.traditionalProfiles) ++ (map mkSsoProfile aws.ssoProfiles)
  );
in
{
  home.file = {
    ".aws/config".text = awsConfigText;

    ".config/home-manager/scripts/aws-sso.zsh" = {
      source = ../scripts/aws-sso.zsh;
      executable = true;
    };
  };

  programs.zsh = {
    initContent = ''
      # Enable AWS CLI command completion.
      if command -v aws_completer > /dev/null 2>&1; then
        autoload -U bashcompinit
        bashcompinit
        complete -C aws_completer aws
      elif [ -x "${pkgs.awscli2}/bin/aws_completer" ]; then
        autoload -U bashcompinit
        bashcompinit
        complete -C "${pkgs.awscli2}/bin/aws_completer" aws
      fi

      source "$HOME/.config/home-manager/scripts/aws-sso.zsh"
    '';

    sessionVariables = {
      AWS_DEFAULT_REGION = region;
      AWS_REGION = region;
      AWS_SSO_DEFAULT_PROFILE = defaultProfile;
      AWS_SSO_PRODUCTION_PROFILE = productionProfile;
      AWS_SSO_STAGING_PROFILE = stagingProfile;
    };
  };
}
