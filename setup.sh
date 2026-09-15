#!/usr/bin/env bash
#
# setup-opencode — One-command setup for OpenCode AI coding agent
# https://github.com/kiraadityaa/setup-opencode
#
set -euo pipefail

# ─── Defaults ──────────────────────────────────────────────────────
REPO_URL="https://github.com/kiraadityaa/setup-opencode"
OPENCODE_HOME="${OPENCODE_HOME:-$HOME/.config/opencode}"
DEPS_DIR="${OPENCODE_HOME}/_deps"
BACKUP_DIR="${HOME}/.config"
NO_BROWSER=false
NO_NOTIFICATOR=false
NO_PLUGINS=false
NO_SKILLS=false
NO_TEMPLATES=false
DRY_RUN=false
FORCE=false
UNINSTALL=false
VERBOSE=false

# ─── Colors ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Helpers ───────────────────────────────────────────────────────
info()  { echo -e "${BLUE}▸${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
err()   { echo -e "${RED}✗${NC} $*" >&2; }
debug() { if $VERBOSE; then echo -e "${CYAN}[debug]${NC} $*"; fi; }
die()   { err "$@"; exit 1; }

confirm() {
    local msg="${1:-Continue?}"
    if $DRY_RUN; then return 0; fi
    read -rp "$(echo -e "${YELLOW}?${NC} ${msg} [y/N] ")" answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

run() {
    if $DRY_RUN; then
        echo -e "  ${CYAN}[dry-run]${NC} $*"
        return 0
    fi
    if $VERBOSE; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# ─── Parse Args ────────────────────────────────────────────────────
usage() {
    cat <<'EOF'
setup-opencode — One-command setup for OpenCode AI coding agent

Usage:
  ./setup.sh [OPTIONS]

Options:
  --no-browser         Skip agent-browser + Chrome install
  --no-notificator     Skip notificator plugin
  --no-plugins         Skip all npm plugin installs
  --no-skills          Skip external skill clones (anthropics, agent-browser)
  --no-templates       Skip project templates
  --dry-run            Preview actions without making changes
  --force              Overwrite existing config (backs up first)
  --uninstall          Remove all setup-opencode files
  --verbose            Show all commands
  --help               Show this help

Examples:
  ./setup.sh                          # Full install (recommended)
  ./setup.sh --no-browser --dry-run   # Preview without browser
  ./setup.sh --force                  # Reinstall (backup existing first)
  ./setup.sh --uninstall              # Remove everything
EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-browser)      NO_BROWSER=true ;;
            --no-notificator)  NO_NOTIFICATOR=true ;;
            --no-plugins)      NO_PLUGINS=true ;;
            --no-skills)       NO_SKILLS=true ;;
            --no-templates)    NO_TEMPLATES=true ;;
            --dry-run)         DRY_RUN=true ;;
            --force)           FORCE=true ;;
            --uninstall)       UNINSTALL=true ;;
            --verbose)         VERBOSE=true ;;
            --help|-h)         usage ;;
            *)                 die "Unknown option: $1 (use --help)" ;;
        esac
        shift
    done
}

# ─── Uninstall ─────────────────────────────────────────────────────
do_uninstall() {
    info "Uninstalling setup-opencode files..."
    rm -rf "${OPENCODE_HOME}/agent"
    rm -rf "${OPENCODE_HOME}/command"
    rm -rf "${OPENCODE_HOME}/skills"
    rm -rf "${OPENCODE_HOME}/instructions"
    rm -rf "${OPENCODE_HOME}/plugins"
    rm -rf "${OPENCODE_HOME}/_deps"
    rm -rf "${HOME}/opencode-ecosystem/templates"
    ok "Removed: agents, commands, skills, instructions, plugins, deps, templates"
    ok "Kept: opencode.jsonc, node_modules, auth (use --force to reinstall)"
    exit 0
}

# ─── Preflight ─────────────────────────────────────────────────────
preflight() {
    info "Checking prerequisites..."

    # OS detection
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
    ARCH="$(uname -m)"
    IS_CONTAINER=false
    IS_MACOS=false

    case "$OS" in
        linux*)   ;;
        darwin*)  IS_MACOS=true ;;
        msys*|mingw*|cygwin*)
            die "Windows native not supported. Use WSL: https://opencode.ai/docs/windows-wsl" ;;
        *)        warn "Unknown OS: $OS — proceeding anyway" ;;
    esac

    # Container detection
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        IS_CONTAINER=true
        debug "Detected container environment"
    fi

    # Required commands
    for cmd in bash curl git; do
        command -v "$cmd" >/dev/null 2>&1 || die "Required: $cmd — install it first"
    done

    # Node.js
    if ! command -v node >/dev/null 2>&1; then
        warn "Node.js not found. Installing via nvm..."
        if [ -f "$HOME/.nvm/nvm.sh" ]; then
            # shellcheck source=/dev/null
            source "$HOME/.nvm/nvm.sh"
            nvm install 22 || die "Failed to install Node.js via nvm"
        else
            warn "nvm not found. Attempting npm install from system..."
            command -v npm >/dev/null 2>&1 || die "Neither node nor npm found. Install Node.js manually."
        fi
    fi

    NODE_VER="$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)"
    if [ "${NODE_VER:-0}" -lt 18 ]; then
        warn "Node.js v${NODE_VER:-?} detected (v18+ recommended)"
    fi

    ok "Preflight: OS=$OS, arch=$ARCH, container=$IS_CONTAINER, node=$(node -v 2>/dev/null || echo 'missing')"
}

# ─── Install OpenCode ──────────────────────────────────────────────
install_opencode() {
    if command -v opencode >/dev/null 2>&1; then
        local ver
        ver="$(opencode --version 2>/dev/null || echo 'unknown')"
        ok "OpenCode already installed ($ver)"
        return 0
    fi

    info "Installing OpenCode..."
    if $DRY_RUN; then
        echo "  ${CYAN}[dry-run]${NC} curl -fsSL https://opencode.ai/install | bash"
        return 0
    fi

    curl -fsSL https://opencode.ai/install | bash
    ok "OpenCode installed"
}

# ─── Backup ────────────────────────────────────────────────────────
backup_existing() {
    if [ ! -d "$OPENCODE_HOME" ]; then
        debug "No existing config to backup"
        return 0
    fi

    if $FORCE; then
        local ts
        ts="$(date +%Y%m%d_%H%M%S)"
        local dest="${BACKUP_DIR}/opencode.bak.${ts}"
        info "Backing up existing config → $dest"
        if ! $DRY_RUN; then
            cp -a "$OPENCODE_HOME" "$dest"
        fi
        ok "Backup created: $dest"
    elif [ -f "${OPENCODE_HOME}/opencode.jsonc" ]; then
        warn "Existing opencode config detected at $OPENCODE_HOME"
        warn "Use --force to backup and reinstall, or --dry-run to preview"
        if ! confirm "Overwrite existing config?"; then
            die "Aborted. Use --force to proceed."
        fi
        local ts
        ts="$(date +%Y%m%d_%H%M%S)"
        local dest="${BACKUP_DIR}/opencode.bak.${ts}"
        info "Backing up → $dest"
        if ! $DRY_RUN; then
            cp -a "$OPENCODE_HOME" "$dest"
        fi
        ok "Backup created"
    fi
}

# ─── Deploy Payload ────────────────────────────────────────────────
resolve_payload_dir() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [ -d "${script_dir}/payload" ]; then
        PAYLOAD_DIR="${script_dir}/payload"
        TEMPLATES_DIR="${script_dir}/templates"
        debug "Using local payload: $PAYLOAD_DIR"
        return 0
    fi

    # Piped install — download tarball
    info "payload/ not found locally — downloading from GitHub..."
    local tmpdir
    tmpdir="$(mktemp -d)"
    if ! $DRY_RUN; then
        curl -fsSL "${REPO_URL}/archive/refs/heads/main.tar.gz" \
            | tar xz -C "$tmpdir" --strip-components=1
    fi
    PAYLOAD_DIR="${tmpdir}/payload"
    TEMPLATES_DIR="${tmpdir}/templates"
    ok "Downloaded to $tmpdir"
}

deploy_payload() {
    info "Deploying config to $OPENCODE_HOME..."
    mkdir -p "${OPENCODE_HOME}/agent"
    mkdir -p "${OPENCODE_HOME}/command"
    mkdir -p "${OPENCODE_HOME}/skills"
    mkdir -p "${OPENCODE_HOME}/instructions"
    mkdir -p "${OPENCODE_HOME}/plugins"
    mkdir -p "${OPENCODE_HOME}/_deps"

    # Core config
    run cp "${PAYLOAD_DIR}/opencode.jsonc" "${OPENCODE_HOME}/opencode.jsonc"

    # Agents
    run cp "${PAYLOAD_DIR}"/agent/*.md "${OPENCODE_HOME}/agent/"

    # Commands
    run cp "${PAYLOAD_DIR}"/command/*.md "${OPENCODE_HOME}/command/"

    # Instructions
    run cp "${PAYLOAD_DIR}"/instructions/*.md "${OPENCODE_HOME}/instructions/"

    # Skills
    run cp -r "${PAYLOAD_DIR}"/skills/*/ "${OPENCODE_HOME}/skills/"

    # Notificator plugin
    if ! $NO_NOTIFICATOR; then
        mkdir -p "${OPENCODE_HOME}/plugins/opencode-notificator/notificator-sounds"
        run cp "${PAYLOAD_DIR}/plugins/opencode-notificator/notificator.js" \
               "${OPENCODE_HOME}/plugins/opencode-notificator/"
        run cp "${PAYLOAD_DIR}/plugins/opencode-notificator/notificator.jsonc" \
               "${OPENCODE_HOME}/plugins/opencode-notificator/"
        run cp "${PAYLOAD_DIR}/plugins/opencode-notificator/notificator-sounds/"*.mp3 \
               "${OPENCODE_HOME}/plugins/opencode-notificator/notificator-sounds/"
        ok "Notificator plugin deployed"
    fi

    ok "Payload deployed"
}

# ─── Install NPM Plugins ───────────────────────────────────────────
install_plugins() {
    if $NO_PLUGINS; then
        debug "Skipping plugins (--no-plugins)"
        return 0
    fi

    info "Installing npm plugins..."
    for pkg in opencode-gemini-auth@latest @tarquinen/opencode-dcp@latest opencode-vibeguard@latest; do
        debug "  npm install -g $pkg"
        run npm install -g "$pkg"
    done
    ok "Plugins installed (gemini-auth, dcp, vibeguard)"
}

# ─── Clone External Skills ─────────────────────────────────────────
clone_external_skills() {
    if $NO_SKILLS; then
        debug "Skipping external skills (--no-skills)"
        return 0
    fi

    info "Cloning external skill repos..."
    mkdir -p "$DEPS_DIR"

    # anthropics/skills
    if [ ! -d "${DEPS_DIR}/anthropic-skills" ]; then
        debug "  git clone anthropics/skills"
        run git clone --depth 1 https://github.com/anthropics/skills.git \
            "${DEPS_DIR}/anthropic-skills"
    fi

    # agent-browser skills
    if [ ! -d "${DEPS_DIR}/agent-browser-skills" ]; then
        debug "  git clone agent-browser (skills)"
        run git clone --depth 1 https://github.com/vercel-labs/agent-browser.git \
            "${DEPS_DIR}/agent-browser-repo"
        if ! $DRY_RUN; then
            run cp -r "${DEPS_DIR}/agent-browser-repo/skills/agent-browser" \
                "${DEPS_DIR}/agent-browser-skills"
            run cp -r "${DEPS_DIR}/agent-browser-repo/skill-data/core" \
                "${DEPS_DIR}/agent-browser-skilldata"
            rm -rf "${DEPS_DIR}/agent-browser-repo"
        fi
    fi

    ok "External skills cloned to _deps/"
}

# ─── Install Agent-Browser ─────────────────────────────────────────
install_agent_browser() {
    if $NO_BROWSER; then
        debug "Skipping agent-browser (--no-browser)"
        return 0
    fi

    info "Installing agent-browser..."
    run npm install -g agent-browser@latest

    info "Installing Chrome for Testing..."
    if $IS_MACOS; then
        run agent-browser install
    else
        run agent-browser install --with-deps || run agent-browser install
    fi
    ok "agent-browser + Chrome installed"
}

# ─── Adapt Config for Environment ──────────────────────────────────
adapt_config() {
    local config="${OPENCODE_HOME}/opencode.jsonc"
    [ -f "$config" ] || return 0

    info "Adapting config for environment..."

    # Replace __HOME__ placeholder with actual home
    if ! $DRY_RUN; then
        local home_escaped
        home_escaped="$(echo "$HOME" | sed 's/[\/&]/\\&/g')"
        sed -i "s|__HOME__|${home_escaped}|g" "$config" 2>/dev/null || true
    fi

    # Container + agent-browser → add no-sandbox flag
    if $IS_CONTAINER && ! $NO_BROWSER; then
        if ! $DRY_RUN; then
            sed -i '/"agent-browser": {/,/}/ {
                /"enabled": true/a\      "environment": { "AGENT_BROWSER_ARGS": "--no-sandbox" }
            }' "$config" 2>/dev/null || true
        fi
        ok "Added --no-sandbox for container environment"
    fi

    # --no-browser → swap agent-browser MCP for Playwright (headless)
    if $NO_BROWSER; then
        if ! $DRY_RUN; then
            sed -i 's|"agent-browser": {|"playwright": {|' "$config"
            sed -i 's|"command": \["agent-browser", "mcp", "--tools", "core"\]|"command": ["npx", "-y", "@playwright/mcp@latest", "--browser", "chrome", "--headless"]|' "$config"
            sed -i '/AGENT_BROWSER_ARGS/d' "$config"
        fi
        ok "MCP agent-browser → playwright"
    fi

    # --no-notificator → remove notificator plugin entry
    if $NO_NOTIFICATOR; then
        if ! $DRY_RUN; then
            sed -i '/opencode-notificator/d' "$config"
        fi
    fi

    # --no-plugins → remove npm plugin entries
    if $NO_PLUGINS; then
        if ! $DRY_RUN; then
            sed -i '/opencode-gemini-auth@latest/d' "$config"
            sed -i '/@tarquinen\/opencode-dcp@latest/d' "$config"
            sed -i '/opencode-vibeguard@latest/d' "$config"
        fi
    fi

    # --no-skills → remove _deps skill paths
    if $NO_SKILLS; then
        if ! $DRY_RUN; then
            sed -i '/_deps/d' "$config"
        fi
    fi

    # Safety net: repair dangling commas left by removals (multi-line, portable)
    if ! $DRY_RUN; then
        perl -0777 -pi -e 's/,\s*([\]}])/$1/g' "$config"
    fi

    ok "Config adapted"
}

# ─── Deploy Templates ──────────────────────────────────────────────
deploy_templates() {
    if $NO_TEMPLATES; then
        debug "Skipping templates (--no-templates)"
        return 0
    fi

    if [ ! -d "$TEMPLATES_DIR" ]; then
        debug "No templates directory found"
        return 0
    fi

    local dest="${HOME}/opencode-ecosystem/templates"
    info "Deploying project templates → $dest"
    mkdir -p "$dest"
    run cp -r "${TEMPLATES_DIR}/ts-react" "$dest/"
    run cp -r "${TEMPLATES_DIR}/python" "$dest/"
    ok "Templates: $dest/ts-react, $dest/python"
}

# ─── Validate ──────────────────────────────────────────────────────
validate_install() {
    info "Validating installation..."

    # Config parse check
    if command -v opencode >/dev/null 2>&1; then
        if ! $DRY_RUN; then
            if opencode debug config >/dev/null 2>&1; then
                ok "Config validates OK"
            else
                warn "Config may have issues — check 'opencode debug config'"
            fi
        fi
    fi

    # MCP check
    if command -v opencode >/dev/null 2>&1; then
        if ! $DRY_RUN; then
            local mcp_out
            mcp_out="$(opencode mcp list 2>&1)" || true
            local count
            count="$(echo "$mcp_out" | grep -c '✓' || true)"
            ok "MCP servers connected: $count"
        fi
    fi

    # File counts
    local agents commands skills
    agents="$(find "${OPENCODE_HOME}/agent" -name '*.md' 2>/dev/null | wc -l)"
    commands="$(find "${OPENCODE_HOME}/command" -name '*.md' 2>/dev/null | wc -l)"
    skills="$(find "${OPENCODE_HOME}/skills" -name 'SKILL.md' 2>/dev/null | wc -l)"
    ok "Deployed: ${agents} agents, ${commands} commands, ${skills} skills"
}

# ─── Print Success ─────────────────────────────────────────────────
print_success() {
    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║     setup-opencode — Setup Complete! 🎉     ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Installed:${NC}"
    echo -e "    • 5 MCP servers  (context7, gh_grep, agent-browser/filesystem, memory)"
    echo -e "    • 6 agents       (reviewer, security, test-writer, docs-writer, docker-ops, architect)"
    echo -e "    • 7 commands     (/commit, /review, /test, /security, /explain, /refactor, /release)"
    echo -e "    • 10+ skills     (git, code-review, security, testing, TS/React, Python...)"
    $NO_PLUGINS   || echo -e "    • 3 plugins     (gemini-auth, dcp, vibeguard)"
    $NO_NOTIFICATOR || echo -e "    • 1 plugin      (notificator — desktop notifications)"
    $NO_BROWSER   || echo -e "    • agent-browser  (Chrome for Testing)"
    $NO_SKILLS     || echo -e "    • 19+ external   (anthropics/skills, agent-browser skills)"
    $NO_TEMPLATES  || echo -e "    • templates      (TypeScript/React, Python)"
    echo ""
    echo -e "  ${BOLD}Next steps:${NC}"
    echo -e "    1. ${CYAN}opencode auth login${NC} — Login GitHub Copilot (free) + Google Gemini (free)"
    echo -e "    2. ${CYAN}opencode${NC} — Launch TUI"
    echo -e "    3. ${CYAN}/models${NC} — Pick your model (defaults to opencode/big-pickle)"
    echo -e "    4. Restart opencode after model changes"
    echo ""
    echo -e "  ${BOLD}Free providers:${NC}"
    echo -e "    • ${GREEN}opencode/big-pickle${NC} — Works right now, no login needed"
    echo -e "    • ${GREEN}GitHub Copilot${NC} — Device flow, free tier (Claude/GPT models)"
    echo -e "    • ${GREEN}Google Gemini${NC} — OAuth free plan"
    echo ""
    echo -e "  ${BOLD}Docs:${NC} https://opencode.ai/docs"
    echo -e "  ${BOLD}Report issues:${NC} https://github.com/kiraadityaa/setup-opencode/issues"
    echo ""
}

# ─── Main ──────────────────────────────────────────────────────────
main() {
    parse_args "$@"

    echo ""
    echo -e "${BOLD}setup-opencode${NC} — One-command setup for OpenCode AI agent"
    echo -e "${CYAN}https://github.com/kiraadityaa/setup-opencode${NC}"
    echo ""

    if $UNINSTALL; then
        do_uninstall
    fi

    preflight
    install_opencode
    resolve_payload_dir
    backup_existing
    deploy_payload
    install_plugins
    clone_external_skills
    install_agent_browser
    adapt_config
    deploy_templates
    validate_install
    print_success
}

main "$@"
