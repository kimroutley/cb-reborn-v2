# Security Audit and Enhancement Report

## 1. Security Breaches

### 1.1 Broken Username Uniqueness Check (Firestore Rules vs. Client Logic Mismatch)
- **Issue:** The Firestore rules for `/user_profiles/{uid}` correctly restrict reads to the owning user (`request.auth.uid == uid`). However, `ProfileRepository.isUsernameAvailable` and `isPublicPlayerIdAvailable` attempt to query the entire `user_profiles` collection to check for uniqueness — a query that always fails with `permission-denied` under these rules.
- **Impact:** The uniqueness validation is effectively bypassed at the client layer. The client proceeds as though a username is available because the `permission-denied` error is silently swallowed and treated as `true`.
- **Exploit:** A malicious actor can register a username or public player ID already in use by another player, leading to impersonation attacks. The restrictive rule is correct design; the flaw is the incompatible client-side uniqueness check.
- **Recommendation:** Replace the collection-wide query with a dedicated `usernames` collection (document ID = username, readable by any authenticated user) to enforce uniqueness without exposing full user profiles.

### 1.2 Public Game State Exposure
- **Vulnerability:** The rule for `/games/{joinCode}` allows any authenticated user to read any game document (`allow read: if isAuthenticated();`).
- **Impact:** While `private_state` is protected, the public game state (including player lists, roles if revealed, and chat) is accessible to anyone who can guess a `joinCode`.
- **Recommendation:** Restrict read access to users who are listed in the `players` array or are the host.

## 2. Inconsistencies

### 2.1 Mismatched Data Validation Logic
- **Issue:** The `ProfileRepository` logic in `packages/cb_comms` assumes it can query the entire `user_profiles` collection to check for duplicates. The Firestore rules explicitly deny this.
- **Consequence:** The validation logic is effectively bypassed. The client believes the username is unique, but the database enforcement is missing.
- **Evidence:** `ProfileRepository.isUsernameAvailable` catches `FirebaseException` (code `permission-denied`) and returns `true`, explicitly acknowledging the rule restriction but failing to provide a secure alternative.

### 2.2 Duplicate Account Data
- **Issue:** Due to the vulnerability described above, the database likely contains duplicate `username` and `publicPlayerId` entries, which violates the intended unique constraints of the player management system.

## 3. Dead Code

### 3.1 Unused Analytics Service
- **Issue:** The `AnalyticsService` class in `packages/cb_logic` contained comprehensive methods for tracking game events (`logGameStarted`, `logGameCompleted`, `logRoleAssigned`, etc.) that were never called in the production codebase.
- **Resolution:** We have integrated `AnalyticsService` into `GameProvider` (`startGame`, `_checkAndResolveWinCondition`) to ensure these methods are now active and providing value.

### 3.2 Ineffective Uniqueness Checks
- **Issue:** As noted in 1.1, the uniqueness checks in `ProfileRepository` are dead code in practice because they always return `true` due to permission errors.
- **Recommendation:** Implement a separate `usernames` collection with public read access (document ID = username) to securely enforce uniqueness without exposing full user profiles.

## 4. Errors in Logging

### 4.1 Swallowed Exceptions in Authentication
- **Issue:** The `AuthNotifier` in `apps/player/lib/auth/auth_provider.dart` was catching exceptions during `signInWithGoogle` and `saveUsername` but swallowing them (only updating local state UI).
- **Resolution:** We have updated the catch blocks to explicitly call `AnalyticsService.logError`, ensuring that authentication failures and system breaches are logged with stack traces for proper debugging and security monitoring.

### 4.2 Silent Failures in Profile Repository
- **Issue:** `ProfileRepository` silently swallows `permission-denied` errors during uniqueness checks.
- **Recommendation:** While we fixed the logging in the consumer (`AuthNotifier`), the repository itself should ideally log these internal failures or throw a specific `ConfigurationException` to alert developers of the rule mismatch.

## 5. Compliance with FULL 3 Standards

### 5.1 Data Protection (Non-Compliant)
- **Finding:** The current architecture forces a choice between "broken uniqueness checks" (current state) or "exposing all user profiles" (if rules were relaxed). Both violate high standards of data protection.
- **Remediation:** To comply with FULL 3 Standards for "Secure data storage and transmission," a dedicated lookup mechanism (e.g., a hash-based lookup collection) must be implemented to separate public identity verification from private user data.

### 5.2 User Consent & Privacy
- **Finding:** Google Sign-In provides standard consent mechanisms. However, the potential for username duplication undermines the user's control over their identity within the platform.
- **Action:** Implementing the recommended `usernames` collection will restore integrity to user identities.

## Summary of Actions Taken
1.  **Fixed Logging:** Integrated `AnalyticsService` into `AuthNotifier` to capture authentication and profile creation errors.
2.  **Activated Dead Code:** Wired up `AnalyticsService` in `GameProvider` to track game start and completion events.
3.  **Identified Critical Vulnerability:** Flagged the broken username uniqueness check and Firestore rule mismatch for immediate architectural review.
