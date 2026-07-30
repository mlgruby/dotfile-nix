# Declarative Neovim and LazyVim

## Goal

Provide a reproducible Neovim and LazyVim environment through Home Manager that
supports the languages used by the projects under `~/Documents/Work` and
`~/Documents/Personal`.

The implementation is applied and verified on the existing `aarch64-darwin`
configuration. The Neovim module must avoid Darwin-specific paths and package
selection so it can be reused by a future Linux Home Manager configuration.
Adding a Linux flake output is explicitly out of scope.

## Architecture

Home Manager owns both layers of the editor installation:

1. `programs.neovim` installs the executable and sets it as the default editor.
2. Repository-managed Lua files are deployed beneath `~/.config/nvim` and load
   LazyVim through `lazy.nvim`.

Plugin versions remain pinned by a repository-managed `lazy-lock.json`. The
current activation script that clones a mutable LazyVim starter is removed. This
eliminates the split ownership where Home Manager bootstraps a directory and
then silently stops managing it.

## GitOps Constraints

The Git repository is the sole source of truth for the editor configuration and
tooling. Neovim, LazyVim configuration, plugin pins, language tools and editor
defaults are declared in tracked Nix or Lua files. The implementation must not
use imperative package installation, manually edit `~/.config/nvim`, or depend
on untracked live-machine state.

Deployment flows through the existing Nix rebuild wrapper. Every source change
is evaluated and reviewed from the Git diff before it is applied. Runtime checks
may read the deployed files and Neovim state, but must not repair them in place.
Future changes, including LazyVim updates, are performed by updating the tracked
lock file and rebuilding rather than running an unrecorded live update.

## Language Coverage

LazyVim language extras and supporting packages cover:

- Python
- Rust
- TypeScript and JavaScript
- Java
- Kotlin
- Go
- Nix
- Bash and other shell scripts
- JSON, YAML and Markdown
- Docker files
- Terraform and OpenTofu

Language servers, formatters and linters are installed with Nix when nixpkgs
provides an appropriate package. Project-local tools remain preferred when a
project shell or `direnv` places them earlier on `PATH`.

Mason may install editor-specific tools that are not practical to source from
nixpkgs, but it is not the primary owner of globally available language tools.

## Existing Configuration Migration

The existing `~/.config/nvim` directory is mutable and is not currently owned by
Home Manager. During the rebuild, Home Manager's configured backup extension
preserves conflicting files before installing the declarative configuration.
No migration step deletes the existing directory or Neovim data directories.

The disabled LazyVim example plugin file is not migrated because it currently
returns an empty specification and therefore expresses no active customization.

## Failure Handling

- Nix evaluation must prove that `programs.neovim.enable` is true and that all
  referenced packages exist for `aarch64-darwin`.
- A failed system rebuild leaves the previously active generation available.
- A failed plugin bootstrap must produce a non-zero headless Neovim invocation
  rather than being hidden by an activation-script fallback.
- Health-check warnings are classified into actionable editor failures versus
  optional provider warnings.

## Verification

The implementation is accepted when:

1. The previous failing check (`command -v nvim`) succeeds after rebuild.
2. The Darwin configuration evaluates successfully.
3. Neovim starts headlessly with the managed configuration and no Lua errors.
4. Lazy reports no failed plugins.
5. Representative language servers and formatters are discoverable on `PATH`.
6. A health report is captured and any remaining material warnings are reported.
7. The repository working tree contains only the intended Neovim and design
   changes.
8. The deployed Neovim configuration corresponds to tracked repository content;
   no required configuration exists only in `~/.config/nvim`.

## Non-goals

- Adding a Linux flake or Home Manager output.
- Installing every possible language tool.
- Customizing LazyVim's visual design or keybindings beyond existing defaults.
- Deleting Neovim caches, state, plugin data or the prior mutable configuration.
