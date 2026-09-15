# setup-opencode

One-command setup for a fully-featured [OpenCode](https://opencode.ai) AI coding agent environment.

## What it installs

| Component | Details | Cost |
|---|---|---|
| **5 MCP servers** | context7, gh_grep, agent-browser, filesystem, memory | Free |
| **3 npm plugins** | gemini-auth, dynamic context pruning, vibeguard | Free |
| **6 agents** | reviewer, security, test-writer, docs-writer, docker-ops, architect | Free |
| **7 commands** | /commit, /review, /test, /security, /explain, /refactor, /release | Free |
| **10 skills** | git, code-review, security, testing, TS/React, Python, SQL, docs | Free |
| **Notificator** | Desktop notification plugin (audio + system) | Free |
| **Project templates** | TypeScript/React, Python | Free |
| **shell-strategy** | Command shell context optimization | Free |
| **agent-browser** | Browser automation via Chrome for Testing | Free |

**Total cost: $0.00. No API keys required to start.**

## Quick start

```bash
git clone https://github.com/kiraadityaa/setup-opencode.git
cd setup-opencode
./setup.sh
```

Or without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/kiraadityaa/setup-opencode/main/setup.sh | bash
```

## What it does NOT do

- **No API keys** — You run `opencode auth login` after setup (GitHub Copilot + Gemini are free)
- **No project changes** — Only touches `~/.config/opencode/` (backs up existing config first)
- **No paid services** — Everything uses free tiers and free models

## Flags

| Flag | Default | Description |
|---|---|---|
| `--no-browser` | — | Skip agent-browser + Chrome (~200MB) |
| `--no-notificator` | — | Skip desktop notification plugin |
| `--no-plugins` | — | Skip all npm plugin installs |
| `--no-skills` | — | Skip external skill repo clones |
| `--no-templates` | — | Skip project template deployment |
| `--force` | — | Overwrite existing config (backup first) |
| `--dry-run` | — | Preview what will happen without changes |
| `--verbose` | — | Show all commands being run |
| `--uninstall` | — | Remove all setup-opencode files |

Examples:

```bash
# Full install (recommended)
./setup.sh

# Minimal — no browser, no plugins
./setup.sh --no-browser --no-plugins

# Preview without making changes
./setup.sh --dry-run --verbose

# Reinstall (backup existing first)
./setup.sh --force

# Remove everything
./setup.sh --uninstall
```

## Requirements

- macOS, Linux, or Windows (WSL only)
- `bash`, `curl`, `git` (required)
- Node.js v18+ (will be installed via nvm if missing)
- Optional: GitHub account for Copilot free auth
- Optional: Google account for Gemini free auth

## Environment detection

The installer automatically detects and adapts to:

| Environment | Adaptation |
|---|---|
| Docker/container | Adds `--no-sandbox` to agent-browser |
| macOS | Uses appropriate package manager |
| No Node.js | Installs via nvm |
| Piped install | Downloads tarball from GitHub |

## After setup

```bash
# 1. Login to free providers
opencode auth login

# 2. Launch OpenCode
opencode

# 3. Pick your model (after auth)
/models

# 4. Restart opencode
```

### Free model providers

| Provider | Auth method | Models |
|---|---|---|
| **OpenCode default** | None (works immediately) | opencode/big-pickle, opencode/mimo-v2.5-free |
| **GitHub Copilot** | Device flow (`opencode auth login`) | Claude Sonnet/Opus, GPT-4o |
| **Google Gemini** | OAuth (`opencode auth login`) | Gemini 2.5 Pro |

## Uninstall

```bash
./setup.sh --uninstall
# or manually:
rm -rf ~/.config/opencode
```

## Project structure

```
setup-opencode/
├── setup.sh              # Main installer (~400 lines)
├── payload/
│   ├── opencode.jsonc    # Config template
│   ├── agent/            # 6 agent definitions
│   ├── command/          # 7 command definitions
│   ├── instructions/     # shell-strategy.md
│   ├── plugins/          # notificator (local)
│   └── skills/           # 10 custom skills
├── templates/            # Project starters
│   ├── ts-react/
│   └── python/
└── .github/workflows/    # CI: shellcheck + validation
```

## Contributing

Contributions welcome! Please run `shellcheck setup.sh` before submitting PRs.

## License

MIT — see [LICENSE](LICENSE).

## Credits

Built on top of these open-source projects:

- [OpenCode](https://opencode.ai) — The AI coding agent
- [context7 MCP](https://context7.com) — Library docs MCP
- [grep.app MCP](https://mcp.grep.app) — GitHub code search
- [agent-browser](https://github.com/vercel-labs/agent-browser) — Browser automation
- [opencode-dcp](https://github.com/Opencode-DCP/opencode-dynamic-context-pruning) — Context pruning
- [opencode-shell-strategy](https://github.com/JRedeker/opencode-shell-strategy) — Shell context
- [opencode-notificator](https://github.com/panta82/opencode-notificator) — Desktop notifications
- [opencode-vibeguard](https://github.com/inkdust2021/opencode-vibeguard) — Safety guard
- [opencode-gemini-auth](https://github.com/jenslys/opencode-gemini-auth) — Free Gemini auth
