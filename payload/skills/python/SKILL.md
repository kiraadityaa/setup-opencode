---
name: python
description: Use when writing, fixing, or reviewing Python code — scripts, libraries, data, backends, packaging. Triggers on "Python", "pip", "pyproject", "pytest", "venv", "conda".
---

# Python

Conventions for Python work.

## Code

- Target the project's Python version; use modern typing (`list[str]`, `dict[str, X]`, `X | None`).
- Prefer explicit `dataclasses`/Pydantic models over plain dicts for anything structured.
- Functions should be small; rely on the standard lib before dependencies.
- Use `pathlib` over `os.path`. Use `zoneinfo`/aware `datetime` over naive times.
- Raise domain exceptions; validate input early (`ValueError` for bad args, not silent fallbacks).
- Keep heavy imports at module top; lazy import only against true circulars.

## Environment & deps

- Define the environment in the repo: `pyproject.toml` (preferred) or `requirements.txt` (pinned).
- Use `uv`/venv for local dev if present; never `pip install` into the system Python globally without asking.
- Scripts get `if __name__ == "__main__":` entrypoints.

## Testing

- Use pytest with clear fixture names; parametrize to avoid copy-paste tests.
- Test error paths and edge cases, not just the happy path.
- Type hints are expected; run `mypy`/`ruff`/`pyright` if the project configures them.