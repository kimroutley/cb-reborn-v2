[CmdletBinding()]
param(
	[switch]$SkipBuild,
	[switch]$HostingOnly,
	[switch]$RulesOnly
)

$ErrorActionPreference = "Stop"

if ($HostingOnly -and $RulesOnly) {
	throw "Use only one of -HostingOnly or -RulesOnly."
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$defaultCredPath = Join-Path $repoRoot ".secrets\firebase-adminsdk.json"

if ([string]::IsNullOrWhiteSpace($env:GOOGLE_APPLICATION_CREDENTIALS)) {
	if (Test-Path $defaultCredPath) {
		$env:GOOGLE_APPLICATION_CREDENTIALS = $defaultCredPath
	}
}

if ([string]::IsNullOrWhiteSpace($env:GOOGLE_APPLICATION_CREDENTIALS)) {
	throw "GOOGLE_APPLICATION_CREDENTIALS is not set and default credential file was not found at '$defaultCredPath'."
}

if (-not (Test-Path $env:GOOGLE_APPLICATION_CREDENTIALS)) {
	throw "Credential file not found: $($env:GOOGLE_APPLICATION_CREDENTIALS)"
}

$firebaseCmd = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseCmd) {
	throw "Firebase CLI is not installed or not on PATH. Install with: npm install -g firebase-tools"
}

$deployTarget = "hosting,firestore:rules"
if ($HostingOnly) {
	$deployTarget = "hosting"
} elseif ($RulesOnly) {
	$deployTarget = "firestore:rules"
}

Push-Location $repoRoot
try {
	if (-not $SkipBuild -and -not $RulesOnly) {
		Write-Host "Building Player web (release)..." -ForegroundColor Cyan
		Push-Location "apps/player"
		try {
			flutter build web --release --no-wasm-dry-run
		} finally {
			Pop-Location
		}
	}

	Write-Host "Deploying Firebase target: $deployTarget" -ForegroundColor Cyan
	firebase deploy --project cb-reborn --only $deployTarget

	Write-Host "Deploy complete." -ForegroundColor Green
	Write-Host "Credentials file used: $($env:GOOGLE_APPLICATION_CREDENTIALS)"
} finally {
	Pop-Location
}
