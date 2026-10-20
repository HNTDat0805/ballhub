---
name: git-workflow-and-versioning
description: Structures git workflow practices. Use when making any code change, committing, branching, resolving conflicts, writing Conventional Commits, or opening pull requests in Ballhub.
---

# Git Workflow & Versioning

## Core Rules

1. **Atomic Commits:** Each commit does exactly one logical thing.
   - Separate refactoring from feature work.
   - Separate documentation/formatting from behavioral logic.
2. **Conventional Commits Format:**
   ```
   <type>: <short description>

   [optional body explaining WHY, not just what]
   ```
   - `feat`: New feature or capability.
   - `fix`: Bug fix.
   - `refactor`: Code reorganization without behavior change.
   - `test`: Adding or updating test cases.
   - `chore`: Tooling, dependencies, or configuration.
3. **Commit Early, Commit Often:**
   - Commit at each stable milestone after running `flutter test`.
   - Never leave uncommitted large diffs spanning multiple unrelated components.
