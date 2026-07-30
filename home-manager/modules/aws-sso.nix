# home-manager/modules/aws-sso.nix
#
# AWS SSO configuration. Shell workflows live in ../scripts/aws-sso.zsh so this
# module stays declarative and easy to scan.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.aws-sso;

  mkTraditionalProfile =
    name:
    let
      header = if name == "default" then "[default]" else "[profile ${name}]";
    in
    ''
      ${header}
      region = ${cfg.region}
      output = json
    '';

  mkSsoProfile =
    profile:
    let
      accountId = cfg.accounts.${profile.account};
    in
    ''
      [profile ${profile.name}]
      sso_start_url = ${cfg.ssoStartUrl}
      sso_region = ${cfg.region}
      sso_account_id = ${accountId}
      sso_role_name = ${cfg.ssoRoleName}
      region = ${cfg.region}
      output = json
    '';

  awsConfigText = builtins.concatStringsSep "\n" (
    (map mkTraditionalProfile cfg.traditionalProfiles) ++ (map mkSsoProfile cfg.ssoProfiles)
  );
in
{
  options.programs.aws-sso = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable AWS SSO configuration";
    };
    region = lib.mkOption {
      type = lib.types.str;
      default = "eu-west-1";
      description = "Default AWS Region";
    };
    ssoStartUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://vortexa.awsapps.com/start";
      description = "AWS SSO Start URL";
    };
    ssoRoleName = lib.mkOption {
      type = lib.types.str;
      default = "PMMT";
      description = "AWS SSO Role Name";
    };
    accounts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        production = "501857513371";
        staging = "045251666112";
      };
      description = "AWS Accounts mapping account name to account ID";
    };
    profiles = {
      default = lib.mkOption {
        type = lib.types.str;
        default = "default-sso";
        description = "Default SSO profile name";
      };
      production = lib.mkOption {
        type = lib.types.str;
        default = "production-sso";
        description = "Production SSO profile name";
      };
      staging = lib.mkOption {
        type = lib.types.str;
        default = "staging-sso";
        description = "Staging SSO profile name";
      };
    };
    traditionalProfiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "default"
        "production"
        "staging"
        "stg"
        "prod"
        "prd"
        "dev"
        "develop"
        "development"
      ];
      description = "AWS traditional profiles to generate";
    };
    ssoProfiles = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption { type = lib.types.str; };
            account = lib.mkOption { type = lib.types.str; };
          };
        }
      );
      default = [
        {
          name = "production-sso";
          account = "production";
        }
        {
          name = "staging-sso";
          account = "staging";
        }
        {
          name = "default-sso";
          account = "staging";
        }
      ];
      description = "AWS SSO profiles to generate";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".aws/config".text = awsConfigText;
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

        source "${../scripts/aws-sso.zsh}"
      '';

      sessionVariables = {
        AWS_DEFAULT_REGION = cfg.region;
        AWS_REGION = cfg.region;
        AWS_SSO_DEFAULT_PROFILE = cfg.profiles.default;
        AWS_SSO_PRODUCTION_PROFILE = cfg.profiles.production;
        AWS_SSO_STAGING_PROFILE = cfg.profiles.staging;
      };
    };
  };
}
