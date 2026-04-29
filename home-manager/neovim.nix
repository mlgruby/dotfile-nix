{
  lib,
  ...
}:
{
  # Bootstrap LazyVim once, but leave ~/.config/nvim mutable afterwards.
  home.activation.installLazyVim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    "${./scripts/install-lazyvim.sh}" || echo "LazyVim installation encountered issues"
  '';
}
