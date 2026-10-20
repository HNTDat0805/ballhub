---
name: firestore-rules-creation
description: Designs, authors, refactors, and hardens production-grade Cloud Firestore Security Rules (firestore.rules). Enforces default-deny, role-based access control (RBAC), prevents unauthorized writes, ensures UID integrity, and validates schema constraints. Use when writing, checking, or auditing firestore.rules.
metadata:
  author: Google LLC
  category: Databases
---

# Firestore Security Rules Creation and Audit

## Workflow

Follow this structured workflow strictly:

### Phase 1: Codebase & Query Analysis

1. **Scan the codebase to identify:**
   - All collection and document paths (e.g., `tournaments/{tournamentId}`, `matches/{matchId}`).
   - All client-side queries (`where()`, `orderBy()`, `limit()`). The rules MUST allow these exact queries.
   - Field constraints: required fields, types, and allowed values.
   - Roles: Tournament Organizer/Admin, Team Captain, Referee, Public Viewer.

### Phase 2: Security Rules Generation Principles

- **Default Deny:** Start with denying all access (`match /{document=**} { allow read, write: if false; }`), then explicitly open specific collections with constraints.
- **Least Privilege:** Granular rules for `read` (`get`, `list`) and `write` (`create`, `update`, `delete`).
- **Authentication Checks:** Verify user identity via `request.auth != null`.
- **UID Protection:** Prevent users from spoofing or altering ownership fields on creates and updates.
- **Validator Functions:** Validate data types, string lengths, and schema invariants in both create and update rules.
- **Role-Based Access Control (RBAC):** Check if user has organizer rights before allowing edits to tournament schedule or score updates.

### Helper Function Template

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper Functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isDocOwner() {
      return isAuthenticated() && request.auth.uid == resource.data.organizerId;
    }
    
    function uidUnchanged() {
      return !('organizerId' in request.resource.data) ||
        request.resource.data.organizerId == request.auth.uid;
    }
    
    function uidNotModified() {
      return !('organizerId' in request.resource.data) ||
        request.resource.data.organizerId == resource.data.organizerId;
    }
    
    function hasOnlyAllowedFields(fields) {
      return request.resource.data.keys().hasOnly(fields);
    }
    
    function hasRequiredFields(fields) {
      return request.resource.data.keys().hasAll(fields);
    }

    // Tournament rules example
    match /tournaments/{tournamentId} {
      allow read: if true; // Public tournaments can be read
      allow create: if isAuthenticated() && 
        request.resource.data.organizerId == request.auth.uid &&
        hasRequiredFields(['name', 'organizerId', 'status', 'createdAt']);
      allow update: if isAuthenticated() && 
        resource.data.organizerId == request.auth.uid &&
        uidNotModified();
      allow delete: if isAuthenticated() && 
        resource.data.organizerId == request.auth.uid;
        
      match /matches/{matchId} {
        allow read: if true;
        allow write: if isAuthenticated() && 
          get(/databases/$(database)/documents/tournaments/$(tournamentId)).data.organizerId == request.auth.uid;
      }
    }
  }
}
```
