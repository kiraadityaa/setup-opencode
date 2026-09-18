# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Vendored the 13-skill [taste-skill](https://github.com/leonxlnx/taste-skill)
  suite (MIT) into `payload/skills/` — design-taste-frontend, industrial-brutalist-ui,
  minimalist-ui, high-end-visual-design, redesign-existing-projects, stitch-design-taste,
  full-output-enforcement, gpt-taste, image-to-code, imagegen-frontend-web,
  imagegen-frontend-mobile, brandkit, design-taste-frontend-v1. Skill count 10 → 23.

### Fixed

- agent-browser MCP crashed with "No usable sandbox" on Linux containers, WSL, VMs,
  and CI runners because the `--no-sandbox` flag was only injected when the installer
  detected a container. The `AGENT_BROWSER_ARGS=--no-sandbox` environment is now baked
  into the payload config unconditionally (see the `agent-browser` entry in
  `payload/opencode.jsonc`). With `--no-browser`, the environment block is dropped while
  swapping to the headless Playwright MCP.

Changelog is generated automatically from `main` when a `v*` tag is pushed —
see [.github/workflows/release.yml](.github/workflows/release.yml).

## [0.1.0] - 2026-09-15

### Added

- Reference release point for the professionalization update (this tag).
- Versioned installer: `VERSION` file + `./setup.sh --version`.
- GitHub Release automation on tagged pushes.
- Community files: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`,
  `FUNDING.yml`, Dependabot, issue/PR templates.
- CI integration job that runs the real installer in a disposable environment.