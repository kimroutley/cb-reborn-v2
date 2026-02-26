# Security Analysis and Remediation Report

**Date:** 2026-02-26
**Target:** Club Blackout Reborn Codebase

## Executive Summary

A comprehensive security analysis was conducted on the Club Blackout Reborn codebase. The assessment focused on data leakage, access control, and persistence security. Critical vulnerabilities related to active game state leakage were identified and remediated. The system now enforces stricter access controls on Firestore and sanitizes public game state.

## Findings & Remediation

### 1. Active Game Data Leakage (Critical)

**Finding:**
Sensitive betting information (`currentBetTargetId` and `deadPoolBets`) was exposed in the public `games/{joinCode}` document. This allowed any authenticated user with the join code to view all players' bets, compromising game integrity.

**Remediation:**
-   **Host Side:** Modified `CloudHostBridge.publishState` to remove `currentBetTargetId` and `deadPoolBets` from the public payload. These fields are now exclusively written to the `private_state/{playerId}` subcollection, which is restricted to the specific player and the host.
-   **Player Side:** Updated `CloudPlayerBridge` to retrieve betting information from the private state document and securely merge it into the local game state. A caching mechanism (`_cachedPrivateData`) was implemented to ensure private data persists across public state updates.

### 2. Permissive Firestore Rules (High)

**Finding:**
The `firestore.rules` configuration allowed any authenticated user to read the `actions`, `joins`, and `chat` subcollections of any game. This could allow a malicious actor to monitor game events (including Ghost Chat and Dead Pool bets) in real-time.

**Remediation:**
-   Updated `firestore.rules` to strictly enforce `read` access on `/actions`, `/joins`, and `/chat`.
-   Access is now restricted to the **Host** only (`request.auth.uid == resource.data.hostId` via parent document lookups).
-   Players can still `create` documents in these collections (submit actions/joins) but cannot read the full history.

### 3. Local Persistence Security (Secure)

**Finding:**
The `PersistenceService` correctly uses `FlutterSecureStorage` to store a generated encryption key for `Hive` boxes. All sensitive local data (active game state, records) is encrypted at rest.

**Status:** No changes required. Current implementation meets industry standards.

### 4. Firebase API Keys (Low)

**Finding:**
Firebase API keys are present in `firebase_options.dart`. While this is standard for Firebase (keys identify the project), unrestricted keys can be abused.

**Recommendation:**
-   Restrict the API keys in the [Google Cloud Console](https://console.cloud.google.com/apis/credentials) to:
    -   **Android/iOS:** Specific package names (`com.clubblackout.cb_host`, `com.clubblackout.player`) and SHA-1 fingerprints.
    -   **Web:** Specific domains (`cb-reborn.web.app`, `localhost`).

## Verification

-   **Firestore Rules:** Verified that `read` rules now include `request.auth.uid == ...hostId` checks.
-   **Host Bridge:** Verified removal of sensitive fields from public maps.
-   **Player Bridge:** Verified implementation of private data merging and caching logic.

## Conclusion

The critical security holes regarding data leakage and access control have been plugged. The system is now significantly more secure against information disclosure attacks during active gameplay.
