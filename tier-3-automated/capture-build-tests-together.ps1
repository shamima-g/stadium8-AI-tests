<#
.SYNOPSIS
  LIVE Tier-3 capture (spends tokens) for the "one agent writes each story's Vitest + Playwright tests,
  so both expect the same controls" feature (commit 4666e23). Produces the Tier-2 GOOD golden-run slot
  fixtures/golden-runs/build-tests-together-contact-form/.

.DESCRIPTION
  Drives a real contact-form project from this branch's template through:
    /start -> intake (unattended, from TIER3-ANSWERS.json) -> approve facts + epic plan -> plan the first
    epic's stories -> approve the story list -> BUILD begins -> shared mock-data step (B0) ->
    per-story test-generator agents (B0.2) -> STOP the moment every story's test files are written,
    BEFORE any story is coded (no B1 / developer loop).

  The capture is accepted only if a deterministic post-hoc FREEZE GATE holds (the stop point is a prompt
  instruction, not an HTML gate, so it is verified, not trusted):
    - the first epic has >= 2 stories (state.json.stories, keyed by story number),
    - EVERY state.json.stories[N].startedAt is null (stamped at B1 when a story goes in-progress —
      epic-state.js:42-43), i.e. no story was built,
    - no developer-authored component/page/route source on the web tree (overshoot guard),
    - every non-parked story has a spec (and a .test.tsx unless its test-generator returned no Vitest file),
    - the transcript is one-agent-per-story with no vitest/playwright split (helpers/test-generator-spawns),
    - control parity holds (no story's shared-name controls disagree — helpers/control-refs).

  FREEZE FORM — a FLAT docs+web WORKING-TREE copy, NOT a git bundle. The run stops after B0.2, before the
  first story's B5 commit, so the generated test files are UNCOMMITTED; a `git bundle --all` would not
  contain them (confirmed against existing slots). So freeze copies the post-B0.2 generated-docs/ and web/
  trees (node_modules excluded) into the slot, alongside transcript.jsonl, a recorded/ dir
  ({npm-test,test-e2e-list,lint,git-status}.txt for T2.5), and meta.json. Then it runs the Tier-2 suite
  against the frozen slot (REQUIRE_BUILD_TESTS_TOGETHER=1) as the final conformance gate.

  PORTABILITY: no hard-coded machine paths — every root is a parameter or derived from $PSScriptRoot
  (mirrors capture-page-consistency.ps1 / capture-plan-design-update.ps1). SPEND SAFETY: nothing signs in
  or spends unless a LIVE phase (plan-dry | build) is named, and each live step prints a sign-in + cost
  notice first.

.PARAMETER TemplateRoot
  A release-shaped Stadium-8 checkout carrying commit 4666e23 (one test-generator per story). Verified via
  .claude/agents/test-generator.md (mode: story) + .claude/commands/continue.md (B0.2). On a template that
  predates the feature this capture should not be run — the Tier-1 guards cover that direction.

.PARAMETER Phase
  dryrun  (default, no spend): describe the live steps; run nothing.
  setup   : scaffold the build work repo + a bare local remote (free).
  plan-dry: LIVE but CHEAP — a throwaway /start+intake+PLAN that STOPS at the first epic's stories gate,
            only to confirm the first epic decomposes into >= 2 stories before spending on the full build.
  build   : LIVE — /start -> intake -> approve -> BUILD through B0.2 (per-story test agents), then STOP.
  freeze  : copy the post-B0.2 docs+web trees + recorded outputs + transcript -> the slot, gated on the
            freeze conditions above, then run the Tier-2 suite against it (free).

.EXAMPLE
  pwsh -File capture-build-tests-together.ps1 -TemplateRoot "C:\TestsArchives\stadium8-tests\stadium-builder 26-10" -Phase setup
  pwsh -File capture-build-tests-together.ps1 -TemplateRoot "...\stadium-builder 26-10" -Phase plan-dry
  pwsh -File capture-build-tests-together.ps1 -TemplateRoot "...\stadium-builder 26-10" -Phase build
  pwsh -File capture-build-tests-together.ps1 -TemplateRoot "...\stadium-builder 26-10" -Phase freeze
#>
param(
  [Parameter(Mandatory)][string]$TemplateRoot,
  [ValidateSet('dryrun','setup','plan-dry','build','freeze')][string]$Phase = 'dryrun',
  [string]$RepoRoot  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
  [string]$WorkRoot  = ([System.IO.Path]::GetTempPath()),
  [string]$Benchmark = 'contact-form',
  [string]$Model     = 'opus',
  [string]$Slot      = 'build-tests-together-contact-form'
)
$ErrorActionPreference = 'Stop'

# Reuse the real scaffold (copies the template, drops benchmark docs into documentation/, places
# TIER3-ANSWERS.json at the root) + the process-tree killer, from the live driver.
. (Join-Path $PSScriptRoot 'live-driver.ps1')

$slotDir    = Join-Path $RepoRoot "fixtures/golden-runs/$Slot"
$work       = Join-Path $WorkRoot 'build-tests-together-run'
$remote     = Join-Path $WorkRoot 'build-tests-together-remote.git'
$planWork   = Join-Path $WorkRoot 'build-tests-together-plandry'
$planRemote = Join-Path $WorkRoot 'build-tests-together-plandry-remote.git'
$logDir     = Join-Path $WorkRoot 'build-tests-together-logs'

function Say([string]$m) { Write-Output $m }

function Assert-Work([string]$w) {
  if (-not (Test-Path (Join-Path $w '.claude'))) { throw "No work repo at $w — run -Phase setup first." }
}

# One headless claude call inside $Work. Prints the sign-in/cost notice; timeout-guarded with a
# process-tree kill so a hung gate can't block the capture forever. Returns the exit code.
function Invoke-Capture([string]$Work, [string]$PromptText, [string]$Name, [int]$TimeoutSeconds = 86400) {
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $pf  = Join-Path $logDir "$Name.prompt.txt"
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

function New-WorkRepo([string]$Work, [string]$Remote) {
  foreach ($p in @($Work, $Remote)) { if (Test-Path $p) { Remove-Item $p -Recurse -Force } }
  $benchDir = Join-Path $RepoRoot "benchmark-files/$Benchmark"
  if (-not (Test-Path $benchDir)) { throw "No benchmark at $benchDir" }
  New-Tier3Scaffold -TemplateRoot $TemplateRoot -WorkingDir $Work -BenchmarkDir $benchDir | Out-Null
  # A bare LOCAL remote so any epic-branch create/push works without GitHub (belt-and-braces: the stop is
  # before the first commit, but /continue sets up a worktree against origin/main).
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

# ---------------------------------------------------------------------------
# Epic/state helpers (deterministic stop verification)
# ---------------------------------------------------------------------------

# The first epic dir under <work>/generated-docs/epics that carries a state.json. Slug is discovered.
function Get-FirstEpic([string]$Work) {
  $epics = Join-Path $Work 'generated-docs/epics'
  if (-not (Test-Path $epics)) { return $null }
  foreach ($d in (Get-ChildItem $epics -Directory | Sort-Object Name)) {
    $sj = Join-Path $d.FullName 'state.json'
    if (Test-Path $sj) {
      try { $st = Get-Content $sj -Raw | ConvertFrom-Json } catch { continue }
      return [pscustomobject]@{ Slug = $d.Name; Dir = $d.FullName; State = $st }
    }
  }
  return $null
}

# state.json.stories is an OBJECT keyed by story number (epic-state.js:26). Return its entries as
# { Key, Node } pairs, excluding parked/deferred keys (overshoot/park is not a built story).
function Get-Stories($State) {
  $out = @()
  if ($null -eq $State -or $null -eq $State.stories) { return $out }
  foreach ($p in $State.stories.PSObject.Properties) {
    $node = $p.Value
    $parked = $false
    foreach ($f in @('parked','deferred')) {
      if ($node.PSObject.Properties.Name -contains $f -and $node.$f) { $parked = $true }
    }
    if ($node.PSObject.Properties.Name -contains 'status' -and ($node.status -match 'park|defer')) { $parked = $true }
    $out += [pscustomobject]@{ Key = $p.Name; Node = $node; Parked = $parked }
  }
  return $out
}

# ---------------------------------------------------------------------------
# Phases
# ---------------------------------------------------------------------------

function Do-Setup {
  if (-not (Test-Path (Join-Path $TemplateRoot '.claude/agents/test-generator.md'))) {
    throw "TemplateRoot $TemplateRoot has no .claude/agents/test-generator.md — needs a checkout with the test-generator (one-agent-per-story) feature."
  }
  if (Test-Path $logDir) { Remove-Item $logDir -Recurse -Force }
  Say "SETUP:"
  New-WorkRepo $work $remote
  Say "SETUP done. NEXT (each spends): -Phase plan-dry (cheap, confirm >=2 stories), -Phase build, then -Phase freeze."
}

# The unattended BUILD-through-B0.2 prompt. Stories are approved, BUILD begins, test agents run, then STOP
# before any story is coded. Shared across build (real) and is the full flow; plan-dry uses a trimmed stop.
function Prompt-Build {
  return @"
You are in a freshly scaffolded Stadium 8 workflow project. This is an AUTOMATED, NON-INTERACTIVE run —
there is NO human at the gates. For EVERY approval or choice (project facts, sign-in, the epic plan, the
story list, any Claude Code git-handling / setup prompt), read the pre-planned answers in
TIER3-ANSWERS.json at the repo root and proceed WITHOUT stopping. Never pause to ask me anything; for any
prompt not covered by the answers file, take the recommended/default and keep going.

Do ONLY this, then STOP:
1. Run /start. Set up the project from documentation/, do INTAKE unattended, and approve the project facts
   and the epic plan from the answers file.
2. Let it plan the FIRST epic's stories and approve the story list from the answers file. BUILD then begins.
3. BUILD first writes the epic's SHARED MOCK DATA (one test-generator in epic-mocks mode, under
   web/src/mocks/data/), then launches ONE test-generator per story that writes BOTH that story's test
   files (web/src/__tests__/integration/<...>.test.tsx AND web/e2e/<...>.spec.ts).
4. STOP THE MOMENT every story's test files have been written (each per-story test-generator has returned
   its "TESTS WRITTEN:" line). Do NOT begin coding or implementing ANY story. Do NOT enter the developer
   loop / story build step (do NOT start step B1 — nothing may set a story's startedAt). Do NOT run the
   generated tests, do NOT commit, do NOT merge, do NOT run /continue further.

Leave ALL generated files on disk (generated-docs/ and web/). Follow CLAUDE.md and .claude/ exactly.
"@
}

# A cheap PLAN-only probe: stop at the first epic's stories gate just to read the decomposition.
function Prompt-PlanDry {
  return @"
You are in a freshly scaffolded Stadium 8 workflow project. This is an AUTOMATED, NON-INTERACTIVE run —
there is NO human at the gates. For every approval or choice read TIER3-ANSWERS.json at the repo root and
proceed WITHOUT stopping. Never pause to ask me anything; for anything not covered, take the default.

Do ONLY this:
1. Run /start. Do INTAKE unattended and approve the project facts + epic plan from the answers file.
2. Let it plan the FIRST epic's stories so that generated-docs/epics/<slug>/state.json is written with the
   story list.
3. STOP THE MOMENT the first epic's stories review page has been written/opened. Do NOT approve the story
   list, do NOT build anything, do NOT run further. Leave generated-docs/ on disk.

Follow CLAUDE.md and .claude/ exactly. Do not delete generated-docs/.
"@
}

function Do-PlanDry {
  # Throwaway work repo so the cheap probe never pollutes the real build tree.
  New-WorkRepo $planWork $planRemote
  Invoke-Capture $planWork (Prompt-PlanDry) 'plan-dry' | Out-Null
  $epic = Get-FirstEpic $planWork
  if (-not $epic) { Say "PLAN-DRY: no epic state.json found under $planWork/generated-docs/epics — see $logDir/plan-dry.jsonl."; return }
  $stories = @(Get-Stories $epic.State)
  $n = $stories.Count
  Say "PLAN-DRY: first epic '$($epic.Slug)' decomposed into $n story/ies (keys: $(( $stories | ForEach-Object { $_.Key }) -join ', '))."
  if ($n -lt 2) {
    Say "  WARNING: < 2 stories. The feature's parity/no-split checks want a multi-story epic — a 1-story epic"
    Say "  can't show 'one agent PER story' meaningfully. Consider a richer benchmark before -Phase build."
  } else {
    Say "  OK: >= 2 stories. Safe to spend on -Phase build."
  }
}

function Do-Build {
  Assert-Work $work
  # A long timeout: BUILD-through-B0.2 includes intake + PLAN + mock-data + N test agents.
  Invoke-Capture $work (Prompt-Build) 'build' | Out-Null
  $epic = Get-FirstEpic $work
  if (-not $epic) { Say "BUILD: no epic state.json under $work/generated-docs/epics — the run did not reach PLAN. See $logDir/build.jsonl."; return }
  $stories = @(Get-Stories $epic.State)
  Say "BUILD: first epic '$($epic.Slug)', $($stories.Count) non-parked story/ies. NEXT: -Phase freeze (gated)."
}

# robocopy a tree excluding heavy/irrelevant dirs. robocopy exit codes 0-7 are success.
function Copy-Tree([string]$Src, [string]$Dst, [string[]]$ExcludeDirs) {
  New-Item -ItemType Directory -Force -Path $Dst | Out-Null
  $roboArgs = @($Src, $Dst, '/E', '/NFL', '/NDL', '/NJH', '/NJS', '/NP', '/R:1', '/W:1')
  if ($ExcludeDirs.Count) { $roboArgs += '/XD'; $roboArgs += $ExcludeDirs }
  & robocopy @roboArgs | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy $Src -> $Dst failed (code $LASTEXITCODE)" }
}

# Run one command inside <work>/web, capture stdout+stderr+exit into recorded/<name>.txt.
function Record-WebCmd([string]$RecordDir, [string]$Name, [string]$CmdLine) {
  $web = Join-Path $work 'web'
  $outFile = Join-Path $RecordDir "$Name.txt"
  Push-Location $web
  $output = & cmd.exe /s /c "$CmdLine 2>&1"
  $code = $LASTEXITCODE
  Pop-Location
  $header = "# cmd: $CmdLine`n# cwd: $web`n# exit: $code`n# ----------------------------------------"
  ($header, ($output -join "`n")) -join "`n" | Set-Content $outFile -Encoding utf8
  Say "  recorded $Name.txt (exit=$code)"
  return $code
}

function Do-Freeze {
  Assert-Work $work
  $web = Join-Path $work 'web'
  $epic = Get-FirstEpic $work
  if (-not $epic) { Say "NOT FREEZING — no epic state.json under $work/generated-docs/epics (build did not reach PLAN)."; return }
  $slug = $epic.Slug
  $stories = @(Get-Stories $epic.State)

  # ---- FREEZE GATE (deterministic; refuse a non-conforming / overshot capture) ----
  $fail = @()

  # (a) first epic must be multi-story.
  if ($stories.Count -lt 2) { $fail += "first epic '$slug' has $($stories.Count) non-parked story/ies (want >= 2)" }

  # (b) no story may have started (startedAt stamped at B1 — epic-state.js:42-43). THE load-bearing stop proof.
  $started = @()
  foreach ($s in $stories) {
    $sa = $null
    if ($s.Node.PSObject.Properties.Name -contains 'startedAt') { $sa = $s.Node.startedAt }
    if ($null -ne $sa -and "$sa" -ne '') { $started += "story $($s.Key) startedAt=$sa" }
  }
  if ($started.Count) { $fail += "a story was already built (overshoot): " + ($started -join '; ') }

  # (c) overshoot guard: no developer-authored component/page/route source on the web tree.
  $devDirs = @('components','pages','routes','features','app') | ForEach-Object { Join-Path $web "src/$_" }
  $devHits = @()
  foreach ($d in $devDirs) {
    if (Test-Path $d) {
      $srcFiles = Get-ChildItem $d -Recurse -File -Include *.tsx,*.ts -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\__tests__\\' -and $_.Name -notmatch '\.(test|spec)\.' }
      if ($srcFiles) { $devHits += "$d ($($srcFiles.Count) file(s))" }
    }
  }
  if ($devHits.Count) { $fail += "developer source present (overshoot): " + ($devHits -join '; ') }

  # (d) every non-parked story has a spec; flag missing .test.tsx (Tier-2 decides if tag-justified).
  $vDir = Join-Path $web 'src/__tests__/integration'
  $eDir = Join-Path $web 'e2e'
  foreach ($s in $stories) {
    $spec = $null; $test = $null
    if (Test-Path $eDir) { $spec = Get-ChildItem $eDir -File -Filter "epic-$slug-story-$($s.Key)-*.spec.ts" -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if (Test-Path $vDir) { $test = Get-ChildItem $vDir -File -Filter "epic-$slug-story-$($s.Key)-*.test.tsx" -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if (-not $spec) { $fail += "story $($s.Key): no Playwright spec under web/e2e/" }
    if (-not $test) { Say "  note: story $($s.Key) has no Vitest .test.tsx — Tier-2 will accept this only if its ACs carry no vitest tag." }
  }

  if ($fail.Count) {
    Say ("NOT FREEZING — freeze gate failed:")
    foreach ($f in $fail) { Say "   - $f" }
    Say "See $logDir/build.jsonl. A startedAt/overshoot failure means the run coded a story — re-capture."
    return
  }

  # ---- RECORD the criterion-2 command outputs (T2.5 reads these) ----
  $recordDir = Join-Path $logDir 'recorded'
  if (Test-Path $recordDir) { Remove-Item $recordDir -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $recordDir | Out-Null
  if (-not (Test-Path (Join-Path $web 'node_modules'))) {
    Say "  web/node_modules missing — installing (needed to run the recorded commands)…"
    Push-Location $web; & cmd.exe /s /c "npm ci 2>&1 || npm install 2>&1" | Out-Null; Pop-Location
  }
  Record-WebCmd $recordDir 'npm-test'       "npm test -- epic-$slug"       | Out-Null
  Record-WebCmd $recordDir 'test-e2e-list'  "npm run test:e2e -- --list"   | Out-Null
  Record-WebCmd $recordDir 'lint'           "npm run lint"                 | Out-Null
  Push-Location $work; (& git status 2>&1) -join "`n" | Set-Content (Join-Path $recordDir 'git-status.txt') -Encoding utf8; Pop-Location

  # ---- FREEZE: flat docs+web working-tree copy (node_modules etc. excluded) ----
  if (Test-Path $slotDir) { Remove-Item $slotDir -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $slotDir | Out-Null
  Copy-Tree (Join-Path $work 'generated-docs') (Join-Path $slotDir 'generated-docs') @()
  Copy-Tree $web (Join-Path $slotDir 'web') @('node_modules','dist','.vite','coverage','test-results','playwright-report','.turbo')
  Copy-Item $recordDir (Join-Path $slotDir 'recorded') -Recurse -Force
  Copy-Item (Join-Path $logDir 'build.jsonl') (Join-Path $slotDir 'transcript.jsonl') -Force

  @{
    benchmark    = $Benchmark
    scenario     = 'build-tests-together'
    slot         = $Slot
    epicSlug     = $slug
    storyCount   = $stories.Count
    stopPoint    = 'post-B0.2'
    startedAtAllNull = $true
    templateRef  = 'v1.4.0'
    featureCommit = '4666e23'
    capturedFrom = (Split-Path $TemplateRoot -Leaf)
    model        = $Model
    note         = 'live /start+intake+PLAN+approve -> BUILD through B0.2 (one test-generator per story); STOPPED before any story coded (startedAt all null). Flat docs+web tree (no git bundle — test files uncommitted). recorded/ holds the criterion-2 command outputs for T2.5.'
  } | ConvertTo-Json | Set-Content (Join-Path $slotDir 'meta.json')

  Say "FROZEN -> $slotDir  (epicSlug=$slug, $($stories.Count) stories; transcript + recorded/ + docs+web tree)"

  # ---- FINAL CONFORMANCE GATE: the Tier-2 suite must pass against the frozen slot ----
  Say "Running the Tier-2 build-tests-together suite against the frozen slot (REQUIRE=1)…"
  Push-Location $RepoRoot
  $env:REQUIRE_BUILD_TESTS_TOGETHER = '1'
  try { & npx vitest run tier-2-recorded-run/build-tests-together }
  catch { Say "  (could not run vitest here: $($_.Exception.Message)) — run: npx vitest run tier-2-recorded-run/build-tests-together" }
  Pop-Location
  Say "If the suite is green, the GOOD slot is conforming and the Tier-2 good-slot checks now run (no longer skipped)."
}

switch ($Phase) {
  'setup'    { Do-Setup }
  'plan-dry' { Do-PlanDry }
  'build'    { Do-Build }
  'freeze'   { Do-Freeze }
  default {
    Say "DRY RUN (no spend). Would run, in order:"
    Say "  1. -Phase setup    scaffold $work + bare remote $remote (free)"
    Say "  2. -Phase plan-dry LIVE but cheap: confirm the first epic has >= 2 stories (throwaway repo; spends a little)"
    Say "  3. -Phase build    LIVE: /start -> intake -> approve -> BUILD through B0.2 (per-story test agents), then STOP (spends)"
    Say "  4. -Phase freeze   gate (>=2 stories, startedAt all null, no dev source, files present, one-agent, parity),"
    Say "                     then copy docs+web tree + recorded/ + transcript -> $slotDir, and run the Tier-2 suite (free)"
    Say ""
    Say "Benchmark: $Benchmark    Template: $TemplateRoot    Slot: $Slot"
    Say "Nothing has been run. Re-invoke with -Phase setup to begin."
  }
}
