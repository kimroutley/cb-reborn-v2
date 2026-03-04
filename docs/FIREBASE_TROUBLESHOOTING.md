# Firebase & Google Sign-In Troubleshooting

If Google Sign-In is failing (e.g., `PlatformException(sign_in_failed, ...)` or `ApiException: 10`), follow these steps to verify your configuration.

## 1. Android Configuration

### A. SHA-1 Fingerprints (CRITICAL)
Google Sign-In on Android requires your app's SHA-1 fingerprint to be registered in the Firebase Console.

1.  **Generate SHA-1 for Debug Key:**
    Run this command in your terminal:
    ```bash
    cd android
    ./gradlew signingReport
    ```
    Look for the `SHA1` under `Task :app:signingReport` -> `Variant: debug`.

2.  **Generate SHA-1 for Release Key (if applicable):**
    If you are building a release APK (`flutter build apk --release`), you must use the SHA-1 from your release keystore.

3.  **Add to Firebase Console:**
    *   Go to [Firebase Console](https://console.firebase.google.com/).
    *   Open **Project Settings** (gear icon).
    *   Scroll down to **Your apps**.
    *   Select the Android app (`com.clubblackout.cb_player` or `com.clubblackout.cb_host`).
    *   Click **Add fingerprint** and paste the SHA-1.
    *   **Download `google-services.json`** again if you added a new fingerprint (though usually not strictly required just for SHA-1 updates, it's good practice).

### B. Package Name Match
Ensure the `package_name` in `google-services.json` matches the `applicationId` in `android/app/build.gradle`.

*   **Player:** `com.clubblackout.cb_player` (or similar, check `build.gradle`)
*   **Host:** `com.clubblackout.cb_host`

### C. Support Email
*   In Firebase Console -> **Project Settings** -> **General**, ensure a **Support email** is selected. Google Sign-In often fails without this.

## 2. Web Configuration

### A. Authorized Domains
1.  Go to [Firebase Console](https://console.firebase.google.com/).
2.  Navigate to **Authentication** -> **Settings** -> **Authorized domains**.
3.  Ensure your hosting domain (e.g., `localhost`, `cb-reborn.web.app`) is listed.

### B. Google Cloud Console (OAuth Consent Screen)
1.  Go to [Google Cloud Console](https://console.cloud.google.com/).
2.  Select your project (`cb-reborn`).
3.  Go to **APIs & Services** -> **Credentials**.
4.  Find the **OAuth 2.0 Client ID** for **Web client (auto created by Google Service)**.
5.  Ensure **Authorized JavaScript origins** includes:
    *   `http://localhost`
    *   `http://localhost:5000` (if running on port 5000)
    *   `https://cb-reborn.web.app`
6.  Ensure **Authorized redirect URIs** includes:
    *   `https://cb-reborn.firebaseapp.com/__/auth/handler`

## 3. Flutter Configuration

### A. `firebase_options.dart`
Ensure you have re-run `flutterfire configure` or manually updated `lib/firebase_options.dart` if you changed any Firebase settings.

*   Check that `android` options have the correct `apiKey` and `appId`.
*   Check that `web` options have the correct `authDomain`, `projectId`, and `appId`.

### B. Dependencies
Ensure `google_sign_in` and `firebase_auth` are compatible.
Run `flutter pub outdated` to check for issues.

## 4. Common Errors

*   **`ApiException: 10` (Android):** Almost always a missing or incorrect SHA-1 fingerprint in Firebase Console.
*   **`PlatformException(popup_closed_by_user, ...)` (Web):** The user closed the popup, or the domain is not authorized.
*   **`PlatformException(sign_in_failed, ...)`:** Generic error. Check Logcat (`adb logcat`) for more details from the native Android side.
