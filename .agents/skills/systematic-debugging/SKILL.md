---
name: systematic-debugging
description: Use when encountering any bug, test failure, compiler warning, or unexpected behavior in Ballhub, before proposing fixes. Enforces 4-phase root cause analysis and prevents shotgun debugging.
---

# Systematic Debugging Protocol

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Never apply symptom-level quick fixes or guess solutions without proving the root cause.

## The 4 Phases

### Phase 1: Root Cause Investigation
1. **Read Error Messages & Stack Traces Completely:** Note line numbers, call stack, and exact exception types.
2. **Reproduce Consistently:** Identify the exact sequence of actions or inputs that trigger the bug.
3. **Trace Data Flow:** Trace backwards from the crash or incorrect state to where the invalid value originated.

### Phase 2: Pattern & Boundary Analysis
1. Compare with working parts of the codebase.
2. Check recent Git commits or dependency updates that touched the affected area.
3. Verify assumptions at component boundaries (e.g. JSON deserialization, nullability, Firestore async responses).

### Phase 3: Single Hypothesis & Verification
1. Formulate one clear hypothesis: "The error occurs because X produces Y under condition Z."
2. Write a minimal reproduction test that fails due to this root cause.

### Phase 4: Targeted Fix & Regression Prevention
1. Apply the single, minimal fix at the source.
2. Run the reproduction test and watch it pass.
3. Run the full test suite (`flutter test`) to verify no regressions were introduced.
