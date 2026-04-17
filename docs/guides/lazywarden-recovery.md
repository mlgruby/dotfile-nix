# Lazywarden Recovery

Use `lazywarden-decrypt` to decrypt Lazywarden backup archives when you need to
inspect or restore a Bitwarden backup.

## Commands

The real command is:

```bash
lazywarden-decrypt <backup.zip>
```

Short aliases are available from `home-manager/aliases/homelab.nix`:

```bash
lwdec <backup.zip>
lw-decrypt <backup.zip>
lw-restore <backup.zip>
```

`lw-restore` adds a safer default output directory:

```bash
lazywarden-decrypt --output ~/Secure/lazywarden-restore
```

## Recommended Usage

Prefer an explicit output directory for vault recovery work:

```bash
lwdec ~/Downloads/bw-backup_2026_04_17.zip \
  --output ~/Secure/lazywarden-restore
```

If you do not want to extract attachments:

```bash
lwdec ~/Downloads/bw-backup_2026_04_17.zip \
  --output ~/Secure/lazywarden-restore \
  --no-attachments
```

By default, extracted encrypted files are kept so recovery is easier to audit.
Remove them only after a successful run:

```bash
lwdec ~/Downloads/bw-backup_2026_04_17.zip \
  --output ~/Secure/lazywarden-restore \
  --cleanup
```

## Safety Notes

- Output directories are created with private permissions.
- Decrypted JSON files are written with `0600` permissions.
- ZIP member paths are validated before extraction.
- Attachments are optional and prompt for their own ZIP password.
- Use `lazywarden-decrypt` or the `lwdec` alias. The old
  `decrypt_lazywarden.py` command is intentionally not installed.

## Implementation

The tool is packaged by Home Manager in:

```text
home-manager/modules/lazywarden/default.nix
home-manager/modules/lazywarden/lazywarden-decrypt.py
```

The homelab aliases live in:

```text
home-manager/aliases/homelab.nix
```
