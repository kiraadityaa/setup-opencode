---
name: testing
description: Use when writing, fixing, or running tests. Triggers on "test", "tests", "testing", "unit test", "integration test", "coverage", "TDD".
---

# Testing

Write tests that give real confidence without babysitting.

## Approach

- Detect the framework first: check `package.json`/`pyproject.toml`/`go.mod` and existing test files, then match their style.
- **Unit**: pure logic, one behaviour per test, no network/filesystem unless mocked.
- **Integration**: real boundary (DB, API, filesystem) with fixtures; keep I/O fast.
- **E2E**: only where user journeys matter (login flows, checkouts). Keep a handful.
- Prioritize the important, glitchy paths: parsing, retry logic, time boundaries, auth, and anything "it works on my machine".

## Naming

- Test name = behaviour: `should reject over-limit amount` / `test_rejects_over_limit`.

## Rules

- No test-only hacks inside production code unless the interface genuinely needs it.
- Never delete or weaken existing tests to make the suite green.
- Run the suite after writing; report commands used and results.
- Aim for meaningful assertions, not coverage numbers alone — prefer behaviour over lock-in of implementation details.