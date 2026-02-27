# Build player web app and append push handler to the service worker.
# Use for local deploy when you want push to work when the app is closed.
# Run from repo root: .\scripts\build_player_web.ps1

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

Push-Location $repoRoot
try {
    Write-Host "Building player web (release)..." -ForegroundColor Cyan
    Push-Location "apps/player"
    try {
        flutter build web --release
    } finally {
        Pop-Location
    }

    Write-Host "Appending push handler to service worker..." -ForegroundColor Cyan
    node scripts/append_push_to_sw.js

    Write-Host "Done. Output: apps/player/build/web" -ForegroundColor Green
    Write-Host "Deploy with: firebase deploy --only hosting (or use scripts/deploy_firebase.ps1 -HostingOnly)"
} finally {
    Pop-Location
}
