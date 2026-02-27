# Generate VAPID keys for Web Push and print next steps.
# Run from repo root: .\scripts\setup_push_vapid.ps1

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

Push-Location $repoRoot
try {
    Write-Host "Installing functions dependencies..." -ForegroundColor Cyan
    Push-Location "functions"
    try {
        npm install 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "npm install failed" }
    } finally {
        Pop-Location
    }

    Write-Host "Generating VAPID keys..." -ForegroundColor Cyan
    Push-Location "functions"
    try {
        npx web-push generate-vapid-keys
    } finally {
        Pop-Location
    }

    Write-Host ""
    Write-Host "=== Copy the Public Key and Private Key from above ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Then run (replace PASTE_PUBLIC_KEY and PASTE_PRIVATE_KEY):" -ForegroundColor Yellow
    Write-Host '  firebase functions:config:set vapid.public_key="PASTE_PUBLIC_KEY" vapid.private_key="PASTE_PRIVATE_KEY"'
    Write-Host ""
    Write-Host "Edit apps/player/lib/services/push_subscription_register.dart:"
    Write-Host "  const String vapidPublicKeyBase64 = 'PASTE_PUBLIC_KEY';"
    Write-Host ""
    Write-Host "Deploy:"
    Write-Host "  firebase deploy --only functions"
    Write-Host ""
    Write-Host "Full runbook: docs/operations/LETS_DO_IT_RUNBOOK.md Section 2" -ForegroundColor Cyan
} finally {
    Pop-Location
}
