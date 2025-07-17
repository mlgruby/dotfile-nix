# Secrets Management Analysis & Implementation Plan

This document analyzes the current secrets management state and provides a
comprehensive plan for implementing SOPS with Age encryption for secure
secrets management in the Nix Darwin dotfiles configuration.

## Current State Analysis

### Existing Secrets Infrastructure

**✅ Already Implemented:**

- GPG configuration with Home Manager integration (`gpg.nix`)
- SSH key management and agent configuration (`ssh.nix`)
- AWS SSO credential management (`aws-sso.nix`)
- Git signing key integration (`git.nix`)

**🔄 Currently Managed Manually:**

- GPG private keys (manual import required)
- SSH private keys (generated and managed locally)
- AWS account IDs and SSO configuration (hardcoded)
- Git signing key ID (template placeholder)

**❌ Missing Critical Components:**

- Encrypted storage of sensitive configuration
- Automated secrets deployment
- Secrets rotation workflows
- Backup and recovery procedures

### Security Gaps Identified

| Secret Type | Current State | Risk Level | Impact |
|-------------|---------------|------------|---------|
| **GPG Keys** | Manual import | Medium | Commit signing disabled |
| **SSH Keys** | Local generation | Low | No backup, manual setup |
| **AWS Config** | Hardcoded values | Medium | Exposed account IDs |
| **API Tokens** | Not managed | High | Manual credential sharing |
| **Service Keys** | Not supported | High | No framework for app secrets |

## Solution Analysis: SOPS vs Age

### SOPS (Secrets OPerationS) - **RECOMMENDED**

**Strengths for Nix Darwin:**

- **Native Nix Integration**: `sops-nix` provides Home Manager modules
- **Multiple Backend Support**: Age, GPG, AWS KMS, GCP KMS, Azure Key Vault
- **Structured Data**: Encrypts only values, preserves YAML/JSON structure
- **Partial Encryption**: Can encrypt specific fields, leave others readable
- **Git-Friendly**: Produces deterministic diffs for encrypted files
- **Audit Trail**: Tracks who can decrypt and when files were modified

**Age Integration Benefits:**

- **Simpler than GPG**: Single key pair, no web of trust complexity
- **Modern Cryptography**: X25519, ChaCha20-Poly1305, HKDF
- **SSH Key Compatibility**: Can derive keys from existing SSH keys
- **Cross-Platform**: Works identically on macOS, Linux, Windows

### Implementation Architecture

```text
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   Encrypted Secrets │    │    SOPS + Age        │    │  Nix Configuration  │
│   (Git Repository)  │────│   Decryption         │────│   (Runtime Secrets) │
│                     │    │                      │    │                     │
│ • .sops.yaml        │    │ • Age private key    │    │ • /run/secrets/     │
│ • secrets.enc.yaml  │    │ • SOPS configuration │    │ • Environment vars  │
│ • aws.enc.yaml      │    │ • Home Manager       │    │ • Config files      │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
```

## Implementation Plan

### Phase 1: Foundation Setup (Week 1)

#### 1.1 Install SOPS and Age

```nix
# Add to homebrew.nix or home-manager packages
homebrew.brews = [
  "sops"
  "age"
];
```

#### 1.2 Generate Age Keys

```bash
# Generate master age key
age-keygen -o ~/.config/sops/age/keys.txt

# Backup age key securely (manual step)
cp ~/.config/sops/age/keys.txt ~/Desktop/age-key-backup.txt
```

#### 1.3 Configure SOPS

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.enc\.yaml$
    age: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - path_regex: secrets/.*\.enc\.yaml$
    age: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Phase 2: Basic Secrets Migration (Week 1-2)

#### 2.1 Create Secrets Structure

```text
secrets/
├── personal.enc.yaml      # GPG keys, SSH keys, personal tokens
├── aws.enc.yaml          # AWS account IDs, SSO configuration
├── development.enc.yaml  # API keys, service tokens
└── git.enc.yaml         # Git signing key, GitHub tokens
```

#### 2.2 Migrate Current Hardcoded Values

**AWS Configuration:**

```yaml
# secrets/aws.enc.yaml (encrypted)
aws:
  accounts:
    production:
      id: "384822754266"
      sso_role: "DataPlatformTeam"
    development:
      id: "588736812464" 
      sso_role: "AdministratorAccess"
  sso:
    start_url: "https://d-90670ca891.awsapps.com/start"
    region: "us-east-1"
```

#### 2.3 Update Nix Configuration

```nix
# home-manager/modules/aws-sso.nix
{ config, ... }: {
  sops.secrets."aws/accounts/production/id" = {
    sopsFile = ../../../secrets/aws.enc.yaml;
  };
  
  # Use placeholder for template generation
  sops.templates."aws-config" = {
    content = ''
      [profile production-sso]
      sso_account_id = ${config.sops.placeholder."aws/accounts/production/id"}
      # ... rest of config
    '';
    path = ".aws/config";
  };
}
```

### Phase 3: Advanced Integration (Week 2-3)

#### 3.1 Add sops-nix Integration

```nix
# flake.nix
{
  inputs = {
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { self, sops-nix, ... }: {
    darwinConfigurations.${hostname} = darwin.lib.darwinSystem {
      modules = [
        sops-nix.darwinModules.sops
        # ... existing modules
      ];
    };
  };
}
```

#### 3.2 Create Secrets Management Module

```nix
# darwin/secrets.nix
{ config, pkgs, ... }: {
  # SOPS configuration
  sops = {
    defaultSopsFile = ../secrets/personal.enc.yaml;
    age = {
      keyFile = "/Users/${config.users.primaryUser.name}/.config/sops/age/keys.txt";
      generateKey = false; # We'll manage keys manually
    };
  };
  
  # Environment for SOPS tools
  environment.systemPackages = with pkgs; [
    sops
    age
  ];
}
```

### Phase 4: Operational Excellence (Week 3-4)

#### 4.1 Secrets Rotation Automation

```bash
#!/usr/bin/env bash
# scripts/rotate-secrets.sh

echo "🔄 Rotating SOPS data keys..."
find secrets/ -name "*.enc.yaml" -exec sops --rotate --in-place {} \;

echo "🔄 Updating git signing key..."
NEW_KEY=$(gpg --list-secret-keys --keyid-format LONG | grep sec | head -1 | cut -d'/' -f2 | cut -d' ' -f1)
sops --set '["git"]["signing_key"] "'$NEW_KEY'"' secrets/git.enc.yaml

echo "✅ Secrets rotation complete"
```

#### 4.2 Health Monitoring Integration

```bash
# Add to scripts/system-health-monitor.sh
check_secrets_health() {
  echo "🔐 Checking secrets management health..."
  
  # Check SOPS is working
  if ! command -v sops &> /dev/null; then
    log_issue "CRITICAL" "SOPS not installed"
    return 1
  fi
  
  # Check age key exists
  if [ ! -f "$HOME/.config/sops/age/keys.txt" ]; then
    log_issue "CRITICAL" "Age private key not found"
    return 1
  fi
  
  # Test decryption
  if ! sops -d secrets/personal.enc.yaml > /dev/null 2>&1; then
    log_issue "CRITICAL" "Cannot decrypt secrets"
    return 1
  fi
  
  echo "✅ Secrets management healthy"
}
```

## Security Considerations

### Key Management Best Practices

1. **Age Key Security:**
   - Store private key outside of git repository
   - Create encrypted backups using different method (GPG, KeePass, etc.)
   - Consider hardware tokens for additional security

2. **Access Control:**
   - Use separate keys for different environments (dev/prod)
   - Implement key rotation schedule (quarterly)
   - Audit access logs for unauthorized decryption

3. **Repository Security:**
   - Never commit unencrypted secrets
   - Use pre-commit hooks to validate encryption
   - Regular security scans of encrypted files

### Backup and Recovery Strategy

**Primary Backup:**

```bash
# Encrypted backup of age key
gpg --cipher-algo AES256 --compress-algo 1 --s2k-digest-algo SHA512 \
    --s2k-mode 3 --s2k-count 65011712 --force-mdc \
    --output age-key.gpg --armor --symmetric ~/.config/sops/age/keys.txt
```

**Recovery Process:**

1. Restore age private key from secure backup
2. Verify decryption capability with test secrets
3. Run system rebuild to populate runtime secrets
4. Test all services requiring secrets

## Migration Timeline

| Phase | Duration | Deliverables | Risk Level |
|-------|----------|--------------|------------|
| **Phase 1** | 2-3 days | SOPS/Age setup, basic config | Low |
| **Phase 2** | 1 week | AWS secrets migration | Medium |
| **Phase 3** | 1 week | Full sops-nix integration | Medium |
| **Phase 4** | 1 week | Automation and monitoring | Low |

## Expected Benefits

### Security Improvements

- **100% encrypted secrets** in version control
- **Audit trail** for all secrets access
- **Automated rotation** workflows
- **Backup and recovery** procedures

### Operational Efficiency  

- **Declarative secrets** management
- **Automated deployment** of secrets
- **Integration** with existing Nix workflows
- **Team collaboration** on encrypted secrets

### Developer Experience

- **Transparent** encryption/decryption
- **Git-friendly** encrypted files
- **IDE integration** for editing secrets
- **Consistent** across all environments

## Implementation Commands

```bash
# Quick start commands
brew install sops age
age-keygen -o ~/.config/sops/age/keys.txt

# Initialize secrets structure
mkdir -p secrets
echo 'creation_rules:\n  - age: "$(cat ~/.config/sops/age/keys.txt | grep public | cut -d: -f2)"' > .sops.yaml

# Create first encrypted secret
echo 'test: "hello-world"' | sops --encrypt --input-type yaml /dev/stdin > secrets/test.enc.yaml
```

This implementation provides a robust, secure, and maintainable secrets
management solution that integrates seamlessly with the existing Nix Darwin
dotfiles configuration while following security best practices.
