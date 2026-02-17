param(
  [switch]$NoPrompt,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-GitRepo {
  try {
    git rev-parse --is-inside-work-tree | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Get-ChangedForFiles {
  param([string[]]$Files)

  $changed = @()
  foreach ($file in $Files) {
    $status = git status --porcelain -- "$file"
    if (-not [string]::IsNullOrWhiteSpace($status)) {
      $changed += $file
    }
  }
  return $changed
}

function Invoke-CommitGroup {
  param(
    [string]$Name,
    [string[]]$Files,
    [string]$Message
  )

  Write-Host "`n=== $Name ===" -ForegroundColor Cyan

  $changed = Get-ChangedForFiles -Files $Files
  if ($changed.Count -eq 0) {
    Write-Host "No changed files found for this group. Skipping." -ForegroundColor Yellow
    return
  }

  if ($DryRun) {
    Write-Host "[DRY-RUN] Would stage and commit these files:" -ForegroundColor Magenta
    $changed | ForEach-Object { Write-Host "  + $_" }
    Write-Host "[DRY-RUN] Commit message: $Message" -ForegroundColor Magenta
    return
  }

  foreach ($f in $changed) {
    git add -- "$f"
  }

  Write-Host "Staged files for ${Name}:" -ForegroundColor Green
  git diff --staged --name-only -- $changed

  if (-not $NoPrompt) {
    $choice = Read-Host "Commit this group now? (y=commit, n=unstage+skip, q=quit)"
    switch ($choice.ToLowerInvariant()) {
      'y' {
        git commit -m "$Message"
        return
      }
      'q' {
        throw "User aborted."
      }
      default {
        git restore --staged -- $changed
        Write-Host "Skipped and unstaged group: $Name" -ForegroundColor Yellow
        return
      }
    }
  }

  git commit -m "$Message"
}

if (-not (Test-GitRepo)) {
  throw "Not inside a git repository. Run this from the repo root."
}

$repoRoot = git rev-parse --show-toplevel
Set-Location $repoRoot

$groups = @(
  @{ 
    Name = '1) Player deep-link guardrails + navigation tests';
    Message = 'fix(player): debounce join links and prevent duplicate claim navigation';
    Files = @(
      'apps/player/lib/screens/home_screen.dart',
      'apps/player/lib/screens/connect_screen.dart',
      'apps/player/test/join_url_parser_test.dart',
      'apps/player/test/join_link_debounce_test.dart',
      'apps/player/test/connect_screen_navigation_guard_test.dart'
    )
  },
  @{
    Name = '2) Role mechanics parity (night actions) + tests';
    Message = 'feat(cb_logic): align night action messaging with mechanics spec';
    Files = @(
      'packages/cb_logic/lib/src/night_actions/actions/sober_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/roofi_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/bouncer_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/bartender_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/club_manager_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/messy_bitch_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/lightweight_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/dealer_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/attack_dog_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/messy_bitch_kill_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/medic_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/silver_fox_action.dart',
      'packages/cb_logic/lib/src/night_actions/actions/whore_action.dart',
      'packages/cb_logic/lib/src/night_actions/night_action_strategy.dart',
      'packages/cb_logic/test/night_resolution_test.dart',
      'packages/cb_logic/test/game_resolution_logic_test.dart'
    )
  },
  @{
    Name = '3) Host setup UX + release/CI hardening';
    Message = 'feat(host): add manual role assignment UX and harden release CI';
    Files = @(
      'apps/host/lib/screens/lobby_screen.dart',
      'apps/host/lib/screens/host_home_shell.dart',
      'apps/host/lib/widgets/lobby/lobby_config_tile.dart',
      'apps/host/lib/sync_mode_runtime.dart',
      'apps/host/test/sync_mode_runtime_test.dart',
      'apps/host/android/key.properties.example',
      'apps/host/README.md',
      '.github/workflows/ci-cd.yml'
    )
  },
  @{
    Name = '4) Docs + handoff sync';
    Message = 'docs: sync roadmap and verification handoff status';
    Files = @(
      'README.md',
      'PROJECT_DEVELOPER_HANDBOOK.md',
      'GEMINI_HANDOFF_LIST.txt',
      'COMMIT_CHECKLIST.md'
    )
  }
)

foreach ($group in $groups) {
  Invoke-CommitGroup -Name $group.Name -Files $group.Files -Message $group.Message
}

if ($DryRun) {
  Write-Host "`nDry run complete. Repository state unchanged." -ForegroundColor Cyan
  return
}

Write-Host "`nDone. Final repo status:" -ForegroundColor Cyan
git status --short
