# home-manager/modules/gpg.nix
#
# GPG Configuration with Home Manager Integration
#
# Purpose:
# - Configures GPG with security-focused settings
# - Uses Home Manager's services.gpg-agent for agent management
# - Provides proper GPG and SSH integration
#
# Features:
# - Strong cipher preferences (AES256, SHA512)
# - Optimized cache settings for development workflow
# - SSH agent support for Git operations
# - Secure keyserver configuration
#
# Integration:
# - GPG agent managed by Home Manager service
# - Main GPG configuration via home.file
# - SSH support for Git authentication
#
# Note:
# - Agent settings now managed declaratively
# - Manual GPG config retained for advanced options
# - Cache TTL optimized for daily development use
{...}: {
  # Install GnuPG via Home Manager.
  # Note: We intentionally do NOT enable `services.gpg-agent` on macOS because
  # Home Manager's darwin launchd module runs `gpg-agent --supervised` (a Linux
  # systemd socket-activation flag expecting LISTEN_FDS), which crashes with exit
  # code 2 on macOS. GnuPG automatically spawns `gpg-agent --daemon` on demand
  # using ~/.gnupg/gpg-agent.conf below.
  programs.gpg.enable = true;

  home.file.".gnupg/gpg-agent.conf".text = ''
    default-cache-ttl 7200
    default-cache-ttl-ssh 7200
    max-cache-ttl 86400
    max-cache-ttl-ssh 86400
    log-file ~/.gnupg/gpg-agent.log
    debug-level basic
  '';

  # Main GPG Configuration
  # Keep as file configuration for advanced security settings
  home.file.".gnupg/gpg.conf".text = ''
    # Security-focused GPG configuration
    
    # Cipher preferences
    personal-cipher-preferences AES256 AES192 AES
    personal-digest-preferences SHA512 SHA384 SHA256
    personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
    default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
    
    # Algorithm settings
    cert-digest-algo SHA512
    s2k-digest-algo SHA512
    s2k-cipher-algo AES256
    
    # General settings
    charset utf-8
    fixed-list-mode
    no-comments
    no-emit-version
    no-greeting
    keyid-format 0xlong
    list-options show-uid-validity
    verify-options show-uid-validity
    with-fingerprint
    require-cross-certification
    no-symkey-cache
    use-agent
    throw-keyids
    
    # Keyserver settings
    keyserver hkps://keys.openpgp.org
    keyserver-options no-honor-keyserver-url
    keyserver-options include-revoked
  '';

  # Environment variables for GPG
  home.sessionVariables = {
    GNUPGHOME = "$HOME/.gnupg";
  };
}
