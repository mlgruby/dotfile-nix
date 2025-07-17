# Secrets Management with SOPS

A comprehensive guide to managing sensitive configuration data using SOPS (Secrets OPerationS) with your Nix Darwin setup.

## Overview

SOPS provides encrypted storage for sensitive configuration data like API keys, passwords, and personal information. It integrates seamlessly with Nix and allows you to safely commit encrypted secrets to Git.

### Benefits

- **🔐 Secure**: Files encrypted with GPG/Age keys
- **📝 Git-friendly**: Safe to commit encrypted files  
- **🏗️ Build-time decryption**: Automatically decrypted during Nix builds
- **👥 Team-ready**: Support multiple team members with different keys
- **🎯 Granular**: Fine-grained access control per secret

## Quick Start

### Prerequisites

1. **GPG key set up** (run `./setup-gpg-github.sh` first)
2. **SOPS installed** (already in Homebrew configuration)
3. **user-config.nix configured** with your information

### Setup SOPS

```bash
# Initialize SOPS with your GPG key
./setup-sops.sh
```

This script will:

- Configure SOPS with your GPG key
- Create an encrypted secrets file
- Test encryption/decryption
- Show you common usage patterns

### Quick Usage

```bash
# Edit secrets (automatically decrypts)
sops secrets.yaml

# View decrypted content
sops -d secrets.yaml

# Manually encrypt after editing
sops -e -i secrets.yaml
```

## File Structure

After setup, you'll have:

```text
.
├── .sops.yaml          # SOPS configuration
├── secrets.yaml        # Encrypted secrets (safe for Git)
├── darwin/secrets.nix  # Nix configuration for secrets
└── setup-sops.sh       # Setup script
```

## Configuration Files

### .sops.yaml

Defines encryption rules and key management:

```yaml
creation_rules:
  - path_regex: secrets\.ya?ml$
    pgp: >-
      YOUR_GPG_KEY_ID
```

### secrets.yaml (after encryption)

Contains your encrypted sensitive data:

```yaml
# Encrypted format (safe for Git)
user:
    email: ENC[AES256_GCM,data:xxxx,iv:yyyy,tag:zzzz,type:str]
    signing_key: ENC[AES256_GCM,data:aaaa,iv:bbbb,tag:cccc,type:str]
```

### darwin/secrets.nix

Nix configuration that defines how secrets are used:

```nix
sops = {
  defaultSopsFile = ../secrets.yaml;
  secrets = {
    "user/email" = {
      path = "/run/secrets/user-email";
      owner = "your-username";
    };
  };
};
```

## Common Use Cases

### 1. User Information

Store personal/sensitive user data:

```yaml
user:
  email: "your.private@email.com"
  signing_key: "ABC123DEF456"
  full_name: "Your Full Name"
```

Access in Nix:

```nix
programs.git = {
  userEmail = builtins.readFile config.sops.secrets."user/email".path;
  signingKey = builtins.readFile config.sops.secrets."user/signing-key".path;
};
```

### 2. API Tokens

Store API keys and tokens:

```yaml
github:
  token: "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  
aws:
  access_key: "AKIAXXXXXXXXXXXXXXXX"
  secret_key: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Access in scripts:

```bash
GITHUB_TOKEN=$(cat /run/secrets/github-token)
```

### 3. Database Credentials

Store database connection information:

```yaml
database:
  password: "super-secret-password"
  connection_string: "postgresql://user:pass@host:5432/db"
```

## Advanced Usage

### Adding New Secrets

1. **Edit the secrets file:**

   ```bash
   sops secrets.yaml
   ```

2. **Add your secret:**

   ```yaml
   new_service:
     api_key: "your-new-secret"
   ```

3. **Define in darwin/secrets.nix:**

   ```nix
   secrets."new_service/api_key" = {
     path = "/run/secrets/new-service-api-key";
     owner = userConfig.username;
   };
   ```

4. **Rebuild system:**

   ```bash
   rebuild
   ```

### Team Collaboration

To add team members who can decrypt secrets:

1. **Get their GPG public key**
2. **Update .sops.yaml:**

   ```yaml
   creation_rules:
     - path_regex: secrets\.ya?ml$
       pgp: >-
         YOUR_KEY_ID,
         TEAMMATE_KEY_ID
   ```

3. **Re-encrypt for new key:**

   ```bash
   sops updatekeys secrets.yaml
   ```

### Different Secret Files

For organization, you can have multiple secret files:

```yaml
# .sops.yaml
creation_rules:
  - path_regex: secrets/prod\.ya?ml$
    pgp: "PROD_KEY_ID"
  - path_regex: secrets/dev\.ya?ml$  
    pgp: "DEV_KEY_ID"
```

## Integration Examples

### Git Configuration

Replace hardcoded values with secrets:

```nix
# Before (in git.nix)
programs.git = {
  userEmail = "hardcoded@email.com";
  signingKey = "ABC123";
};

# After (using SOPS)
programs.git = {
  userEmail = builtins.readFile config.sops.secrets."user/email".path;
  signingKey = builtins.readFile config.sops.secrets."user/signing-key".path;
};
```

### Environment Variables

Make secrets available as environment variables:

```nix
# In home-manager configuration
home.sessionVariables = {
  GITHUB_TOKEN_FILE = config.sops.secrets."github/token".path;
};
```

```bash
# In shell scripts
export GITHUB_TOKEN=$(cat $GITHUB_TOKEN_FILE)
```

### Application Configuration

Use secrets in application configs:

```nix
# Example: Configure a service with secret API key
programs.some-app = {
  enable = true;
  apiKeyFile = config.sops.secrets."some-app/api-key".path;
};
```

## Troubleshooting

### Common Issues

1. **"no matching keys found"**
   - Check your GPG key is in .sops.yaml
   - Verify GPG key is available: `gpg --list-secret-keys`

2. **"Failed to decrypt"**
   - Ensure GPG agent is running
   - Check file permissions on secrets

3. **"Build fails with SOPS error"**
   - Set `validateSopsFiles = false` during initial setup
   - Enable once secrets.yaml exists and is encrypted

### Debug Commands

```bash
# Check SOPS can decrypt
sops -d secrets.yaml

# Verify GPG setup
gpg --list-secret-keys

# Check secret file permissions
ls -la /run/secrets/

# Test GPG decryption manually
echo "test" | gpg --encrypt --armor -r YOUR_KEY_ID | gpg --decrypt
```

## Best Practices

### Security

1. **Never commit unencrypted secrets**
2. **Use different keys for different environments**
3. **Regularly rotate secrets and keys**
4. **Limit key access to necessary team members**

### Organization

1. **Group related secrets logically**
2. **Use descriptive secret names**
3. **Document secret purposes**
4. **Keep .sops.yaml in version control**

### Maintenance

1. **Regular key rotation**
2. **Clean up unused secrets**
3. **Monitor secret access logs**
4. **Backup encryption keys securely**

## Examples Repository

See `secrets.yaml` (after running `./setup-sops.sh`) for a complete example with:

- User information
- AWS configuration  
- GitHub tokens
- Database credentials
- API keys

## Getting Help

1. **SOPS Documentation**: [https://github.com/mozilla/sops](https://github.com/mozilla/sops)
2. **Check setup script**: `./setup-sops.sh`
3. **Verify configuration**: `sops -d secrets.yaml`
4. **Debug build**: `rebuild` and check error messages
