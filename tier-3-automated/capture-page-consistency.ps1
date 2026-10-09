<#
.SYNOPSIS
  LIVE Tier-3 capture (spends tokens) that produces the Tier-2 page-consistency offline fixture.

.DESCRIPTION
  Produces fixtures/page-consistency/ by driving TWO real projects to the gates that emit the review pages:

    Project A = minimal-concurrent (the cheapest 2-epic spec, but the HEAVIEST leg: manual-tests.html is only
      written AFTER a full green epic-end — build + quality gates + Playwright E2E — so expect retries):
      /start -> approve intake -> /continue to PLAN (writes epic-plan-review.html + first epic's
      stories-review.html) -> approve stories -> build through EPIC-END into MANUAL-TEST (writes
      manual-tests.html). STOP before merge. Yields 3 pages.
    Project B = transactions (distinct richer 2-epic spec):
      /start -> approve intake -> /continue to PLAN (writes epic-plan-review.html + stories-review.html).
      STOP at the stories gate. Yields 2 pages.

  The 5 generated pages are git-ignored inside each scaffold; `freeze` copies them OUT into the committed
  slot (preserving the committed calibration/ fixtures) and VERIFIES each project stopped at the intended
  phase (A=MANUAL-TEST, B=PLAN) via state.json. After freeze the test runs offline (vitest + Chromium, no
  AI). The calibration that proves the checks bite is HAND-AUTHORED and committed under
  fixtures/page-consistency/calibration/ — freeze does NOT generate it.

  PORTABILITY: no hard-coded machine paths — every root is a parameter or derived from this script's
  location (mirrors capture-plan-design-update.ps1). SPEND SAFETY: nothing signs in or spends unless a
  LIVE phase (A-stories|A-manual|B-stories) is named, and each live step prints a sign-in + cost notice.

.PARAMETER TemplateRoot
  A Stadium-8 checkout whose /start + /continue emit the three review pages (epic-plan-review.html,
  stories-review.html, manual-tests.html) per .claude/shared/approval-pattern.md.

.PARAMETER Phase
  dryrun (default, no spend): describe the live steps; run nothing.
  setup  : scaffold both work repos (A and B) + a bare local remote each (free).
  A-stories: LIVE — project A /start+intake, /continue to the first stories page. (spends)
  A-manual : LIVE — continue project A through to the manual-test page. (spends; needs A-stories first)
  B-stories: LIVE — project B /start+intake, /continue to the first stories page. (spends)
  freeze : copy the 5 pages into fixtures/page-consistency/ + write calibration; gated on all 5 present.

.EXAMPLE
  pwsh -File capture-page-consistency.ps1 -TemplateRoot C:\path\to\checkout -Phase setup
#>
param(
  [Parameter(Mandatory)][string]$TemplateRoot,
  [ValidateSet('dryrun','setup','A-stories','A-manual','B-stories','freeze')][string]$Phase = 'dryrun',
  [string]$RepoRoot   = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$WorkRoot   = ([System.IO.Path]::GetTempPath()),
  [string]$BenchmarkA = 'minimal-concurrent',
  [string]$BenchmarkB = 'transactions',
  [string]$Model      = 'opus'
)
$ErrorActionPreference = 'Stop'

# Reuse the real scaffold used by the live driver (copies the template, drops benchmark docs into
# documentation/, and places TIER3-ANSWERS.json at the root for unattended gate answers).
. (Join-Path $PSScriptRoot 'live-driver.ps1')

$slot = Join-Path $RepoRoot 'fixtures/page-consistency'
$workA = Join-Path $WorkRoot 'page-consistency-A'
$workB = Join-Path $WorkRoot 'page-consistency-B'
$remoteA = Join-Path $WorkRoot 'page-consistency-A-remote.git'
$remoteB = Join-Path $WorkRoot 'page-consistency-B-remote.git'
$logDir = Join-Path $WorkRoot 'page-consistency-logs'

function Say([string]$m) { Write-Output $m }

function Assert-Work([string]$w, [string]$which) {
  if (-not (Test-Path (Join-Path $w '.claude'))) { throw "No work repo for project $which at $w — run -Phase setup first." }
}

# One headless claude call inside $work. Prints the sign-in/cost notice; returns the exit code. Has a hard
# timeout + process-tree kill (like Invoke-ClaudeHeadless) so a hung gate can't block the capture forever.
function Invoke-Capture([string]$Work, [string]$PromptText, [string]$Name, [int]$TimeoutSeconds = 86400) {
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $pf = Join-Path $logDir "$Name.prompt.txt"
  $out = Join-Path $logDir "$Name.jsonl"
  $err = "$out.err"
  Say "─────────────────────────────────────────────────────────────"
  Say "LIVE STEP '$Name': uses the locally signed-in Claude CLI and SPENDS tokens."
  Say "  model=$Model  workdir=$Work  log=$out  timeout=${TimeoutSeconds}s"
  Say "─────────────────────────────────────────────────────────────"
  Set-Content $pf $PromptText -Encoding utf8 -NoNewline
  $env:CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS = '0'
  $inner = "claude -p --output-format stream-json --verbose --dangerously-skip-permissions --model $Model < `"$pf`" > `"$out`" 2> `"$err`""
  $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList "/s /c `"$inner`"" -WorkingDirectory $Work -NoNewWindow -PassThru
  if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
    Say "TIMEOUT after ${TimeoutSeconds}s — killing the run (see $out / $err)."
    Stop-ProcessTree -ProcessId $proc.Id   # from live-driver.ps1 (dot-sourced)
    try { $proc.WaitForExit(5000) | Out-Null } catch { }
    return 124
  }
  $code = $proc.ExitCode
  Say "claude exit=$code"
  return $code
}

function New-WorkRepo([string]$Benchmark, [string]$Work, [string]$Remote) {
  foreach ($p in @($Work, $Remote)) { if (Test-Path $p) { Remove-Item $p -Recurse -Force } }
  $benchDir = Join-Path $RepoRoot "benchmark-files/$Benchmark"
  if (-not (Test-Path $benchDir)) { throw "No benchmark at $benchDir" }
  New-Tier3Scaffold -TemplateRoot $TemplateRoot -WorkingDir $Work -BenchmarkDir $benchDir | Out-Null
  # A bare LOCAL remote so epic-branch create/push works without GitHub.
  & git init --bare -q $Remote
  Push-Location $Work
  & git init -q
  & git symbolic-ref HEAD refs/heads/main
  & git -c user.email=t@t.co -c user.name=capture add -A | Out-Null
  & git -c user.email=t@t.co -c user.name=capture commit -qm "chore: scaffold $Benchmark (pre-intake)" | Out-Null
  & git remote add origin $Remote
  & git push -q origin main
  Pop-Location
  Say "  scaffolded $Benchmark -> $Work (remote $Remote)"
}

function Do-Setup {
  if (-not (Test-Path (Join-Path $TemplateRoot '.claude/shared/approval-pattern.md'))) {
    throw "TemplateRoot $TemplateRoot has no .claude/shared/approval-pattern.md — needs a checkout that emits the review pages."
  }
  if (Test-Path $logDir) { Remove-Item $logDir -Recurse -Force }
  Say "SETUP:"
  New-WorkRepo $BenchmarkA $workA $remoteA
  New-WorkRepo $BenchmarkB $workB $remoteB
  Say "SETUP done. NEXT (each spends): -Phase A-stories, -Phase A-manual, -Phase B-stories, then -Phase freeze."
}

# Project B (and the first leg of A): /start + intake, then /continue to the first stories page. STOP there.
function Prompt-ToStories {
  return @"
You are in a freshly scaffolded Stadium 8 workflow project. This is an AUTOMATED, NON-INTERACTIVE run —
there is NO human at the gates. For every approval or choice (project facts, sign-in, the epic plan),
read the pre-planned answers in TIER3-ANSWERS.json at the repo root and proceed WITHOUT stopping.

Do ONLY this:
1. Run /start. Set up the project from documentation/ and approve the project facts + epic plan from the
   answers file. This opens the editable plan review page (generated-docs/epic-plan-review.html).
2. It then hands to /continue, which plans the FIRST epic and opens that epic's stories review page
   (generated-docs/epics/<slug>/stories-review.html).
3. STOP THE MOMENT the first epic's stories review page has been written and opened. Do NOT approve the
   story list, do NOT build anything, do NOT run further. Leave the generated-docs files on disk.

Follow CLAUDE.md and .claude/ exactly. Do not delete generated-docs/.
"@
}

# Project A, second leg: approve stories and build through to the MANUAL-TEST check-off page. STOP there.
function Prompt-ToManual {
  return @"
You are resuming an automated Stadium 8 build whose first epic is planned and whose stories review page is
already open. This is NON-INTERACTIVE — for every approval (the story list, the brief, the hands-on manual
checklist) read TIER3-ANSWERS.json at the repo root and proceed WITHOUT stopping. Do NOT merge.

Do ONLY this:
1. Run /continue. Approve the first epic's story list from the answers file and build it test-first all the
   way through EPIC-END.
2. Continue into MANUAL-TEST, which writes and opens the manual-test check-off page
   (generated-docs/epics/<slug>/manual-tests.html).
3. STOP THE MOMENT manual-tests.html has been written and opened. Do NOT click Done / approve the manual
   tests, do NOT merge, do NOT run further. Leave the generated-docs files on disk.

Anything that must build should build (npm run build passes). Follow CLAUDE.md and .claude/ exactly.
"@
}

function Do-A-Stories { Assert-Work $workA 'A'; Invoke-Capture $workA (Prompt-ToStories) 'A-stories' | Out-Null
  Say "NEXT: -Phase A-manual (continue A to the manual-test page)." }
function Do-A-Manual  { Assert-Work $workA 'A'; Invoke-Capture $workA (Prompt-ToManual)  'A-manual'  | Out-Null
  Say "NEXT: -Phase B-stories (if not done), then -Phase freeze." }
function Do-B-Stories { Assert-Work $workB 'B'; Invoke-Capture $workB (Prompt-ToStories) 'B-stories' | Out-Null
  Say "NEXT: -Phase freeze." }

# Find <work>/generated-docs/epics/<slug>/<leaf> (first match) — slug is discovered, not assumed.
function Find-UnderEpic([string]$Work, [string]$Leaf) {
  $epics = Join-Path $Work 'generated-docs/epics'
  if (-not (Test-Path $epics)) { return $null }
  Get-ChildItem $epics -Directory | ForEach-Object {
    $p = Join-Path $_.FullName $Leaf
    if (Test-Path $p) { return $p }
  } | Select-Object -First 1
}

# The first epic's state.json phase on the working tree's current branch — the deterministic stop signal
# (the three pages are git-ignored, so file presence alone can't tell a correct stop from an overshoot).
function Get-EpicPhase([string]$Work) {
  $epics = Join-Path $Work 'generated-docs/epics'
  if (-not (Test-Path $epics)) { return $null }
  foreach ($d in (Get-ChildItem $epics -Directory)) {
    $sj = Join-Path $d.FullName 'state.json'
    if (Test-Path $sj) { try { return (Get-Content $sj -Raw | ConvertFrom-Json).phase } catch { return $null } }
  }
  return $null
}

# Last few stream lines of a leg's log, to explain a missing page without opening the jsonl by hand.
function Tail-Log([string]$Name) {
  $out = Join-Path $logDir "$Name.jsonl"
  if (Test-Path $out) {
    Say "  --- tail $Name.jsonl ---"
    Get-Content $out -Tail 6 -ErrorAction SilentlyContinue | ForEach-Object { Say "    $_" }
  }
}

function Do-Freeze {
  Assert-Work $workA 'A'; Assert-Work $workB 'B'
  $aEpicPlan = Join-Path $workA 'generated-docs/epic-plan-review.html'
  $bEpicPlan = Join-Path $workB 'generated-docs/epic-plan-review.html'
  $aStories  = Find-UnderEpic $workA 'stories-review.html'
  $aManual   = Find-UnderEpic $workA 'manual-tests.html'
  $bStories  = Find-UnderEpic $workB 'stories-review.html'

  $missing = @()
  if (-not (Test-Path $aEpicPlan)) { $missing += 'A epic-plan-review.html' }
  if (-not $aStories)              { $missing += 'A stories-review.html' }
  if (-not $aManual)               { $missing += 'A manual-tests.html' }
  if (-not (Test-Path $bEpicPlan)) { $missing += 'B epic-plan-review.html' }
  if (-not $bStories)              { $missing += 'B stories-review.html' }
  if ($missing.Count) {
    Say ("NOT FREEZING — missing: " + ($missing -join '; ') + ". A missing manual-tests.html usually means A's epic-end (build/quality/E2E) did not go green. Logs in ${logDir}:")
    foreach ($n in @('A-stories','A-manual','B-stories')) { Tail-Log $n }
    return
  }

  # Deterministic stop verification: the pages are git-ignored (no commit to check), so confirm each project
  # stopped where intended via its epic state.json phase. A=MANUAL-TEST (reached the check-off page), B=PLAN
  # (stopped at the stories gate). A mismatch means a run overshot (and over-spent) — refuse to freeze.
  $phaseA = Get-EpicPhase $workA
  $phaseB = Get-EpicPhase $workB
  $badPhase = @()
  if ($phaseA -ne 'MANUAL-TEST') { $badPhase += "project A phase is '$phaseA' (expected MANUAL-TEST)" }
  if ($phaseB -ne 'PLAN')        { $badPhase += "project B phase is '$phaseB' (expected PLAN — it may have overshot the stories gate)" }
  if ($badPhase.Count) { Say ("NOT FREEZING — stop-point check failed: " + ($badPhase -join '; ') + "."); return }

  $slugA = Split-Path (Split-Path $aStories -Parent) -Leaf
  $slugB = Split-Path (Split-Path $bStories -Parent) -Leaf

  # Replace ONLY the live project pages; the committed calibration/ fixtures must be preserved.
  foreach ($d in @('projectA', 'projectB')) { $p = Join-Path $slot $d; if (Test-Path $p) { Remove-Item $p -Recurse -Force } }
  foreach ($d in @("projectA/epics/$slugA", "projectB/epics/$slugB")) { New-Item -ItemType Directory -Force -Path (Join-Path $slot $d) | Out-Null }

  Copy-Item $aEpicPlan (Join-Path $slot 'projectA/epic-plan-review.html') -Force
  Copy-Item $aStories  (Join-Path $slot "projectA/epics/$slugA/stories-review.html") -Force
  Copy-Item $aManual   (Join-Path $slot "projectA/epics/$slugA/manual-tests.html") -Force
  Copy-Item $bEpicPlan (Join-Path $slot 'projectB/epic-plan-review.html') -Force
  Copy-Item $bStories  (Join-Path $slot "projectB/epics/$slugB/stories-review.html") -Force

  @{
    benchmarkA   = $BenchmarkA
    benchmarkB   = $BenchmarkB
    slugA        = $slugA
    slugB        = $slugB
    phaseA       = $phaseA
    phaseB       = $phaseB
    capturedFrom = (Split-Path $TemplateRoot -Leaf)
    pages        = 5
    note         = 'live /start+/continue to the first stories page (A and B) and on to the manual-test page (A); no merge. Pages compared by computed style in tier-2-recorded-run/page-consistency. Calibration is committed, not generated here.'
  } | ConvertTo-Json | Set-Content (Join-Path $slot 'meta.json')

  Say "FROZEN -> $slot  (slugA=$slugA, slugB=$slugB; 5 pages; calibration preserved)"

  # Gate the freeze on the fixture actually passing its own suite (don't ship an inconsistent capture silently).
  Say "Running the consistency suite against the frozen fixture…"
  Push-Location $RepoRoot
  try { & npx vitest run tier-2-recorded-run/page-consistency } catch { Say "  (could not run vitest here: $($_.Exception.Message)) — run: npm run test:page-consistency" }
  Pop-Location
}

switch ($Phase) {
  'setup'     { Do-Setup }
  'A-stories' { Do-A-Stories }
  'A-manual'  { Do-A-Manual }
  'B-stories' { Do-B-Stories }
  'freeze'    { Do-Freeze }
  default {
    Say "DRY RUN (no spend). Would run, in order:"
    Say "  1. -Phase setup     scaffold A ($BenchmarkA) + B ($BenchmarkB) work repos + bare remotes (free)"
    Say "  2. -Phase A-stories LIVE: project A /start+intake -> first stories page (spends)"
    Say "  3. -Phase A-manual  LIVE: project A continue -> manual-test page (spends)"
    Say "  4. -Phase B-stories LIVE: project B /start+intake -> first stories page (spends)"
    Say "  5. -Phase freeze    copy the 5 pages + write calibration -> $slot (free)"
    Say ""
    Say "Template: $TemplateRoot"
    Say "Nothing has been run. Re-invoke with -Phase setup to begin."
  }
}
