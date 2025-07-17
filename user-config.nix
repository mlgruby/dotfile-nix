# Copy this file to user-config.nix and update with your information
# Note: 'username' must match your macOS username (the one you use to log in)
{
  # Personal Information
  username = "satyasheel";
  fullName = "Satyasheel";
  email = "satyasheel@lightricks.com";
  githubUsername = "mlgruby";
  hostname = "satyasheel-MBP";
  signingKey = "B7394BFB258839CE";
  
  # Directory Configuration
  # These paths can be customized based on your preferences
  # All paths are relative to your home directory unless absolute paths are specified
  directories = {
    # Dotfiles repository location (relative to home directory)
    dotfiles = "Documents/dotfile";
    
    # Development workspace (where you keep your projects)
    workspace = "Development";
    
    # Additional directories for shortcuts
    downloads = "Downloads";
    documents = "Documents";
  };
}
