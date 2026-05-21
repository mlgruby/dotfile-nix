# Msgvault

Msgvault is installed locally for client commands, while the archive API runs on
the `msgvault` LXC.

## Local Commands

- `mv` / `mvt` - open the remote TUI.
- `mvstats` - show archive stats.
- `mvp "query"` - search, fuzzy-pick a result, and open the message.
- `mvat "query"` - same as `mvp`, but biased toward attachment-bearing results.
- `mva "query"` - pick an account first, then search.
- `mvhybrid "query"` - API hybrid search.
- `mvsemantic "query"` - API vector search.
- `mvrotate` - rotate the encrypted API key locally and on the server.
- `mvschedule` - reconcile the remote systemd sync timer.

## Secret Model

The API key is stored encrypted in the repo as an age file:

```bash
home-manager/secrets/msgvault-api-key.age
```

Local wrappers decrypt it into a temporary file at runtime and delete that file
when the command exits. The SSH private key at `~/.ssh/nuc_homelab_id_ed25519`
is the local identity used for age decryption.

## Server Checks

```bash
ssh msgvault
systemctl status msgvault.service msgvault-sync.timer msgvault-sync.service
journalctl -u msgvault.service -u msgvault-sync.service --since today
```

Use `mvhealth`, `mvscheduler`, and `mvvector` from the Mac for quick client-side
checks.
