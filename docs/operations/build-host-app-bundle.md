# Build Host App Bundle (Play Store)

For a smaller, optimized release for Google Play, build an **Android App Bundle** instead of a standalone APK.

## Command

From the repo root:

```bash
cd apps/host
flutter build appbundle
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Notes

- Play Store uses the AAB to generate split APKs per device (smaller downloads).
- For local testing or sideload, continue using `flutter build apk`; the APK is in `build/app/outputs/flutter-apk/app-release.apk`.
