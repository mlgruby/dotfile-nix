{userConfig, ...}: {
  # Nix Settings extracted from flake.nix inline module
  # Includes settings previously in darwin/configuration.nix

  nix.settings = {
    # Performance tuning
    max-jobs = 6; # Number of parallel jobs (adjust based on CPU)
    cores = 2; # Cores per job (total = max-jobs * cores)

    # Other Settings
    trusted-users = [
      "root"
      userConfig.username
    ]; # Trust specific users
    keep-derivations = true; # Keep build dependencies
    keep-outputs = true; # Keep build outputs
    experimental-features = [
      "nix-command"
      "flakes"
    ]; # Enable modern features
  };
}
