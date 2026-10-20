---
name: firebase-auth-basics
description: Guide for setting up and using Firebase Authentication in Flutter. Use this skill when the app requires user sign-in (Email/Password, Google Sign-In, Anonymous), user session persistence, auth state listening, or linking auth tokens with Firestore security rules.
compatibility: This skill is best used with the Firebase CLI, but does not require it.
metadata:
  author: Google LLC
  category: Identity
---

# Firebase Authentication in Flutter

## 1. Core Workflow & Providers

1. **Authentication Providers:**
   - **Email & Password**: `FirebaseAuth.instance.createUserWithEmailAndPassword(...)`, `signInWithEmailAndPassword(...)`.
   - **Google Sign-In**: Integrated with `google_sign_in` plugin.
   - **Anonymous Auth**: `signInAnonymously()` for onboarding guests before team registration.

2. **Session Persistence & Reactive Auth State:**
   - Listen to user changes via `FirebaseAuth.instance.authStateChanges()`.
   - Expose the current user stream via a Riverpod StreamProvider (`authStateProvider`).
   - Use GoRouter's `redirect` parameter to redirect unauthenticated users away from organizer/team management screens.

3. **User Profile & Custom Claims:**
   - Extract `user.uid` for mapping user data in Firestore (`/users/{uid}`).
   - Store user role (organizer, team_captain, player, referee) in Firestore or Firebase Auth Custom Claims.
