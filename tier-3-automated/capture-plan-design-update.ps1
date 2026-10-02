<#
.SYNOPSIS
  Portable capture for the parked design-update /plan golden run (Tier-2 invariants #200/#201).

.DESCRIPTION
  Produces fixtures/golden-runs/plan-design-update/ by driving a real design-taskboard project:
    intake (live)  ->  edit the design (free)  ->  /plan parks a design-update epic (live)  ->  freeze.
  No prior BUILD or GitHub is needed: /plan plans against the design digest and runs on a bare LOCAL
  git remote (verified against plan.md / continue.md). Run in PHASES so the "is blue a real decision?"
  risk is verified between intake and plan.

  PORTABILITY: no hard-coded machine paths — every root is a parameter or derived from this script's
  location. SPEND SAFETY: nothing signs in or spends unless a live phase (intake|plan) is named, and
  each live step prints a sign-in + cost notice first.

.PARAMETER TemplateRoot
  A release-shaped Stadium-8 checkout that has /plan + design-update + design-interpreter.

.PARAMETER Phase
  dryrun (default, no spend): run setup only and describe the live steps.
  setup : scaffold the work repo + bare local remote (free).
  intake: live /start intake (needs setup). STOPS after the intake commit.
  plan  : edit the design (pink primary + button rename), then live /plan to park the design-update epic.
  freeze: bundle + meta into the slot, gated on a real, conforming capture (free).

.EXAMPLE
  pwsh -File capture-plan-design-update.ps1 -TemplateRoot C:\path\to\release-checkout -Phase setup
#>
param(
  [Parameter(Mandatory)][string]$TemplateRoot,
  [ValidateSet('dryrun','setup','intake','plan','freeze')][string]$Phase = 'dryrun',
  [string]$RepoRoot  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$WorkRoot  = ([System.IO.Path]::GetTempPath()),
  [string]$Benchmark = 'design-taskboard',
  [string]$Model     = 'opus',
  [string]$PinkHex   = '#ec4899'
)
$ErrorActionPreference = 'Stop'

$bench  = Join-Path $RepoRoot    "benchmark-files/$Benchmark"
$slot   = Join-Path $RepoRoot    'fixtures/golden-runs/plan-design-update'
$work   = Join-Path $WorkRoot    'plan-design-update-run'
$remote = Join-Path $WorkRoot    'plan-design-update-remote.git'
$logDir = Join-Path $WorkRoot    'plan-design-update-logs'
# The non-styling project fact #200 checks landed on main, and the design facts #201 checks:
$FactNeedle = 'Priority'

function Say([string]$m) { Write-Output $m }

function Assert-Setup {
  if (-not (Test-Path (Join-Path $work '.claude'))) { throw "No work repo at $work — run -Phase setup first." }
}

# One headless claude call inside $work. Prints the sign-in/cost notice; returns the exit code.
function Invoke-Capture([string]$PromptText, [string]$Name) {
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $pf = Join-Path $logDir "$Name.prompt.txt"
  $out = Join-Path $logDir "$Name.jsonl"
  $err = "$out.err"
  Say "─────────────────────────────────────────────────────────────"
  Say "LIVE STEP '$Name': this uses the locally signed-in Claude CLI and SPENDS tokens."
  Say "  model=$Model  workdir=$work  log=$out"
  Say "─────────────────────────────────────────────────────────────"
  Set-Content $pf $PromptText -Encoding utf8 -NoNewline
  $env:CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS = '0'
  $inner = "claude -p --output-format stream-json --verbose --dangerously-skip-permissions --model $Model < `"$pf`" > `"$out`" 2> `"$err`""
  Push-Location $work
  cmd.exe /s /c "$inner"
  $code = $LASTEXITCODE
  Pop-Location
  Say "claude exit=$code"
  return $code
}

function Do-Setup {
  foreach ($p in @($work, $remote, $logDir)) { if (Test-Path $p) { Remove-Item $p -Recurse -Force } }
  if (-not (Test-Path (Join-Path $TemplateRoot '.claude/commands/plan.md'))) {
    throw "TemplateRoot $TemplateRoot has no .claude/commands/plan.md — needs a checkout with the /plan + design features."
  }
  Copy-Item $TemplateRoot $work -Recurse
  # Drop the design into documentation/design/ + the gap-filler answers (mirrors the Tier-3 scaffold).
  $desDst = Join-Path $work 'documentation/design'
  New-Item -ItemType Directory -Force -Path $desDst | Out-Null
  Copy-Item (Join-Path $bench 'frontend/docs/design/*') $desDst -Recurse -Force
  Copy-Item (Join-Path $bench 'answers.json') (Join-Path $work 'TIER3-ANSWERS.json') -Force
  # A bare LOCAL remote so /plan's `worktree add ... origin/main` and `push origin HEAD:main` work (no GitHub).
  & git init --bare -q $remote
  Push-Location $work
  & git init -q
  & git symbolic-ref HEAD refs/heads/main
  & git -c user.email=t@t.co -c user.name=tier3 add -A | Out-Null
  & git -c user.email=t@t.co -c user.name=tier3 commit -qm "chore: scaffold design-taskboard (pre-intake)" | Out-Null
  & git remote add origin $remote
  & git push -q origin main
  Pop-Location
  Say "SETUP done:"
  Say "  work   = $work"
  Say "  remote = $remote (bare, local)"
  Say "  design = documentation/design/ (blue #2563eb primary)"
}

function Do-Intake {
  Assert-Setup
  $answers = Get-Content (Join-Path $work 'TIER3-ANSWERS.json') -Raw
  $prompt = @"
You are in a freshly scaffolded Stadium 8 build-from-design project. Do the INTAKE only - do NOT build.

1. Run /start. It reads the design under documentation/design/ and runs INTAKE.
2. Answer EVERY question WITHOUT pausing - this is unattended, there is no human to reply:
   - Use these pre-approved answers (match by intent), including the design read-back confirmation:
$answers
   - IMPORTANT: record the primary colour as a CONFIRMED styling DECISION (primary #2563eb / blue,
     from the design tokens) - it must be a saved decision, not just a palette note.
   - For the Claude Code git-handling setup question choose "Auto-approve both"; for any other setup
     prompt take the recommended/default and keep going. NEVER stop to ask me.
3. STOP the instant INTAKE is committed to main (the "docs(project): ..." commit). Do NOT plan or
   build any epic, do NOT run /continue. After that commit you are done.

Follow CLAUDE.md and .claude/ exactly.
"@
  $code = Invoke-Capture $prompt 'intake'
  Push-Location $work; $subjects = (& git log --format=%s 2>$null) -join "`n"; Pop-Location
  if ($subjects -notmatch 'docs\(project\)') { Say "INTAKE did not commit (no docs(project)). See the log; not proceeding."; return }
  Say "INTAKE committed. NEXT: verify blue is a saved DECISION (not just a token) before -Phase plan."
  Say "  check: generated-docs/design/digest.md 'Your Decisions' + generated-docs/project.md §Styling"
}

function Edit-Design {
  # The free design edit: pink primary (conflicts with the recorded blue) + one button rename.
  $tokens = Join-Path $work 'documentation/design/tokens.css'
  (Get-Content $tokens -Raw) -replace '#2563eb', $PinkHex -replace '#1d4ed8', $PinkHex | Set-Content $tokens -NoNewline
  foreach ($f in @('design-notes.md','mockup.html')) {
    $p = Join-Path $work "documentation/design/$f"
    if (Test-Path $p) { (Get-Content $p -Raw) -replace 'New task','Add task' | Set-Content $p -NoNewline }
  }
  Say "DESIGN edited: primary -> $PinkHex (pink), 'New task' -> 'Add task'."
}

function Do-Plan {
  Assert-Setup
  Edit-Design
  $prompt = @"
You are picking up a built-from-design Stadium 8 project to PLAN ahead - do NOT build.

Run /plan. In this one planning session:
1. A project fact changes: add a "Priority" field (Low | Medium | High) to a task. Land this fact on
   main now (it does not wait for a build).
2. A design-update epic: I edited the design in documentation/design/ - rebuild the Board and Task
   detail screens to match it. When the updated design's primary colour (pink $PinkHex) conflicts with
   the recorded blue #2563eb decision, ASK which wins and I answer: USE PINK (the new design wins) -
   record that as a held design decision.
Park the design-update epic at READY-TO-BUILD (write its epic-plan row + state.json on main, remove the
worktree). Answer every question without pausing; for any setup prompt take the default. STOP once the
epic is parked - do NOT build it, do NOT run /continue.

Follow CLAUDE.md and .claude/ exactly.
"@
  $code = Invoke-Capture $prompt 'plan'
  Push-Location $work; $subjects = (& git log --format=%s 2>$null) -join "`n"; Pop-Location
  if ($subjects -notmatch 'docs\(plan\)') { Say "PLAN did not park (no docs(plan) commit). See the log; not freezing."; return }
  Say "PLAN parked. NEXT: -Phase freeze (gated on fact-on-main + a held decision)."
}

function Do-Freeze {
  Assert-Setup
  Push-Location $work
  $subjects   = (& git log --format=%s 2>$null) -join "`n"
  $planCommit = (& git log --format=%H -n 1 --grep 'docs(plan)' 2>$null | Select-Object -First 1)
  $projectMd  = (& git show "main:generated-docs/project.md" 2>$null) -join "`n"
  # find the parked epic's state.json on main
  $statePaths = @(& git ls-tree -r --name-only main 2>$null | Where-Object { $_ -match 'generated-docs/epics/.+/state\.json$' })
  Pop-Location
  $fail = @()
  if ($subjects -notmatch 'docs\(plan\)') { $fail += 'no docs(plan) commit' }
  if ($projectMd -notmatch [regex]::Escape($FactNeedle)) { $fail += "fact '$FactNeedle' not on main" }
  $parkedState = $null
  foreach ($sp in $statePaths) {
    $json = (& git -C $work show "main:$sp" 2>$null) -join "`n"
    if ($json -match '"parkedDesignUpdate"\s*:\s*true') { $parkedState = $sp; $parkedJson = $json; break }
  }
  if (-not $parkedState) { $fail += 'no parked design-update state.json on main' }
  elseif ($parkedJson -notmatch '"designDecisions"\s*:\s*\[\s*\{') { $fail += 'held design decision missing (designDecisions empty) - the pink/blue conflict did not fire' }

  if ($fail.Count) { Say ("NOT FREEZING - " + ($fail -join '; ') + ". See logs in $logDir."); return }

  New-Item -ItemType Directory -Force -Path $slot | Out-Null
  Push-Location $work; & git bundle create (Join-Path $slot 'repo.bundle') --all | Out-Null; Pop-Location
  @{
    benchmark       = $Benchmark
    scenario        = 'plan-design-update'
    capturedFrom    = (Split-Path $TemplateRoot -Leaf)
    factNeedle      = $FactNeedle
    parkedStatePath = $parkedState
    planCommit      = $planCommit
    note            = 'live intake + /plan parked design-update (pink wins); no build/merge; bundling verifies a real conforming park, not full spec-conformance (see the Tier-2 suite)'
  } | ConvertTo-Json | Set-Content (Join-Path $slot 'meta.json')
  Say "FROZEN -> $slot (factNeedle=$FactNeedle, parkedStatePath=$parkedState, planCommit=$planCommit)"
}

switch ($Phase) {
  'setup'  { Do-Setup }
  'intake' { Do-Intake }
  'plan'   { Do-Plan }
  'freeze' { Do-Freeze }
  default  {
    Say "DRY RUN (no spend). Would run, in order:"
    Say "  1. -Phase setup   scaffold $work + bare remote $remote (free)"
    Say "  2. -Phase intake  LIVE /start intake (spends; signs in locally); stops after the intake commit"
    Say "     -> then VERIFY blue is a saved decision before step 3"
    Say "  3. -Phase plan    edit design (pink + rename), LIVE /plan to park the design-update (spends)"
    Say "  4. -Phase freeze  bundle -> $slot, gated on fact-on-main + a held decision (free)"
    Say ""
    Say "Template: $TemplateRoot"
    Say "Nothing has been run. Re-invoke with -Phase setup to begin."
  }
}
