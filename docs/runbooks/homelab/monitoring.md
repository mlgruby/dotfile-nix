# Monitoring LXC

The `monitoring` host is the consolidated observability LXC.

## URLs

- Grafana: `http://192.168.10.27:3000`
- Prometheus: `http://192.168.10.27:9090`
- Alertmanager: `http://192.168.10.27:9093`
- Uptime Kuma: `http://192.168.10.27:3001`

Public hostnames are owned by the reverse proxy, not this dotfile.

## Runtime Layout

The live compose stack is expected under:

```bash
/root/monitoring
```

Grafana dashboard source artifacts are tracked in:

```bash
Grafana_dashboards/
```

When dashboards are migrated or regenerated, keep source JSON files in the repo
and provision them into Grafana from files. Avoid treating `grafana.db` as the
source of truth for dashboard design.

## Basic Checks

```bash
ssh monitoring
cd /root/monitoring
docker compose ps
docker compose logs --tail=100 grafana prometheus alertmanager uptime-kuma
```

## Retirement Checks For Old LXCs

Before shutting down an old Grafana, Prometheus, Alertmanager, or Uptime Kuma
LXC, verify:

- DNS/reverse proxy points at `192.168.10.27`.
- `docker compose ps` is healthy on `monitoring`.
- Grafana datasources work.
- Prometheus targets are up.
- Alertmanager UI loads and receives alerts.
- Uptime Kuma push URLs still receive pings.
