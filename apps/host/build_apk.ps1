Set-Location .\apps\host
flutter pub get
flutter build apk --release
if (Test-Path "build\app\outputs\flutter-apk\app-release.apk") {
    Write-Host "SUCCESS: APK generated at apps\host\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
} else {
    Write-Host "FAILURE: APK not found" -ForegroundColor Red
}
