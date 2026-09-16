# AGENTS.md — Python project

## Stack

- Python 3.x. Packaging and tooling via `pyproject.toml`; venv managed with `uv` (fallback: `python -m venv`).
- Lint/format: `ruff` (reformat `ruff format`, fix `ruff check --fix`). Type checking: `mypy` / `pyright` if configured.

## Commands

- `uv sync` — install dependencies into `.venv`
- `uv run pytest` — run tests
- `uv run ruff check .` — lint
- `uv run ruff format --check .` — format check
- `uv run mypy .` — type check (if configured)

## Conventions

- Modern typing everywhere: `list[str]`, `dict[str, X]`, `X | None`.
- `pathlib` for paths, zoneinfo-aware datetimes, dataclasses/Pydantic for structured data.
- One module = one responsibility; keep functions small.
- Tests in `tests/`, pytest style, parametrized over copy-paste.
- Update `AGENTS.md` when commands or conventions change.

## Rules for agents

- Verify behavior by reading code and running tests — never assume.
- Run lint + typecheck + the relevant tests before considering a change done.
- Do not install packages globally; work inside the project env.