#!/usr/bin/env bash
# alias-cheatsheet.sh - Interactive alias cheat sheet viewer
#
# Usage: alias-cheatsheet.sh [category]
#
# Categories: all, core, git, dev, docker, k8s, terraform
#
# Description:
#   Shows a quick reference cheat sheet for shell aliases.
#   Supports filtering by category.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
README_PATH="$SCRIPT_DIR/../aliases/README.md"
CATEGORY="${1:-all}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
${CYAN}Alias Cheat Sheet Viewer${NC}

Usage: $(basename "$0") [category]

Categories:
  ${GREEN}all${NC}       - Show full README (default)
  ${GREEN}core${NC}      - Core shell aliases
  ${GREEN}git${NC}       - Git workflow aliases
  ${GREEN}dev${NC}       - Development tools (Docker, K8s, Terraform)
  ${GREEN}docker${NC}    - Docker-specific aliases
  ${GREEN}k8s${NC}       - Kubernetes-specific aliases
  ${GREEN}terraform${NC} - Terraform-specific aliases
  ${GREEN}quick${NC}     - Quick reference (most used)

Examples:
  $(basename "$0")          # Show full documentation
  $(basename "$0") git      # Show git aliases only
  $(basename "$0") quick    # Show most used aliases
EOF
}

show_quick_reference() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}            Quick Alias Reference (Most Used)${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${MAGENTA}📁 Navigation${NC}"
    echo -e "  ${GREEN}..${NC}         Go up one directory"
    echo -e "  ${GREEN}...${NC}        Go up two directories"
    echo -e "  ${GREEN}work${NC}       Go to workspace"
    echo -e "  ${GREEN}dotfile${NC}    Go to dotfiles"
    echo ""
    echo -e "${MAGENTA}📝 Git Basics${NC}"
    echo -e "  ${GREEN}gs${NC}         Git status (short)"
    echo -e "  ${GREEN}gaa${NC}        Stage all changes"
    echo -e "  ${GREEN}gcm${NC} \"msg\"  Commit with message"
    echo -e "  ${GREEN}gp${NC}         Push to remote"
    echo -e "  ${GREEN}gl${NC}         Pull from remote"
    echo ""
    echo -e "${MAGENTA}⚡ Git Workflows${NC}"
    echo -e "  ${GREEN}quickcommit${NC} \"msg\"  Stage + commit"
    echo -e "  ${GREEN}quickpush${NC} \"msg\"    Stage + commit + push"
    echo -e "  ${GREEN}quickamend${NC}         Stage + amend last commit"
    echo -e "  ${GREEN}gwip${NC}               Quick WIP commit"
    echo ""
    echo -e "${MAGENTA}🔀 Git Branches${NC}"
    echo -e "  ${GREEN}gco${NC} branch  Checkout branch"
    echo -e "  ${GREEN}gcob${NC} name   Create and checkout new branch"
    echo -e "  ${GREEN}gcb${NC}         Fuzzy checkout (interactive)"
    echo -e "  ${GREEN}gbd${NC} branch  Delete branch (safe)"
    echo ""
    echo -e "${MAGENTA}🐳 Docker${NC}"
    echo -e "  ${GREEN}d${NC} ps        List containers"
    echo -e "  ${GREEN}dlog${NC}        Tail logs (interactive)"
    echo -e "  ${GREEN}dexec${NC}       Exec into container (interactive)"
    echo -e "  ${GREEN}dsp${NC}         Stop container (interactive)"
    echo ""
    echo -e "${MAGENTA}☸️  Kubernetes${NC}"
    echo -e "  ${GREEN}k${NC} get pods  List pods"
    echo -e "  ${GREEN}klogs${NC} pod   Follow pod logs"
    echo -e "  ${GREEN}kexec${NC} pod -- /bin/sh  Exec into pod"
    echo -e "  ${GREEN}kfp${NC}         Select pod (interactive)"
    echo ""
    echo -e "${MAGENTA}🔧 System${NC}"
    echo -e "  ${GREEN}rebuild${NC}     Rebuild system configuration"
    echo -e "  ${GREEN}update${NC}      Update and rebuild"
    echo -e "  ${GREEN}cleanup${NC}     Clean old generations and caches"
    echo -e "  ${GREEN}rollback${NC}    Rollback to previous generation"
    echo ""
    echo -e "${MAGENTA}🔍 Discovery${NC}"
    echo -e "  ${GREEN}alias-find${NC}    Fuzzy find aliases"
    echo -e "  ${GREEN}alias-search${NC}  Search by keyword"
    echo -e "  ${GREEN}alias-help${NC}    Show full documentation"
    echo -e "  ${GREEN}alias-list${NC}    List all aliases"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Tip:${NC} Use ${GREEN}alias-find${NC} to interactively search all aliases!"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

show_category() {
    local category="$1"

    case "$category" in
        core)
            echo -e "${CYAN}Core Shell Aliases${NC}\n"
            alias | grep -E "^(c=|x=|h=|r=|rl=|l=|ll=|la=|ls=|\.\.=|backup=|xtract=|compress=|psg=|killall=|size=|copy=|paste=|json=|yaml=|path=|now=|today=|myip=|ports=)" | sort
            ;;
        git)
            echo -e "${CYAN}Git Workflow Aliases${NC}\n"
            alias | grep -E "^(gs=|gaa=|gcm=|gp=|gl=|gco=|gcob=|gbd=|gst=|grb=|glog=|gd=|gcb=|fshow=|fstash=|quick)" | sort
            ;;
        docker)
            echo -e "${CYAN}Docker Aliases${NC}\n"
            alias | grep -E "^(d=|dc=|dsp=|drm=|dimg=|dlog=|dexec=)" | sort
            ;;
        k8s|kubernetes)
            echo -e "${CYAN}Kubernetes Aliases${NC}\n"
            alias | grep -E "^(k=|kgp=|kgs=|kgd=|kgn=|kdp=|kds=|klogs=|kexec=|kctx=|kns=|kaf=|kpf=|kfp=)" | sort
            ;;
        terraform)
            echo -e "${CYAN}Terraform Aliases${NC}\n"
            alias | grep -E "^(tf=|tfin=|tfp=|tfa=|tfd=|tfwst=|tfwsw=|tfwls=)" | sort
            ;;
        dev)
            echo -e "${CYAN}Development Tools Aliases${NC}\n"
            alias | grep -E "^(d=|dc=|k=|tf=|tn=|ta=|tk=|fe=|fcd=|fif=|lsa=|lst=|fdh=|fa=)" | sort
            ;;
        quick)
            show_quick_reference
            return
            ;;
        all)
            if command -v bat &> /dev/null; then
                bat "$README_PATH"
            elif command -v less &> /dev/null; then
                less "$README_PATH"
            else
                cat "$README_PATH"
            fi
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Unknown category '$category'${NC}\n"
            show_help
            exit 1
            ;;
    esac
}

# Main execution
if [ ! -f "$README_PATH" ]; then
    echo -e "${RED}Error: README.md not found at $README_PATH${NC}" >&2
    exit 1
fi

show_category "$CATEGORY"
