{
  pkgs,
  lib,
  ...
}: {
  # Install LazyVim during activation
  home.activation.installLazyVim = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "$HOME/.config/nvim" ]; then
      echo "Installing LazyVim..."
      # Backup existing configs
      mv $HOME/.config/nvim{,.bak} 2>/dev/null || true
      mv $HOME/.local/share/nvim{,.bak} 2>/dev/null || true
      mv $HOME/.local/state/nvim{,.bak} 2>/dev/null || true
      mv $HOME/.cache/nvim{,.bak} 2>/dev/null || true

      # Clone LazyVim starter using Nix's git
      ${pkgs.git}/bin/git clone https://github.com/LazyVim/starter $HOME/.config/nvim
      rm -rf $HOME/.config/nvim/.git
      echo "LazyVim installed successfully!"
    else
      echo "LazyVim is already installed."
    fi
  '';
}
