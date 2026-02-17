{
  common = {
    username = "your-macos-username";
    fullName = "Your Full Name";
    githubUsername = "your-github-username";
    signingKey = ""; # GPG key ID for signing commits
  };

  hosts = {
    work = {
      hostname = "your-work-hostname";
      profile = "work";
    };

    personal = {
      hostname = "your-personal-hostname";
      profile = "personal";
    };
  };
}
