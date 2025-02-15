{
  description = "Satya's nix-darwin system configuration";

  inputs = {
    # Core nixpkgs repository
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    # Home Manager for user environment management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # nix-darwin for macOS system configuration
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Homebrew management
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs = { self, darwin, nixpkgs, home-manager, nix-homebrew, ... }:
  let
    system = "aarch64-darwin";
    username = "satyasheel";
    nixpkgsConfig = {
      config = {
        allowUnfree = true;
      };
    };
  in
  {
    darwinConfigurations."ss-mbp" = darwin.lib.darwinSystem {
      inherit system;
      modules = [
        # Base darwin configuration
        ./darwin/configuration.nix
        
        # Home manager configuration
        home-manager.darwinModules.home-manager
        {
          nixpkgs = nixpkgsConfig;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "bak";
            extraSpecialArgs = {
              inherit username;
            };
            users.${username} = { pkgs, lib, ... }: {
              imports = [ ./home-manager/default.nix ];
              home = {
                username = lib.mkForce username;
                homeDirectory = lib.mkForce "/Users/${username}";
                stateVersion = "23.11";
              };
              programs.home-manager.enable = true;
            };
          };
        }
        
        # Homebrew configuration
        nix-homebrew.darwinModules.nix-homebrew
        ./darwin/homebrew.nix

        ({ config, pkgs, ... }: {
          nix.settings = {
            trusted-users = [ "root" username ];
            keep-derivations = true;
            keep-outputs = true;
            experimental-features = [ "nix-command" "flakes" ];
          };

          system.activationScripts.preUserActivation.text = ''
            export INSTALLING_HOMEBREW=1
          '';

          # Keep all your system.defaults exactly as they were
          system.defaults = {
            finder = {
              FXPreferredViewStyle = "clmv";
              AppleShowAllFiles = true;
              ShowPathbar = true;
              ShowStatusBar = true;
              _FXShowPosixPathInTitle = true;
              CreateDesktop = true;
            };
            
            loginwindow = {
              GuestEnabled = false;
            };
            
            NSGlobalDomain = {
              AppleICUForce24HourTime = true;
              AppleInterfaceStyle = "Dark";
              KeyRepeat = 2;
            };
          };

          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 5;
          nixpkgs = nixpkgsConfig // {
            hostPlatform = "aarch64-darwin";
          };
          security.pam.enableSudoTouchIdAuth = true;

          programs.zsh = {
            enable = true;
            enableCompletion = true;
            promptInit = "";
            interactiveShellInit = ''
              export PATH="$HOME/Library/Application Support/pypoetry/venv/bin:$PATH"
              export PATH="$HOME/.local/bin:$PATH"
            '';
          };

          users.users.${username} = {
            home = "/Users/${username}";
            shell = "${pkgs.zsh}/bin/zsh";
          };
        })
      ];
    };

    darwinPackages = self.darwinConfigurations."ss-mbp".pkgs;
  };
}
  