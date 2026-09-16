---
name: commit-conventions
description: Use when writing or suggesting git commit messages. Triggers on "commit", "commit message", "conventional commit", "semantic versioning".
---

# Conventional Commits

Write commit messages using the Conventional Commits format:

```
<type>(<scope>): <subject>
```

- **type**: `feat` | `fix` | `docs` | `style` | `refactor` | `perf` | `test` | `build` | `ci` | `chore`
- **scope** (optional): the area affected, e.g. `auth`, `api`, `ui`
- **subject**: imperative mood, lowercase, under 72 chars, no trailing period

Guidelines:

- One logical change per commit.
- Breaking changes: add `!` after type/scope or a footer `BREAKING CHANGE:`.
- Add a body when the why matters (referencing issues like `Refs #123` or `Closes #456`).
- Relate commits to semantic versioning: `feat` → minor, `fix` → patch, breaking → major.

Examples:

- `feat(auth): add refresh token rotation`
- `fix(api): return 404 for unknown resource ids`
- `chore: bump dev dependencies`
- `refactor(db): extract connection pool helper`