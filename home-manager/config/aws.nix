{
  region = "eu-west-1";
  ssoStartUrl = "https://vortexa.awsapps.com/start";
  ssoRoleName = "PMMT";

  accounts = {
    production = "501857513371";
    staging = "045251666112";
    root = "874568069660";
  };

  profiles = {
    default = "default-sso";
    production = "production-sso";
    staging = "staging-sso";
    root = "root-sso";
  };

  traditionalProfiles = [
    "default"
    "production"
    "staging"
    "stg"
    "prod"
    "prd"
    "dev"
    "develop"
    "development"
    "root"
    "vortexa"
  ];

  ssoProfiles = [
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
    {
      name = "root-sso";
      account = "root";
    }
    {
      name = "vortexa-sso";
      account = "root";
    }
  ];
}
