{
  region = "eu-west-1";
  ssoStartUrl = "https://vortexa.awsapps.com/start";
  ssoRoleName = "PMMT";

  accounts = {
    production = "501857513371";
    staging = "045251666112";
  };

  profiles = {
    default = "default-sso";
    production = "production-sso";
    staging = "staging-sso";
  };

  traditionalProfiles = [
    "default"
    "production"
    "staging"
    "prod"
    "dev"
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
  ];
}
