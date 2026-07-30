{
  ssh = {
    bitwardenAgent = {
      enable = true;
      socketPath = "~/.bitwarden-ssh-agent.sock";
    };

    homelabIdentityFile = "~/.ssh/nuc_homelab_id_ed25519";
    homelabUser = "root";
  };

  homelabHosts = {
    pve1 = "192.168.10.12";
    pve2 = "192.168.10.13";
    pve3 = "192.168.10.14";
  };
}
