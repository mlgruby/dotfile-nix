# home/aliases.nix
{ pkgs, ... }:

let
  # Helper function to determine the operating system
  isMacOS = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Common aliases for both platforms
  commonAliases = {
    # VS Code
    c = "code .";
    ce = "code . && exit";
    cdf = "cd $(ls -d */ | fzf)";

    # Directory operations
    mkdir = "mkdir -p";
    rm = "rm -rf";
    cp = "cp -r";
    mv = "mv -i";
    dl = "cd $HOME/Downloads";
    docs = "cd $HOME/Documents";

    # Editor
    v = "nvim";
    vim = "nvim";

    # exa aliases
    ls = "exa -l";
    lsa = "exa -l -a";
    lst = "exa -l -T";
    lsr = "exa -l -R";

    # Terraform aliases
    tf = "terraform";
    tfin = "terraform init";
    tfp = "terraform plan";
    tfwst = "terraform workspace select";
    tfwsw = "terraform workspace show";
    tfwls = "terraform workspace list";

    # Docker aliases
    d = "docker";
    dc = "docker-compose";

    # Common utilities
    ipp = "curl https://ipecho.net/plain; echo";
  };

  # macOS specific aliases
  macAliases = if isMacOS then {
    # System maintenance
    cleanup = ''
      echo "🧹 Running system cleanup..." && \
      echo "🗑️  Emptying trash..." && \
      rm -rf ~/.Trash/* 2>/dev/null && \
      sudo rm -rf /Volumes/*/.Trashes/* 2>/dev/null && \
      echo "📝 Cleaning system logs..." && \
      sudo rm -rf /private/var/log/asl/*.asl 2>/dev/null && \
      sudo rm -rf /Library/Logs/DiagnosticReports/* 2>/dev/null && \
      sudo rm -rf ~/Library/Logs/DiagnosticReports/* 2>/dev/null && \
      echo "🧹 Cleaning temporary files..." && \
      sudo rm -rf /private/var/tmp/* 2>/dev/null && \
      echo "✨ Cleanup complete!"
    '';
    
    # Update commands
    update = ''
      echo "🔄 Updating Nix flake..." && \
      cd ~/Documents/dotfile && \
      nix flake update && \
      echo "🔄 Rebuilding system..." && \
      darwin-rebuild switch --flake .#ss-mbp && \
      echo "✨ System update complete!"
    '';

    # Quick rebuild without updating flake
    rebuild = "cd ~/Documents/dotfile && darwin-rebuild switch --flake .#ss-mbp";
    
    # Finder
    show = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";
    hide = "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder";
    hidedesktop = "defaults write com.apple.finder CreateDesktop -bool false && killall Finder";
    showdesktop = "defaults write com.apple.finder CreateDesktop -bool true && killall Finder";

    # System controls
    stfu = "osascript -e 'set volume output muted true'";
    pumpitup = "osascript -e 'set volume output volume 100'";
    afk = "osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down,control down}'";

    # Directory shortcuts
    codedot = "code $HOME/Documents/dotfile/";
    dotfile = "cd $HOME/Documents/dotfile";

    # Reload zshrc and clear terminal screen (macOS)
#    re = "source ~/.zshrc && osascript -e 'tell application \"System Events\" to keystroke \"k\" using command down'";
  } else {};

  # Linux specific aliases
  linuxAliases = if isLinux then {
    update = "sudo apt update && sudo apt -y --allow-downgrades full-upgrade && sudo apt -y autoremove && cs update";
    dotfile = "cd $HOME/Documents/dotfile";
    codedot = "code $HOME/Documents/dotfile";

    # Reload zshrc and clear terminal screen (Linux)
    re = "source ~/.zshrc && clear";
  } else {};

in
commonAliases // macAliases // linuxAliases
