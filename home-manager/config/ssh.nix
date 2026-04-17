{
  ssh = {
    homelabIdentityFile = "~/.ssh/nuc_homelab_id_ed25519";
    homelabUser = "root";
  };

  homelabHosts = {
    pve1 = "192.168.10.12";
    pve2 = "192.168.10.13";
    pve3 = "192.168.10.14";

    pi1 = "192.168.10.5";
    pi2 = "192.168.10.6";
    pi3 = "192.168.10.7";

    servarr = "192.168.10.21";
    glance = "192.168.10.22";
    audiobookshelf = "192.168.10.26";
    lazywarden = "192.168.10.28";
    ha = "192.168.10.24";
    linkwarden = "192.168.10.29";
    windmill = "192.168.10.30";

    metric-exporter = "192.168.10.32";
    prometheus = "192.168.10.17";

    warracker = "192.168.10.19";
    utility = "192.168.10.9";
    Obsidian-Livesync = "192.168.10.19";
  };
}
