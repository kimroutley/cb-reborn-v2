Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RelativeFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        return @()
    }

    $base = (Resolve-Path -LiteralPath $Root).Path
    Get-ChildItem -LiteralPath $base -Recurse -File | ForEach-Object {
        $_.FullName.Substring($base.Length).TrimStart('\', '/')
    }
}

$leftRoot = '.agents/skills'
$rightRoot = '.claude/skills'

if (-not (Test-Path -LiteralPath $leftRoot)) {
    throw "Missing required directory: $leftRoot"
}

if (-not (Test-Path -LiteralPath $rightRoot)) {
    throw "Missing required directory: $rightRoot"
}

$leftFiles = @(Get-RelativeFiles -Root $leftRoot)
$rightFiles = @(Get-RelativeFiles -Root $rightRoot)

$allFiles = @($leftFiles + $rightFiles | Sort-Object -Unique)
$mismatches = @()

foreach ($relative in $allFiles) {
    $leftPath = Join-Path $leftRoot $relative
    $rightPath = Join-Path $rightRoot $relative

    $leftExists = Test-Path -LiteralPath $leftPath
    $rightExists = Test-Path -LiteralPath $rightPath

    if (-not $leftExists -or -not $rightExists) {
        $mismatches += "Missing counterpart for '$relative' (left=$leftExists right=$rightExists)"
        continue
    }

    $leftHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $leftPath).Hash
    $rightHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $rightPath).Hash

    if ($leftHash -ne $rightHash) {
        $mismatches += "Content mismatch for '$relative'"
    }
}

if ($mismatches.Count -gt 0) {
    Write-Host '❌ Skill sync check failed:' -ForegroundColor Red
    $mismatches | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host '✅ Skill sync check passed (.agents/skills <-> .claude/skills)' -ForegroundColor Green
