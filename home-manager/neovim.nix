{ config, pkgs, ... }:

{
  # Check if LazyVim is installed
  home.packages = with pkgs; [
    (writeScriptBin "check-lazyvim" ''
      if [ ! -d "$HOME/.config/nvim" ]; then
        echo "LazyVim not found. Installing..."
        # Backup existing configs
        mv $HOME/.config/nvim{,.bak} 2>/dev/null || true
        mv $HOME/.local/share/nvim{,.bak} 2>/dev/null || true
        mv $HOME/.local/state/nvim{,.bak} 2>/dev/null || true
        mv $HOME/.cache/nvim{,.bak} 2>/dev/null || true
        
        # Clone LazyVim starter
        git clone https://github.com/LazyVim/starter $HOME/.config/nvim
        rm -rf $HOME/.config/nvim/.git
        echo "LazyVim installed successfully!"
      else
        echo "LazyVim is already installed."
      fi
    '')
  ];
} 