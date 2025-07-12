# home-manager/modules/session-management.nix
#
# Advanced Session Management Configuration
#
# Purpose:
# - Demonstrates Home Manager's session management capabilities
# - Provides advanced activation scripts and system integration
# - Manages session-specific configurations and startup procedures
#
# Features:
# - Custom activation scripts for system setup
# - Session-specific environment management
# - Automatic system maintenance tasks
# - Integration with system services
#
# Integration:
# - Works with Home Manager's activation system
# - Integrates with shell environments
# - Provides system-wide session enhancements
#
# Note:
# - Activation scripts run during Home Manager switches
# - Some features require system permissions
# - macOS-specific adaptations included
{config, pkgs, lib, ...}: {
  # Advanced session management using Home Manager's activation system
  
  # Custom activation scripts for system setup
  home.activation = {
    # Create development directory structure
    createDevelopmentDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create development directories
      mkdir -p "$HOME/Documents/Projects"
      mkdir -p "$HOME/Documents/Work"
      mkdir -p "$HOME/Documents/Learning"
      mkdir -p "$HOME/Documents/Experiments"
      mkdir -p "$HOME/Documents/Templates"
      
      # Create .local directories for XDG compliance
      mkdir -p "$HOME/.local/bin"
      mkdir -p "$HOME/.local/share"
      mkdir -p "$HOME/.local/state"
      mkdir -p "$HOME/.cache"
      
      # Create development-specific directories
      mkdir -p "$HOME/.local/share/virtualenvs"
      mkdir -p "$HOME/.local/share/docker"
      mkdir -p "$HOME/.local/share/kubernetes"
      
      echo "Development directory structure created"
    '';
    
    # Setup SSH configuration
    setupSSHConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Ensure SSH directory exists with correct permissions
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      
      # Create SSH key if it doesn't exist
      if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        echo "Generating SSH key..."
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N "" -C "$(whoami)@$(hostname)"
        echo "SSH key generated: $HOME/.ssh/id_rsa"
      fi
      
      # Set correct permissions
      chmod 600 "$HOME/.ssh/id_rsa" 2>/dev/null || true
      chmod 644 "$HOME/.ssh/id_rsa.pub" 2>/dev/null || true
      chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
      chmod 644 "$HOME/.ssh/known_hosts" 2>/dev/null || true
      
      echo "SSH configuration setup complete"
    '';
    
    # Setup GPG directories and permissions
    setupGPGDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create GPG directory with correct permissions
      mkdir -p "$HOME/.gnupg"
      chmod 700 "$HOME/.gnupg"
      
      # Set correct permissions for GPG files
      chmod 600 "$HOME/.gnupg/gpg.conf" 2>/dev/null || true
      chmod 600 "$HOME/.gnupg/gpg-agent.conf" 2>/dev/null || true
      
      echo "GPG directories setup complete"
    '';
    
    # Setup development tools and environments
    setupDevelopmentTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create symlinks for development tools
      mkdir -p "$HOME/.local/bin"
      
      # Create development utility scripts
      cat > "$HOME/.local/bin/dev-status" << 'EOF'
      #!/bin/bash
      # Development environment status checker
      
      echo "=== Development Environment Status ==="
      echo
      
      # Git status
      echo "Git Configuration:"
      git config --global user.name 2>/dev/null || echo "  Name: Not configured"
      git config --global user.email 2>/dev/null || echo "  Email: Not configured"
      git config --global commit.gpgsign 2>/dev/null || echo "  GPG Signing: Not configured"
      echo
      
      # SSH status
      echo "SSH Configuration:"
      if [ -f "$HOME/.ssh/id_rsa" ]; then
        echo "  SSH Key: Present"
      else
        echo "  SSH Key: Not found"
      fi
      echo
      
      # GPG status
      echo "GPG Configuration:"
      if command -v gpg &> /dev/null; then
        gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c "sec" || echo "  GPG Keys: 0"
      else
        echo "  GPG: Not installed"
      fi
      echo
      
      # Development directories
      echo "Development Directories:"
      for dir in "Projects" "Work" "Learning" "Experiments"; do
        if [ -d "$HOME/Documents/$dir" ]; then
          count=$(ls -1 "$HOME/Documents/$dir" 2>/dev/null | wc -l)
          echo "  $dir: $count items"
        else
          echo "  $dir: Not found"
        fi
      done
      echo
      
      # Environment variables
      echo "Environment Variables:"
      echo "  EDITOR: ${EDITOR:-Not set}"
      echo "  BROWSER: ${BROWSER:-Not set}"
      echo "  PROJECTS_DIR: ${PROJECTS_DIR:-Not set}"
      echo "  WORK_DIR: ${WORK_DIR:-Not set}"
      echo
      
      # Tool availability
      echo "Development Tools:"
      tools=("git" "nvim" "tmux" "docker" "python3" "node" "npm" "yarn" "go" "rust" "java" "scala")
      for tool in "''${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
          version=$(command "$tool" --version 2>/dev/null | head -1 | cut -d' ' -f3 || echo "unknown")
          echo "  $tool: Available ($version)"
        else
          echo "  $tool: Not available"
        fi
      done
      EOF
      
      chmod +x "$HOME/.local/bin/dev-status"
      
      # Create project initialization script
      cat > "$HOME/.local/bin/new-project" << 'EOF'
      #!/bin/bash
      # Project initialization script
      
      if [ -z "$1" ]; then
        echo "Usage: new-project <project-name> [type]"
        echo "Types: python, node, go, rust, generic"
        exit 1
      fi
      
      PROJECT_NAME="$1"
      PROJECT_TYPE="''${2:-generic}"
      PROJECT_DIR="$HOME/Documents/Projects/$PROJECT_NAME"
      
      if [ -d "$PROJECT_DIR" ]; then
        echo "Project $PROJECT_NAME already exists"
        exit 1
      fi
      
      mkdir -p "$PROJECT_DIR"
      cd "$PROJECT_DIR"
      
      # Initialize git repository
      git init
      
      # Create README
      cat > README.md << EOL
      # $PROJECT_NAME
      
      ## Description
      
      [Add project description here]
      
      ## Setup
      
      [Add setup instructions here]
      
      ## Usage
      
      [Add usage instructions here]
      
      ## Development
      
      [Add development instructions here]
      
      ## License
      
      [Add license information here]
      EOL
      
      # Create project-specific files based on type
      case "$PROJECT_TYPE" in
        python)
          init-python "$PROJECT_NAME"
          ;;
        node)
          init-node "$PROJECT_NAME"
          ;;
        go)
          go mod init "$PROJECT_NAME"
          ;;
        rust)
          cargo init --name "$PROJECT_NAME"
          ;;
        *)
          echo "Generic project created"
          ;;
      esac
      
      # Create initial commit
      git add .
      git commit -m "Initial commit"
      
      echo "Project $PROJECT_NAME created in $PROJECT_DIR"
      echo "Type: $PROJECT_TYPE"
      EOF
      
      chmod +x "$HOME/.local/bin/new-project"
      
      # Create system maintenance script
      cat > "$HOME/.local/bin/system-maintenance" << 'EOF'
      #!/bin/bash
      # System maintenance script
      
      echo "=== System Maintenance ==="
      echo
      
      # Clean up development environments
      echo "Cleaning development environments..."
      
      # Clean Docker (if available)
      if command -v docker &> /dev/null; then
        echo "  Cleaning Docker..."
        docker system prune -f 2>/dev/null || true
      fi
      
      # Clean npm cache (if available)
      if command -v npm &> /dev/null; then
        echo "  Cleaning npm cache..."
        npm cache clean --force 2>/dev/null || true
      fi
      
      # Clean yarn cache (if available)
      if command -v yarn &> /dev/null; then
        echo "  Cleaning yarn cache..."
        yarn cache clean 2>/dev/null || true
      fi
      
      # Clean pip cache (if available)
      if command -v pip &> /dev/null; then
        echo "  Cleaning pip cache..."
        pip cache purge 2>/dev/null || true
      fi
      
      # Clean cargo cache (if available)
      if command -v cargo &> /dev/null; then
        echo "  Cleaning cargo cache..."
        cargo clean 2>/dev/null || true
      fi
      
      # Clean go cache (if available)
      if command -v go &> /dev/null; then
        echo "  Cleaning go cache..."
        go clean -cache 2>/dev/null || true
        go clean -modcache 2>/dev/null || true
      fi
      
      # Clean temporary files
      echo "  Cleaning temporary files..."
      rm -rf /tmp/* 2>/dev/null || true
      rm -rf "$HOME/.cache/*" 2>/dev/null || true
      
      # Clean log files
      echo "  Cleaning log files..."
      find "$HOME/.local/share" -name "*.log" -type f -delete 2>/dev/null || true
      
      # Update development tools
      echo "Updating development tools..."
      
      # Update Homebrew (if available)
      if command -v brew &> /dev/null; then
        echo "  Updating Homebrew..."
        brew update && brew upgrade
      fi
      
      # Update npm packages (if available)
      if command -v npm &> /dev/null; then
        echo "  Updating global npm packages..."
        npm update -g 2>/dev/null || true
      fi
      
      # Update pip packages (if available)
      if command -v pip &> /dev/null; then
        echo "  Updating pip..."
        pip install --upgrade pip 2>/dev/null || true
      fi
      
      # Update rustup (if available)
      if command -v rustup &> /dev/null; then
        echo "  Updating Rust..."
        rustup update 2>/dev/null || true
      fi
      
      echo "System maintenance complete!"
      EOF
      
      chmod +x "$HOME/.local/bin/system-maintenance"
      
      echo "Development tools setup complete"
    '';
    
    # Setup shell integrations
    setupShellIntegrations = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create shell integration scripts
      mkdir -p "$HOME/.local/share/shell"
      
      # Create productivity shortcuts
      cat > "$HOME/.local/share/shell/productivity.sh" << 'EOF'
      #!/bin/bash
      # Productivity shortcuts and functions
      
      # Quick note taking
      note() {
        local note_file="$HOME/Documents/notes.md"
        if [ -z "$1" ]; then
          if [ -f "$note_file" ]; then
            cat "$note_file"
          else
            echo "No notes found. Use 'note <text>' to create a note."
          fi
        else
          echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$note_file"
          echo "Note added: $*"
        fi
      }
      
      # Quick bookmark management
      bookmark() {
        local bookmark_file="$HOME/.local/share/bookmarks.txt"
        if [ -z "$1" ]; then
          if [ -f "$bookmark_file" ]; then
            cat -n "$bookmark_file"
          else
            echo "No bookmarks found. Use 'bookmark <url> [description]' to add one."
          fi
        else
          local url="$1"
          local desc="''${2:-$url}"
          echo "$url - $desc" >> "$bookmark_file"
          echo "Bookmark added: $desc"
        fi
      }
      
      # Quick task management
      task() {
        local task_file="$HOME/Documents/tasks.md"
        case "$1" in
          add)
            if [ -z "$2" ]; then
              echo "Usage: task add <description>"
              return 1
            fi
            echo "- [ ] $2" >> "$task_file"
            echo "Task added: $2"
            ;;
          done)
            if [ -z "$2" ]; then
              echo "Usage: task done <task-number>"
              return 1
            fi
            sed -i "$2s/- \[ \]/- [x]/" "$task_file" 2>/dev/null || echo "Task not found"
            ;;
          list|"")
            if [ -f "$task_file" ]; then
              cat -n "$task_file"
            else
              echo "No tasks found. Use 'task add <description>' to create one."
            fi
            ;;
          *)
            echo "Usage: task [add|done|list] [args...]"
            ;;
        esac
      }
      
      # Export functions
      export -f note bookmark task
      EOF
      
      echo "Shell integrations setup complete"
    '';
    
    # Report completion
    reportActivationComplete = lib.hm.dag.entryAfter ["createDevelopmentDirs" "setupSSHConfig" "setupGPGDirs" "setupDevelopmentTools" "setupShellIntegrations"] ''
      echo "=== Home Manager Activation Complete ==="
      echo "✅ Development directories created"
      echo "✅ SSH configuration setup"
      echo "✅ GPG directories configured"
      echo "✅ Development tools installed"
      echo "✅ Shell integrations configured"
      echo
      echo "Available commands:"
      echo "  dev-status        - Check development environment status"
      echo "  new-project       - Create new project"
      echo "  system-maintenance - Run system maintenance tasks"
      echo "  note              - Quick note taking"
      echo "  bookmark          - Bookmark management"
      echo "  task              - Task management"
      echo
      echo "Run 'dev-status' to see your development environment status."
    '';
  };

  # Session-specific environment variables
  home.sessionVariables = {
    # Add local bin to PATH
    PATH = "$HOME/.local/bin:$PATH";
    
    # Session management
    SESSION_MANAGER = "home-manager";
    
    # Development environment indicators
    DEV_ENV_INITIALIZED = "true";
    
    # Productivity settings
    NOTES_FILE = "$HOME/Documents/notes.md";
    TASKS_FILE = "$HOME/Documents/tasks.md";
    BOOKMARKS_FILE = "$HOME/.local/share/bookmarks.txt";
    
    # Tool preferences
    MANPAGER = "less -X";
    MANWIDTH = "80";
    
    # Session timeout settings
    TMOUT = "3600"; # 1 hour
    
    # Development workflow settings
    AUTO_PUSH = "false";
    AUTO_COMMIT = "false";
    
    # System maintenance
    MAINTENANCE_FREQUENCY = "weekly";
    
    # Performance settings
    HISTCONTROL = "ignoreboth:erasedups";
    HISTIGNORE = "ls:cd:cd -:pwd:exit:date:* --help";
    
    # Security settings
    LESSHISTFILE = "/dev/null";
    MYSQL_HISTFILE = "/dev/null";
    
    # Locale settings
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
    
    # Terminal settings
    TERM_PROGRAM = "alacritty";
    COLORTERM = "truecolor";
  };

  # Session-specific file configurations
  home.file = {
    # Productivity configuration
    ".local/share/productivity.conf".text = ''
      # Productivity configuration
      
      # Note taking settings
      NOTE_FORMAT=markdown
      NOTE_TIMESTAMP=true
      NOTE_EDITOR=nvim
      
      # Task management settings
      TASK_FORMAT=markdown
      TASK_NUMBERING=true
      TASK_PRIORITY=false
      
      # Bookmark settings
      BOOKMARK_FORMAT=text
      BOOKMARK_CATEGORIES=false
      
      # Development workflow
      AUTO_GIT_STATUS=true
      AUTO_PROJECT_DETECTION=true
      AUTO_ENVIRONMENT_ACTIVATION=true
      
      # System maintenance
      MAINTENANCE_AUTO_CLEAN=true
      MAINTENANCE_AUTO_UPDATE=false
      MAINTENANCE_NOTIFICATIONS=true
    '';
    
    # Session startup script
    ".local/bin/session-startup".text = ''
      #!/bin/bash
      # Session startup script
      
      # Source productivity functions
      source "$HOME/.local/share/shell/productivity.sh"
      
      # Check for system updates (if enabled)
      if [ "$MAINTENANCE_AUTO_UPDATE" = "true" ]; then
        system-maintenance --quiet
      fi
      
      # Display development environment status
      if [ "$DEV_ENV_INITIALIZED" = "true" ]; then
        echo "Development environment ready!"
        echo "Run 'dev-status' for details."
      fi
      
      # Auto-activate project environment if in project directory
      if [ "$AUTO_ENVIRONMENT_ACTIVATION" = "true" ]; then
        if [ -f ".envrc" ]; then
          direnv allow
        elif [ -f ".venv/bin/activate" ]; then
          source .venv/bin/activate
        elif [ -f "package.json" ]; then
          echo "Node.js project detected"
        fi
      fi
    '';
    
    # Session cleanup script
    ".local/bin/session-cleanup".text = ''
      #!/bin/bash
      # Session cleanup script
      
      # Clean temporary files
      rm -rf /tmp/home-manager-* 2>/dev/null || true
      
      # Clean cache files
      find "$HOME/.cache" -name "*.tmp" -delete 2>/dev/null || true
      
      # Clean log files older than 7 days
      find "$HOME/.local/share" -name "*.log" -mtime +7 -delete 2>/dev/null || true
      
      # Save session state
      echo "$(date): Session ended" >> "$HOME/.local/share/session.log"
      
      echo "Session cleanup complete"
    '';
  };

  # Make scripts executable
  home.activation.makeScriptsExecutable = lib.hm.dag.entryAfter ["writeBoundary"] ''
    chmod +x "$HOME/.local/bin/session-startup" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/session-cleanup" 2>/dev/null || true
  '';

  # Integration with shell configuration
  programs.zsh = {
    initExtra = ''
      # Session management integration
      
      # Source productivity functions
      if [ -f "$HOME/.local/share/shell/productivity.sh" ]; then
        source "$HOME/.local/share/shell/productivity.sh"
      fi
      
      # Auto-run session startup on new shells
      if [ -f "$HOME/.local/bin/session-startup" ]; then
        "$HOME/.local/bin/session-startup"
      fi
      
      # Session cleanup on exit
      trap 'if [ -f "$HOME/.local/bin/session-cleanup" ]; then "$HOME/.local/bin/session-cleanup"; fi' EXIT
    '';
  };
} 