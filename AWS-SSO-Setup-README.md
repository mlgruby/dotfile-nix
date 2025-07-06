# AWS SSO Setup for Non-Nix Users

A comprehensive setup script that provides AWS SSO functionality equivalent to Nix-based configurations, with cross-shell compatibility and convenient aliases.

## 🚀 Quick Start

### Prerequisites
- AWS CLI v2 installed
- Access to Lightricks AWS SSO portal

### Installation

1. **Download and run the setup script:**
   ```bash
   chmod +x setup-aws-sso-cross-shell.sh
   ./setup-aws-sso-cross-shell.sh
   ```

2. **Reload your shell:**
   ```bash
   source ~/.zshrc    # for zsh users
   source ~/.bashrc   # for bash users (Linux)
   source ~/.bash_profile  # for bash users (macOS)
   ```

3. **Login to AWS SSO:**
   ```bash
   awsl  # Short alias for aws_sso_login
   ```

4. **Verify setup:**
   ```bash
   awsw  # Shows your current AWS identity
   ```

## ✨ Features

- **🔄 Cross-Shell Compatible**: Works with both bash and zsh
- **🎯 Auto-Detection**: Automatically detects your shell and config files
- **⚡ Short Aliases**: Super convenient 2-4 character commands
- **🔑 Multiple Export Options**: Environment variables, files, copy-paste commands
- **🏢 Multi-Account Support**: Production, staging, and development profiles
- **🧹 Easy Cleanup**: Clear credentials and switch profiles easily

## 🎯 Quick Reference

### 📱 Login & Profile Management

| Command | Full Command | Description |
|---------|-------------|-------------|
| `awsl` | `aws_sso_login` | Login to default SSO profile |
| `awslp` | `aws_sso_login production-sso` | Login to production |
| `awsld` | `aws_sso_login default-sso` | Login to default/dev |
| `awslb` | `aws_sso_login both` | Login to both profiles |
| `awsp <profile>` | `aws_profile <profile>` | Switch to specific profile |
| `awspp` | `aws_profile production-sso` | Switch to production |
| `awspd` | `aws_profile default-sso` | Switch to default/dev |

### 🔑 Credential Export

| Command | Description | Use Case |
|---------|-------------|----------|
| `awse` | Export to environment variables | Current shell session |
| `awsec` | Export + show identity | Quick export with verification |
| `awsef <profile>` | Export profile to file | Save for later use |
| `awsenv` | Show copy-paste commands | Share with others/scripts |
| `awsgen` | Generate .env file | Application development |

### 🔍 Utilities

| Command | Description |
|---------|-------------|
| `awsw` | Who am I? (current identity) |
| `awsc` | Clear all AWS credentials |
| `awsls` | List all available profiles |
| `awsid` | Quick identity check |
| `awsr` | Show current AWS configuration |

## 📋 Available Profiles

### SSO Profiles (Recommended)
- **`default-sso`** - Development account (588736812464) with AdministratorAccess
- **`production-sso`** - Production account (384822754266) with DataPlatformTeam role
- **`staging-sso`** - Staging account (588736812464) with AdministratorAccess

### Traditional Profiles
- **`default`**, **`production`**, **`staging`**, **`prod`**, **`dev`** - For applications that don't support SSO

## 🛠 Detailed Usage

### Basic Workflow

1. **Login to AWS SSO:**
   ```bash
   awsl                    # Login to default profile
   # or
   awslp                   # Login to production
   # or  
   awslb                   # Login to both profiles
   ```

2. **Check your identity:**
   ```bash
   awsw
   # Output:
   # 🔍 Current AWS Configuration:
   # Profile: default-sso
   # Region: us-west-2
   # ✅ Account: 588736812464
   # 👤 User ID: AIDACKCEVSQ6C2EXAMPLE
   # 🎭 ARN: arn:aws:sts::588736812464:assumed-role/...
   ```

3. **Use AWS CLI normally:**
   ```bash
   aws s3 ls
   aws ec2 describe-instances
   # All commands use your current profile automatically
   ```

### Advanced Credential Export

#### 1. Export to Environment Variables
```bash
awse
# Exports AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN
# to your current shell session
```

#### 2. Export to File
```bash
awsef production-sso ~/.aws/prod-creds.env
# Creates a file you can source later:
source ~/.aws/prod-creds.env
```

#### 3. Generate .env File for Applications
```bash
awsgen myapp.env
# Creates myapp.env with:
# AWS_ACCESS_KEY_ID=AKIA...
# AWS_SECRET_ACCESS_KEY=...
# AWS_SESSION_TOKEN=...
# AWS_REGION=us-west-2
# AWS_DEFAULT_REGION=us-west-2
```

#### 4. Get Copy-Paste Commands
```bash
awsenv production-sso
# Output:
# 📋 Copy and paste these commands to export credentials:
# # ===== AWS Credentials for production-sso =====
# export AWS_ACCESS_KEY_ID=AKIA...
# export AWS_SECRET_ACCESS_KEY=...
# export AWS_SESSION_TOKEN=...
# # ===== End AWS Credentials =====
```

### Profile Management

#### Switch Between Profiles
```bash
awsp default-sso        # Switch to development
awsp production-sso     # Switch to production
awsp staging-sso        # Switch to staging
```

#### Quick Profile Switches
```bash
awspp                   # Quick switch to production
awspd                   # Quick switch to default/dev
```

#### List Available Profiles
```bash
awsls
# Output:
# 📋 Available AWS profiles:
#   default
#   default-sso
#   production
#   production-sso
#   staging-sso
```

### Troubleshooting

#### Clear All Credentials
```bash
awsc
# Clears all AWS environment variables
```

#### Check Current Status
```bash
awsw                    # Detailed identity information
awsid                   # Quick identity check
awsr                    # Current configuration
```

#### Re-login if Credentials Expire
```bash
awsl                    # Re-login to current/default profile
awslp                   # Re-login to production
```

## 🔧 Technical Details

### What the Script Does

1. **Installs AWS Configuration**: Creates `~/.aws/config` with SSO profiles
2. **Adds Shell Functions**: Installs helper functions in your shell config
3. **Creates Aliases**: Sets up convenient short commands
4. **Enables Completion**: Configures AWS CLI tab completion

### Files Modified

- **`~/.aws/config`** - AWS CLI configuration with SSO profiles
- **`~/.zshrc`** or **`~/.bashrc`/`~/.bash_profile`** - Shell functions and aliases

### Shell Compatibility

| Shell | Config File | Platform |
|-------|-------------|----------|
| Zsh | `~/.zshrc` | All |
| Bash | `~/.bashrc` | Linux |
| Bash | `~/.bash_profile` | macOS |

The script automatically detects your shell and uses the appropriate configuration file.

## 🚨 Security Notes

- **Temporary Credentials**: All exported credentials are temporary (typically 1-12 hours)
- **SSO Integration**: Uses AWS SSO for secure authentication
- **No Stored Secrets**: No long-term credentials are stored locally
- **Session Management**: SSO sessions need periodic re-authentication

## 🤝 Integration with Applications

### For Docker/Docker Compose
```bash
awsgen .env
docker-compose up
# Your containers will have AWS credentials
```

### For Node.js/Python Applications
```bash
awsgen .env
# Add to your application:
# require('dotenv').config() // Node.js
# from dotenv import load_dotenv; load_dotenv() // Python
```

### For Shell Scripts
```bash
awsef ~/.aws/script-creds.env
# In your script:
source ~/.aws/script-creds.env
```

## 📞 Support

### Common Issues

1. **"aws command not found"**
   - Install AWS CLI v2: `brew install awscli` (macOS) or follow AWS documentation

2. **"Profile not found"**
   - Run `awsls` to see available profiles
   - Make sure you've run the setup script

3. **"Credentials expired"**
   - Run `awsl` to re-authenticate
   - SSO sessions expire periodically

4. **Functions not available after installation**
   - Reload your shell: `source ~/.zshrc` or `source ~/.bashrc`
   - Make sure the setup script completed successfully

### Getting Help

- Run `awsw` to check current status
- Run `awsls` to see available profiles  
- Check AWS SSO portal access with your administrator

## 🔄 Comparison with Nix Setup

This setup provides equivalent functionality to Nix-based AWS SSO configurations:

| Feature | Nix Setup | This Setup |
|---------|-----------|------------|
| SSO Login | ✅ | ✅ |
| Profile Switching | ✅ | ✅ |
| Credential Export | ✅ | ✅ |
| Shell Integration | ✅ | ✅ |
| Auto-completion | ✅ | ✅ |
| Cross-shell Support | ✅ | ✅ |
| Easy Installation | ✅ | ✅ |
| No Dependencies | ❌ | ✅ |

## 📄 License

This setup script is provided as-is for internal use. Modify as needed for your organization.

---

**🎉 Enjoy your streamlined AWS SSO experience!** 