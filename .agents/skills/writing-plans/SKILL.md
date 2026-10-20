---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code. Breaks tasks into bite-sized, independently testable increments with exact file paths and verification gates.
---

# Writing Implementation Plans

## Overview

Produce structured, step-by-step implementation plans for complex features. Each plan must detail:
1. Target file paths.
2. Exact signatures and contracts.
3. Test commands to verify each incremental task.
4. Checkbox-driven task tracking (`- [ ]`).

## Plan Document Structure

Save implementation plans to `docs/plans/YYYY-MM-DD-<feature-name>.md`:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]
**Tech Stack:** Flutter / Dart / Firebase Firestore
**Architecture:** Feature-first layered MVVM

## Step 1: Domain Entities & Unit Tests
- [ ] Create domain entities (immutable value objects).
- [ ] Write unit tests for business logic & algorithms (TDD Red).
- [ ] Implement logic (TDD Green).
- [ ] Verify `flutter test`.

## Step 2: Firestore Repository & Data Models
- [ ] Define Firestore DTOs and mappers (`fromFirestore`, `toFirestore`).
- [ ] Implement repository with transactions & error handling.
- [ ] Define Firestore Security Rules.

## Step 3: ViewModel & Presentation
- [ ] Create Riverpod AsyncNotifier / ViewModel.
- [ ] Build dumb UI widgets with const constructors.
- [ ] Verify responsive layouts and user feedback.
```
