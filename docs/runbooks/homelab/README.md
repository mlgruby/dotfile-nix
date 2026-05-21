# Homelab Runbooks

These runbooks cover external homelab systems that this dotfile can reach, but
does not fully own.

Use this directory for operational procedures: migrations, recovery steps,
service checks, and dashboard lifecycle notes. Keep reusable local client
configuration in Home Manager modules instead.

## Services

- `monitoring` (`192.168.10.27`) - consolidated Prometheus, Grafana,
  Alertmanager, and Uptime Kuma host.
- `msgvault` (`192.168.10.25`) - remote mail archive API and TUI backend.
- `paperlessng` (`192.168.10.20`) - Paperless-ngx document service.

Host aliases are declared in `home-manager/config/ssh.nix`.

## Rule Of Thumb

- If it changes this Mac, put it in Nix/Home Manager.
- If it changes an LXC or service runtime, put the procedure here.
- If it is a reusable local command, expose it through `home-manager/aliases`
  or a script under `home-manager/scripts`.
