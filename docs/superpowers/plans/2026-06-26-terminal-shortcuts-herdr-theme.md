# Terminal Shortcuts and Herdr Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dedicated Alacritty launcher shortcut and configure Herdr to use its built-in Gruvbox theme.

**Architecture:** Extend the existing declarative Karabiner rule list for application launching. Add a focused Home Manager module that owns Herdr's TOML configuration and import it from the main Home Manager configuration.

**Tech Stack:** Nix, Home Manager, Karabiner-Elements, Herdr TOML configuration

---

### Task 1: Add the Alacritty launcher

**Files:**
- Modify: `home-manager/modules/karabiner/default.nix:16-87`

- [ ] **Step 1: Add the documented shortcut**

Add this entry to the shortcut summary:

```nix
# - Command + Option + Enter -> Alacritty (Terminal)
```

- [ ] **Step 2: Add the Karabiner rule**

Insert this rule after the Ghostty launcher:

```nix
{
  description = "Open Alacritty with Command + Option + Enter";
  manipulators = [
    {
      type = "basic";
      from = {
        key_code = "return_or_enter";
        modifiers = {
          mandatory = [
            "command"
            "option"
          ];
          optional = [ "any" ];
        };
      };
      to = [
        {
          shell_command = "osascript -e 'tell application \"Alacritty\" to activate'";
        }
      ];
    }
  ];
}
```

- [ ] **Step 3: Confirm both terminal bindings evaluate into the generated configuration**

Run:

```bash
nix eval --raw '.#darwinConfigurations.work.config.home-manager.users.satyasheel.home.file.".config/karabiner/karabiner.json".text' | jq -r '.profiles[0].complex_modifications.rules[].description' | rg 'Ghostty|Alacritty'
```

Expected output contains both launcher descriptions.

### Task 2: Manage the Herdr theme

**Files:**
- Create: `home-manager/modules/herdr.nix`
- Modify: `home-manager/default.nix:87-115`

- [ ] **Step 1: Create the focused Home Manager module**

Create `home-manager/modules/herdr.nix` with:

```nix
{ ... }:
{
  xdg.configFile."herdr/config.toml".text = ''
    [theme]
    name = "gruvbox"
  '';
}
```

- [ ] **Step 2: Import the module**

Add this import near the terminal modules in `home-manager/default.nix`:

```nix
./modules/herdr.nix
```

- [ ] **Step 3: Verify the flake**

Run:

```bash
nix flake check --no-build
```

Expected: command exits successfully.

- [ ] **Step 4: Apply the configuration**

Run:

```bash
rebuild --work
```

Expected: nix-darwin and Home Manager activation complete successfully.

- [ ] **Step 5: Verify the live Herdr theme**

Run:

```bash
rg -n '^name = "gruvbox"$' ~/.config/herdr/config.toml
```

Expected output:

```text
2:name = "gruvbox"
```
