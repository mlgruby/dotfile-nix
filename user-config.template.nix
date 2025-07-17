# Copy this file to user-config.nix and update with your information
# Note: 'username' must match your macOS username (the one you use to log in)
# Note: 'hostname' must only contain letters, numbers, and hyphens (e.g., macbook-pro)
{
  # Personal Information
  username = "your-macos-username"; # Must match your macOS login username
  fullName = "Your Full Name";
  email = "your.email@example.com";
  githubUsername = "your-github-username";
  hostname = "your-hostname"; # Only use letters, numbers, and hyphens (e.g., macbook-pro)
  signingKey = ""; # GPG key ID for signing commits (leave empty initially)
  
  # Directory Configuration
  # These paths can be customized based on your preferences
  # All paths are relative to your home directory unless absolute paths are specified
  directories = {
    # Dotfiles repository location (relative to home directory)
    dotfiles = "Documents/dotfile";
    
    # Development workspace (where you keep your projects)
    # workspace = "Development";  # Uncomment and customize if needed
    
    # Additional custom directories for aliases and shortcuts
    # downloads = "Downloads";    # Default: Downloads
    # documents = "Documents";    # Default: Documents
    
    # Project-specific directories (examples)
    # Note: These are examples - uncomment and customize as needed
    # personal = "Development/Personal";
    # work = "Development/Work";
    # opensource = "Development/OpenSource";
  };
  
  # Application Preferences (future extension point)
  # preferences = {
  #   # Terminal preferences
  #   terminal = {
  #     defaultSession = "main";
  #     theme = "gruvbox-dark";
  #   };
  #   
  #   # Development preferences
  #   development = {
  #     defaultEditor = "nvim";
  #     defaultShell = "zsh";
  #   };
  # };
}
