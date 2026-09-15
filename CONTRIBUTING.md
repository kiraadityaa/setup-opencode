# Contributing to setup-opencode

Thanks for wanting to improve setup-opencode! Here's how to get started.

## Development setup

```bash
git clone https://github.com/kiraadityaa/setup-opencode.git
cd setup-opencode
shellcheck -x -s bash setup.sh
```

## Testing your changes

Before opening a PR, run:

```bash
./setup.sh --dry-run                  # Preview everything
./setup.sh --version                  # Verify version flag works
shellcheck -x -s bash setup.sh        # Static analysis (must be clean)
```

Payload changes are validated by CI (file counts + JSONC syntax), but you can
check locally too:

```bash
# Validate opencode.jsonc parses
sed 's|^[[:space:]]*//.*$||' payload/opencode.jsonc | \
  sed 's/,\s*\]/]/g; s/,\s*\}/}/g' | grep -v '^\s*$' | python3 -m json.tool
```

## What counts as a good PR

- One logical change per PR.
- No emoji in user-facing docs or scripts.
- `setup.sh` stays compatible with the `--no-*` flags (each component is optional).
- README flags table updated if you touch setup.sh flags.
- `VERSION` bumped only in release PRs, not feature PRs.

## Where things live

| Path | Purpose |
|---|---|
| `setup.sh` | Entry point: parse flags, preflight, deploy, validate |
| `payload/` | Config copied verbatim into `~/.config/opencode/` |
| `templates/` | New project starters (`ts-react`, `python`) |
| `assets/` | README images: `demo.gif`, `og-image.png` |
| `.github/workflows/` | CI, validation, release automation |

## Reporting bugs

Open an issue with the environment info the script prints on preflight
(OS, arch, node version) plus the flags you used. See
[SECURITY.md](SECURITY.md) for vulnerability reports.

## Code of conduct

All contributions are governed by our
[Code of Conduct](CODE_OF_CONDUCT.md). Be kind, assume good intent.