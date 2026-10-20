---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, modifying behavior, or planning anything new in Ballhub."
---

# Brainstorming & Requirement Discovery

## Overview

Before jumping into code implementation, pause to clarify user intent and map out non-obvious requirements. Good discovery questions prevent building the wrong software.

## Discovery Workflow

1. **Understand Goals & Constraints:**
   - What is the primary user flow (e.g. creating a tournament, enrolling teams, generating round-robin vs knockout bracket)?
   - What are the anti-goals (what should NOT be built in this phase)?
2. **Clarify Edge Cases:**
   - Tie-breaking rules for tournament standings (Head-to-head vs Goal difference vs Fair play).
   - Odd number of registered teams (Byes/rest rounds).
   - Offline handling vs real-time sync.
3. **Present Options & Align:**
   - Propose 2-3 concrete design alternatives with pros and cons before finalizing architecture.
