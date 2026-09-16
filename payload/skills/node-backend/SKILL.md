---
name: node-backend
description: Use when working on Node.js backends — Express/Fastify, REST or GraphQL APIs, workers, database access, npm packages. Triggers on "Node", "npm", "Express", "Fastify", "API", "backend", "worker".
---

# Node.js Backend

Conventions for Node backend work.

## General

- Match the project's runtime (Node version in `.nvmrc`/`engines`), module system (ESM vs CJS), and package manager (npm/pnpm/yarn). Do not mix.
- Keep handlers thin: parse → validate → call service → map errors → respond.
- Centralize error handling; translate domain errors to HTTP status codes once.
- Prefer async/await; never fire-and-forget a Promise without attaching a handler.

## API specifics

- Validate all input at the boundary (zod/ajv/joi or framework equivalent); reject unknown schema shapes explicitly.
- Use cursor-based pagination for lists; never unbounded `findAll`.
- Set sensible timeouts for outbound calls; propagate cancellation (`AbortSignal`).
- Idempotency keys for mutating endpoints that matter (payments, jobs).
- Structured logging, no `console.log` in production paths.

## Persistence

- Use the project's ORM/query builder; never concatenate raw SQL strings.
- Wrap multi-statement work in transactions.
- Add indexes based on query patterns; watch for N+1.

## Package hygiene

- `npm` scripts named with convention (`dev`, `build`, `test`, `lint`, `typecheck`).
- Keep dependencies pinned and minimal; prefer lockfile over ranges where the repo already pins.