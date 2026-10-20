---
name: flutter-architecture
description: Enforces a right-sized feature-first layered MVVM Flutter architecture — features are folders and cross-cutting foundations become packages only when a compile wall earns it, a strict downward-only dependency DAG, dumb Views over one Notifier/AsyncNotifier ViewModel per feature, repositories as the single source of truth and single write path returning immutable domain values, abstractions only where something genuinely can't run in a test, and Riverpod 3.x as the one context-free DI+state mechanism (no get_it/injectable/package:provider container). Use when creating a Flutter feature or file, deciding folder-vs-package or where a class belongs, naming a Screen/Notifier/Repository/Service, wiring providers or a composition-root/bootstrap.dart, adding a use-case/domain layer, resisting over-engineering on a small app, or reviewing whether a change respects the layer boundaries.
---

# Flutter Architecture

Structure every Flutter app as a **layered, feature-first MVVM system, sized to the app**. You must always answer "where does this code belong?" in one second. Based on Flutter's official *Guide to app architecture*, with Riverpod 3.x as the one mechanism for both state and dependency injection.

Two failure modes kill an architecture: under-structure (a widget touching a database) and over-structure (a `*UseCase` wrapping one repository call, an interface over code that already runs in a test). This skill fights both. **Start small; add a layer only when it carries a load you can name.**

## Non-negotiable rules

1. **Answer "where does this belong?" in one second.** Group by **feature first, layer second**. No giant app-wide `screens/`, `models/`, or `widgets/` bucket — those smear one feature across the tree and force a name lookup on every edit.
2. **Two layers minimum: UI and Data. A domain/use-case layer only when logic spans multiple repositories** (projection, aggregation, a multi-step workflow). A `*UseCase` that forwards one repository call is a rename, not a boundary — Flutter's own guidance rates the domain layer *conditional* and says most apps don't need it.
3. **Abstract exactly what cannot run in a test — name what the abstraction makes testable.** A platform channel, network client, or plugin that can't execute in `flutter test` earns an interface + a fake. Code that already runs headless (an in-memory DB, a pure calculator, a repository over it) stays **concrete**. "It's cleaner" is not a load; if you can't name the seam it buys, don't add it.
4. **Data flows one way; never skip or reverse a hop.** Data down: `Service → Repository → ViewModel → View`. Events up: `View → ViewModel → Repository`. A widget calls its ViewModel only; a ViewModel calls repositories only. No two-way binding, no widget reaching a data source.
5. **The View is dumb.** A View does layout, `if`/`switch` on state, animation, and navigation — nothing else. No business logic, no formatting/number math, no `try/catch`, no data access. If a widget computes or fetches, it's in the wrong layer.
6. **One ViewModel per feature, over immutable state.** The ViewModel holds **private mutable state** and exposes **intent methods** (`load()`, `add(...)`); every transition assigns a **new immutable value** with value equality. No public setters, no mutable field the UI edits in place.
7. **Repositories are the single source of truth AND the single write path.** Every mutation is one named repository method that **persists first, then publishes** (one transaction where the store supports it). Never persist-after-publish — a crash in between credits state that never saved.
8. **Derive, don't store.** Counts, totals, streaks, filtered lists are **computed from the source of truth** (a stream/derived provider), never a second stored counter that can drift out of sync.
9. **Map at the boundary; keep domain types out of the edges.** Repositories map storage rows / JSON DTOs → immutable domain **value objects**. A generated Drift row or a `Map` never reaches a ViewModel or widget; unit math and locale formatting never happen in a widget.
10. **Inject through providers; depend on the abstraction where it earns one.** No globals, no singletons, no service locator reached from a widget, no `DateTime.now()` outside an injected `Clock`. A composition root wires the object graph once.
11. **Features are FOLDERS; foundations become PACKAGES only when a compile wall is load-bearing.** Default to a **single package**. A feature never imports another feature — share via a foundation layer or navigate by route **ID**. The dependency graph is a strict **downward-only DAG**.
12. **Errors are typed values at boundaries.** Repositories/use-cases return a sealed `Result`/`Failure` rather than throwing across a layer; the UI switches exhaustively.

## The layered shape (single package, the default)

Features are FOLDERS under `lib/features/`; a feature's Views and its one ViewModel live in `presentation/`.

```text
lib/
  main.dart                 # thin entrypoint → bootstrap()
  bootstrap.dart            # composition root: build infra, override placeholder providers, runApp
  app.dart                  # MaterialApp.router, theme, top-level ProviderScope children
  core/                     # PURE foundation, NO Flutter: value objects, Result/Failure, the Clock seam,
                            #   extensions, pure calculators (the sanctioned foundation, not a junk-drawer)
  data/                     # shared data layer: DAOs, repositories, row→model mappers
  services/                 # injectable side-effect ports + live impls (services/native/ = MethodChannel)
  routing/                  # the single go_router config, typed routes, guards
  theme/  l10n/             # ThemeExtension token sets; generated AppLocalizations + ARB
  features/
    tournament/
      presentation/
        tournament_list_screen.dart    # View: dumb ConsumerWidget
        tournament_notifier.dart       # ViewModel: StreamNotifier over immutable state
        widgets/                       # widget CLASSES used only by this feature
      application/                     # optional: use-cases, ONLY when logic spans repositories
      domain/                          # feature-local domain models / entities
```
