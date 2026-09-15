---
name: git-workflow
description: Use when working with git in a repository — status, branches, commits, history, stashing, reverting, worktrees, or remote operations. Triggers on "git", "commit", "branch", "push", "pull", "merge", "rebase", "cherry-pick", "stash", "worktree".
---

# Git Workflow

Follow these rules for all git operations.

- Always start with `git status --short` to understand the working tree.
- Work on a feature branch, not directly on `main`/`master` unless the project is tiny or the user says otherwise.
- Name branches `type/short-description` (feat/, fix/, chore/, docs/, refactor/).
- Use `git add <specific files>`, never blind `git add -A` unless the user confirms.
- Read the diff before committing: `git diff` and `git diff --cached`.
- Prefer `git pull --rebase` over `git pull` to keep history linear.
- Never force-push (`git push --force`); use `git push --force-with-lease` only after explicit consent.
- When asked to revert, prefer `git revert` over rewriting history.
- Use `git worktree` to work on multiple branches in parallel when possible.
- Push/PR only when the user asks for it.

## Common task snippets

- Find what changed recently: `git log --oneline -20`
- See who/what last touched three: `git log -p -- <file>`
- Unstage a file: `git restore --staged <file>`
- Discard working changes (ask first): `git restore <file>`