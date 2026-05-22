# Dev Container Shell Personalization Flake

This is a lightweight, self-contained, and blazing-fast **Nix Flake** designed specifically to personalizing your **Dev Container** shell environment. It ports over all of your custom shell configurations (Zsh, core/Git aliases, beautiful Gruvbox-themed Starship prompt, Zoxide, Fzf, Direnv, etc.) without pulling in heavy, system-wide macOS settings (Karabiner, Aerospace, GPG, Stylix, etc.).

It runs seamlessly on standard Dev Container architectures (`x86_64-linux` and `aarch64-linux`).

---

## 🚀 Features Included

*   **Zsh** with fast autocomplete and syntax highlighting enabled.
*   **Starship Prompt** with your exact custom **Gruvbox Dark** theme (custom icons, languages, git, and path truncation matching your desktop setup).
*   **FZF Integration** (Fuzzy file selection, history searches, fuzzy `cd` including hidden files with `Alt+D`, and interactive `git status` with file previews using `Ctrl+G`).
*   **Zoxide** for smart directory jumps (`z` / `zi`).
*   **Direnv** with optimized `nix-direnv` for lightning-fast, zero-overhead environment loading.
*   **Modern CLI tools** prepackaged: `eza` (beautiful `ls` replacement), `bat` (syntax-highlighted `cat`), `ripgrep` (grep replacement), `jq` (JSON editor), `tmux` (terminal multiplexer), `glow` (markdown renderer), and `tldr` (cheatsheet RTFM helper).
*   **Custom Helpers**: Automatic `ssh-agent` forwarding discovery (to make git pushes from the container work out of the box), `extract` archive utility, `zsh-startup-time` profiling, and interactive GitHub CLI wrappers (`ghprco`, `ghopr`).

---

## 🛠️ How to Integrate with Dev Containers

There are two primary ways to add this customization to your development containers:

### Option A: Fully Automated in `.devcontainer.json` (Recommended)

To configure your dev container to automatically set up your customized environment whenever you build/start it:

1.  **Add Nix Feature** to your `.devcontainer.json`:
    ```json
    "features": {
      "ghcr.io/devcontainers/features/nix:1": {
        "version": "latest"
      }
    }
    ```

2.  **Add Activation Hook** to run on container creation (`postCreateCommand`):
    ```json
    "postCreateCommand": "nix run \"github:<your-github-username>/dotfile?dir=devcontainer-shell\" -- vscode"
    ```
    *(Note: Replace `<your-github-username>` with your GitHub username. The `-- vscode` argument tells the flake to configure for the standard `vscode` container user.)*

---

### Option B: Manual Ad-hoc Activation

If you already have Nix installed in a running dev container and want to personalizing the shell immediately, simply open your terminal and run:

```bash
# Formatted for the default user (e.g. 'vscode')
nix run "github:<your-github-username>/dotfile?dir=devcontainer-shell" -- $(whoami)
```

If you are currently inside your cloned dotfiles folder, you can run it locally:
```bash
nix run .# -- $(whoami)
```

---

## 📂 File Structure

*   `flake.nix` — Defines inputs, supported platforms (`x86_64-linux`, `aarch64-linux`), user profiles (`vscode`, `root`, `node`), and the activation entry point.
*   `home.nix` — Lightweight Home Manager configuration declaring packages, alias lists, and Starship configurations.
*   `zsh-integration.zsh` — Interactive shell utilities (FZF status, UV cache, keybindings, and extract helpers) optimized for Linux container runtimes.
