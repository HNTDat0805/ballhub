---
name: dart3-idioms-and-coding-standards
description: Enforces modern Dart 3 idioms, type safety, pattern matching, sealed classes, and Effective Dart coding conventions. Use when defining domain models, handling errors, writing exhaustive switch expressions, and designing API contracts in Dart.
---

# Dart 3 Idioms & Coding Standards

## 1. Sealed Classes & Exhaustive Matching

Always represent domain states and outcomes with `sealed class` hierarchies instead of loosely typed booleans, enums, or strings:

```dart
sealed class TournamentState {
  const TournamentState();
}

final class TournamentDraft extends TournamentState {
  const TournamentDraft();
}

final class TournamentRegistrationOpen extends TournamentState {
  final List<Team> registeredTeams;
  const TournamentRegistrationOpen(this.registeredTeams);
}

final class TournamentInProgress extends TournamentState {
  final List<Match> schedule;
  const TournamentInProgress(this.schedule);
}

final class TournamentCompleted extends TournamentState {
  final List<StandingsRow> table;
  const TournamentCompleted(this.table);
}
```

Use exhaustive switch expressions without fallback `default`:
```dart
String statusMessage(TournamentState state) => switch (state) {
  TournamentDraft() => 'Draft mode',
  TournamentRegistrationOpen(:final registeredTeams) => 'Open: ${registeredTeams.length} teams',
  TournamentInProgress(:final schedule) => 'Matches: ${schedule.length}',
  TournamentCompleted() => 'Completed',
};
```

## 2. Records and Multiple Returns

Use records `(int, String)` for private internal groupings or typed lightweight pairs rather than ad-hoc maps or throwaway tuples:

```dart
(int scoreA, int scoreB) parseScore(String raw) { ... }
```

## 3. Immutability & Value Semantics

- Declare all fields `final`.
- Annotate immutable classes with `@immutable`.
- Implement `operator ==` and `hashCode` (or use packages like `freezed` or Dart 3 class modifiers) so state comparisons work predictably in reactive UI.

## 4. Effective Dart Standards

- Adhere to `pedantic` / `flutter_lints` rules defined in `analysis_options.yaml`.
- Prefer descriptive names over abbreviations.
- Document public APIs using `///` markdown docstrings.
