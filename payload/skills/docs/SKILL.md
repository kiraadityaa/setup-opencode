---
name: docs
description: Use when creating or updating documentation — README, API docs, guides, comments, changelog. Triggers on "documentation", "docs", "README", "write docs", "changelog".
---

# Writing Documentation

Write documentation that stays true after the code changes.

## Principles

- **Accuracy > completeness.** Verify commands, flags, and APIs in the actual codebase before writing them. If uncertain, mark as unverified.
- Understand the audience: quick-start for beginners, reference for power users, architecture notes for maintainers.
- Show, don't tell: prefer working examples over prose. Every snippet should be copy-paste runnable.
- Structure with short paragraphs and headings; let readers scan.

## README skeleton

1. One-line description + badges if the repo uses them.
2. Quick start: install → configure → run → verify.
3. Configuration reference (env vars, flags, defaults).
4. Usage examples.
5. Testing / dev commands.
6. Troubleshooting / FAQ.
7. License and contribution notes if present.

## Rules

- Do not invent features, options, or APIs.
- Keep a single source of truth: link to canonical docs rather than duplicating.
- Update the changelog when the change is user-visible, following its existing format.
- Format consistently with the project's existing docs (markdown conventions, code fences, link styles).