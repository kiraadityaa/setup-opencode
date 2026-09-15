# Security Policy

We take the security of setup-opencode seriously. The installer downloads and
executes scripts on your machine, so any vulnerability must be handled
responsibly.

## Reporting a vulnerability

**Please do not open a public issue for security vulnerabilities.**

Report security issues privately via GitHub's private vulnerability reporting
(on the repo's *Security* tab) or by emailing the project owner. Include:

- Repository URL and version (`setup.sh --version`)
- OS, architecture, and `uname -a`
- Environment the issue was found in (container, WSL, macOS)
- Minimal reproduction steps

You should receive a response within 5 business days.

## Scope

Issues that matter most to us:

- Anything in `setup.sh` that could lead to code execution without consent
  (e.g. dependency confusion, GitHub URL/redirect tampering)
- Traversal or overwrite of files outside `~/.config/opencode` during payload
  deployment
- Unsafe handling of `__HOME__` substitution or sed/perl repair logic

## Supported versions

The latest release on `main` is the only supported version. Releases are
tagged `v*` on GitHub and validated by CI.