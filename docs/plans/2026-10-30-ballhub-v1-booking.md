# BallHub V1 Booking Implementation Plan

**Goal:** Deliver the Booking / Football Field V1 while preserving the existing Tournament API-first architecture.

**Tech Stack:** Flutter/Dart 3.13.4, Material 3, Express/TypeScript, Firebase Admin SDK, Cloud Firestore, Zod.

**Architecture:** Flutter View -> Controller -> Repository -> ApiClient -> REST; Express Route -> Zod Validation -> Service -> Repository -> Firestore.

## Phase 0: Environment and compatibility audit

- [ ] Verify Flutter/Dart, Node/NPM/Firebase CLI, and backend dependencies.
- [ ] Preserve all pre-existing user changes and Tournament files.
- [ ] Confirm existing auth headers, RBAC and route conventions.

## Phase 1: Backend field and slot foundations

- [ ] Add field/slot repositories, Zod schemas, services and routes under `functions/src/`.
- [ ] Add only required FieldOwner role support to existing auth types/context.
- [ ] Verify field ownership and archive-not-delete behavior with backend tests.

## Phase 2: Backend booking lifecycle

- [ ] Add booking repository, service and routes with transactional create/confirm/reject/cancel operations.
- [ ] Write backend tests for authorization, contiguous slots and double-booking prevention.
- [ ] Verify `npm.cmd run build` and `npm.cmd test`.

## Phase 3: Flutter data and controller

- [ ] Implement `ApiBookingRepository` using `ApiClient`; keep the existing repository contract backward compatible.
- [ ] Add `BookingController` for loading and mutation state.
- [ ] Add repository/controller tests.

## Phase 4: Flutter user and owner experience

- [ ] Add field discovery/detail, slot selection, booking create/detail/my-bookings screens.
- [ ] Add owner dashboard, field management and booking approval screens.
- [ ] Add reusable booking widgets and all loading/empty/error/success states.
- [ ] Wire navigation without replacing the Tournament entry flow.

## Phase 5: Documentation and verification

- [ ] Add `docs/booking-architecture.md`.
- [ ] Run formatting, analyzer, Flutter tests, backend build/tests and JSON validation.
- [ ] Report environmental blockers honestly if tools cannot run.
