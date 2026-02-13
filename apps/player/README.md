# cb_player (Player App)

Player app for Club Blackout Reborn.

## What this app does

- Joins host sessions via local or cloud mode
- Supports QR/URL join payload parsing (`mode`, `code`, `host`)
- Runs role prompts, voting, and player game feed
- Tracks player-facing history and profile-linked stats

## Run

```powershell
cd apps/player
flutter run
```

## Firebase Auth Setup (Email Link)

Player uses **Firebase Email Link (passwordless)** sign-in.

- Firebase Console → Authentication → Sign-in method: enable **Email/Password**.
- Firebase Console → Authentication → Sign-in method: enable **Email link (passwordless sign-in)**.
- Ensure authorized domains include `cb-reborn.web.app`.
- Continue URL used by Player auth gate: `https://cb-reborn.web.app/email-link-signin?app=player`.
- Current `ActionCodeSettings` app IDs:
  - Android: `com.clubblackout.player`
  - iOS: `com.clubblackout.player`

If your Firebase project uses different package/bundle IDs, update Player auth settings before release.

## Firebase Auth Preflight (Quick Check)

Before testing Player sign-in, confirm all 5 are true:

- [ ] **Email/Password** provider is enabled.
- [ ] **Email link (passwordless)** provider is enabled.
- [ ] `cb-reborn.web.app` is listed in Authentication authorized domains.
- [ ] Continue URL matches Player flow: `https://cb-reborn.web.app/email-link-signin?app=player`
- [ ] Player IDs match Firebase app registration (`com.clubblackout.player` for Android + iOS).

## Firebase Email Link Troubleshooting

- `auth/invalid-action-code`: request a new Player sign-in link and use only the latest email.
- `auth/unauthorized-continue-uri`: add `cb-reborn.web.app` (or your domain) to Firebase Authentication authorized domains.
- `auth/operation-not-allowed`: ensure both **Email/Password** and **Email link (passwordless)** are enabled.
- Link opens but Player does not sign in: verify Player `ActionCodeSettings` IDs match Firebase app registration (`com.clubblackout.player` for Android and iOS).
