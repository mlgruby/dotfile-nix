# Paperless-ngx

The `paperlessng` SSH alias points at the Paperless-ngx LXC.

## Basic Checks

```bash
ssh paperlessng
docker ps
docker compose ps
docker compose logs --tail=100
```

If the browser shows `Bad Request (400)`, check Paperless host/origin settings
and reverse proxy headers first. Paperless commonly rejects requests when the
public hostname is not present in its allowed host or CSRF origin settings.

## Empty-Instance Reset

Only use this if the instance has no data worth keeping.

1. Stop the Paperless stack.
2. Remove the app database and media volumes/directories.
3. Start the stack.
4. Create a fresh admin user from inside the webserver container.

Prefer creating a new admin user over deleting data when documents already
exist.
