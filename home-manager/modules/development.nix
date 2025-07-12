# home-manager/modules/development.nix
#
# Development Environment Configuration
#
# Purpose:
# - Provides comprehensive development environment setup
# - Configures language-specific tools and environments
# - Manages development-related configurations
#
# Features:
# - Language-specific configurations (Python, Node.js, Go, Rust, etc.)
# - Editor configurations and integrations
# - Development tool configurations
# - Build system configurations
#
# Integration:
# - Works with existing shell configuration
# - Integrates with version managers
# - Supports multiple development workflows
#
# Note:
# - Language tools may be installed via Homebrew
# - This focuses on configuration management
{config, pkgs, ...}: {
  # Development environment configurations
  programs = {
    # Advanced Git configuration for development
    git = {
      extraConfig = {
        # Advanced Git settings for development
        diff = {
          tool = "vimdiff";
          algorithm = "patience";
          colorMoved = "default";
        };
        merge = {
          tool = "vimdiff";
          conflictstyle = "diff3";
        };
        rebase = {
          autoStash = true;
          autoSquash = true;
        };
        rerere = {
          enabled = true;
        };
        branch = {
          autosetupmerge = "always";
          autosetuprebase = "always";
        };
        submodule = {
          recurse = true;
        };
        # GitHub-specific settings
        github = {
          user = "$(gh api user --jq .login)";
        };
        # Performance improvements
        core = {
          preloadindex = true;
          fscache = true;
        };
        gc = {
          auto = 256;
        };
        # Security settings
        transfer = {
          fsckobjects = true;
        };
        fetch = {
          fsckobjects = true;
        };
        receive = {
          fsckObjects = true;
        };
      };
    };

    # Enhanced Direnv configuration
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        # Global direnv configuration
        global = {
          hide_env_diff = true;
          strict_env = true;
          disable_stdin = true;
          warn_timeout = "30s";
        };
        # Whitelist for trusted directories
        whitelist = {
          prefix = [
            "${config.home.homeDirectory}/Documents"
            "${config.home.homeDirectory}/Projects"
            "${config.home.homeDirectory}/Work"
          ];
        };
      };
    };

    # Zsh development enhancements
    zsh = {
      initExtra = ''
        # Development environment functions
        
        # Quick project navigation
        function dev() {
          local project_dir="$HOME/Documents/Projects"
          if [ -d "$project_dir" ]; then
            cd "$project_dir"
            if command -v eza &> /dev/null; then
              eza --tree --level=2 --icons
            else
              ls -la
            fi
          fi
        }
        
        # Quick work navigation
        function work() {
          local work_dir="$HOME/Documents/Work"
          if [ -d "$work_dir" ]; then
            cd "$work_dir"
            if command -v eza &> /dev/null; then
              eza --tree --level=2 --icons
            else
              ls -la
            fi
          fi
        }
        
        # Git worktree helper
        function git-worktree-add() {
          if [ -z "$1" ]; then
            echo "Usage: git-worktree-add <branch-name>"
            return 1
          fi
          
          local branch_name="$1"
          local worktree_path="../$(basename $(pwd))-$branch_name"
          
          git worktree add "$worktree_path" "$branch_name"
          cd "$worktree_path"
        }
        
        # Docker development helpers
        function docker-dev-clean() {
          echo "Cleaning Docker development environment..."
          docker container prune -f
          docker image prune -f
          docker volume prune -f
          docker network prune -f
          echo "Docker cleanup complete!"
        }
        
        # Python development helpers
        function py-venv() {
          if [ -d ".venv" ]; then
            source .venv/bin/activate
            echo "Activated Python virtual environment"
          else
            echo "No .venv directory found"
          fi
        }
        
        function py-requirements() {
          if [ -f "requirements.txt" ]; then
            pip install -r requirements.txt
          elif [ -f "pyproject.toml" ]; then
            pip install -e .
          else
            echo "No requirements.txt or pyproject.toml found"
          fi
        }
        
        # Node.js development helpers
        function npm-check-updates() {
          if command -v ncu &> /dev/null; then
            ncu -u && npm install
          else
            echo "npm-check-updates not installed"
          fi
        }
        
        # Go development helpers
        function go-mod-tidy() {
          if [ -f "go.mod" ]; then
            go mod tidy
            go mod verify
          else
            echo "No go.mod file found"
          fi
        }
        
        # Rust development helpers
        function cargo-update() {
          if [ -f "Cargo.toml" ]; then
            cargo update
            cargo check
          else
            echo "No Cargo.toml file found"
          fi
        }
        
        # Project initialization helpers
        function init-python() {
          local project_name="$1"
          if [ -z "$project_name" ]; then
            project_name="$(basename $(pwd))"
          fi
          
          python -m venv .venv
          source .venv/bin/activate
          
          cat > requirements.txt << EOF
# Development dependencies
pytest
black
flake8
mypy
pre-commit
EOF
          
          cat > .gitignore << EOF
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF
          
          echo "Python project initialized: $project_name"
        }
        
        function init-node() {
          local project_name="$1"
          if [ -z "$project_name" ]; then
            project_name="$(basename $(pwd))"
          fi
          
          npm init -y
          npm install --save-dev eslint prettier @typescript-eslint/parser @typescript-eslint/eslint-plugin
          
          cat > .gitignore << EOF
# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*
.pnpm-debug.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# Build outputs
dist/
build/
.next/
out/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF
          
          echo "Node.js project initialized: $project_name"
        }
        
        # Development server helpers
        function serve() {
          local port="${1:-8000}"
          if command -v python3 &> /dev/null; then
            python3 -m http.server "$port"
          elif command -v python &> /dev/null; then
            python -m SimpleHTTPServer "$port"
          else
            echo "Python not found"
          fi
        }
        
        # Database development helpers
        function db-backup() {
          local db_name="$1"
          if [ -z "$db_name" ]; then
            echo "Usage: db-backup <database-name>"
            return 1
          fi
          
          local backup_file="backup_$(date +%Y%m%d_%H%M%S).sql"
          pg_dump "$db_name" > "$backup_file"
          echo "Database backup created: $backup_file"
        }
        
        # Code quality helpers
        function lint-all() {
          echo "Running linters..."
          
          # Python
          if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
            if command -v black &> /dev/null; then
              black .
            fi
            if command -v flake8 &> /dev/null; then
              flake8 .
            fi
            if command -v mypy &> /dev/null; then
              mypy .
            fi
          fi
          
          # JavaScript/TypeScript
          if [ -f "package.json" ]; then
            if command -v eslint &> /dev/null; then
              eslint .
            fi
            if command -v prettier &> /dev/null; then
              prettier --write .
            fi
          fi
          
          # Go
          if [ -f "go.mod" ]; then
            if command -v gofmt &> /dev/null; then
              gofmt -w .
            fi
            if command -v golint &> /dev/null; then
              golint ./...
            fi
          fi
          
          # Rust
          if [ -f "Cargo.toml" ]; then
            if command -v rustfmt &> /dev/null; then
              rustfmt --edition 2021 $(find . -name "*.rs")
            fi
            if command -v clippy &> /dev/null; then
              cargo clippy
            fi
          fi
          
          echo "Linting complete!"
        }
        
        # Development workflow aliases
        alias dev='dev'
        alias work='work'
        alias serve='serve'
        alias lint='lint-all'
        alias py-env='py-venv'
        alias py-req='py-requirements'
        alias npm-up='npm-check-updates'
        alias go-tidy='go-mod-tidy'
        alias cargo-up='cargo-update'
        alias docker-clean='docker-dev-clean'
        alias git-wt='git-worktree-add'
        alias init-py='init-python'
        alias init-js='init-node'
        alias db-bak='db-backup'
      '';
    };
  };

  # Development-specific environment variables
  home.sessionVariables = {
    # Development directories
    PROJECTS_DIR = "${config.home.homeDirectory}/Documents/Projects";
    WORK_DIR = "${config.home.homeDirectory}/Documents/Work";
    
    # Language-specific settings
    PYTHONDONTWRITEBYTECODE = "1";
    PYTHONUNBUFFERED = "1";
    PIP_DISABLE_PIP_VERSION_CHECK = "1";
    
    # Node.js settings
    NODE_ENV = "development";
    NPM_CONFIG_SAVE_EXACT = "true";
    
    # Go settings
    GOPROXY = "https://proxy.golang.org,direct";
    GOSUMDB = "sum.golang.org";
    
    # Rust settings
    RUST_BACKTRACE = "1";
    RUSTUP_UPDATE_ROOT = "${config.xdg.dataHome}/rustup";
    
    # Development tools
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less -R";
    BROWSER = "open";
    
    # Build and compilation
    MAKEFLAGS = "-j$(nproc)";
    
    # Docker development
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    
    # Database development
    PGUSER = "postgres";
    PGHOST = "localhost";
    PGPORT = "5432";
    
    # Performance and debugging
    HISTTIMEFORMAT = "%Y-%m-%d %H:%M:%S ";
    HISTSIZE = "100000";
    HISTFILESIZE = "100000";
    
    # Security
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    
    # XDG compliance for development tools
    BUNDLE_USER_CONFIG = "${config.xdg.configHome}/bundle";
    BUNDLE_USER_CACHE = "${config.xdg.cacheHome}/bundle";
    BUNDLE_USER_PLUGIN = "${config.xdg.dataHome}/bundle";
    
    # Jupyter
    JUPYTER_CONFIG_DIR = "${config.xdg.configHome}/jupyter";
    JUPYTER_DATA_DIR = "${config.xdg.dataHome}/jupyter";
    
    # VS Code
    VSCODE_EXTENSIONS = "${config.xdg.dataHome}/vscode/extensions";
    
    # IntelliJ
    IDEA_PROPERTIES = "${config.xdg.configHome}/idea/idea.properties";
    IDEA_VM_OPTIONS = "${config.xdg.configHome}/idea/idea64.vmoptions";
  };

  # Development-specific file configurations
  home.file = {
    # Global .editorconfig
    ".editorconfig".text = ''
      root = true
      
      [*]
      charset = utf-8
      end_of_line = lf
      indent_style = space
      indent_size = 2
      insert_final_newline = true
      trim_trailing_whitespace = true
      
      [*.py]
      indent_size = 4
      
      [*.go]
      indent_style = tab
      
      [*.md]
      trim_trailing_whitespace = false
      
      [Makefile]
      indent_style = tab
    '';
    
    # Global .gitattributes
    ".gitattributes".text = ''
      # Auto detect text files and perform LF normalization
      * text=auto
      
      # Custom for Visual Studio
      *.cs     diff=csharp
      *.sln    merge=union
      *.csproj merge=union
      *.vbproj merge=union
      *.vcxproj merge=union
      *.vcproj merge=union
      *.dbproj merge=union
      *.fsproj merge=union
      *.lsproj merge=union
      *.wixproj merge=union
      *.modelproj merge=union
      *.sqlproj merge=union
      *.wwaproj merge=union
      
      # Custom for Python
      *.py text diff=python
      
      # Custom for Go
      *.go text diff=golang
      
      # Custom for Rust
      *.rs text diff=rust
      
      # Custom for JavaScript
      *.js text diff=javascript
      *.jsx text diff=javascript
      *.ts text diff=typescript
      *.tsx text diff=typescript
      
      # Documents
      *.doc	 diff=astextplain
      *.DOC	 diff=astextplain
      *.docx diff=astextplain
      *.DOCX diff=astextplain
      *.dot  diff=astextplain
      *.DOT  diff=astextplain
      *.pdf  diff=astextplain
      *.PDF	 diff=astextplain
      *.rtf	 diff=astextplain
      *.RTF	 diff=astextplain
      
      # Binary files
      *.png binary
      *.jpg binary
      *.jpeg binary
      *.gif binary
      *.ico binary
      *.svg binary
      *.woff binary
      *.woff2 binary
      *.ttf binary
      *.eot binary
      
      # Archives
      *.zip binary
      *.tar binary
      *.gz binary
      *.bz2 binary
      *.xz binary
      *.7z binary
      *.rar binary
    '';
    
    # Development project templates directory
    "Documents/Templates/.keep".text = "";
    
    # Common development directories
    "Documents/Projects/.keep".text = "";
    "Documents/Work/.keep".text = "";
    "Documents/Learning/.keep".text = "";
    "Documents/Experiments/.keep".text = "";
  };

  # Development packages
  home.packages = with pkgs; [
    # Version control
    git-lfs
    git-crypt
    git-secret
    
    # Code quality
    pre-commit
    editorconfig-core-c
    
    # Documentation
    mdbook
    hugo
    
    # API tools
    insomnia
    
    # Database tools
    postgresql
    sqlite
    
    # Container tools
    docker-compose
    
    # Cloud tools
    awscli2
    
    # Monitoring
    htop
    iotop
    
    # File tools
    jq
    yq
    
    # Network tools
    curl
    wget
    
    # Archive tools
    zip
    unzip
    
    # System tools
    tree
    which
    
    # Development utilities
    make
    cmake
    
    # Text processing
    sed
    grep
    awk
    
    # Performance analysis
    time
    
    # Security tools
    gnupg
    
    # Backup tools
    rsync
    
    # Terminal utilities
    screen
    
    # Development servers
    python3
    nodejs
    
    # Build tools
    pkg-config
    
    # Compression tools
    gzip
    bzip2
    xz
  ];
} 