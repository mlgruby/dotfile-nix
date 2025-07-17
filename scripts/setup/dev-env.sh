#!/bin/bash
# setup-dev-env.sh
#
# Development Environment Setup Script
#
# Purpose:
# - Initialize development environments with direnv templates
# - Support multiple project types with automatic detection
# - Provide interactive project setup
# - Integrate with existing dotfile configuration
#
# Features:
# - Auto-detects project type from existing files
# - Interactive template selection
# - Customizable environment variables
# - Validation and error handling
#
# Usage:
#   ./setup-dev-env.sh [project-type] [directory]
#   ./setup-dev-env.sh python ./my-python-project
#   ./setup-dev-env.sh --list
#   ./setup-dev-env.sh --auto

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/dev-templates"

# Available templates (template:description format)
TEMPLATES=(
    "python:🐍 Python (uv, pytest, ruff)"
    "nodejs:🟢 Node.js (npm/yarn/pnpm, TypeScript)"
    "rust:🦀 Rust (cargo, clippy, rustfmt)"
    "go:🐹 Go (modules, testing, live reload)"
    "java:☕ Java/Scala (SDKMAN, Maven/SBT)"
    "docker:🐳 Docker (compose, multi-service)"
)

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
🏗️  Development Environment Setup

Usage:
    $0 [OPTIONS] [PROJECT_TYPE] [DIRECTORY]

Options:
    -h, --help      Show this help message
    -l, --list      List available templates
    -a, --auto      Auto-detect project type
    --force         Overwrite existing .envrc

Project Types:
EOF
    for template_info in "${TEMPLATES[@]}"; do
        template="${template_info%:*}"
        description="${template_info#*:}"
        echo "    $template: $description"
    done
    
    cat << EOF

Examples:
    $0 python                    # Setup Python env in current directory
    $0 nodejs ./my-app           # Setup Node.js env in ./my-app
    $0 --auto                    # Auto-detect and setup
    $0 --list                    # Show available templates

EOF
}

# List available templates
list_templates() {
    log_info "Available development environment templates:"
    echo
    for template_info in "${TEMPLATES[@]}"; do
        template="${template_info%:*}"
        description="${template_info#*:}"
        echo -e "  ${CYAN}$template${NC}: $description"
    done
    echo
}

# Auto-detect project type based on existing files
auto_detect_type() {
    local dir="${1:-.}"
    
    if [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/requirements.txt" ]] || [[ -f "$dir/setup.py" ]]; then
        echo "python"
    elif [[ -f "$dir/package.json" ]]; then
        echo "nodejs"
    elif [[ -f "$dir/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$dir/go.mod" ]] || [[ -f "$dir/main.go" ]]; then
        echo "go"
    elif [[ -f "$dir/pom.xml" ]] || [[ -f "$dir/build.sbt" ]] || [[ -f "$dir/build.gradle" ]]; then
        echo "java"
    elif [[ -f "$dir/docker-compose.yml" ]] || [[ -f "$dir/compose.yaml" ]] || [[ -f "$dir/Dockerfile" ]]; then
        echo "docker"
    else
        echo ""
    fi
}

# Interactive template selection
interactive_selection() {
    echo -e "${CYAN}🏗️  Development Environment Setup${NC}"
    echo
    echo "Available templates:"
    
    local templates_array=()
    local i=1
    for template_info in "${TEMPLATES[@]}"; do
        template="${template_info%:*}"
        description="${template_info#*:}"
        echo "  $i) $template: $description"
        templates_array+=("$template")
        ((i++))
    done
    
    echo
    read -rp "Select template (1-${#templates_array[@]}): " selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le "${#templates_array[@]}" ]]; then
        echo "${templates_array[$((selection-1))]}"
    else
        log_error "Invalid selection"
        exit 1
    fi
}

# Validate template exists
validate_template() {
    local template="$1"
    
    # Check if template exists in our list
    local found=false
    for template_info in "${TEMPLATES[@]}"; do
        if [[ "${template_info%:*}" == "$template" ]]; then
            found=true
            break
        fi
    done
    
    if [[ "$found" != "true" ]]; then
        log_error "Unknown template: $template"
        log_info "Available templates:"
        for template_info in "${TEMPLATES[@]}"; do
            echo "  - ${template_info%:*}"
        done
        exit 1
    fi
    
    if [[ ! -f "$TEMPLATES_DIR/$template/.envrc" ]]; then
        log_error "Template file not found: $TEMPLATES_DIR/$template/.envrc"
        exit 1
    fi
}

# Setup environment
setup_environment() {
    local template="$1"
    local target_dir="${2:-.}"
    local force="${3:-false}"
    
    # Create target directory if it doesn't exist
    if [[ ! -d "$target_dir" ]]; then
        log_step "Creating directory: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    # Check if .envrc already exists
    if [[ -f "$target_dir/.envrc" ]] && [[ "$force" != "true" ]]; then
        log_warning ".envrc already exists in $target_dir"
        read -rp "Overwrite? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Setup cancelled"
            exit 0
        fi
    fi
    
    # Copy template
    log_step "Setting up $template environment in $target_dir"
    cp "$TEMPLATES_DIR/$template/.envrc" "$target_dir/.envrc"
    
    # Make sure direnv is configured
    if ! command -v direnv >/dev/null 2>&1; then
        log_warning "direnv not found in PATH"
        log_info "direnv should be available via Home Manager configuration"
    fi
    
    log_success "Environment template copied!"
    
    # Instructions
    echo
    log_info "Next steps:"
    echo "  1. cd $target_dir"
    echo "  2. direnv allow"
    echo "  3. The environment will be automatically activated"
    echo
    # Find template description
    local template_desc=""
    for template_info in "${TEMPLATES[@]}"; do
        if [[ "${template_info%:*}" == "$template" ]]; then
            template_desc="${template_info#*:}"
            break
        fi
    done
    log_info "Template: $template_desc"
}

# Main function
main() {
    local template=""
    local target_dir="."
    local force="false"
    local auto_detect="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_templates
                exit 0
                ;;
            -a|--auto)
                auto_detect="true"
                shift
                ;;
            --force)
                force="true"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$template" ]]; then
                    template="$1"
                elif [[ "$target_dir" == "." ]]; then
                    target_dir="$1"
                else
                    log_error "Too many arguments"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Auto-detect if requested
    if [[ "$auto_detect" == "true" ]]; then
        template=$(auto_detect_type "$target_dir")
        if [[ -z "$template" ]]; then
            log_warning "Could not auto-detect project type"
            template=$(interactive_selection)
        else
            log_info "Auto-detected project type: $template"
        fi
    fi
    
    # Interactive selection if no template specified
    if [[ -z "$template" ]]; then
        template=$(interactive_selection)
    fi
    
    # Validate and setup
    validate_template "$template"
    setup_environment "$template" "$target_dir" "$force"
}

# Check if templates directory exists
if [[ ! -d "$TEMPLATES_DIR" ]]; then
    log_error "Templates directory not found: $TEMPLATES_DIR"
    log_info "Make sure you're running this script from the dotfile directory"
    exit 1
fi

# Run main function
main "$@"
 