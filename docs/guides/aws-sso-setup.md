# AWS SSO User Guide

Complete guide to using the AWS SSO configuration for seamless multi-account development.

## 🎯 **What This Module Provides**

Your AWS SSO configuration automates authentication and credential management across multiple AWS accounts with intelligent profile switching, credential validation, and support for both CLI and application usage.

### **Key Features**
- ✅ **Automated SSO Authentication** - One-command login to multiple accounts
- ✅ **Smart Profile Switching** - Automatic credential validation and account verification  
- ✅ **Dual Configuration** - Both SSO profiles (CLI) and traditional profiles (applications)
- ✅ **Lazy Loading** - Fast shell startup with on-demand function loading
- ✅ **Credential Export** - Environment variables and file-based credentials
- ✅ **Java/Scala Support** - Traditional credential files for legacy applications
- ✅ **Workflow Shortcuts** - Common operations simplified to single commands

## 🏢 **Configured AWS Accounts**

### **Production Account**
- **Account ID**: `384822754266` 
- **Role**: `DataPlatformTeam`
- **SSO Profile**: `production-sso`
- **Traditional Profile**: `production`

### **Development Account** 
- **Account ID**: `588736812464`
- **Role**: `AdministratorAccess`
- **SSO Profile**: `default-sso` / `staging-sso`
- **Traditional Profile**: `default` / `staging`

## 🚀 **Quick Start Commands**

### **Essential Daily Commands**
```bash
# Login to both AWS accounts (most common)
awsl                    # Login to both SSO profiles

# Switch to specific profile
awsprod                 # Switch to production
awsdefault              # Switch to development/default

# Export credentials for applications
awse                    # Export current profile to environment variables
awsb                    # Export both profiles to ~/.aws/credentials

# Super workflow (login + export everything)
awsall                  # Complete setup for development work

# Check current status
aws_status              # Show current profile and credentials
```

### **Profile Management**
```bash
# Switch profiles
aws_profile production-sso       # Switch to production SSO
aws_profile default-sso         # Switch to default SSO
aws_profile production          # Switch to traditional production

# Login to specific profiles
aws_sso_login production-sso    # Login to production only
aws_sso_login default-sso       # Login to development only
aws_sso_login both              # Login to both (same as awsl)
```

## 📚 **Complete Command Reference**

### **🔐 Authentication Commands**

| Command | Purpose | Example |
|---------|---------|---------|
| `awsl` | Login to both SSO profiles | `awsl` |
| `aws_sso_login [profile]` | Login to specific profile | `aws_sso_login production-sso` |
| `awsrp` | Refresh production login | `awsrp` |
| `awsrd` | Refresh default/dev login | `awsrd` |
| `awsc` / `aws_clear` | Clear all credentials | `awsc` |

### **🎯 Profile Switching**

| Command | Purpose | Target Profile |
|---------|---------|---------------|
| `awsprod` | Switch to production SSO | `production-sso` |
| `awsdefault` | Switch to default SSO | `default-sso` |
| `awsprod-trad` | Switch to production traditional | `production` |
| `awsdefault-trad` | Switch to default traditional | `default` |
| `aws_profile [name]` | Switch to any profile | Custom profile |

### **📤 Credential Export**

| Command | Purpose | Output |
|---------|---------|---------|
| `awse` / `aws_export_creds` | Export to environment variables | `AWS_ACCESS_KEY_ID`, etc. |
| `awsw` / `aws_export_to_file` | Export current to file | `~/.aws/credentials` |
| `awsb` / `aws_export_both_to_file` | Export both profiles to file | Both profiles in credentials |
| `awsp` / `aws_prod_env` | Production profile + export | Full production setup |
| `awsd` / `aws_default_env` | Default profile + export | Full default setup |

### **🔍 Status & Utilities**

| Command | Purpose | Information Shown |
|---------|---------|------------------|
| `aws_status` | Show current AWS state | Profile, region, account, identity |
| `aws configure list-profiles` | List all available profiles | All configured profiles |
| `aws sts get-caller-identity` | Show current AWS identity | Account ID, user ARN |

### **🚀 Workflow Shortcuts**

| Command | Purpose | What It Does |
|---------|---------|-------------|
| `awsall` / `aws_super_workflow` | Complete AWS setup | Login both + export both to file |
| `awsf` | Super workflow (alias) | Same as `awsall` |

## 🎯 **Common Workflows**

### **1. Daily Development Start**
```bash
# Complete setup for development work
awsall
# ✅ Logs into both SSO profiles
# ✅ Exports both to ~/.aws/credentials 
# ✅ Ready for CLI, Java, Scala, and other tools
```

### **2. Switch to Production Work**
```bash
# Switch to production and set up environment
awsp
# ✅ Switches to production-sso profile
# ✅ Exports credentials to environment variables
# ✅ Exports to ~/.aws/credentials as [production]
# ✅ Ready for production operations
```

### **3. CLI-Only Quick Switch**
```bash
# Just switch profiles for AWS CLI usage
awsprod                 # Switch to production
aws s3 ls              # Use production credentials

awsdefault             # Switch back to default
aws ec2 describe-instances  # Use default credentials
```

### **4. Application Development Setup**
```bash
# For Java/Scala applications that read ~/.aws/credentials
awsb                   # Export both profiles to credentials file
# ✅ [production] and [default] profiles available
# ✅ Applications can use standard credential resolution
```

### **5. Credential Refresh**
```bash
# When credentials expire (typically after 8-12 hours)
awsl                   # Re-login to both profiles
awsb                   # Re-export to credentials file
```

### **6. Troubleshooting**
```bash
# Check current status
aws_status             # See active profile and credentials

# Clear everything and start fresh
awsc                   # Clear all credentials and sessions
awsall                 # Set up everything again
```

## 🔧 **Configuration Details**

### **SSO Configuration**
- **SSO Start URL**: `https://d-90670ca891.awsapps.com/start`
- **SSO Region**: `us-east-1`
- **Default Region**: `us-west-2`
- **Output Format**: `json`

### **Profile Types**

**SSO Profiles** (for AWS CLI):
- `production-sso` → DataPlatformTeam role
- `default-sso` → AdministratorAccess role  
- `staging-sso` → AdministratorAccess role

**Traditional Profiles** (for applications):
- `production` → No SSO properties, works with static credentials
- `default` → No SSO properties, works with static credentials
- `staging` → No SSO properties, works with static credentials

### **File Locations**
- **AWS Config**: `~/.aws/config` (managed by Home Manager)
- **AWS Credentials**: `~/.aws/credentials` (generated by export commands)
- **Backups**: `~/.aws/credentials.backup.YYYYMMDD_HHMMSS`

## 🚨 **Troubleshooting**

### **Common Issues**

**"Profile not found" errors:**
```bash
aws configure list-profiles  # Check available profiles
aws_status                  # Check current state
```

**"Credentials expired" errors:**
```bash
awsl                        # Re-login to SSO
aws_status                  # Verify credentials are working
```

**"SSO session expired":**
```bash
awsc                        # Clear all sessions
awsall                      # Complete fresh setup
```

**Applications can't find credentials:**
```bash
awsb                        # Export both profiles to ~/.aws/credentials
ls -la ~/.aws/credentials   # Verify file exists
```

### **Credential Lifecycle**

1. **SSO Login** → Temporary SSO credentials (8-12 hours)
2. **Profile Switch** → Active profile set in environment
3. **Export to Environment** → `AWS_ACCESS_KEY_ID`, etc. set
4. **Export to File** → Traditional credentials written to `~/.aws/credentials`

### **Environment Variables**

The module sets these automatically:
```bash
AWS_DEFAULT_REGION=us-west-2
AWS_REGION=us-west-2
AWS_PROFILE=<current-profile>
```

When using `awse` or credential export:
```bash
AWS_ACCESS_KEY_ID=<temporary-key>
AWS_SECRET_ACCESS_KEY=<temporary-secret>
AWS_SESSION_TOKEN=<temporary-token>
```

## 💡 **Tips & Best Practices**

### **Recommended Daily Workflow**
1. **Morning**: `awsall` (complete setup)
2. **Switch contexts**: `awsprod` or `awsdefault` as needed
3. **Before important operations**: `aws_status` (verify credentials)
4. **End of day**: No cleanup needed (credentials auto-expire)

### **For Different Use Cases**

**AWS CLI Only:**
```bash
awsprod    # or awsdefault
# Just use AWS CLI commands
```

**Development Applications:**
```bash
awsall     # Sets up everything including ~/.aws/credentials
# Applications can now use standard credential resolution
```

**Production Operations:**
```bash
awsp       # Switch to production with full environment setup
aws_status # Double-check you're in the right account
# Proceed with production operations
```

### **Security Notes**
- ✅ Credentials are temporary (8-12 hours)
- ✅ SSO provides audit logging
- ✅ No long-term credentials stored
- ✅ Role-based access control
- ✅ Automatic credential backup before overwriting

## 🎓 **Advanced Usage**

### **Custom Profile Switching**
```bash
# Switch to any configured profile
aws_profile staging-sso
aws_profile production

# Export specific profile to file with custom name
aws_export_to_file production-sso my-prod-profile
```

### **Credential Validation**
```bash
# Test specific profile credentials
AWS_PROFILE=production-sso aws sts get-caller-identity

# Use internal validation function
_aws_test_creds production-sso
```

### **Manual SSO Operations**
```bash
# Individual SSO logins
aws sso login --profile production-sso
aws sso login --profile default-sso

# Manual logout
aws sso logout
```

This comprehensive AWS SSO setup streamlines multi-account development and ensures secure, efficient credential management across all your AWS operations! 🚀
