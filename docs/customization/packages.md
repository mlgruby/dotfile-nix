# Package Management Guide

A comprehensive guide to managing packages in your Nix Darwin configuration.

## Package Types

### 1. System Packages

System-wide packages installed via Nix, available to all users.

```nix
# In darwin/configuration.nix
environment.systemPackages = with pkgs; [
  # Development Tools
  git
  python3
  nodejs

  # System Utilities
  coreutils
  gnused
  gawk
];
```

### 2. User Packages

User-specific packages managed by Home Manager.

```nix
# In home-manager/default.nix
home.packages = with pkgs; [
  # Development Tools
  ripgrep    # Better grep
  fd         # Better find
  eza        # Better ls

  # Cloud Tools
  awscli2
  google-cloud-sdk
  terraform

  # Utilities
  btop       # System monitor
  duf        # Disk usage
  neofetch   # System info
];
```

### 3. Homebrew Packages

macOS-specific packages and GUI applications.

```nix
# In darwin/homebrew.nix
homebrew = {
  # CLI Tools
  brews = [
    "git"
    "starship"
  ];

  # GUI Applications
  casks = [
    "alacritty"
    "brave-browser"
    "visual-studio-code"
  ];
};
```

## Adding Packages

### Finding Packages

1. **Nix Packages**

   ```bash
   # Search nixpkgs
   nix search nixpkgs#package-name

   # Check package availability
   nix-env -qa package-name
   ```

2. **Homebrew Packages**

   ```bash
   # Search formulae
   brew search package-name

   # Search casks
   brew search --casks package-name
   ```

### Best Practices

1. **Choose the Right Source**
   - Use Nix for CLI tools and development packages
   - Use Homebrew for:
     - GUI applications
     - Packages needing frequent updates
     - macOS-specific tools

2. **Package Organization**
   - Group related packages together
   - Add comments for non-obvious packages
   - Keep lists alphabetically sorted

3. **Version Management**

   ```nix
   # Pin specific versions (Nix)
   pkgs.nodejs-18_x

   # Pin Homebrew versions
   homebrew.brews = [
     "python@3.10"
   ];
   ```

## Removing Packages

### Nix Packages

1. **Remove from Configuration**

   ```nix
   # Simply remove the package from the list
   home.packages = with pkgs; [
     # Remove unwanted package
   ];
   ```

2. **Clean Up**

   ```bash
   # Remove old generations
   nix-collect-garbage -d

   # Clean store
   nix store optimise
   ```

### Homebrew Packages

1. **Remove from Configuration**

   ```nix
   homebrew = {
     # Remove from brews or casks list
   };
   ```

2. **Clean Up**

   ```bash
   # Clean up Homebrew
   brew cleanup
   ```

## Maintenance

### Regular Updates

```bash
# Update all packages
update

# Update specific components
nix flake update    # Update Nix packages
brew update         # Update Homebrew
```

### Health Checks

```bash
# Check Nix store
nix store verify

# Check Homebrew
brew doctor
```

### Space Management

```bash
# Clean Nix store
nix-collect-garbage -d

# Clean Homebrew
brew cleanup
```
