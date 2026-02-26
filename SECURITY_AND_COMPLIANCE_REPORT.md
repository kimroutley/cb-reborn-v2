# Security and Compliance Report: Player Logging and Profile Editing

## 1. Security Breach Analysis

### Authentication Vulnerabilities
*   **Method**: Authentication relies on Firebase Auth (Google Sign-In).
*   **Findings**: The implementation correctly uses `FirebaseAuth` and `GoogleSignIn`. The `auth_provider.dart` handles authentication state changes and profile loading.
*   **Risks**:
    *   No major vulnerabilities found in the authentication flow itself.
    *   Error handling was previously generic, masking potential specific attack vectors or system failures. This has been mitigated by adding error logging.

### SQL Injection & Data Sanitization
*   **Database**: Uses Cloud Firestore (NoSQL), making traditional SQL injection impossible.
*   **Sanitization**:
    *   Input fields (`username`, `publicPlayerId`, `avatarEmoji`) are trimmed using `.trim()`.
    *   `ProfileRepository.normalizePublicPlayerId` restricts characters to `a-z0-9_-`.
    *   `username` length is checked (`>= 3`).
    *   Firestore rules enforce string types and length limits (e.g., `name` <= 50 chars).
*   **Recommendation**: Implement profanity filtering for usernames and stricter validation for "emoji" fields to ensure they are valid unicode emojis.

### Access Control
*   **Mechanisms**: Controlled via `firestore.rules`.
*   **Findings**:
    *   **Profile Editing**: `match /user_profiles/{uid}` correctly restricts `write` access to `request.auth.uid == uid`. Users can only modify their own profiles.
    *   **Game State**: `match /games/{joinCode}` allows `read` access to *any* authenticated user.
*   **Risk**: If a `joinCode` is guessed or leaked, any authenticated user can monitor the public state of a game. This is a potential privacy concern, though may be intended for "spectator" functionality.
*   **Recommendation**: Consider restricting game read access to players listed in the `players` array or implementing a specific "spectator" list.

### Data Encryption
*   **Transmission**: All data transmission to/from Firebase is encrypted via TLS (HTTPS).
*   **Storage**: Firebase encrypts data at rest automatically.
*   **Compliance**: Adheres to standard security practices for cloud-hosted data.

## 2. Inconsistencies

### Logging vs. Database
*   **Findings**:
    *   Game events (start, role assignment, death, end) are logged to Firebase Analytics via `AnalyticsService`.
    *   **Gap**: Profile creation and updates were *not* previously logged to Analytics. This created a blind spot where user registration activity could not be correlated with game activity in analytics reports.
*   **Resolution**: Added `AnalyticsService.logError` to capture failures. However, success events for profile updates are still not explicitly logged to Analytics (only implicitly via screen views or if added in future).

### Data Fields
*   **Schema**: `ProfileRepository` handles fields like `username`, `email`, `publicPlayerId`, `avatarEmoji`.
*   **Consistency**: Firestore rules for `user_profiles` do not strictly enforce the schema of the document, only the ownership. This allows potentially extra fields to be added by a malicious client (though they would only affect their own profile).

## 3. Dead Code Identification

### Unused Functions/Variables
*   `AnalyticsService`: Several methods (e.g., `logError`) were available but unused in the player app until the recent fix.
*   `ProfileRepository`: Static methods like `normalizePublicPlayerId` are used. `maskEmail` appears to be used for UI display (though exact usage in UI wasn't verified, it's a utility function).

## 4. Error Detection

### Implementation
*   **Previous State**: `auth_provider.dart` caught exceptions but swallowed the stack trace and specific error message, replacing it with a generic "System breach" message.
*   **New Implementation**: Added `AnalyticsService.logError(e.toString(), stackTrace: stack.toString())` to `signInWithGoogle` and `saveUsername` methods.
*   **Effectiveness**: Now, runtime errors during authentication and profile creation are logged to Firebase Analytics, allowing developers to diagnose issues that users encounter in the wild.

## 5. Profile Editing Features

### User Experience & Material Design 3
*   **UI Components**:
    *   `CBTextField`: Uses `OutlineInputBorder` and a custom "glassmorphism" fill (`surfaceContainerHighest` with low alpha). This is a custom styling on top of Material 3 concepts. It uses `Theme.of(context).colorScheme`, ensuring consistency with the app's dynamic theme.
    *   `CBPrimaryButton`: Uses `FilledButton`, which is the standard Material 3 high-emphasis button.
*   **Flow**: The profile setup form (`_ProfileSetupForm`) is clear, asking for a "Moniker" and optional "Public Player ID".
*   **Responsiveness**: The UI is wrapped in `SingleChildScrollView`, handling different screen sizes and keyboard appearance.

## 6. Compliance Check

### Google Material Design 3
*   **Adherence**:
    *   **Color System**: Uses `DynamicColorBuilder` and `ColorScheme` derived from seeds, complying with Material 3 dynamic color system.
    *   **Typography**: Uses `Theme.of(context).textTheme` (e.g., `headlineMedium`, `bodyLarge`), aligning with the type scale.
    *   **Components**: Uses standard Flutter Material 3 widgets (`FilledButton`, `TextField` with `InputDecoration`) or custom wrappers that respect the theme.
*   **Accessibility**:
    *   `CBTextField` supports standard accessibility features (hints, labels).
    *   Contrast ratios should be verified in the generated theme, especially with the "glass" transparency effects.

### Usability
*   **Feedback**: Haptic feedback is implemented (`HapticFeedback.heavyImpact()`, `HapticService.light()`) on interactions, enhancing usability.
*   **Error Messages**: The UI displays error messages returned by the `AuthNotifier` (e.g., "Handle already claimed").

## Recommendations Summary
1.  **Security**: Review `firestore.rules` for the `games` collection to see if read access can be tightened.
2.  **Validation**: Add server-side validation (Cloud Functions or stricter rules) for `username` content (profanity filter).
3.  **Analytics**: Consider adding success events for profile updates to `AnalyticsService` (e.g., `logEvent(name: 'profile_updated')`) to complete the audit trail.
