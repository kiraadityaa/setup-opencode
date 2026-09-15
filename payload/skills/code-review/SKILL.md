---
name: code-review
description: Use when reviewing code, diffs, pull requests, or recently changed files. Triggers on "review", "PR", "pull request", "diff", "code review".
---

# Code Review

Perform structured, evidence-based code reviews.

## Process

1. Establish scope: `git diff <base>..HEAD`, `git diff --cached`, or `git show`.
2. Read the affected files in full — review context, not just the diff hunks.
3. Verify claims against the real code; never review from memory.

## What to check (priority order)

1. **Correctness** — edge cases, off-by-one, races, error handling, resource leaks.
2. **Security** — injection, secrets, authz, unvalidated input, unsafe defaults.
3. **Performance** — hot paths, N+1 queries, unnecessary allocations, lock contention.
4. **Maintainability** — naming, duplication, dead code, function size, abstractions that obscure.
5. **Conventions** — matches the project's formatting/lint/patterns.

## Output format

- Verdict first: `approve` / `needs-changes` / `reject`.
- Issues grouped by severity: critical → major → minor → nit.
- Each issue: `file:line` + what is wrong + concrete suggested fix.
- End with a one-paragraph summary.