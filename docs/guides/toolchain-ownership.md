# Toolchain Ownership

This dotfile intentionally does not move every development tool into Nix.
Toolchains affect IDEs, project builds, shell startup, and work repositories, so
they need a clearer rule than "prefer Nix".

## Policy

Use this order when deciding where a tool belongs:

```text
Project-local toolchain > Home Manager CLI package > Homebrew global toolchain > Homebrew app/cask
```

In practice:

- Use project-local tooling for exact runtime versions.
- Use Home Manager for user-level CLI tools and configured programs.
- Use Homebrew for global runtimes/build chains when IDEs or macOS tooling
  expect them.
- Use Homebrew casks for GUI apps, fonts, and vendor-managed desktop software.

## Current Global Toolchains

These are intentionally kept in Homebrew for now:

```text
uv
poetry
python@3.12
go
node
maven
cmake
pkg-config
kafka
neovim
yamlresume
coreutils
gnu-getopt
gnupg
mas
```

This does not mean they must stay there forever. It means they should only move
after checking how they are used by IDEs, work repos, shell PATH, and project
tooling.

## Project-Local First

Prefer project-local versions when a project depends on an exact runtime:

```text
Python app      -> uv / .python-version / project devshell
Node app        -> package manager + project config / devshell
Go service      -> go.mod + project devshell when needed
JVM service     -> Maven/Gradle wrapper or project devshell
Infra project   -> project-pinned Terraform/Kubernetes tooling
```

Global tools should be a convenient baseline, not the source of truth for every
project.

## Move To Home Manager When

A tool is a good Home Manager candidate when:

- it is a CLI utility rather than a GUI app
- it does not need macOS app integration
- it is not tightly coupled to an IDE's expected Homebrew path
- it has a stable nixpkgs package on macOS
- changing its PATH location will not surprise work projects

Examples already moved:

```text
fd
duf
dust
shellcheck
glow
yq-go
awscli2
sops
age
kubernetes-helm
terraform-docs
tflint
```

## Keep In Homebrew When

Keep a tool in Homebrew when:

- it is a GUI app, font, or vendor-managed desktop tool
- it integrates with macOS services or app bundles
- it is a global runtime shared by many tools and IDEs
- the Homebrew version is intentionally the compatibility baseline
- the Nix package would be surprising or brittle on macOS

Examples:

```text
node
go
python@3.12
uv
poetry
cmake
pkg-config
gnupg
mas
```

## Before Moving A Toolchain

For each candidate, answer:

1. Which commands depend on it?
2. Which IDEs or editors discover it?
3. Which work repositories assume its path or version?
4. Does nixpkgs provide the right macOS package?
5. Would project-local tooling be better than a global package?
6. What validation proves the migration is safe?

Good validation examples:

```bash
which node
node --version
which go
go version
which python3
python3 --version
which cmake
cmake --version
```

Then test representative work and personal projects before moving the package
ownership.
