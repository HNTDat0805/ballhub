---
name: async-safety
description: Eliminates silent async failures, unhandled Future errors, and context leaks across async gaps in Flutter. Enforces mounted checks after awaits, cancellation tokens, and safe lifecycle management. Use when writing asynchronous workflows, network requests, or database calls in Flutter widgets and controllers.
---

# Async Safety in Flutter & Dart

## 1. Context Leaks & The Async Gap

Never use `BuildContext` across an `await` without verifying the widget is still mounted:

```dart
// BAD
await service.registerTeam(teamId);
Navigator.of(context).pop(); // Crash if user navigated away while waiting!

// GOOD
await service.registerTeam(teamId);
if (!context.mounted) return;
Navigator.of(context).pop();
```

In `StatefulWidget`, use `if (!mounted) return;`.
In Riverpod `AsyncNotifier` or `StateNotifier`, keep UI operations out of the controller entirely. The controller updates state; the UI listens to state changes and navigates safely.

## 2. Unhandled Futures

- Never fire-and-forget a `Future` without error handling:
  - WRONG: `fetchData();`
  - RIGHT: `unawaited(fetchData().catchError((e, s) => ...));` or handle with `try/catch`.
- Always propagate errors or map them to a typed `Result`/`Failure` sealed class before crossing layer boundaries.

## 3. Disposing & Stream Subscriptions

- Always cancel `StreamSubscription` instances in `dispose()` or use `autoDispose` providers to prevent memory leaks.
- Ensure Firestore snapshot listeners are closed when the screen or feature is destroyed.
