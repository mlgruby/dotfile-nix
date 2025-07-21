# AWS SSO User Guide

Complete guide to setting up and using the AWS SSO configuration for seamless
multi-account development.

## 🎯 **What This Module Provides**

Your AWS SSO configuration automates authentication and credential management
across multiple AWS accounts with intelligent profile switching, credential
validation, and support for both CLI and application usage.

### **Key Features**

- ✅ **Automated SSO Authentication** - One-command login to multiple accounts
- ✅ **Smart Profile Switching** - Automatic credential validation and account
  verification
- ✅ **Dual Configuration** - Both SSO profiles (CLI) and traditional profiles
  (applications)
- ✅ **Lazy Loading** - Fast shell startup with on-demand function loading
- ✅ **Credential Export** - Environment variables and file-based credentials
- ✅ **Java/Scala Support** - Traditional credential files for legacy
  applications
- ✅ **Workflow Shortcuts** - Common operations simplified to single commands

## 🛠️ **Initial AWS SSO Setup**

Before using AWS SSO, you need to set up AWS SSO access and configure the AWS CLI.
This is a one-time setup process.

### **Prerequisites**

- AWS CLI v2 installed (`aws --version` should show v2.x.x)
- Access to your organization's AWS SSO portal
- Appropriate permissions in target AWS accounts

### **Step 1: Install AWS CLI v2 (if not already installed)**

**macOS (with Homebrew):**

```bash
brew install awscli
```

**macOS (official installer):**

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Verify installation:**

```bash
aws --version
# Should show: aws-cli/2.x.x Python/3.x.x ...
```

### **Step 2: Configure AWS SSO**

**Initial SSO Configuration:**

```bash
# Configure the default SSO profile
aws configure sso

# You'll be prompted for:
# SSO start URL: https://d-90670ca891.awsapps.com/start
# SSO Region: us-east-1
# Account ID: 588736812464 (for dev/default)
# Role name: AdministratorAccess
# CLI default client Region: us-west-2
# CLI default output format: json
# CLI profile name: default-sso
```

**Configure Production SSO Profile:**

```bash
# Configure production profile
aws configure sso --profile production-sso

# You'll be prompted for:
# SSO start URL: https://d-90670ca891.awsapps.com/start
# SSO Region: us-east-1
# Account ID: 384822754266 (for production)
# Role name: DataPlatformTeam
# CLI default client Region: us-west-2
# CLI default output format: json
# CLI profile name: production-sso
```

### **Step 3: Initial SSO Login**

**Login to both profiles:**

```bash
# Login to default/dev account
aws sso login --profile default-sso

# Login to production account
aws sso login --profile production-sso
```

This will:

1. Open your browser to the SSO portal
2. Prompt you to sign in with your credentials
3. Ask you to authorize the AWS CLI
4. Store temporary credentials locally

### **Step 4: Verify Setup**

**Test your profiles:**

```bash
# Test default profile
aws sts get-caller-identity --profile default-sso

# Test production profile
aws sts get-caller-identity --profile production-sso
```

You should see output like:

```json
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "588736812464",
    "Arn": "arn:aws:sts::588736812464:assumed-role/..."
}
```

### **Step 5: Test Your Setup**

**Verify both profiles work correctly:**

```bash
# Test profile switching
aws sts get-caller-identity --profile default-sso
aws sts get-caller-identity --profile production-sso

# Test switching between profiles
export AWS_PROFILE=default-sso
aws sts get-caller-identity

export AWS_PROFILE=production-sso  
aws sts get-caller-identity
```

### **🔧 Configuration Files Created**

After setup, these files will exist:

**AWS CLI Configuration (`~/.aws/config`):**

```ini
[profile default-sso]
sso_start_url = https://d-90670ca891.awsapps.com/start
sso_region = us-east-1
sso_account_id = 588736812464
sso_role_name = AdministratorAccess
region = us-west-2
output = json

[profile production-sso]
sso_start_url = https://d-90670ca891.awsapps.com/start
sso_region = us-east-1
sso_account_id = 384822754266
sso_role_name = DataPlatformTeam
region = us-west-2
output = json
```

**SSO Cache Directory:**

```bash
~/.aws/sso/cache/          # SSO session cache
~/.aws/cli/cache/          # CLI cache
```

### **🚨 Troubleshooting Initial Setup**

**"AWS CLI not found":**

```bash
# Check if AWS CLI v2 is installed
which aws
aws --version

# If not found, install AWS CLI v2
brew install awscli
```

**"SSO session expired" during setup:**

```bash
# Clear any existing SSO sessions
aws sso logout

# Start fresh
aws configure sso --profile default-sso
```

**"Invalid SSO token" errors:**

```bash
# Remove cached credentials
rm -rf ~/.aws/sso/cache/
rm -rf ~/.aws/cli/cache/

# Re-login
aws sso login --profile default-sso
```

**Permission denied errors:**

- Check with your AWS administrator that your user has access to the specified
  accounts and roles
- Verify you're using the correct Account IDs and Role names
- Ensure your user is assigned to the appropriate permission sets

**Browser doesn't open for SSO login:**

```bash
# Manual browser login
aws sso login --profile default-sso --no-browser

# This will give you a URL to open manually
```

### **📋 Account Information Reference**

For your organization's setup:

| Account Type | Account ID | Role | Profile Name |
|--------------|------------|------|--------------|
| Development/Default | `588736812464` | `AdministratorAccess` | `default-sso` |
| Production | `384822754266` | `DataPlatformTeam` | `production-sso` |

**SSO Portal URL:** `https://d-90670ca891.awsapps.com/start`

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
# Login to SSO profiles
aws sso login --profile default-sso      # Login to development
aws sso login --profile production-sso   # Login to production

# Switch between profiles
export AWS_PROFILE=default-sso           # Switch to development
export AWS_PROFILE=production-sso        # Switch to production

# Check current identity
aws sts get-caller-identity              # Show current AWS identity

# Export credentials for applications
aws configure export-credentials --format env    # Export to environment variables
aws configure export-credentials --format env-no-export > .env  # Save to file
```

### **Profile Management**

```bash
# Switch profiles using environment variable
export AWS_PROFILE=production-sso       # Switch to production SSO
export AWS_PROFILE=default-sso          # Switch to default SSO

# Or use --profile flag with commands
aws sts get-caller-identity --profile production-sso
aws s3 ls --profile default-sso

# Login to specific profiles
aws sso login --profile production-sso  # Login to production only
aws sso login --profile default-sso     # Login to development only

# List available profiles
aws configure list-profiles
```

## 📚 **Common AWS CLI Commands**

### **🔐 Authentication Commands**

| Command | Purpose | Example |
|---------|---------|---------|
| `aws sso login` | Login to default SSO profile | `aws sso login` |
| `aws sso login --profile [name]` | Login to specific profile | `aws sso login --profile production-sso` |
| `aws sso logout` | Logout from SSO | `aws sso logout` |

### **🎯 Profile Management**

| Command | Purpose | Example |
|---------|---------|---------------|
| `export AWS_PROFILE=[name]` | Switch to profile | `export AWS_PROFILE=production-sso` |
| `aws configure list-profiles` | List all available profiles | `aws configure list-profiles` |
| `aws configure list` | Show current configuration | `aws configure list` |

### **📤 Credential Management**

| Command | Purpose | Output |
|---------|---------|---------|
| `aws configure export-credentials` | Export to environment variables | `AWS_ACCESS_KEY_ID`, etc. |
| `aws configure export-credentials --format env-no-export` | Export to file format | Export commands |
| `aws sts get-caller-identity` | Show current AWS identity | Account ID, user ARN |

### **🔍 Status & Verification**

| Command | Purpose | Information Shown |
|---------|---------|------------------|
| `aws sts get-caller-identity` | Show current AWS identity | Account ID, user ARN, role |
| `aws configure list` | Show current configuration | Profile, region, credentials |
| `echo $AWS_PROFILE` | Show active profile | Current profile name |

## 🎯 **Common Workflows**

### **1. Daily Development Start**

```bash
# Login to both profiles
aws sso login --profile default-sso
aws sso login --profile production-sso

# Set default profile for the session
export AWS_PROFILE=default-sso

# Verify setup
aws sts get-caller-identity
```

### **2. Switch to Production Work**

```bash
# Switch to production profile
export AWS_PROFILE=production-sso

# Verify you're in the right account
aws sts get-caller-identity

# Proceed with production operations
aws s3 ls
```

### **3. CLI-Only Quick Switch**

```bash
# Switch to production
export AWS_PROFILE=production-sso
aws s3 ls              # Use production credentials

# Switch back to default
export AWS_PROFILE=default-sso
aws ec2 describe-instances  # Use default credentials
```

### **4. Application Development Setup**

```bash
# Export credentials for applications
aws configure export-credentials --format env > .env

# Or export to environment variables
eval $(aws configure export-credentials --format env)

# Verify credentials are set
echo $AWS_ACCESS_KEY_ID
```

### **5. Credential Refresh**

```bash
# When credentials expire (typically after 8-12 hours)
aws sso login --profile default-sso
aws sso login --profile production-sso

# Test that credentials work
aws sts get-caller-identity
```

### **6. Troubleshooting**

```bash
# Check current status
aws configure list
aws sts get-caller-identity

# Clear SSO sessions and start fresh
aws sso logout
aws sso login --profile default-sso
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
4. **Export to File** → Traditional credentials written to
   `~/.aws/credentials`

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

This comprehensive AWS SSO setup streamlines multi-account development and
ensures secure, efficient credential management across all your AWS
operations! 🚀
