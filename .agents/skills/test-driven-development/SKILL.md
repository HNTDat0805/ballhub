---
name: test-driven-development
description: Enforces strict Test-Driven Development (TDD) via the Red-Green-Refactor cycle. Mandates that no production code be written without a failing test first. Use when implementing any feature, algorithm, calculation, or bugfix in Flutter and Dart.
---

# Test-Driven Development (TDD)

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over fresh from tests.

## The Red-Green-Refactor Cycle

1. **RED - Write Failing Test:**
   - Write one minimal test showing what should happen (e.g. testing tournament standings points when team A wins).
   - Run the test (`flutter test test/...`) and verify that it fails for the expected reason (feature missing), not due to syntax or compiler errors.

2. **GREEN - Minimal Code:**
   - Write the simplest, absolute minimum code required to make the test pass.
   - Do not add speculative features or out-of-scope code.
   - Run the test and verify it passes.

3. **REFACTOR - Clean Up:**
   - Clean up structure, remove duplication, improve naming while keeping the test suite green.
   - Run the full test suite (`flutter test`) before proceeding.
