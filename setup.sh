#!/usr/bin/env bash
#
# setup-opencode — One-command setup for OpenCode AI coding agent
# https://github.com/kiraadityaa/setup-opencode
#
set -euo pipefail

# ─── Defaults ──────────────────────────────────────────────────────
REPO_URL="https://github.com/kiraadityaa/setup-opencode"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="${SCRIPT_DIR}/VERSION"
VERSION="$(cat "${VERSION_FILE}" 2>/dev/null || echo "0.0.0")"
[ -n "${VERSION}" ] || VERSION="0.0.0"
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

STEP_N=0
STEP_TOTAL=0
START_TS=""
SPIN_MODE=none
SPIN_PID=""

# ─── Design system ─────────────────────────────────────────────────
# Color is signal, never decoration. Tokens are empty when stdout is not
# a TTY, NO_COLOR is set, or TERM is dumb — so piped installs and CI logs
# stay free of stray escape codes. FORCE_COLOR=1 opts back in (demo GIFs).
ACCENT=''
OK=''
WARN=''
ALARM=''
MUTED=''
BOLD=''
NC=''

TTY_OUT=false
if [[ -t 1 ]]; then TTY_OUT=true; fi

USE_COLOR=false
if $TTY_OUT && [[ -z "${NO_COLOR:-}" ]] && [[ "${TERM:-dumb}" != dumb ]]; then
    USE_COLOR=true
fi
if [[ "${FORCE_COLOR:-0}" == "1" ]]; then
    USE_COLOR=true
fi

setup_colors() {
    if $USE_COLOR; then
        ACCENT='\033[0;36m'
        OK='\033[0;32m'
        WARN='\033[1;33m'
        ALARM='\033[0;31m'
        MUTED='\033[2;90m'
        BOLD='\033[1m'
        NC='\033[0m'
    fi

    COLS="$(tput cols 2>/dev/null || echo 80)"
    case "${COLS:-0}" in
        ''|*[!0-9]*|0) COLS=80 ;;
    esac
    if [ "$COLS" -lt 68 ]; then COLS=68; fi
    if [ "$COLS" -gt 220 ]; then COLS=220; fi
    return 0
}

# ─── Layout primitives ─────────────────────────────────────────────
# A single grammar — panel borders, step rules, status lines mirror the
# same rail so the whole installer reads as one instrument.
dashes() { printf '%*s' "$1" '' | sed 's/ /─/g'; }

panel_open() { # panel_open [title]
    local title="${1:-}"
    if [ -n "$title" ]; then
        local pad=$(( COLS - 8 - ${#title} ))
        [ "$pad" -lt 0 ] && pad=0
        echo -e "${ACCENT}╭── ${title} $(dashes "$pad")──╮${NC}"
    else
        echo -e "${ACCENT}╭$(dashes "$(( COLS - 2 ))")╮${NC}"
    fi
}

panel_line() { # panel_line <text>
    local text="$1" len=${#1} pad
    local w=$(( COLS - 4 ))
    if [ "$len" -gt "$w" ]; then
        text="${text:0:$w}"
        len=$w
    fi
    pad=$(( w - len ))
    echo -e "${ACCENT}│${NC} ${text}${MUTED}$(printf '%*s' "$pad" '')${NC} ${ACCENT}│${NC}"
}

panel_close() {
    echo -e "${ACCENT}╰$(dashes "$(( COLS - 2 ))")╯${NC}"
}

step() { # step <title>
    local title="$1"
    STEP_N=$((STEP_N + 1))
    local tag="[ ${STEP_N}/${STEP_TOTAL} ]"
    local head="── ${tag} ${title}"
    local fill=$(( COLS - 5 - ${#head} ))
    [ "$fill" -lt 0 ] && fill=0
    echo ""
    echo -e "  ${ACCENT}──${NC} ${BOLD}${tag}${NC} ${ACCENT}${title}${NC} ${MUTED}$(dashes "$fill")${NC} ${ACCENT}●${NC}"
}

# ─── Status lines ──────────────────────────────────────────────────
info()  { echo -e "  ${ACCENT}▸${NC} $*"; }
muted() { echo -e "  ${MUTED}$*${NC}"; }
ok()    { echo -e "  ${OK}✓${NC} $*"; }
warn()  { echo -e "  ${WARN}⚠${NC} $*"; }
err()   { echo -e "  ${ALARM}✗${NC} $*" >&2; }
debug() { if $VERBOSE; then echo -e "  ${MUTED}[debug]${NC} $*"; fi; }

die() {
    err "$@"
    kill_spinner
    if [ -n "$START_TS" ]; then
        echo -e "  ${MUTED}Aborted after $(elapsed_time)${NC}" >&2
    fi
    echo -e "  ${MUTED}Tip: re-run with --verbose to see each command${NC}" >&2
    exit 1
}

confirm() {
    local msg="${1:-Continue?}"
    if $DRY_RUN; then return 0; fi
    read -rp "$(echo -e "  ${WARN}?${NC} ${msg} [y/N] ")" answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

run() {
    if $DRY_RUN; then
        echo -e "  ${MUTED}[dry-run]${NC} $*"
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

# ─── Timing ────────────────────────────────────────────────────────
elapsed_time() {
    if [ -z "$START_TS" ]; then echo "0s"; return 0; fi
    local now diff m s
    now="$(date +%s)"
    diff=$(( now - START_TS ))
    m=$(( diff / 60 ))
    s=$(( diff % 60 ))
    if [ "$m" -gt 0 ]; then printf "%dm %ds" "$m" "$s"; else printf "%ds" "$s"; fi
}

# ─── Spinner ───────────────────────────────────────────────────────
SPINNER_CHARS=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

spinner_start() { # spinner_start <label>
    SPIN_MSG="$1"
    if $DRY_RUN; then
        SPIN_MODE=none
        return 0
    fi
    if ! $TTY_OUT; then
        SPIN_MODE=plain
        echo -e "  ${MUTED}${SPIN_MSG}…${NC}"
        return 0
    fi
    SPIN_MODE=anim
    local i=0
    echo -e "  ${ACCENT}⠋${NC} ${SPIN_MSG}…"
    (
        while :; do
            printf "\r  ${ACCENT}%s${NC} ${SPIN_MSG}…" "${SPINNER_CHARS[$((i % 10))]}"
            i=$((i + 1))
            sleep 0.08
        done
    ) &
    SPIN_PID=$!
}

spinner_stop() { # spinner_stop <ok|warn|fail> <msg>
    local status="$1" msg="$2"
    if [ "$SPIN_MODE" = anim ]; then
        if [ -n "$SPIN_PID" ]; then
            kill "$SPIN_PID" 2>/dev/null || true
            wait "$SPIN_PID" 2>/dev/null || true
        fi
        printf "\r%*s\r" "$COLS" ''
    fi
    SPIN_MODE=none
    SPIN_PID=""
    case "$status" in
        warn) echo -e "  ${WARN}⚠${NC} ${msg}" ;;
        fail) echo -e "  ${ALARM}✗${NC} ${msg}" ;;
        *)    echo -e "  ${OK}✓${NC} ${msg}" ;;
    esac
}

kill_spinner() {
    if [ "$SPIN_MODE" = anim ] && [ -n "$SPIN_PID" ]; then
        kill "$SPIN_PID" 2>/dev/null || true
        wait "$SPIN_PID" 2>/dev/null || true
        printf "\r%*s\r" "$COLS" ''
        SPIN_MODE=none
        SPIN_PID=""
    fi
}

# ─── Banner ────────────────────────────────────────────────────────
print_banner() {
    echo ""
    panel_open "setup-opencode  v${VERSION}"
    panel_line ""
    panel_line "One-command setup for OpenCode AI coding agent"
    panel_line ""
    panel_line "https://github.com/kiraadityaa/setup-opencode"
    panel_close
    echo ""
}

# ─── Install plan ─────────────────────────────────────────────────
preview_plan() {
    if ! $TTY_OUT; then return 0; fi
    local on="  ${OK}●${NC}" off="  ${MUTED}○${NC}"
    echo -e "  ${BOLD}Will install:${NC}"
    echo ""
    echo -e "${on} OpenCode CLI — config, 6 agents, 7 commands, 23 skills"
    echo -e "${on} MCP servers — context7, gh_grep, filesystem, memory,"
    echo -e "    chrome-devtools, sequential-thinking"
    if $NO_BROWSER; then
        echo -e "${off} agent-browser + Chrome for Testing (headless Playwright instead)"
    else
        echo -e "${on} agent-browser + Chrome for Testing"
    fi
    if $NO_SKILLS; then
        echo -e "${off} external skills (anthropics/skills, agent-browser)"
    else
        echo -e "${on} external skills (anthropics/skills, agent-browser)"
    fi
    if $NO_PLUGINS; then
        echo -e "${off} npm plugins (gemini-auth, dcp, vibeguard)"
    else
        echo -e "${on} npm plugins (gemini-auth, dcp, vibeguard)"
    fi
    if $NO_NOTIFICATOR; then
        echo -e "${off} notificator plugin (desktop notifications)"
    else
        echo -e "${on} notificator plugin (desktop notifications)"
    fi
    if $NO_TEMPLATES; then
        echo -e "${off} project templates (TypeScript/React, Python)"
    else
        echo -e "${on} project templates (TypeScript/React, Python)"
    fi
    echo ""
}

# ─── Parse Args ────────────────────────────────────────────────────
usage() {
    echo ""
    echo -e "  ${BOLD}setup-opencode${NC}${MUTED} — One-command setup for the OpenCode AI coding agent${NC}"
    echo ""
    echo -e "  ${ACCENT}Usage:${NC}  bash setup.sh [OPTIONS]"
    echo ""
    echo -e "  ${BOLD}Component selection${NC}"
    printf "    %-24s %s\n" "--no-browser"     "Skip agent-browser + Chrome install"
    printf "    %-24s %s\n" "--no-notificator" "Skip the desktop notification plugin"
    printf "    %-24s %s\n" "--no-plugins"     "Skip all npm plugin installs"
    printf "    %-24s %s\n" "--no-skills"      "Skip external skill repo clones"
    printf "    %-24s %s\n" "--no-templates"   "Skip project template deployment"
    echo ""
    echo -e "  ${BOLD}Execution control${NC}"
    printf "    %-24s %s\n" "--dry-run"   "Preview every action without changing anything"
    printf "    %-24s %s\n" "--force"     "Overwrite existing config (backup created first)"
    printf "    %-24s %s\n" "--uninstall" "Remove all setup-opencode files"
    printf "    %-24s %s\n" "--verbose"   "Show every command as it runs"
    printf "    %-24s %s\n" "--version"   "Print the installer version"
    printf "    %-24s %s\n" "--help"      "Show this help"
    echo ""
    echo -e "  ${BOLD}Examples${NC}"
    printf "    %-46s %s\n" "bash setup.sh"                              "Full install (recommended)"
    printf "    %-46s %s\n" "bash setup.sh --no-browser --no-plugins"   "Minimal — no browser, no plugins"
    printf "    %-46s %s\n" "bash setup.sh --dry-run --verbose"         "Preview everything without changes"
    printf "    %-46s %s\n" "bash setup.sh --force"                     "Reinstall, backing up existing config"
    printf "    %-46s %s\n" "bash setup.sh --uninstall"                 "Remove everything"
    echo ""
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
            --version|-V)      echo "setup-opencode ${VERSION}" && exit 0 ;;
            --help|-h)         usage ;;
            *)                 die "Unknown option: $1 (use --help)" ;;
        esac
        shift
    done
}

# ─── Uninstall ─────────────────────────────────────────────────────
do_uninstall() {
    echo ""
    panel_open "uninstall"
    panel_line "Removing agents, commands, skills, instructions, plugins,"
    panel_line "deps, and templates…"
    panel_close
    echo ""
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
    debug "Checking prerequisites..."

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
    # opencode is looked up on PATH or in its documented install location
    find_opencode() {
        command -v opencode 2>/dev/null \
            || { [ -x "$HOME/.opencode/bin/opencode" ] && echo "$HOME/.opencode/bin/opencode"; } \
            || true
    }

    local found
    found="$(find_opencode)"
    if [ -n "$found" ]; then
        local ver
        ver="$("$found" --version 2>/dev/null || echo 'unknown')"
        ok "OpenCode already installed ($ver)"
        return 0
    fi

    spinner_start "Installing OpenCode"
    if $DRY_RUN; then
        echo "  ${MUTED}[dry-run]${NC} curl -fsSL https://opencode.ai/install | bash"
        return 0
    fi

    local attempt
    for attempt in 1 2 3; do
        if curl -fsSL https://opencode.ai/install | bash; then
            found="$(find_opencode)"
            if [ -n "$found" ]; then
                # Register for the rest of this session too (not just $GITHUB_PATH)
                local dir
                dir="$(dirname "$found")"
                case ":$PATH:" in
                    *":${dir}:"*) ;;
                    *) export PATH="${dir}:${PATH}" ;;
                esac
                spinner_stop ok "OpenCode installed"
                return 0
            fi
        fi
        warn "Attempt ${attempt}/3 failed — retrying in 3s..."
        sleep 3
    done
    die "Failed to install OpenCode after 3 attempts"
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
    return 0
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
    if $DRY_RUN; then
        echo "  ${MUTED}[dry-run]${NC} curl ${REPO_URL}/archive/refs/heads/main.tar.gz | tar xz"
        return 0
    fi
    local tmpdir
    tmpdir="$(mktemp -d)"
    spinner_start "Downloading payload from GitHub"
    curl -fsSL "${REPO_URL}/archive/refs/heads/main.tar.gz" \
        | tar xz -C "$tmpdir" --strip-components=1
    spinner_stop ok "Downloaded to $tmpdir"
    PAYLOAD_DIR="${tmpdir}/payload"
    TEMPLATES_DIR="${tmpdir}/templates"
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
        spinner_start "npm install -g ${pkg}"
        run npm install -g "$pkg"
        spinner_stop ok "installed ${pkg}"
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
        spinner_start "Cloning anthropics/skills"
        run git clone --depth 1 https://github.com/anthropics/skills.git \
            "${DEPS_DIR}/anthropic-skills"
        spinner_stop ok "anthropics/skills cloned"
    fi

    # agent-browser skills
    if [ ! -d "${DEPS_DIR}/agent-browser-skills" ]; then
        debug "  git clone agent-browser (skills)"
        spinner_start "Cloning agent-browser skills"
        run git clone --depth 1 https://github.com/vercel-labs/agent-browser.git \
            "${DEPS_DIR}/agent-browser-repo"
        if ! $DRY_RUN; then
            if [ -d "${DEPS_DIR}/agent-browser-repo/skills/agent-browser" ]; then
                run cp -r "${DEPS_DIR}/agent-browser-repo/skills/agent-browser" \
                    "${DEPS_DIR}/agent-browser-skills"
            fi
            if [ -d "${DEPS_DIR}/agent-browser-repo/skill-data/core" ]; then
                run cp -r "${DEPS_DIR}/agent-browser-repo/skill-data/core" \
                    "${DEPS_DIR}/agent-browser-skilldata"
            fi
            rm -rf "${DEPS_DIR}/agent-browser-repo"
        fi
        spinner_stop ok "agent-browser skills cloned"
    fi

    ok "External skills cloned to _deps/"
}

# ─── Install Agent-Browser ─────────────────────────────────────────
install_agent_browser() {
    if $NO_BROWSER; then
        debug "Skipping agent-browser (--no-browser)"
        return 0
    fi

    spinner_start "npm install -g agent-browser"
    run npm install -g agent-browser@latest
    spinner_stop ok "agent-browser installed"

    info "Installing Chrome for Testing..."
    spinner_start "agent-browser install"
    if $IS_MACOS; then
        run agent-browser install
    else
        run agent-browser install --with-deps || run agent-browser install
    fi
    spinner_stop ok "Chrome for Testing installed"
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

    # --no-browser → swap agent-browser MCP for Playwright (headless)
    if $NO_BROWSER; then
        if ! $DRY_RUN; then
            sed -i 's|"agent-browser": {|"playwright": {|' "$config"
            sed -i 's|"command": \["agent-browser", "mcp", "--tools", "core"\]|"command": ["npx", "-y", "@playwright/mcp@latest", "--browser", "chrome", "--headless"]|' "$config"
            # Drop the baked-in --no-sandbox comment block + environment (Playwright manages its own flags)
            sed -i "/^      \/\/ Chrome can't init its sandbox/,/^      },$/d" "$config"
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
    local dur
    dur="$(elapsed_time)"
    echo ""
    panel_open "setup complete"
    panel_line ""
    panel_line "  INSTALLED"
    panel_line "    •  7 MCP servers    context7, gh_grep, agent-browser,"
    panel_line "                         filesystem, memory, chrome-devtools,"
    panel_line "                         sequential-thinking"
    panel_line "    •  6 agents         architect, docker-ops, docs-writer,"
    panel_line "                         reviewer, security, test-writer"
    panel_line "    •  7 commands       /commit  /review  /test  /security"
    panel_line "                         /explain  /refactor  /release"
    panel_line "    • 23 skills        10 workspace + 13 design-taste"
    if ! $NO_PLUGINS; then
        panel_line "    •  3 plugins        gemini-auth, dcp, vibeguard"
    fi
    if ! $NO_NOTIFICATOR; then
        panel_line "    •  1 plugin         notificator — desktop notifications"
    fi
    if ! $NO_BROWSER; then
        panel_line "    •  agent-browser   + Chrome for Testing"
    fi
    if ! $NO_SKILLS; then
        panel_line "    • 19+ external     anthropics/skills, agent-browser skills"
    fi
    if ! $NO_TEMPLATES; then
        panel_line "    •  templates      TypeScript/React, Python"
    fi
    panel_line ""
    panel_line "  NEXT STEPS"
    panel_line "    1. opencode auth login   add free GitHub Copilot + Google Gemini"
    panel_line "    2. opencode              launch the TUI"
    panel_line "    3. /models               pick your model (big-pickle default)"
    panel_line "    4. restart opencode after model changes"
    panel_line ""
    panel_line "  FREE PROVIDERS"
    panel_line "    • opencode/big-pickle   works right now, no login needed"
    panel_line "    • GitHub Copilot        device flow, free tier"
    panel_line "    • Google Gemini         OAuth, free plan"
    panel_line ""
    panel_line "  Docs            https://opencode.ai/docs"
    panel_line "  Report issues   https://github.com/kiraadityaa/setup-opencode/issues"
    panel_close
    echo ""
    echo -e "  ${OK}✓${NC} ${BOLD}Setup complete in ${dur}${NC}"
    echo ""
}

# ─── Main ──────────────────────────────────────────────────────────
main() {
    setup_colors
    trap kill_spinner EXIT

    parse_args "$@"

    if $UNINSTALL; then
        do_uninstall
    fi

    print_banner

    if ! $UNINSTALL; then
        preview_plan
    fi

    START_TS="$(date +%s)"
    STEP_TOTAL=11
    STEP_N=0

    step "Preflight checks"
    preflight
    step "Install OpenCode"
    install_opencode
    step "Resolve payload"
    resolve_payload_dir
    step "Backup existing config"
    backup_existing
    step "Deploy config"
    deploy_payload
    step "Install npm plugins"
    install_plugins
    step "Clone external skills"
    clone_external_skills
    step "Install agent-browser"
    install_agent_browser
    step "Adapt config for environment"
    adapt_config
    step "Deploy templates"
    deploy_templates
    step "Validate installation"
    validate_install
    print_success
}

main "$@"