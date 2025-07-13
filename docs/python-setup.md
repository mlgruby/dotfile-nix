# Python Development Setup

## Overview

This configuration provides a clean Python development environment using:

- **System-wide Python 3.12** via Homebrew for consistent base 
environment
- **uv** for fast project-specific Python version and package management
- **No pyenv** to avoid PATH conflicts and complexity

## System Python

The system uses Python 3.12 from Homebrew:

```bash
which python3
# /opt/homebrew/opt/python@3.12/libexec/bin/python3

python3 --version
# Python 3.12.11
```

## Project Management with uv

### Create a new project

```bash
uv init my-project
cd my-project
```

### Add dependencies

```bash
uv add requests pandas
uv add pytest --dev  # Development dependencies
```

### Use specific Python version for a project

```bash
uv python install 3.11  # Install Python 3.11
uv init --python 3.11 my-legacy-project
```

### Run scripts

```bash
uv run python script.py
uv run pytest  # Run tests
```

### Install packages globally (rare)

```bash
uv tool install black  # Global tool installation
```

## Migration from pyenv/poetry

### Old workflow:

```bash
pyenv install 3.11.0
pyenv local 3.11.0
poetry init
poetry add requests
poetry shell
```

### New workflow:

```bash
uv init --python 3.11 my-project
cd my-project
uv add requests
uv run python script.py
```

## Benefits

1. **Faster**: uv is significantly faster than pip/poetry
2. **Simpler**: No virtual environment management needed
3. **Consistent**: System Python 3.12 for all system tasks
4. **Flexible**: Easy to use different Python versions per project
5. **Modern**: Uses the latest Python packaging standards

## Available Commands

- `uv init` - Create new project
- `uv add` - Add dependencies
- `uv remove` - Remove dependencies
- `uv run` - Run commands in project environment
- `uv python list` - List available Python versions
- `uv python install` - Install Python versions
- `uv tool install` - Install global tools
- `uv sync` - Sync dependencies
- `uv lock` - Generate lock file

## Configuration

The system is configured in:

- `darwin/homebrew.nix` - Python 3.12 and uv installation
- `home-manager/modules/zsh.nix` - PATH setup and environment variables
