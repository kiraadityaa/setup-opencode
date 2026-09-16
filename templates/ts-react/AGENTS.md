# AGENTS.md — TypeScript / React project

## Stack

- TypeScript (strict), React, Node.js. Package manager: `npm`.
- Build: Vite (or framework configured in this repo — check `package.json` scripts).

## Commands

- `npm run dev` — start dev server
- `npm run build` — typecheck + production build
- `npm run lint` — lint
- `npm test` — run unit tests
- `npm run typecheck` — TypeScript only

## Conventions

- Follow existing component/hook/file structure. New shared UI goes in `src/components/`.
- Use `satisfies` over `as`; avoid `any`. No non-null assertions without justification.
- Conditionals prefer discriminated unions over boolean flags.
- Add tests alongside non-trivial logic; keep them behaviour-focused.
- Update `AGENTS.md` when commands or conventions change.

## Rules for agents

- Verify assumptions by reading code; never invent APIs.
- Before committing, run lint, typecheck, and the relevant tests.
- Keep dependency changes to a minimum and explain them.