# H02 Booking Domain Models Implementation Plan

**Goal:** Add the Booking/Football Field domain contracts, Firestore indexes, and non-HTTP repository abstraction without changing the Tournament subsystem or implementing API/UI.

**Tech Stack:** Flutter/Dart 3.13.4, TypeScript/Node.js 20, Cloud Firestore.

**Architecture:** Existing API-first flow — UI -> Controller -> Repository -> REST API; backend Route -> Service -> Repository -> Firestore.

## Step 1: Test-first Flutter domain models

- [x] Create failing unit tests in `test/features/booking/domain/models/` for enum fallback and JSON round trips.
- [ ] Verify the tests fail because the Booking models do not yet exist (blocked: Flutter is not available in PATH).
- [x] Create immutable `FootballField`, `FieldSlot`, and `Booking` models in `lib/features/booking/domain/models/`.
- [ ] Verify model tests pass with `flutter test test/features/booking/domain/models` (blocked: Flutter is not available in PATH).

## Step 2: Domain contracts and Firestore metadata

- [x] Add `functions/src/types/booking.types.ts` with owner, field, slot, booking entities and enums only.
- [x] Add `lib/features/booking/data/booking_repository.dart` as a REST-independent contract; do not add HTTP implementation.
- [x] Add only the booking indexes dictated by H02's identified queries; preserve Tournament indexes.
- [x] Keep Firestore client access default-deny; do not edit `firestore.rules` because server-side Firebase Admin SDK will be the access path.

## Step 3: Verification

- [ ] Run `dart format` on modified Dart source and test files (blocked: Dart is not available in PATH).
- [ ] Run `dart analyze lib test` and `flutter test` (blocked: Dart and Flutter are not available in PATH).
- [ ] Run `npm run build` from `functions/` (blocked: `tsc` is unavailable because dependencies are not installed).
- [x] Confirm no Tournament source/schema/API files were changed.
