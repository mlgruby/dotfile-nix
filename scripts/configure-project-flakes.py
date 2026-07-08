#!/usr/bin/env python3
import os
import subprocess
import sys

PERSONAL_DIR = "/Users/satyasheel/Documents/Personal"
WORK_DIR = "/Users/satyasheel/Documents/Work"

FLAKE_TEMPLATE = """{{
  description = "{project_name} development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {{ self, nixpkgs }}:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${{system}};
    in {{
      devShells.${{system}}.default = pkgs.mkShell {{
        packages = with pkgs; [
{packages}
        ];
      }};
    }};
}}
"""

def detect_packages(project_path):
    packages = []
    files = os.listdir(project_path)
    
    # Rust detection
    if "Cargo.toml" in files:
        packages.extend(["rustc", "cargo", "rustfmt", "clippy", "rust-analyzer"])
        
    # Go detection
    if "go.mod" in files:
        packages.extend(["go", "gofumpt", "gopls"])
        
    # Node detection
    if "package.json" in files:
        packages.extend(["nodejs", "nodePackages.npm"])
        
    # Python detection
    if any(f in files for f in ["requirements.txt", "pyproject.toml", "poetry.lock", "setup.py", "Pipfile"]):
        packages.extend(["python3", "uv"])
        
    # Java detection
    if "pom.xml" in files or "build.gradle" in files or ".java-version" in files:
        packages.extend(["jdk", "maven"])
        
    # Python venv fallback detection
    if ".venv" in files:
        packages.extend(["python3", "uv"])
        
    return sorted(list(set(packages)))

def process_directory(base_dir):
    if not os.path.exists(base_dir):
        print(f"Directory {base_dir} does not exist. Skipping.")
        return
        
    print(f"\nScanning projects in {base_dir}...")
    for entry in os.scandir(base_dir):
        if not entry.is_dir() or entry.name.startswith("."):
            continue
            
        project_path = entry.path
        project_name = entry.name
        
        try:
            packages = detect_packages(project_path)
        except Exception as e:
            print(f"Error scanning {project_name}: {e}")
            continue
            
        if not packages:
            # Skip projects that don't have recognizable file structures
            continue
            
        flake_path = os.path.join(project_path, "flake.nix")
        envrc_path = os.path.join(project_path, ".envrc")
        
        # Check if flake.nix already exists
        if os.path.exists(flake_path):
            print(f"  [SKIP] {project_name} (flake.nix already exists)")
            continue
            
        print(f"  [CONFIG] {project_name} -> {', '.join(packages)}")
        
        # Write flake.nix
        pkg_lines = "\n".join(f"          {pkg}" for pkg in packages)
        flake_content = FLAKE_TEMPLATE.format(project_name=project_name, packages=pkg_lines)
        with open(flake_path, "w") as f:
            f.write(flake_content)
            
        # Write .envrc
        if not os.path.exists(envrc_path):
            with open(envrc_path, "w") as f:
                f.write("use flake\n")
                
        # Run direnv allow
        try:
            subprocess.run(["direnv", "allow"], cwd=project_path, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError:
            print(f"  [WARN] Failed to authorize direnv in {project_name}")

if __name__ == "__main__":
    process_directory(PERSONAL_DIR)
    process_directory(WORK_DIR)
    print("\nAll projects processed successfully!")
