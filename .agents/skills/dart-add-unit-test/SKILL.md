---
name: dart-add-unit-test
description: Write and organize unit tests for functions, methods, and classes using package:test and flutter_test. Use when creating new logic, domain models, tournament schedule algorithms, or fixing bugs to ensure code remains correct and regression-free.
metadata:
  author: Dart Team / Google LLC
  model: models/gemini-3.1-pro-preview
---

# Testing Dart and Flutter Applications

## Structuring Test Files

Organize test files to mirror the `lib` directory structure:
* Place all test code within the `test/` directory at the root of the package.
* Append `_test.dart` to the end of all test file names (e.g. `lib/features/tournament/domain/tournament.dart` → `test/features/tournament/domain/tournament_test.dart`).

## Writing Unit Tests

1. **Import:** Use `package:flutter_test/flutter_test.dart`.
2. **Grouping:** Group related scenarios with `group('Tournament scheduling', () { ... })`.
3. **Assertions:** Use `expect(actual, matcher)`.
4. **Mocking:** For repositories or external dependencies, use fake classes or `mockito` / `mocktail`.
5. **Pure Domain Testing:** Test scheduling algorithms, standing table calculations (points, goal difference, head-to-head) as pure functions without Flutter UI bindings.
