---
name: widget-composition
description: Enforces right-sized widget composition in Flutter. Mandates small const widget classes over _buildX() helper methods, clean build() methods without inline business logic, and efficient widget subtree re-renders. Use when authoring Flutter UI, refactoring complex screens, or optimizing widget rebuild performance.
---

# Widget Composition Best Practices

## Non-Negotiable Rules

1. **Prefer `const` Widget Classes over `_buildX()` Helper Methods:**
   - Methods like `Widget _buildHeader()` stay bound to the parent's `BuildContext` and force full subtree rebuilds whenever the parent changes.
   - Extracting a private or public `StatelessWidget` / `ConsumerWidget` with a `const` constructor allows Flutter's element tree to short-circuit rebuilds when inputs don't change.

2. **Lean `build()` Methods:**
   - A `build()` method must only return widget trees based on incoming state.
   - NEVER trigger side-effects, initialize network requests, or mutate state directly inside `build()`.
   - Keep formatting, complex computations, or data munging outside the widget — delegate to the ViewModel or domain models.

3. **Responsive & Adaptive Layouts:**
   - Use `LayoutBuilder`, `MediaQuery.sizeOf(context)` (to avoid unnecessary rebuilds compared to `MediaQuery.of(context)`), and `Flexible`/`Expanded` instead of hardcoded pixel dimensions.
   - Use `SafeArea` to respect device notches, home indicators, and system overlays.

4. **Surgical Re-renders:**
   - Keep state listeners scoped to the exact subtree that depends on that state (`Consumer` or localized `ref.watch`).
   - Do not watch high-frequency state changes at the root screen widget if only a badge or counter needs the update.
