{
  lib,
  ...
}:
{
  home.file.".config/home-manager/scripts/install-lazyvim.sh" = {
    source = ./scripts/install-lazyvim.sh;
    executable = true;
  };

  # Bootstrap LazyVim once, but leave ~/.config/nvim mutable afterwards.
  home.activation.installLazyVim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    "$HOME/.config/home-manager/scripts/install-lazyvim.sh" || echo "LazyVim installation encountered issues"
  '';
}
