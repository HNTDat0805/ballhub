---
name: firebase-firestore
description: Sets up, manages, queries, and configures Cloud Firestore databases, including data modeling, indexes, batched writes, transactions, and Flutter SDK integrations (cloud_firestore). Use when defining Firestore schemas/models, writing queries (where, orderBy, limit), structuring subcollections, or handling concurrent tournament updates with transactions.
compatibility: This skill is best used with the Firebase CLI, but does not require it.
metadata:
  author: Google LLC
  category: Databases
---

# Cloud Firestore Database and Operations for Flutter

## 1. Data Modeling Best Practices for Sports / Tournament Management

1. **Denormalization vs. Subcollections:**
   - **Top-level collections:** `tournaments`, `teams`, `users`.
   - **Subcollections:** Use subcollections (e.g., `tournaments/{tournamentId}/matches`, `tournaments/{tournamentId}/standings`) when sub-items naturally belong to a single parent and are queried together.
   - **Document Size Limits:** Remember each Firestore document has a 1 MB limit. Avoid embedding unbounded arrays (e.g., a list of hundreds of matches inside the tournament document). Keep matches in a subcollection.

2. **Compound Queries and Indexing:**
   - Single-field inequality and range filters require compound indexes when combined with sorting or multiple equalities.
   - Provide exact composite index definitions in `firestore.indexes.json` when writing complex filters.

## 2. Transactions and Batched Writes

Tournament management frequently involves simultaneous score updates and standing recalculations:

1. **Transactions for Atomic Updates:**
   - When updating match score and updating the leaderboard/standings simultaneously, ALWAYS use a Firestore Transaction (`FirebaseFirestore.instance.runTransaction(...)`).
   - All reads inside the transaction MUST precede all writes.

2. **Batched Writes for Bulk Operations:**
   - When generating an entire tournament schedule (e.g., 20+ matches at once), use `WriteBatch` (`batch.commit()`) to commit up to 500 operations in an atomic request.

## 3. Flutter Integration Patterns

- Wrap Firestore operations inside a Repository class in `lib/data/repositories/` or `lib/features/<feature>/data/`.
- Never expose `DocumentSnapshot` or `QuerySnapshot` directly to ViewWidgets. Map them immediately into immutable domain models (e.g., `Tournament`, `Match`, `Team`).
- Provide both `Stream<T>` (for real-time live match score updates) and `Future<T>` (for one-time lookups).
