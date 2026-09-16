---
name: database-sql
description: Use when working with databases and SQL — queries, schema design, migrations, indexes, joins, optimization. Triggers on "SQL", "database", "Postgres", "MySQL", "SQLite", "migration", "query", "index".
---

# Database & SQL

Guidelines for querying and designing databases.

## Querying

- Prefer parameterized queries/migrations over string interpolation — never f-string/concatenate user input into SQL.
- Write explicit column lists in `SELECT`; avoid `SELECT *` in code.
- Use `LIMIT` on exploratory queries; add `ORDER BY` for determinism.
- Prefer `INNER JOIN`/`LEFT JOIN` explicitly; prefilter before joining when possible.
- Use window functions for ranking/"previous row" problems; `DISTINCT ON` only for true de-dupe.

## Schema design

- Intentional types: use proper date/time types, enums or check constraints, and fixed-length where it matters.
- `NOT NULL` + defaults where the default is sane; avoid nullable "mystery" columns.
- Foreign keys on, cascades explicit and rare. Soft-delete or hard-delete chosen consciously per table.
- Name tables/columns in the project's existing style.

## Migrations

- One migration per logical change; write both up and down if the tool supports it.
- Test migrations against a copy of real data shape, not empty schema.

## Optimization

- Look at `EXPLAIN ANALYZE` before indexing; add indexes for real query patterns.
- Beware N+1: batch reads, use joins or `IN` lookups.
- Watch for `COUNT(*)` on huge tables, missing `LIMIT` in pagination, and hot-write contention.