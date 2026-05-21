# home-manager/aliases/dev-tools/docker.nix
#
# Docker and Docker Compose aliases.
{ ... }:
{
  d = "docker"; # Docker shorthand
  dc = "docker-compose"; # Docker Compose shorthand

  # Interactive container management
  dsp = "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker stop"; # Fuzzy select and stop container
  drm = "docker ps -a --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker rm"; # Fuzzy select and remove container
  dimg = "docker images --format 'table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}' | fzf --header-lines=1"; # Fuzzy browse docker images
  dlog = "docker ps --format 'table {{.Names}}\\t{{.Status}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker logs -f"; # Fuzzy select and tail container logs
  dexec = "docker ps --format 'table {{.Names}}\\t{{.Status}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r -I {} docker exec -it {} /bin/bash"; # Fuzzy select and exec into container
}
