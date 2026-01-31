# Development Environment Templates

A collection of direnv-powered development environment templates that provide automatic, project-specific tooling and configuration.

## Overview

These templates leverage [direnv](https://direnv.net/) to automatically activate project-specific environments when you enter a directory. Each template provides:

- **Automatic tool installation** and version management
- **Environment variable configuration**
- **Project initialization** with best practices
- **Development workflow automation**
- **Consistent setup** across team members

## Quick Start

### 1. Setup a New Project

```bash
# Interactive setup
./scripts/setup/dev-env.sh

# Specify project type
./scripts/setup/dev-env.sh python ./my-python-project

# Auto-detect existing project
./scripts/setup/dev-env.sh --auto
```

### 2. Activate Environment

```bash
cd my-project
direnv allow  # First time only
# Environment automatically activates!
```

## Available Templates

### 🐍 Python Template

**Features:**

- Modern Python development with [uv](https://github.com/astral-sh/uv)
- Automatic virtual environment management
- Pre-commit hooks integration
- Testing with pytest
- Code formatting with black and ruff

**Setup:**

```bash
./scripts/setup/dev-env.sh python ./my-python-project
cd my-python-project
direnv allow
```

**What you get:**

- Python version management (default: 3.12)
- Virtual environment in `.venv/`
- Development dependencies: pytest, black, ruff, mypy
- Pre-commit hooks if `.pre-commit-config.yaml` exists
- Environment variables for Python development

**Commands available:**

```bash
uv add requests          # Add dependency
uv add --dev pytest-mock # Add dev dependency
pytest                   # Run tests
black .                  # Format code
ruff check .             # Lint code
```

### 🟢 Node.js Template

**Features:**

- Package manager detection (npm/yarn/pnpm)
- TypeScript support with automatic detection
- Development server with hot reload
- Testing with Jest
- Code formatting with Prettier

**Setup:**

```bash
./scripts/setup/dev-env.sh nodejs ./my-node-project
cd my-node-project
direnv allow
```

**What you get:**

- Node.js version detection
- Package manager auto-detection
- TypeScript configuration if available
- Development dependencies: eslint, prettier, jest
- Environment variables for web development

**Commands available:**

```bash
npm start                # Start application
npm run dev              # Development server
npm test                 # Run tests
npm run build            # Build for production
```

### 🦀 Rust Template

**Features:**

- Rust toolchain management
- Development tools (clippy, rustfmt)
- Benchmarking with criterion
- Cross-compilation support
- Cargo workspace support

**Setup:**

```bash
./scripts/setup/dev-env.sh rust ./my-rust-project
cd my-rust-project
direnv allow
```

**What you get:**

- Rust stable toolchain (rustc, cargo)
- Development tools: clippy, rustfmt
- LSP support: rust-analyzer (for Claude Code and IDEs)
- Benchmark setup with criterion
- Performance optimization flags
- Cross-compilation configuration

**Commands available:**

```bash
cargo build              # Build project
cargo run                # Run project
cargo test               # Run tests
cargo bench              # Run benchmarks
cargo clippy             # Lint code
```

### 🐹 Go Template

**Features:**

- Go module management
- Development tools (goimports, golangci-lint)
- Live reload with air
- Debugging with delve
- Cross-compilation support

**Setup:**

```bash
./scripts/setup/dev-env.sh go ./my-go-project
cd my-go-project
direnv allow
```

**What you get:**

- Go module initialization
- Project structure (cmd/, pkg/, internal/)
- Development tools: golangci-lint, air, delve
- Makefile with common tasks
- Cross-compilation targets

**Commands available:**

```bash
go run ./cmd/myproject   # Run application
go test ./...            # Run tests
make build               # Build with Makefile
air                      # Live reload
golangci-lint run        # Lint code
```

### ☕ Java/Kotlin/Scala Template

**Features:**

- Java version management with SDKMAN
- Kotlin language server for LSP support
- Scala and SBT support
- Maven/Gradle build tools
- Auto-detection of project type
- IDE integration support

**Setup:**

```bash
./scripts/setup/dev-env.sh java ./my-java-project
cd my-java-project
direnv allow
```

**What you get:**

- Java version management via SDKMAN
- Kotlin language server (for Claude Code and IDEs)
- Scala and SBT for Scala projects
- Maven/Gradle setup for Java/Kotlin projects
- Memory optimization settings
- Project structure initialization

**Commands available:**

```bash
# For Scala projects
sbt compile              # Compile project
sbt run                  # Run application
sbt test                 # Run tests

# For Java projects  
mvn compile              # Compile project
mvn exec:java            # Run application
mvn test                 # Run tests
```

### 🐳 Docker Template

**Features:**

- Docker Compose multi-service setup
- Development and production containers
- Database and cache services
- Volume mounting for hot reload
- Helper functions for common tasks

**Setup:**

```bash
./scripts/setup/dev-env.sh docker ./my-docker-project
cd my-docker-project
direnv allow
```

**What you get:**

- Multi-service Docker Compose setup
- Development and production Dockerfiles
- PostgreSQL and Redis services
- Helper functions for container management
- Environment variable configuration

**Commands available:**

```bash
dev_up                   # Start all services
dev_down                 # Stop all services
dev_logs app             # View service logs
dev_shell app            # Shell into container
dev_reset                # Reset entire environment
```

## Advanced Usage

### Custom Environment Variables

Each template supports customization via environment variables:

```bash
# Python example
export PYTHON_VERSION="3.11"
export PROJECT_TYPE="library"

# Node.js example
export NODE_VERSION="18"
export PORT="4000"

# Rust example
export RUST_VERSION="nightly"
export PROJECT_TYPE="lib"
```

### Template Customization

You can customize templates by:

1. **Copying and modifying** the `.envrc` files in `dev-templates/`
2. **Adding project-specific** environment variables
3. **Extending with custom functions** in your project's `.envrc`

### Integration with IDEs

The templates work seamlessly with:

- **VS Code** with direnv extension
- **IntelliJ IDEA** with direnv plugin
- **Neovim** with direnv integration
- **Emacs** with direnv-mode
- **Claude Code** with LSP plugins

### Language Server Protocol (LSP) Support

Your dotfiles include language servers for enhanced IDE and Claude Code integration:

**Available Language Servers:**

- **Rust**: `rust-analyzer` - Provides code completion, go-to-definition, type information
- **Kotlin**: `kotlin-language-server` - JVM language support for Kotlin projects
- **Python**: Built into most Python distributions and IDEs
- **TypeScript/JavaScript**: Included with Node.js installations

**Configuration:**

Language servers are installed system-wide via Nix and work automatically with:

```bash
# Claude Code uses these automatically when available
# Check if LSP servers are installed:
which rust-analyzer          # → /nix/store/.../bin/rust-analyzer
which kotlin-language-server # → /nix/store/.../bin/kotlin-language-server
```

**Benefits:**

- Real-time syntax checking and error detection
- Intelligent code completion
- Go-to-definition and find references
- Refactoring support
- Works across all editors and Claude Code

## Team Collaboration

### Sharing Templates

1. **Commit `.envrc`** to your project repository
2. **Document setup** in your project README:

   ```markdown
   ## Development Setup
   1. Install direnv: `brew install direnv`
   2. Allow environment: `direnv allow`
   3. Environment will auto-activate
   ```

### Team-Specific Customization

Create team-specific overrides:

```bash
# In .envrc.local (gitignored)
export DATABASE_URL="postgresql://localhost:5433/myproject"
export API_KEY="team-specific-key"

# Source in main .envrc
[[ -f .envrc.local ]] && source .envrc.local
```

## Troubleshooting

### Common Issues

1. **direnv not working**

   ```bash
   # Check direnv is installed and configured
   which direnv
   # Add to shell config if missing
   eval "$(direnv hook zsh)"  # or bash
   ```

2. **Template not found**

   ```bash
   # List available templates
   ./scripts/setup/dev-env.sh --list
   # Check templates directory
   ls dev-templates/
   ```

3. **Environment not activating**

   ```bash
   # Check direnv status
   direnv status
   # Allow the directory
   direnv allow
   ```

4. **Tool not found after activation**

   ```bash
   # Check PATH in environment
   echo $PATH
   # Reload environment
   direnv reload
   ```

### Debug Mode

Enable debug mode for troubleshooting:

```bash
export DIRENV_LOG_FORMAT="$(date) direnv: %s"
direnv reload
```

## Best Practices

### Project Organization

```text
my-project/
├── .envrc              # Environment configuration
├── .envrc.local        # Local overrides (gitignored)
├── .gitignore          # Include .envrc.local
├── README.md           # Document setup process
└── src/                # Source code
```

### Security

1. **Never commit secrets** in `.envrc`
2. **Use `.envrc.local`** for sensitive data
3. **Document required variables** in README
4. **Use placeholder values** in committed `.envrc`

### Performance

1. **Keep `.envrc` fast** - avoid expensive operations
2. **Cache tool installations** when possible
3. **Use conditional checks** for optional dependencies
4. **Lazy load** heavy tools

## Integration with Nix Darwin

The templates integrate seamlessly with your Nix Darwin configuration:

- **direnv** is pre-configured via Home Manager
- **Tools are available** via Homebrew and Nix packages
- **Shell integration** works automatically
- **No additional setup** required

## Examples

### Python Data Science Project

```bash
./scripts/setup/dev-env.sh python ./data-analysis
cd data-analysis
# Environment activates with Python 3.12, pytest, jupyter
uv add pandas numpy matplotlib jupyter
jupyter notebook  # Ready to go!
```

### Rust Web Service

```bash
./scripts/setup/dev-env.sh rust ./web-service
cd web-service
# Environment activates with Rust stable, clippy, benchmarks
cargo add tokio serde axum
cargo run  # Development server ready!
```

### Full-Stack Application

```bash
# Backend
./scripts/setup/dev-env.sh go ./backend
cd backend && direnv allow

# Frontend  
./scripts/setup/dev-env.sh nodejs ./frontend
cd frontend && direnv allow

# Infrastructure
./scripts/setup/dev-env.sh docker ./infrastructure
cd infrastructure && direnv allow
```

## Contributing

To add new templates:

1. Create directory: `dev-templates/newlang/`
2. Add `.envrc` file with template
3. Update `TEMPLATES` array in `scripts/setup/dev-env.sh`
4. Add documentation section above
5. Test with various project scenarios

## Resources

- [direnv Documentation](https://direnv.net/)
- [Development Environment Best Practices](../core/configuration.md)
- [Tool Configuration](../customization/packages.md)
- [Troubleshooting Guide](../core/troubleshooting.md)
