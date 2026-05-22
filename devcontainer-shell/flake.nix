{
  description = "Lightweight, self-contained shell personalization flake for Dev Containers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # Dev containers are standard x86_64-linux, but we also support aarch64-linux (e.g. Apple Silicon dev containers)
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in {
      # Custom generator for team members to run dynamically
      # Usage: nix run github:<user>/dotfiles?dir=devcontainer-shell -- <username> <homeDirectory>
      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = toString (nixpkgsFor.${system}.writeShellScript "activate-devcontainer" ''
            set -e
            USERNAME="$1"
            HOMEDIR="$2"

            if [ -z "$USERNAME" ]; then
              USERNAME=$(whoami)
            fi

            if [ -z "$HOMEDIR" ]; then
              HOMEDIR="$HOME"
            fi

            # Detect architecture to select correct homeConfiguration profile
            SYS_ARCH=$(uname -m)
            if [ "$SYS_ARCH" = "x86_64" ]; then
              SYSTEM="x86_64-linux"
            elif [ "$SYS_ARCH" = "aarch64" ] || [ "$SYS_ARCH" = "arm64" ]; then
              SYSTEM="aarch64-linux"
            else
              SYSTEM="x86_64-linux"
            fi

            echo "Initializing shell customization flake for $USERNAME ($SYSTEM) at $HOMEDIR..."
            
            # Ensure flakes and nix-commands are globally enabled for this activation session
            export NIX_CONFIG="experimental-features = nix-command flakes"

            # Temporary nix-run of home-manager to switch configurations
            nix run --impure github:nix-community/home-manager -- switch \
              --flake ".#$USERNAME-$SYSTEM" \
              --impure \
              --override-input nixpkgs github:nixos/nixpkgs/nixos-unstable
          '');
        };
      });

      # Configured profiles for standard Dev Container environments
      # We define configurations for both x86_64-linux and aarch64-linux architectures
      homeConfigurations = let
        createConfig = username: homeDirectory: system: home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./home.nix
            {
              home = {
                inherit username homeDirectory;
                stateVersion = "24.05";
              };
            }
          ];
        };
      in {
        "vscode-x86_64-linux" = createConfig "vscode" "/home/vscode" "x86_64-linux";
        "vscode-aarch64-linux" = createConfig "vscode" "/home/vscode" "aarch64-linux";
        "root-x86_64-linux" = createConfig "root" "/root" "x86_64-linux";
        "root-aarch64-linux" = createConfig "root" "/root" "aarch64-linux";
        "node-x86_64-linux" = createConfig "node" "/home/node" "x86_64-linux";
        "node-aarch64-linux" = createConfig "node" "/home/node" "aarch64-linux";
      };
    };
}
