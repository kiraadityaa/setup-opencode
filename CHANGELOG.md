# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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