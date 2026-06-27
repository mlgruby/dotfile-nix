# Terminal Shortcuts and Herdr Theme

## Goal

Keep both terminal applications directly accessible while making Herdr match the
existing Gruvbox terminal appearance.

## Design

- Preserve `Command + Shift + Enter` for Ghostty.
- Add `Command + Option + Enter` for Alacritty through the existing declarative
  Karabiner configuration.
- Manage `~/.config/herdr/config.toml` with Home Manager and select Herdr's
  official built-in `gruvbox` theme.
- Leave Alacritty's automatic tmux startup and Ghostty's automatic Herdr startup
  unchanged.

## Verification

- Run `nix flake check --no-build`.
- Apply the configuration with `rebuild --work`.
- Confirm the live Herdr config contains `name = "gruvbox"`.
