#!/bin/bash
#
# Pre-Nix Installation Script
# ==========================
#
# This script automates the setup of a new macOS system with Nix, nix-darwin, and dotfiles.
#
# Core Files:
# - nix/nix.conf: Core Nix configuration
# - nix/zshrc: Shell configuration
# - nix/dynamic-config.zsh: Shell functions
# - flake.nix: System configuration
#
# File Placement:
# - nix.conf → /etc/nix/nix.conf
# - zshrc → ~/.zshrc
# - dynamic-config.zsh → ~/.dynamic-config.zsh
#
# Features:
# ---------
# 1. System Preparation:
#    - Installs Xcode Command Line Tools
#    - Sets up Homebrew
#    - Installs essential packages (git, stow)
#
# 2. Nix Setup:
#    - Installs Nix package manager
#    - Configures multi-user installation
#    - Enables experimental features (flakes)
#
# 3. Dotfiles Management:
#    - Clones your dotfiles repository
#    - Creates necessary directory structure
#    - Sets up proper symlinks
#
# 4. Git/GitHub Configuration:
#    - Configures Git identity
#    - Sets up SSH keys for GitHub
#    - Tests GitHub connectivity
#
# File Structure:
# --------------
# ~/Documents/dotfile/
# ├── nix/
# │   ├── nix.conf           # Nix configuration
# │   ├── zshrc              # Shell configuration
# │   └── dynamic-config.zsh # Shell functions
# ├── darwin/                # Darwin configuration
# ├── home-manager/          # User environment
# └── flake.nix              # System definition
#
# Usage:
# ------
# 1. Basic Installation:
#    ```bash
#    curl -o pre-nix-installation.sh <your-repo-raw-url>/scripts/install/pre-nix-installation.sh
#    chmod +x pre-nix-installation.sh
#    ./pre-nix-installation.sh
#    ```
#
# 2. Interactive Options:
#    - The script will prompt for:
#      * Dotfiles repository URL
#      * Git user name and email
#      * SSH key generation for GitHub
#
# Directory Structure Created:
# --------------------------
# ~/.config/
# ├── nix/
# ├── darwin/
# └── home-manager/
#
# ~/Documents/dotfile/ (Your configuration repository)
#
# Requirements:
# ------------
# - macOS operating system
# - Internet connection
# - GitHub account (for dotfiles and SSH setup)
#
# Error Handling:
# --------------
# - The script uses set -e to exit on any error
# - Custom error handling function for better feedback
# - Backup creation for important files
#
# Post-Installation:
# ----------------
# After running the script:
# 1. Restart your terminal
# 2. Run 'darwin-rebuild switch --flake .#ss-mbp'
# 3. Test your new configuration
#
# Troubleshooting:
# ---------------
# If you encounter issues:
# 1. Check the terminal output for error messages
# 2. Verify your dotfiles repository is accessible
# 3. Ensure you have proper permissions
# 4. Check system requirements are met
#
# Maintenance:
# -----------
# To update your system after installation:
# 1. cd ~/Documents/dotfile
# 2. git pull
# 3. darwin-rebuild switch --flake .#ss-mbp

# Exit on any error
set -e

# ================================================================================================
# BOOTSTRAP SCRIPT FOR BARE METAL MAC
# ================================================================================================
# 
# This script is designed to be run on a completely fresh Mac with nothing installed.
# Download and run with:
# 
#   curl -o pre-nix-installation.sh <your-repo-raw-url>/scripts/install/pre-nix-installation.sh
#   chmod +x pre-nix-installation.sh
#   ./pre-nix-installation.sh
#
# ================================================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Utility Functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

normalize_hostname() {
    local raw="$1"

    # Keep only the first label and normalize separators for flake output names.
    raw="${raw%%.*}"
    raw="${raw//_/-}"
    raw=$(echo "$raw" | tr -cd '[:alnum:]-')
    raw=$(echo "$raw" | sed -E 's/-+/-/g; s/^-+//; s/-+$//')

    echo "$raw"
}

is_valid_hostname() {
    [[ "$1" =~ ^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$ ]]
}

is_valid_profile() {
    [[ "$1" == "personal" || "$1" == "work" ]]
}

is_valid_email() {
    [[ "$1" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]
}

ensure_trailing_slash() {
    local path="$1"
    case "$path" in
        */) echo "$path" ;;
        *) echo "${path}/" ;;
    esac
}

list_hosts_profiles() {
    local hosts_file="$1"
    awk '
        /^[[:space:]]*hosts[[:space:]]*=[[:space:]]*{/ {in_hosts=1; next}
        in_hosts && /^[[:space:]]*};[[:space:]]*$/ {in_hosts=0; exit}
        in_hosts && /^[[:space:]]*[a-zA-Z0-9_-]+[[:space:]]*=[[:space:]]*{/ {
            line=$0
            sub(/^[[:space:]]*/, "", line)
            sub(/[[:space:]]*=.*/, "", line)
            print line
        }
    ' "$hosts_file"
}

read_hosts_common_value() {
    local key="$1"
    local hosts_file="$2"
    awk -v key="$key" '
        /^[[:space:]]*common[[:space:]]*=[[:space:]]*{/ {in_common=1; next}
        in_common && /^[[:space:]]*};[[:space:]]*$/ {in_common=0; exit}
        in_common {
            pattern="^[[:space:]]*" key "[[:space:]]*="
            if ($0 ~ pattern) {
                match($0, /"[^"]*"/)
                if (RSTART > 0) {
                    print substr($0, RSTART + 1, RLENGTH - 2)
                    exit
                }
            }
        }
    ' "$hosts_file"
}

read_hosts_profile_value() {
    local profile="$1"
    local key="$2"
    local hosts_file="$3"
    awk -v profile="$profile" -v key="$key" '
        /^[[:space:]]*hosts[[:space:]]*=[[:space:]]*{/ {in_hosts=1; next}
        in_hosts && /^[[:space:]]*};[[:space:]]*$/ {in_hosts=0; exit}
        in_hosts && $0 ~ ("^[[:space:]]*" profile "[[:space:]]*=[[:space:]]*{") {in_profile=1; next}
        in_profile && /^[[:space:]]*};[[:space:]]*$/ {in_profile=0; next}
        in_profile {
            pattern="^[[:space:]]*" key "[[:space:]]*="
            if ($0 ~ pattern) {
                match($0, /"[^"]*"/)
                if (RSTART > 0) {
                    print substr($0, RSTART + 1, RLENGTH - 2)
                    exit
                }
            }
        }
    ' "$hosts_file"
}

find_hosts_profile_by_hostname() {
    local hosts_file="$1"
    local current_hostname="$2"
    local profile
    while IFS= read -r profile; do
        [ -z "$profile" ] && continue
        local file_hostname
        file_hostname=$(read_hosts_profile_value "$profile" "hostname" "$hosts_file")
        if [ "$file_hostname" = "$current_hostname" ]; then
            echo "$profile"
            return 0
        fi
    done < <(list_hosts_profiles "$hosts_file")
    return 1
}

configure_git_email_profiles() {
    local default_work_path="$HOME/Documents/Work/"
    local default_personal_path="$HOME/Documents/Personal/"
    local work_path=""
    local personal_path=""
    local work_email=""
    local personal_email=""

    if [ -f "$HOME/.gitconfig-work" ]; then
        work_email=$(git config -f "$HOME/.gitconfig-work" --get user.email || true)
    fi
    if [ -f "$HOME/.gitconfig-personal" ]; then
        personal_email=$(git config -f "$HOME/.gitconfig-personal" --get user.email || true)
    fi

    echo -e "${BLUE}Git uses repository paths to select WORK vs PERSONAL email (includeIf.gitdir).${NC}"
    echo -e "${BLUE}Any repo inside this WORK directory will use your WORK email profile.${NC}"
    echo -e "${BLUE}Set base directory for work repositories (default: $default_work_path):${NC}"
    read -r work_path
    work_path=${work_path:-$default_work_path}
    work_path=$(ensure_trailing_slash "$work_path")

    echo -e "${BLUE}Any repo inside this PERSONAL directory will use your PERSONAL email profile.${NC}"
    echo -e "${BLUE}Set base directory for personal repositories (default: $default_personal_path):${NC}"
    read -r personal_path
    personal_path=${personal_path:-$default_personal_path}
    personal_path=$(ensure_trailing_slash "$personal_path")

    echo -e "${BLUE}Enter WORK Git email${work_email:+ (default: $work_email)}:${NC}"
    read -r input_work_email
    work_email=${input_work_email:-$work_email}
    while ! is_valid_email "${work_email:-}"; do
        echo -e "${YELLOW}⚠ Invalid work email format. Use a valid email like name@example.com${NC}"
        echo -e "${BLUE}Enter WORK Git email:${NC}"
        read -r work_email
    done

    echo -e "${BLUE}Enter PERSONAL Git email${personal_email:+ (default: $personal_email)}:${NC}"
    read -r input_personal_email
    personal_email=${input_personal_email:-$personal_email}
    while ! is_valid_email "${personal_email:-}"; do
        echo -e "${YELLOW}⚠ Invalid personal email format. Use a valid email like name@example.com${NC}"
        echo -e "${BLUE}Enter PERSONAL Git email:${NC}"
        read -r personal_email
    done

    cat > "$HOME/.gitconfig-work" << EOF
[user]
    email = $work_email
EOF

    cat > "$HOME/.gitconfig-personal" << EOF
[user]
    email = $personal_email
EOF

    # Remove previous defaults if they exist to avoid stale includeIf rules.
    git config --global --unset-all "includeIf.gitdir:${HOME}/Development/Work/.path" >/dev/null 2>&1 || true
    git config --global --unset-all "includeIf.gitdir:${HOME}/Development/Personal/.path" >/dev/null 2>&1 || true

    git config --global --replace-all "includeIf.gitdir:${work_path}.path" "$HOME/.gitconfig-work"
    git config --global --replace-all "includeIf.gitdir:${personal_path}.path" "$HOME/.gitconfig-personal"

    echo -e "${GREEN}✓ Git email profiles configured${NC}"
    echo -e "  • Work: $work_path -> $HOME/.gitconfig-work"
    echo -e "  • Personal: $personal_path -> $HOME/.gitconfig-personal"
}

configure_dotfiles_git_scope() {
    local dotfiles_path="$1"
    local dotfiles_path_with_slash
    dotfiles_path_with_slash=$(ensure_trailing_slash "$dotfiles_path")

    # Dotfiles repo is treated as personal by default.
    git config --global --replace-all "includeIf.gitdir:${dotfiles_path_with_slash}.path" "$HOME/.gitconfig-personal"
    echo -e "${GREEN}✓ Dotfiles repository mapped to PERSONAL Git profile${NC}"
    echo -e "  • Dotfiles: $dotfiles_path_with_slash -> $HOME/.gitconfig-personal"
}

optional_github_auth_and_signing_setup() {
    local gpg_script="$DOTFILES_PATH/scripts/setup/gpg-github.sh"
    local run_gh_auth=""
    local setup_signing=""
    local signing_scope=""

    echo -e "${BLUE}4.4 Optional GitHub auth and commit-signing setup...${NC}"

    if ! command_exists gh; then
        echo -e "${YELLOW}⚠ GitHub CLI (gh) is not available yet. Skipping GitHub auth/GPG setup.${NC}"
        echo -e "${BLUE}  You can run later: gh auth login && ./scripts/setup/gpg-github.sh --all${NC}"
        return
    fi

    echo -e "${BLUE}Authenticate GitHub CLI now? (y/N)${NC}"
    read -r run_gh_auth
    if [[ "$run_gh_auth" =~ ^[Yy]$ ]]; then
        if gh auth status >/dev/null 2>&1; then
            echo -e "${GREEN}✓ GitHub CLI already authenticated${NC}"
        else
            if gh auth login; then
                echo -e "${GREEN}✓ GitHub CLI authentication complete${NC}"
            else
                echo -e "${YELLOW}⚠ GitHub authentication not completed. You can run 'gh auth login' later.${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠ Skipped GitHub CLI authentication${NC}"
    fi

    if [ ! -f "$gpg_script" ]; then
        echo -e "${YELLOW}⚠ GPG setup script not found at $gpg_script${NC}"
        return
    fi

    echo -e "${BLUE}Configure Git commit signing now?${NC}"
    echo -e "${BLUE}Choose scope: [all/work/personal/skip] (default: skip)${NC}"
    read -r setup_signing
    setup_signing=$(echo "${setup_signing:-skip}" | tr '[:upper:]' '[:lower:]')

    case "$setup_signing" in
        all|work|personal)
            signing_scope="--$setup_signing"
            if bash "$gpg_script" "$signing_scope"; then
                echo -e "${GREEN}✓ GPG signing setup completed for scope: $setup_signing${NC}"
            else
                echo -e "${YELLOW}⚠ GPG signing setup did not complete. You can rerun: ./scripts/setup/gpg-github.sh $signing_scope${NC}"
            fi
            ;;
        skip|"")
            echo -e "${YELLOW}⚠ Skipped GPG signing setup${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠ Invalid option '$setup_signing'. Skipping GPG signing setup.${NC}"
            echo -e "${BLUE}  You can run later: ./scripts/setup/gpg-github.sh --all${NC}"
            ;;
    esac
}

first_hosts_profile() {
    local hosts_file="$1"
    list_hosts_profiles "$hosts_file" | head -n1
}

safe_link_config_dir() {
    local dir_name="$1"
    local source_dir="$DOTFILES_PATH/$dir_name"
    local target_dir="$HOME/.config/$dir_name"
    local backup_dir="$HOME/.config-backups/dotfile-install-$BACKUP_TS"

    if [ ! -d "$source_dir" ]; then
        echo -e "${YELLOW}⚠ Directory $dir_name not found in dotfiles, creating minimal structure${NC}"
        mkdir -p "$source_dir"
    fi

    if [ -L "$target_dir" ]; then
        local current_link
        current_link="$(readlink "$target_dir")"
        if [ "$current_link" = "$source_dir" ]; then
            echo -e "${GREEN}✓ $dir_name already linked${NC}"
            return
        fi
    fi

    if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
        mkdir -p "$backup_dir"
        mv "$target_dir" "$backup_dir/$dir_name"
        echo -e "${YELLOW}⚠ Backed up existing ~/.config/$dir_name to $backup_dir/$dir_name${NC}"
    fi

    ln -sfn "$source_dir" "$target_dir"
    echo -e "${GREEN}✓ Linked $dir_name${NC}"
}

print_phase() {
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW} PHASE $1: $2${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
}

echo -e "${BLUE}🚀 Starting Bare Metal Mac Setup...${NC}"
echo -e "${BLUE}This script will install and configure everything from scratch${NC}"

# System Verification
if [[ "$OSTYPE" != "darwin"* ]]; then
    handle_error "This script is only for macOS"
fi

# ================================================================================================
# PHASE 1: BOOTSTRAP ESSENTIAL TOOLS (Only using built-in macOS tools)
# ================================================================================================
print_phase "1" "BOOTSTRAP ESSENTIAL TOOLS"

echo -e "${BLUE}Phase 1 installs the minimum tools needed for everything else:${NC}"
echo -e "  • Xcode Command Line Tools (for git, gcc, etc.)"
echo -e "  • Homebrew (package manager)"
echo -e "  • Essential CLI tools (git, gh, tree, stow)"
echo ""

# 1.1: Xcode Command Line Tools
echo -e "${BLUE}1.1 Installing Xcode Command Line Tools...${NC}"
if ! xcode-select -p &> /dev/null; then
    echo -e "${BLUE}Installing Xcode Command Line Tools (this may take a while)...${NC}"
    xcode-select --install
    echo -e "${BLUE}Please complete the installation prompt window${NC}"
    echo -e "${BLUE}Press RETURN when installation is complete...${NC}"
    read
    
    if ! xcode-select -p &> /dev/null; then
        handle_error "Xcode Command Line Tools installation failed"
    fi
    
    sudo xcodebuild -license accept
    echo -e "${GREEN}✓ Xcode Command Line Tools installed${NC}"
else
    echo -e "${GREEN}✓ Xcode Command Line Tools already installed${NC}"
fi

# 1.2: Homebrew Installation
echo -e "${BLUE}1.2 Installing Homebrew...${NC}"
if ! command_exists brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    echo -e "${GREEN}✓ Homebrew installed${NC}"
else
    echo -e "${GREEN}✓ Homebrew already installed${NC}"
fi

# 1.3: Essential CLI Tools
echo -e "${BLUE}1.3 Installing essential CLI tools...${NC}"
echo -e "${BLUE}Installing: git, tree, stow${NC}"

# Install essential tools that we'll need in later phases
brew install git tree stow

echo -e "${GREEN}✓ Essential tools installed:${NC}"
echo -e "  • git: $(git --version 2>/dev/null || echo 'not found')"
echo -e "  • tree: $(tree --version 2>/dev/null | head -1 || echo 'not found')"
echo -e "  • stow: $(stow --version 2>/dev/null | head -1 || echo 'not found')"

echo -e "${GREEN}✓ Phase 1 Complete: Bootstrap tools are ready!${NC}"

# ================================================================================================
# PHASE 2: USER CONFIGURATION & DOTFILES SETUP
# ================================================================================================
print_phase "2" "USER CONFIGURATION & DOTFILES SETUP"

echo -e "${BLUE}Phase 2 sets up user configuration and dotfiles:${NC}"
echo -e "  • User configuration setup"
echo -e "  • Git configuration"
echo -e "  • Dotfiles repository setup"
echo ""

# 2.1: Get user configuration first (before any git operations)
echo -e "${BLUE}2.1 Setting up user configuration...${NC}"

# Create directories
mkdir -p "$HOME/.config"

# Check for existing dotfiles in common locations
EXISTING_CONFIG=""
HOSTS_CONFIG_FILE=""
ACTIVE_PROFILE=""
CURRENT_HOSTNAME=$(normalize_hostname "$(scutil --get LocalHostName 2>/dev/null || hostname -s)")
for possible_dir in "dotfile" "dotfiles" "nix-config" "nix-darwin" ".dotfiles"; do
    CANDIDATE_REPO="$HOME/Documents/$possible_dir"
    if [ ! -d "$CANDIDATE_REPO" ]; then
        continue
    fi

    if [ -f "$CANDIDATE_REPO/hosts.nix" ]; then
        HOSTS_CONFIG_FILE="$CANDIDATE_REPO/hosts.nix"
        ACTIVE_PROFILE=$(find_hosts_profile_by_hostname "$HOSTS_CONFIG_FILE" "$CURRENT_HOSTNAME" || true)
        if [ -z "$ACTIVE_PROFILE" ]; then
            ACTIVE_PROFILE=$(first_hosts_profile "$HOSTS_CONFIG_FILE" || true)
        fi
        if [ -n "$ACTIVE_PROFILE" ]; then
            EXISTING_CONFIG="$CANDIDATE_REPO"
            break
        fi
    fi
done

# Check if we already have a dotfiles repo
if [ -n "$EXISTING_CONFIG" ]; then
    echo -e "${GREEN}✓ Found existing config in $EXISTING_CONFIG${NC}"
    cd "$EXISTING_CONFIG"
    if [ -z "$HOSTS_CONFIG_FILE" ] || [ -z "$ACTIVE_PROFILE" ]; then
        handle_error "hosts.nix not found or missing profiles in $EXISTING_CONFIG"
    fi
    echo -e "${GREEN}  Using hosts.nix profile: $ACTIVE_PROFILE${NC}"
    USERNAME=$(read_hosts_common_value "username" "$HOSTS_CONFIG_FILE")
    FULLNAME=$(read_hosts_common_value "fullName" "$HOSTS_CONFIG_FILE")
    GITHUB_USERNAME=$(read_hosts_common_value "githubUsername" "$HOSTS_CONFIG_FILE")
    SIGNING_KEY=$(read_hosts_common_value "signingKey" "$HOSTS_CONFIG_FILE")

    HOSTNAME=$(read_hosts_profile_value "$ACTIVE_PROFILE" "hostname" "$HOSTS_CONFIG_FILE")
    PROFILE=$(read_hosts_profile_value "$ACTIVE_PROFILE" "profile" "$HOSTS_CONFIG_FILE")
    PROFILE=${PROFILE:-$ACTIVE_PROFILE}

    SIGNING_KEY=${SIGNING_KEY:-""}
    PROFILE=${PROFILE:-personal}
    PROFILE=$(echo "$PROFILE" | tr '[:upper:]' '[:lower:]')
    if ! is_valid_profile "$PROFILE"; then
        PROFILE="personal"
    fi
    
    echo -e "${GREEN}Configuration loaded:${NC}"
    echo -e "  Username: $USERNAME"
    echo -e "  GitHub: $GITHUB_USERNAME"
    echo -e "  Profile: $PROFILE"
    
    # Set the dotfiles directory for later use
    DOTFILES_PATH="$EXISTING_CONFIG"
    dotfiles_dir=$(basename "$EXISTING_CONFIG")
    
    # Skip the repository cloning section since we already have it
    SKIP_CLONE=true
else
    echo -e "${BLUE}Setting up new user configuration...${NC}"
    echo -e "${BLUE}Enter your macOS username ($(whoami)):${NC}"
    read -r USERNAME
    USERNAME=${USERNAME:-$(whoami)}
    
    echo -e "${BLUE}Enter your full name:${NC}"
    read -r FULLNAME
    
    echo -e "${BLUE}Enter your GitHub username (default: $USERNAME):${NC}"
    read -r GITHUB_USERNAME
    GITHUB_USERNAME=${GITHUB_USERNAME:-$USERNAME}

    DEFAULT_HOSTNAME=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
    DEFAULT_HOSTNAME=$(normalize_hostname "$DEFAULT_HOSTNAME")
    DEFAULT_HOSTNAME=${DEFAULT_HOSTNAME:-"macbook"}

    echo -e "${BLUE}Enter hostname for this machine (default: $DEFAULT_HOSTNAME):${NC}"
    read -r HOSTNAME
    HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}
    HOSTNAME=$(normalize_hostname "$HOSTNAME")

    while ! is_valid_hostname "$HOSTNAME"; do
        echo -e "${YELLOW}⚠ Invalid hostname format: $HOSTNAME${NC}"
        echo -e "${BLUE}Use only letters, numbers, and hyphens (e.g., macbook-pro).${NC}"
        echo -e "${BLUE}Enter hostname:${NC}"
        read -r HOSTNAME
        HOSTNAME=$(normalize_hostname "$HOSTNAME")
    done

    echo -e "${BLUE}Using hostname: $HOSTNAME${NC}"

    DEFAULT_PROFILE="personal"
    echo -e "${BLUE}Enter profile for this machine [personal/work] (default: $DEFAULT_PROFILE):${NC}"
    read -r PROFILE
    PROFILE=${PROFILE:-$DEFAULT_PROFILE}
    PROFILE=$(echo "$PROFILE" | tr '[:upper:]' '[:lower:]')

    while ! is_valid_profile "$PROFILE"; do
        echo -e "${YELLOW}⚠ Invalid profile: $PROFILE${NC}"
        echo -e "${BLUE}Allowed values: personal or work${NC}"
        echo -e "${BLUE}Enter profile:${NC}"
        read -r PROFILE
        PROFILE=$(echo "$PROFILE" | tr '[:upper:]' '[:lower:]')
    done

    SIGNING_KEY=""
    
    SKIP_CLONE=false
fi

# 2.2: Git Configuration
echo -e "${BLUE}2.2 Setting up Git configuration...${NC}"

# Configure git
git config --global user.name "$FULLNAME"
configure_git_email_profiles
echo -e "${GREEN}✓ Git configured (name + per-scope email profiles)${NC}"


# 2.3: Setup Dotfiles Repository
echo -e "${BLUE}2.3 Setting up dotfiles repository...${NC}"

if [ "$SKIP_CLONE" = true ]; then
    echo -e "${GREEN}✓ Using existing dotfiles repository at $DOTFILES_PATH${NC}"
else
    # Ask for directory name
    echo -e "${BLUE}What directory name do you want for your dotfiles? (default: dotfile)${NC}"
    read -r dotfiles_dir
    dotfiles_dir=${dotfiles_dir:-dotfile}

    # Validate directory name (no spaces, special characters, etc.)
    while [[ ! "$dotfiles_dir" =~ ^[a-zA-Z0-9_-]+$ ]]; do
        echo -e "${YELLOW}⚠ Directory name should only contain letters, numbers, hyphens, and underscores${NC}"
        echo -e "${BLUE}Please enter a valid directory name:${NC}"
        read -r dotfiles_dir
        dotfiles_dir=${dotfiles_dir:-dotfile}
    done

    DOTFILES_PATH="$HOME/Documents/$dotfiles_dir"

    if [ ! -d "$DOTFILES_PATH/.git" ]; then
        echo -e "${BLUE}Enter your dotfiles repository URL:${NC}"
        read -r dotfiles_url
        
        if [[ -n "$dotfiles_url" ]]; then
            git clone "$dotfiles_url" "$DOTFILES_PATH"
            echo -e "${GREEN}✓ Dotfiles repository cloned to ~/Documents/$dotfiles_dir${NC}"
        else
            echo -e "${GREEN}✓ Using existing dotfiles directory${NC}"
        fi
    else
        echo -e "${GREEN}✓ Dotfiles repository already exists at ~/Documents/$dotfiles_dir${NC}"
        echo -e "${BLUE}Pull latest changes? (y/n)${NC}"
        read -r pull_changes
        if [[ $pull_changes =~ ^[Yy]$ ]]; then
            cd "$DOTFILES_PATH"
            git pull
            echo -e "${GREEN}✓ Repository updated${NC}"
        fi
    fi
fi

cd "$DOTFILES_PATH"
configure_dotfiles_git_scope "$DOTFILES_PATH"

# 2.4: Create/Update hosts.nix
echo -e "${BLUE}2.4 Creating host configuration file...${NC}"

HOSTS_FILE="hosts.nix"
if [ "$PROFILE" = "work" ]; then
    OTHER_PROFILE="personal"
else
    OTHER_PROFILE="work"
fi

OTHER_HOSTNAME=""
if [ -f "$HOSTS_FILE" ]; then
    OTHER_HOSTNAME=$(read_hosts_profile_value "$OTHER_PROFILE" "hostname" "$HOSTS_FILE")
fi
OTHER_HOSTNAME=${OTHER_HOSTNAME:-"your-${OTHER_PROFILE}-hostname"}

if [ "$PROFILE" = "work" ]; then
    WORK_HOSTNAME="$HOSTNAME"
    PERSONAL_HOSTNAME="$OTHER_HOSTNAME"
else
    PERSONAL_HOSTNAME="$HOSTNAME"
    WORK_HOSTNAME="$OTHER_HOSTNAME"
fi

cat > "$HOSTS_FILE" << EOF
{
  common = {
    username = "$USERNAME";
    fullName = "$FULLNAME";
    githubUsername = "$GITHUB_USERNAME";
    signingKey = "$SIGNING_KEY"; # GPG key ID for signing commits
  };

  hosts = {
    work = {
      hostname = "$WORK_HOSTNAME";
      profile = "work";
    };

    personal = {
      hostname = "$PERSONAL_HOSTNAME";
      profile = "personal";
    };
  };
}
EOF

echo -e "${GREEN}✓ Configuration saved to $HOSTS_FILE${NC}"
echo -e "${GREEN}✓ Phase 2 Complete: User configuration and dotfiles ready!${NC}"

# ================================================================================================
# PHASE 3: NIX INSTALLATION & SYSTEM SETUP
# ================================================================================================
print_phase "3" "NIX INSTALLATION & SYSTEM SETUP"

echo -e "${BLUE}Phase 3 installs Nix and sets up the declarative system:${NC}"
echo -e "  • Nix package manager installation"
echo -e "  • nix-darwin system configuration"
echo -e "  • Configuration symlinks"
echo ""

# 3.1: Nix Installation
echo -e "${BLUE}3.1 Installing Nix package manager...${NC}"

if ! command_exists nix; then
    # Check if /nix exists - if so, try to source it
    if [ -d "/nix" ]; then
        echo -e "${YELLOW}⚠ Nix command not found, but /nix directory exists.${NC}"
        echo -e "${BLUE}Attempting to source Nix profile...${NC}"
        
        if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
            . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
            . "$HOME/.nix-profile/etc/profile.d/nix.sh"
        fi
    fi
fi

if ! command_exists nix; then
    if [ -d "/nix" ]; then
        echo -e "${YELLOW}⚠ /nix directory exists but could not activate nix command.${NC}"
        echo -e "${YELLOW}Assuming Nix is installed but not in PATH. Skipping installation to avoid conflicts.${NC}"
        echo -e "${GREEN}✓ Nix assumed installed (found /nix)${NC}"
    else
        echo -e "${BLUE}Installing Nix (this will modify shell configurations)...${NC}"
        
        # Backup shell configs
        for file in ~/.zshrc ~/.bashrc; do
            if [ -f "$file" ]; then
                cp "$file" "$file.backup-before-nix"
            fi
        done
        
        sh <(curl -L https://nixos.org/nix/install)
        
        echo -e "${GREEN}✓ Nix installed${NC}"
        echo -e "${BLUE}Please restart your terminal and run this script again to continue${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}✓ Nix already installed${NC}"
fi

# 3.2: Directory Structure & Symlinks
echo -e "${BLUE}3.2 Setting up configuration directories...${NC}"

# Prepare backup timestamp for existing config directories.
BACKUP_TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "$HOME/.config"

# Reorganize dotfiles if needed
if [ -d ".config" ]; then
    echo -e "${BLUE}Reorganizing configuration structure...${NC}"
    mv .config/darwin ./ 2>/dev/null || true
    mv .config/home-manager ./ 2>/dev/null || true  
    mv .config/nix ./ 2>/dev/null || true
    rmdir .config 2>/dev/null || true
fi

# Create symlinks
echo -e "${BLUE}Creating configuration symlinks...${NC}"
for dir in nix darwin home-manager; do
    safe_link_config_dir "$dir"
done

# Show structure
echo -e "${BLUE}Current configuration structure:${NC}"
tree -L 2 || ls -la

echo -e "${GREEN}✓ Configuration directories ready${NC}"

# 3.3: nix-darwin Installation
echo -e "${BLUE}3.3 Installing nix-darwin...${NC}"

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Verify flake.nix exists
if [ ! -f "flake.nix" ]; then
    handle_error "flake.nix not found in repository. Please ensure your dotfiles repo contains a valid flake.nix"
fi

# Install nix-darwin
if ! command_exists darwin-rebuild; then
    export NIX_CONFIG="experimental-features = nix-command flakes"
    echo -e "${BLUE}Running nix-darwin installation (this may take several minutes)...${NC}"

    # Handle /etc/bashrc conflict
    if [ -f "/etc/bashrc" ]; then
        echo -e "${YELLOW}⚠ Found existing /etc/bashrc. Backing up to /etc/bashrc.before-nix-darwin...${NC}"
        sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
    fi

    # Ensure /etc/synthetic.conf exists
    if [ ! -f "/etc/synthetic.conf" ]; then
        echo -e "${BLUE}Creating empty /etc/synthetic.conf...${NC}"
        sudo touch /etc/synthetic.conf
    fi

    if sudo nix run --extra-experimental-features 'nix-command flakes' nix-darwin -- switch --flake ".#$HOSTNAME"; then
        echo -e "${GREEN}✓ nix-darwin installed successfully${NC}"
    else
        handle_error "nix-darwin installation failed"
    fi
else
    echo -e "${GREEN}✓ nix-darwin already installed${NC}"
fi

echo -e "${GREEN}✓ Phase 3 Complete: Nix system is configured!${NC}"

# ================================================================================================
# PHASE 4: FINAL CONFIGURATION & CLEANUP
# ================================================================================================
print_phase "4" "FINAL CONFIGURATION & CLEANUP"

echo -e "${BLUE}Phase 4 completes the setup:${NC}"
echo -e "  • Shell configuration"
echo -e "  • System service startup"
echo -e "  • Final verification"
echo ""

# 4.1: Shell Configuration
echo -e "${BLUE}4.1 Setting up shell configuration...${NC}"

# Install/configure Zsh
if ! command_exists zsh; then
    echo -e "${BLUE}Installing Zsh...${NC}"
    brew install zsh
fi

# Create shell config symlinks if they exist
if [ -f "nix/zshrc" ]; then
    ln -sf "$DOTFILES_PATH/nix/zshrc" "$HOME/.zshrc"
    echo -e "${GREEN}✓ Linked .zshrc${NC}"
fi

if [ -f "nix/dynamic-config.zsh" ]; then
    ln -sf "$DOTFILES_PATH/nix/dynamic-config.zsh" "$HOME/.dynamic-config.zsh"
    echo -e "${GREEN}✓ Linked dynamic-config.zsh${NC}"
fi

# 4.2: System Services
echo -e "${BLUE}4.2 Starting system services...${NC}"

if sudo launchctl list | grep -q "org.nixos.nix-daemon"; then
    echo -e "${BLUE}Restarting Nix daemon...${NC}"
    sudo launchctl kickstart -k system/org.nixos.nix-daemon || true
    echo -e "${GREEN}✓ Nix daemon restarted${NC}"
else
    echo -e "${YELLOW}⚠ Nix daemon not running, attempting to load...${NC}"
    if [ -f "/Library/LaunchDaemons/org.nixos.nix-daemon.plist" ]; then
        sudo launchctl load -w /Library/LaunchDaemons/org.nixos.nix-daemon.plist || true
        echo -e "${GREEN}✓ Nix daemon loaded${NC}"
    else
        echo -e "${YELLOW}⚠ Nix daemon plist not found, skipping service start${NC}"
    fi
fi

# 4.3: Final Verification & Information
echo -e "${BLUE}4.3 Final verification...${NC}"

# Test nix
if nix-shell -p hello --run "hello" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Nix is working${NC}"
else
    echo -e "${YELLOW}⚠ Nix test failed, but installation may still be successful${NC}"
fi

# Test git configuration
if git config --global user.name >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Git configuration working${NC}"
else
    echo -e "${YELLOW}⚠ Git configuration may need adjustment${NC}"
fi

optional_github_auth_and_signing_setup

echo -e "${GREEN}✓ Phase 4 Complete: Setup finished!${NC}"

# ================================================================================================
# SETUP COMPLETE
# ================================================================================================

echo ""
echo -e "${GREEN}🎉 Bare Metal Mac Setup Complete!${NC}"
echo ""
echo -e "${BLUE}What was installed:${NC}"
echo -e "  ✓ Xcode Command Line Tools"
echo -e "  ✓ Homebrew package manager"
echo -e "  ✓ Essential CLI tools (git, tree, stow)"
echo -e "  ✓ Git configuration"
echo -e "  ✓ Nix package manager"
echo -e "  ✓ nix-darwin system configuration"
echo -e "  ✓ Configuration symlinks"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. ${YELLOW}Restart your terminal${NC} to load all changes"
echo -e "  2. Run: ${YELLOW}cd $DOTFILES_PATH && sudo darwin-rebuild switch --flake .#$HOSTNAME${NC}"
echo -e "  3. Customize your configuration in ${YELLOW}$DOTFILES_PATH/${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  • Update system: ${YELLOW}sudo darwin-rebuild switch --flake .#$HOSTNAME${NC}"
echo -e "  • Update packages: ${YELLOW}cd $DOTFILES_PATH && nix flake update${NC}"
echo -e "  • Check system info: ${YELLOW}nix-shell -p nix-info --run 'nix-info -m'${NC}"
echo ""
echo -e "${GREEN}Enjoy your declaratively configured Mac! 🚀${NC}"
