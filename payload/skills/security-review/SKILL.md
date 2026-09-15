---
name: security-review
description: Use when auditing code or repos for vulnerabilities, secrets, or insecure configuration. Triggers on "security", "audit", "vulnerability", "secrets", "CVE", "pentest".
---

# Security Review

Hunt for security weaknesses methodically.

## Scan checklist

- **Secrets**: hardcoded API keys, tokens, passwords, private keys, connection strings, `.env` committed to git. Check history too: `git log -p --all`.
- **Injection**: SQL, command, template, XSS, file inclusion. Trace user input to sinks.
- **Auth**: weak passwords, missing rate limits, insecure session handling, missing authorization checks, JWT/HS256 vs RS256 mistakes.
- **Deserialization / parsing**: unsafe `pickle`, `eval`, `yaml.load`, protobuf, XML entity expansion (XXE).
- **Filesystem**: path traversal, symlink attacks, insecure temp files, directory listing.
- **Network**: SSRF, open redirects, missing TLS, permissive CORS, cleartext transport.
- **Dependencies**: known CVEs, outdated packages, `latest`/`*` ranges, lockfile hygiene.
- **Infra/CI**: default credentials, too-broad IAM, exposed ports, privileged containers, secrets in pipeline logs.

## Reporting

- Rank: critical → high → medium → low → info.
- Each finding: `file:line`, impact, and a concrete fix.
- **Never modify files during an audit** unless explicitly asked.