---
name: typescript-react
description: Use when working with TypeScript and React codebases — components, hooks, state, rendering, Vite/Next.js. Triggers on "React", "TypeScript", "TSX", "hook", "component", "Next.js".
---

# TypeScript + React

Conventions for TS/React work.

## TypeScript

- Prefer explicit typing at API boundaries; use `const` inference inside functions.
- Use `satisfies` over `as` where possible; avoid `any` and non-null assertions unless proven necessary.
- Prefer discriminated unions over boolean/optional flags for state that can be one of several shapes.
- `strict` mode is expected. Handle `null`/`undefined` explicitly.

## React

- Keep components small and purely presentational; move logic into hooks.
- One responsibility per hook; name hooks for what they return, e.g. `useAuth`.
- Use controlled components unless the framework (e.g. React Hook Form) prefers otherwise.
- Memoize with `useMemo`/`useCallback` only for real perf wins, not habit.
- Key list items with stable IDs, never array index.
- Handle async with async handlers + `AbortController` in effects; always cancel on unmount.
- Match the existing styling approach (Tailwind/CSS modules/UI lib) — do not introduce a new one without asking.

## Framework notes

- Vite/Next: prefer server components / SSR only where it helps; keep client components minimal.
- Check the project's routing and data-fetching conventions and follow them verbatim.