<#
.SYNOPSIS
  live-driver.ps1 — Part 2: drive the Claude command-line tool to build the app.

.DESCRIPTION
  A faithful PowerShell port of the reference harness's pattern
  (C:\AI\Linx8-QATests-DO-NOT-DELETE\QATests — Helpers/ClaudeCli.cs + Tests/AgenticEndToEndTests.cs):

    1. Scaffold a throwaway copy of the Stadium 8 template into a working folder.
    2. Drop the chosen benchmark's docs into its documentation/ folder.
    3. Compose ONE autonomous prompt (embedding the benchmark's answers.json) that tells
       Claude to build the whole app and NOT stop for approvals.
    4. Run `claude -p "<prompt>" --output-format stream-json --verbose
       --dangerously-skip-permissions --model <m>`, output redirected to a FILE (the only
       way to capture claude.exe's stream on Windows), tailed live so each turn is timed.
    5. Feed each turn to the stopwatch (timing.ps1); on exit assemble the run-result the
       report/history/charts already understand.

  The flaky actor (Claude) is kept separate from the deterministic checks (build + rules),
  which are recorded, never gating — matching the agreed "score is recorded, never fails
  the run" decision.

  Invoke-Tier3LiveRun is what Run-QATests.ps1 calls on the live path.
#>

Set-StrictMode -Version Latest

# stream.ps1 dot-sources timing.ps1, so this pulls in both Get-JsonProp / ConvertFrom-ClaudeStream
# and the Tier3Timer class + Get-WorkflowPhaseGuess (loading timing once, not twice).
. (Join-Path $PSScriptRoot 'stream.ps1')
. (Join-Path $PSScriptRoot 'memory.ps1')

# Files/dirs never copied when scaffolding a throwaway template copy.
$script:ScaffoldExclude = @('AI-tests', '.git', 'node_modules', '.next', 'TestResults', 'generated-docs')

# Copy the Stadium 8 template (TemplateRoot) into WorkingDir, skipping heavy/irrelevant dirs.
function New-Tier3Scaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TemplateRoot,
        [Parameter(Mandatory)][string]$WorkingDir,
        [Parameter(Mandatory)][string]$BenchmarkDir
    )
    if (-not (Test-Path $WorkingDir)) { New-Item -ItemType Directory -Path $WorkingDir -Force | Out-Null }

    foreach ($item in Get-ChildItem -LiteralPath $TemplateRoot -Force) {
        if ($script:ScaffoldExclude -contains $item.Name) { continue }
        $dest = Join-Path $WorkingDir $item.Name
        if ($item.PSIsContainer) {
            Copy-Item -LiteralPath $item.FullName -Destination $dest -Recurse -Force
        }
        else {
            Copy-Item -LiteralPath $item.FullName -Destination $dest -Force
        }
    }

    # Drop the benchmark's docs into documentation/ (what INTAKE reads).
    $docDest = Join-Path $WorkingDir 'documentation'
    New-Item -ItemType Directory -Path $docDest -Force | Out-Null
    $frontendDocs = Join-Path $BenchmarkDir 'frontend\docs'
    if (Test-Path $frontendDocs) { Copy-Item -Path (Join-Path $frontendDocs '*') -Destination $docDest -Recurse -Force }
    $backend = Join-Path $BenchmarkDir 'backend'
    if (Test-Path $backend) { Copy-Item -LiteralPath $backend -Destination (Join-Path $docDest 'backend') -Recurse -Force }

    # Drop the pre-planned answers into the scaffold root, so the workflow (and its agents)
    # can READ them at each approval gate — the file-in-the-folder approach that lets the real
    # /start + /continue commands run unattended.
    $answers = Join-Path $BenchmarkDir 'answers.json'
    if (Test-Path $answers) { Copy-Item -LiteralPath $answers -Destination (Join-Path $WorkingDir 'TIER3-ANSWERS.json') -Force }

    return $WorkingDir
}

# Compose the entry prompt. MAXIMUM FIDELITY: it drives the real workflow via the actual
# /start and /continue commands, and points Claude at the pre-planned answers file in the
# folder (TIER3-ANSWERS.json) for every approval — so the genuine command-driven workflow
# runs unattended, with no human at the gates.
function Get-Tier3Prompt {
    [CmdletBinding()]
    param([string]$AnswersFileName = 'TIER3-ANSWERS.json')

    return @"
You are in a freshly scaffolded Stadium 8 workflow project. Build the COMPLETE application
described by the documents in the documentation/ folder, by running the project's REAL
workflow commands: run ``/start`` to begin, then ``/continue`` repeatedly to drive PLAN,
BUILD and EPIC-END, until the whole app is built. Follow CLAUDE.md and .claude/ exactly and
use the project's conventions (Shadcn UI, the shared API client, centralised styling, a role
on every story, plain-language checklists), test-first.

This is an AUTOMATED, NON-INTERACTIVE run. There is NO human to answer approval gates, so:
whenever the workflow asks you to approve something or make a choice (the intake/project
facts, the sign-in method, the story list, the hands-on checklist, the merge), read the
pre-planned answers in ``$AnswersFileName`` at the repo root and proceed with them WITHOUT
stopping. Never wait for input — carry straight on through every phase and finish the work.

Key answers (also in $AnswersFileName): sign-in uses the BFF pattern (the app's own Next.js
server holds the session cookie and proxies to the auth API). Build against mock data derived
from the OpenAPI specs unless the backend is reachable. The app must build (npm run build
passes). Do not commit anything unless the workflow itself does so as part of a story.
"@
}

# The prompt used to RESUME an interrupted run (after a shutdown), continuing the same
# session. Short — the workflow already knows where it was up to.
function Get-Tier3ResumePrompt {
    [CmdletBinding()]
    param([string]$AnswersFileName = 'TIER3-ANSWERS.json')
    return @"
This automated Stadium 8 build was interrupted before it finished. Resume and complete it:
run ``/continue`` and proceed through all the remaining phases until the app is fully built
and EPIC-END passes. Same rules as before — this is NON-INTERACTIVE: for any approval or
choice, use the pre-planned answers in ``$AnswersFileName`` at the repo root and carry on
without stopping. The app must build (npm run build passes).
"@
}

# Compose the PLAN-A entry prompt (Scenario = 'plan'). Same autonomous, non-interactive
# contract as Get-Tier3Prompt, but it drives the plan-ahead command (/plan) through its full
# choreography so its live behaviours can be checked: build the FIRST epic, then PLAN — not
# build — the next epics (one already outlined at setup, one brand-new, one that depends on an
# as-yet-unbuilt epic), parking each ready to build; then build a parked epic to prove the
# READY-TO-BUILD → BUILD handoff resumes straight into BUILD with no re-planning.
function Get-Tier3PlanPrompt {
    [CmdletBinding()]
    param([string]$AnswersFileName = 'TIER3-ANSWERS.json')
    return @"
You are in a freshly scaffolded Stadium 8 workflow project. Follow CLAUDE.md and .claude/
exactly, use the project's conventions (Shadcn UI, the shared API client, centralised styling,
a role on every story, plain-language checklists), and work test-first.

This is an AUTOMATED, NON-INTERACTIVE run. There is NO human at the approval gates. Whenever
the workflow asks you to approve something or make a choice (project facts, sign-in, a story
list, a brief, the hands-on checklist, a merge), read the pre-planned answers in
``$AnswersFileName`` at the repo root and proceed with them WITHOUT stopping. Never wait for
input. Sign-in uses the BFF pattern; build against mock data derived from the OpenAPI specs.

Do these steps IN ORDER. Do NOT skip ahead, and do NOT build any epic you were not told to build:

1. Run ``/start``. Set up the project from the documents in documentation/ (project facts +
   the epic plan), then build ONLY THE FIRST epic all the way through EPIC-END. When the first
   epic is done, STOP building — do NOT ``/continue`` into the next epic.

2. Run ``/plan`` and plan the NEXT epic that is already outlined in the epic plan. Break its
   stories down, approve them from the answers file, and PARK it ready to build. Do not build it.

3. Run ``/plan`` again and plan a BRAND-NEW epic that is NOT in the original epic plan: a
   "User Settings" epic — a settings page where a signed-in user can view and change their own
   display name. Approve its brief and its story list from the answers file, and PARK it ready
   to build. Do not build it.

4. Run ``/plan`` again and plan an epic that DEPENDS ON the epic you parked in step 2 (it builds
   on that epic and must not merge before it): a "Saved Views" epic that lets a user save and
   reuse a named filter over the parked epic's screen. Record the dependency, and PARK it ready
   to build. Do not build it.

5. Run ``/status``, then regenerate the dashboard: ``node .claude/scripts/generate-dashboard-html.js``.

6. Run ``/start`` again, pick the epic you PARKED in step 2, and build it. It should resume
   straight into BUILD from where planning left off, with NO re-planning. Build it through
   EPIC-END, then STOP.

Carry straight on from one step to the next without waiting. Anything that must build should
build (npm run build passes).
"@
}

# ---- headless Claude, ported from ClaudeCli.Run -------------------------------------------

# Kill a process tree (claude spawns a node child) on Windows/Unix.
function Stop-ProcessTree {
    param([int]$ProcessId)
    try {
        if ($IsWindows -or $null -eq $IsWindows) { & taskkill /T /F /PID $ProcessId 2>$null | Out-Null }
        else { & kill -9 $ProcessId 2>$null | Out-Null }
    }
    catch { }
}

<#
  Run Claude once headless. Redirects stdout/stderr to files (the only reliable capture on
  Windows), tails the stdout file live, and invokes -OnTurn (turnNumber, gate) as each
  assistant turn arrives. Returns a result hashtable.
#>
function Invoke-ClaudeHeadless {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string]$WorkingDir,
        [string]$Model,
        [string]$ResumeSessionId,
        [int]$TimeoutSeconds = 86400,
        [scriptblock]$OnTurn,
        [scriptblock]$OnHeartbeat,
        [string]$OutFile,
        [int]$HeartbeatMs = 1000,
        [hashtable]$MemoryPeak,
        [string]$SessionIdFile
    )
    if (-not $OutFile) { $OutFile = Join-Path ([System.IO.Path]::GetTempPath()) ("claude-out-" + [Guid]::NewGuid().ToString('N') + ".jsonl") }
    $errFile = "$OutFile.err"
    $promptFile = "$OutFile.prompt.txt"

    # The prompt is passed via STDIN (a file), and Claude's output is captured by cmd.exe's `>` file
    # redirect. This is the ONLY reliable capture on Windows — .NET/PowerShell pipe redirection
    # (Start-Process -RedirectStandardOutput) does NOT receive claude.exe's streamed output. Passing the
    # prompt via stdin also sidesteps all command-line quoting of a long, multi-line, JSON-bearing prompt.
    Set-Content -Path $promptFile -Value $Prompt -Encoding utf8 -NoNewline

    # Let the workflow's background subagents (per-story "developer" and "test-gen" agents that
    # the orchestrator spawns and then awaits) run to completion. Without this, headless Claude
    # Code terminates the process when background tasks are still running after its default 600s
    # ceiling — which truncates the build mid-epic (the orchestrator repeatedly yields with
    # "I'll await the Story N developer", and the ceiling kills it). '0' = wait indefinitely; the
    # driver's own $TimeoutSeconds (Stop-ProcessTree, below) stays the real overall ceiling.
    # Inherited by the cmd.exe child launched below.
    $env:CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS = '0'

    $inner = 'claude -p --output-format stream-json --verbose --dangerously-skip-permissions'
    if ($Model) { $inner += " --model `"$Model`"" }
    if ($ResumeSessionId) { $inner += " --resume `"$ResumeSessionId`"" }
    $inner += " < `"$promptFile`" > `"$OutFile`" 2> `"$errFile`""

    $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList "/s /c `"$inner`"" `
        -WorkingDirectory $WorkingDir -NoNewWindow -PassThru

    $state = @{ turns = 0; sessionId = $null; model = $Model; sawResult = $false; isError = $false; durationMs = 0.0; costUsd = 0.0; tokens = 0; partialTokens = 0; lastType = $null; prevGate = 'spec' }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $pos = 0L
    $timedOut = $false
    $sessionWritten = $false

    while ($true) {
        Start-Sleep -Milliseconds $HeartbeatMs
        if ($MemoryPeak) { Update-MemoryPeak -Tracker $MemoryPeak }
        if ($OnHeartbeat) { & $OnHeartbeat }   # tick the stopwatch every poll, so a long turn isn't miscounted as an offline gap
        # tail new bytes from the redirected file
        if (Test-Path $OutFile) {
            try {
                $fs = [System.IO.File]::Open($OutFile, 'Open', 'Read', 'ReadWrite,Delete')
                $fs.Seek($pos, 'Begin') | Out-Null
                $sr = New-Object System.IO.StreamReader($fs)
                $chunk = $sr.ReadToEnd()
                $pos = $fs.Position
                $sr.Dispose(); $fs.Dispose()
                if ($chunk) {
                    foreach ($line in ($chunk -split "`n")) {
                        if ([string]::IsNullOrWhiteSpace($line)) { continue }
                        Read-ClaudeEvent -Line $line -State $state -OnTurn $OnTurn
                    }
                }
            }
            catch { }
        }

        # Persist the session id as soon as it's known, so a later run can --resume this one
        # after a shutdown. Written once, best-effort.
        if ($SessionIdFile -and -not $sessionWritten -and $state.sessionId) {
            try { Set-Content -Path $SessionIdFile -Value $state.sessionId -Encoding utf8 -NoNewline; $sessionWritten = $true } catch { }
        }

        if ($proc.HasExited) { break }
        if ($sw.Elapsed.TotalSeconds -ge $TimeoutSeconds) { $timedOut = $true; Stop-ProcessTree -ProcessId $proc.Id; break }
    }
    $sw.Stop()
    try { if (Test-Path $promptFile) { Remove-Item $promptFile -Force } } catch { }

    return @{
        succeeded  = (-not $timedOut) -and $state.sawResult -and (-not $state.isError)
        timedOut   = $timedOut
        sessionId  = $state.sessionId
        model      = $state.model
        turns      = $state.turns
        tokens     = if ($state.sawResult) { $state.tokens } else { $state.partialTokens }
        claudeSeconds = if ($state.durationMs -gt 0) { $state.durationMs / 1000.0 } else { $sw.Elapsed.TotalSeconds }
        costUsd    = $state.costUsd
        outFile    = $OutFile
    }
}

# Total tokens (input + output + cache) from a result event, tolerant of format:
# the `usage` object, or a per-model `modelUsage` map (varies across CLI versions).
function Get-ClaudeUsageTokens {
    param($Event)
    $fields = @('input_tokens', 'output_tokens', 'cache_creation_input_tokens', 'cache_read_input_tokens')
    $u = Get-JsonProp $Event 'usage'
    if ($u) {
        $sum = 0; foreach ($k in $fields) { $sum += [int](Get-JsonProp $u $k 0) }
        return $sum
    }
    $mu = Get-JsonProp $Event 'modelUsage'
    if ($mu) {
        $sum = 0
        foreach ($p in $mu.PSObject.Properties) { foreach ($k in $fields) { $sum += [int](Get-JsonProp $p.Value $k 0) } }
        return $sum
    }
    return 0
}

# Ingest one stream-json line, updating $State and firing $OnTurn on assistant turns.
function Read-ClaudeEvent {
    param([string]$Line, [hashtable]$State, [scriptblock]$OnTurn)
    $evt = $null
    try { $evt = $Line | ConvertFrom-Json } catch { return }
    $type = Get-JsonProp $evt 'type'
    if ($type) { $State.lastType = $type }

    switch ($type) {
        'system' {
            $m = Get-JsonProp $evt 'model'; if ($m) { $State.model = $m }
            $s = Get-JsonProp $evt 'session_id'; if ($s) { $State.sessionId = $s }
        }
        'assistant' {
            $State.turns++
            $msg = Get-JsonProp $evt 'message'
            $touched = New-Object System.Collections.Generic.List[string]
            foreach ($block in @(Get-JsonProp $msg 'content' @())) {
                if ((Get-JsonProp $block 'type') -ne 'tool_use') { continue }
                $inp = Get-JsonProp $block 'input'
                $fp = Get-JsonProp $inp 'file_path'; if ($fp) { $touched.Add([string]$fp) }
                $cmd = Get-JsonProp $inp 'command'; if ($cmd) { $touched.Add([string]$cmd) }
            }
            $usage = Get-JsonProp $msg 'usage'
            $outTok = 0
            if ($usage) {
                $outTok = [int](Get-JsonProp $usage 'output_tokens' 0)
                $State.partialTokens += ([int](Get-JsonProp $usage 'input_tokens' 0) + $outTok)
            }
            $gate = Get-WorkflowPhaseGuess -Touched @($touched) -PreviousPhase $State.prevGate
            $State.prevGate = $gate
            if ($OnTurn) { & $OnTurn $State.turns $gate $outTok }
        }
        'result' {
            # A Tier 3 run emits MANY result events — one per Claude sub-invocation, each
            # carrying ITS OWN duration/cost/usage. SUM across them for the run total;
            # overwriting (the old bug) kept only the last sub-call, giving a wildly wrong
            # figure (e.g. 2h of work reported as ~2 min, or tokens off by 20x).
            $State.sawResult = $true
            $State.isError = [bool](Get-JsonProp $evt 'is_error' $false)
            $d = Get-JsonProp $evt 'duration_ms'
            if ($null -eq $d) { $d = Get-JsonProp $evt 'duration_api_ms' }   # tolerate the api-only field
            if ($null -ne $d) { $State.durationMs += [double]$d }
            $c = Get-JsonProp $evt 'total_cost_usd'; if ($null -ne $c) { $State.costUsd += [double]$c }
            $rs = Get-JsonProp $evt 'session_id'; if ($rs) { $State.sessionId = $rs }
            $State.tokens += (Get-ClaudeUsageTokens -Event $evt)
        }
    }
}

# ---- deterministic checks + tools -----------------------------------------------------------

# Did the workflow produce a web/ app that builds? Recorded, never gating.
# The scaffold carries no node_modules, so deps are installed first. On Windows `npm` is a
# .cmd shim that Start-Process can't launch directly ("%1 is not a valid Win32 application"),
# so every npm call goes through cmd.exe.
function Test-Tier3Build {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$WorkingDir, [string]$LogPath, [hashtable]$MemoryPeak, [int]$StepTimeoutSeconds = 1800)
    $web = Join-Path $WorkingDir 'web'
    if (-not (Test-Path (Join-Path $web 'package.json'))) {
        return @{ ok = $false; detail = 'no web/ app was produced' }
    }

    # Run "npm <args>" in $web via cmd.exe (npm is a .cmd shim), polling for exit while
    # sampling memory each second — the build is the memory-hungry phase we most want peaked.
    function Invoke-NpmSampled {
        param([string]$NpmArgs, [string]$OutLog, [hashtable]$MemPeak, [int]$TimeoutSec)
        $inner = "npm $NpmArgs > `"$OutLog`" 2>&1"
        $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/s /c `"$inner`"" -WorkingDirectory $web -NoNewWindow -PassThru
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while (-not $p.HasExited) {
            Start-Sleep -Milliseconds 1000
            if ($MemPeak) { Update-MemoryPeak -Tracker $MemPeak }
            if ($sw.Elapsed.TotalSeconds -ge $TimeoutSec) {
                try { & taskkill /T /F /PID $p.Id 2>$null | Out-Null } catch { }
                return -1
            }
        }
        return $p.ExitCode
    }

    if (-not $LogPath) { $LogPath = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-build-" + [Guid]::NewGuid().ToString('N') + ".log") }
    $installLog = "$LogPath.install.txt"
    $buildLog = "$LogPath.build.txt"

    try {
        $installExit = Invoke-NpmSampled -NpmArgs 'install --no-audit --no-fund' -OutLog $installLog -MemPeak $MemoryPeak -TimeoutSec $StepTimeoutSeconds
        if ($installExit -ne 0) {
            return @{ ok = $false; detail = "npm install failed (exit $installExit); see $installLog" }
        }
        $buildExit = Invoke-NpmSampled -NpmArgs 'run build' -OutLog $buildLog -MemPeak $MemoryPeak -TimeoutSec $StepTimeoutSeconds
        if ($buildExit -eq 0) { return @{ ok = $true; detail = 'npm install + npm run build passed' } }
        return @{ ok = $false; detail = "npm run build failed (exit $buildExit); see $buildLog" }
    }
    catch {
        return @{ ok = $false; detail = "could not run the build: $($_.Exception.Message)" }
    }
}

# Collect files under $Root, pruning excluded directories at any level (so node_modules
# etc. are never even walked). Returns absolute file paths.
function Get-AppFiles {
    param([string]$Root, [string[]]$ExcludeDirs)
    $files = [System.Collections.Generic.List[string]]::new()
    $stack = [System.Collections.Generic.Stack[string]]::new()
    $stack.Push($Root)
    while ($stack.Count -gt 0) {
        $dir = $stack.Pop()
        foreach ($e in Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue) {
            if ($e.PSIsContainer) {
                if ($ExcludeDirs -notcontains $e.Name) { $stack.Push($e.FullName) }
            }
            else { $files.Add($e.FullName) }
        }
    }
    return $files
}

# Best-effort: zip the built app into $DestZip, skipping heavy rebuildable dirs and any
# locked/unreadable file. A zip problem never throws — it returns ok=$false. Run BEFORE
# teardown so the source (and anything else kept) is captured.
function Compress-Tier3App {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourceDir,
        [Parameter(Mandatory)][string]$DestZip,
        [string[]]$ExcludeDirs = @('node_modules', '.next', '.turbo', '.git', 'coverage', '.vite', 'dist', '.cache')
    )
    try {
        if (-not (Test-Path $SourceDir)) { return @{ ok = $false; detail = "source not found: $SourceDir" } }
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $destDir = Split-Path -Parent $DestZip
        if ($destDir -and -not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        if (Test-Path $DestZip) { Remove-Item $DestZip -Force }

        $base = (Resolve-Path -LiteralPath $SourceDir).Path.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        $added = 0; $skipped = 0
        $zip = [System.IO.Compression.ZipFile]::Open($DestZip, 'Create')
        try {
            foreach ($full in (Get-AppFiles -Root $SourceDir -ExcludeDirs $ExcludeDirs)) {
                $rel = ($full.Substring($base.Length)) -replace '\\', '/'
                try {
                    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $full, $rel) | Out-Null
                    $added++
                }
                catch { $skipped++ }   # locked/unreadable — skip this file, keep going
            }
        }
        finally { $zip.Dispose() }
        return @{ ok = $true; zip = $DestZip; files = $added; skipped = $skipped }
    }
    catch {
        return @{ ok = $false; detail = $_.Exception.Message }
    }
}

# Map artifact-lint test-file basenames to the short rule ids used in the report/history
# (these ids match the fix hints in Generate-Report.ps1).
$script:ArtifactRuleMap = @{
    'api-path-exactness'        = 'exact-api-paths'
    'no-suppression-directives' = 'no-suppressions'
    'shadcn-imports-only'       = 'shadcn-only'
    'plain-language-checklists' = 'plain-language'
    'role-field-in-stories'     = 'role-per-story'
}

# Parse the vitest JSON report from an artifact-lint run into the list of rule ids that
# FAILED (i.e. the built app violated them). Pure and testable.
function ConvertFrom-VitestArtifactJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Json)
    $missed = [System.Collections.Generic.List[string]]::new()
    $obj = $Json | ConvertFrom-Json
    foreach ($tr in @($obj.testResults)) {
        $name = ("$($tr.name)") -replace '\\', '/'
        foreach ($base in $script:ArtifactRuleMap.Keys) {
            if ($name -match "artifact-lint/$base") {
                $anyFail = @($tr.assertionResults | Where-Object { $_.status -eq 'failed' }).Count -gt 0
                $rule = $script:ArtifactRuleMap[$base]
                if ($anyFail -and -not $missed.Contains($rule)) { $missed.Add($rule) }
            }
        }
    }
    return @($missed)
}

# Run the REAL artifact-lint rules against the built app (via REPO_ROOT), returning the rule
# ids it violated. Reuses the single source of truth — the tier-1 rules — rather than
# re-implementing them. Best-effort: if vitest can't run, returns ran=$false (no scoring).
function Get-Tier3Conformance {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Scaffold, [Parameter(Mandatory)][string]$QaRoot, [int]$TimeoutSeconds = 600)
    $outFile = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-lint-" + [Guid]::NewGuid().ToString('N') + ".json")
    try {
        # Point the rules' REPO_ROOT at the scaffold so their "real web/src" scans judge the
        # built app. npx is a .cmd shim, so go through cmd.exe; capture JSON to a file.
        $inner = "set `"REPO_ROOT=$Scaffold`" && npx vitest run tier-1-unit/artifact-lint --reporter=json > `"$outFile`" 2>nul"
        $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/s /c `"$inner`"" -WorkingDirectory $QaRoot -NoNewWindow -PassThru
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while (-not $p.HasExited) {
            Start-Sleep -Milliseconds 500
            if ($sw.Elapsed.TotalSeconds -ge $TimeoutSeconds) { try { & taskkill /T /F /PID $p.Id 2>$null | Out-Null } catch { }; break }
        }
        if (-not (Test-Path $outFile)) { return @{ ran = $false; rulesMissed = @() } }
        $json = Get-Content -Raw -Path $outFile
        if ([string]::IsNullOrWhiteSpace($json)) { return @{ ran = $false; rulesMissed = @() } }
        $missed = ConvertFrom-VitestArtifactJson -Json $json
        return @{ ran = $true; rulesMissed = @($missed) }
    }
    catch {
        return @{ ran = $false; rulesMissed = @() }
    }
    finally {
        try { if (Test-Path $outFile) { Remove-Item $outFile -Force } } catch { }
    }
}

# The epic slug from a conventional-commit subject: "type(scope): ..." -> the scope, then
# the part before any '/' (so "feat(auth/story-3): x" -> "auth"). $null when there's no scope.
function Get-Tier3CommitEpic {
    param([string]$Subject)
    if ($Subject -match '^\s*[a-zA-Z]+\(([^)]+)\)') { return (($Matches[1]) -split '/')[0] }
    return $null
}

# Epic folders + story counts + lifecycle phase under the built app's generated-docs/epics.
# Returns an ordered array of @{ slug; stories; phase } (empty when the app has no epics yet).
# `phase` is the epic's state.json phase (e.g. READY-TO-BUILD, COMPLETE, EPIC-END), or '' when
# there's no readable state — a built-then-branched epic can leave an empty folder on this branch.
function Get-Tier3EpicDirs {
    param([Parameter(Mandatory)][string]$Scaffold)
    $epicsRoot = Join-Path $Scaffold 'generated-docs/epics'
    if (-not (Test-Path $epicsRoot)) { return @() }
    $out = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($d in (Get-ChildItem -Path $epicsRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
        $stories = @(Get-ChildItem -Path (Join-Path $d.FullName 'stories') -Filter 'story-*.md' -File -ErrorAction SilentlyContinue).Count
        $phase = ''
        $stateFile = Join-Path $d.FullName 'state.json'
        if (Test-Path $stateFile) {
            try { $phase = [string]((Get-Content -Raw -Path $stateFile -ErrorAction Stop | ConvertFrom-Json).phase) } catch { $phase = '' }
        }
        $out.Add(@{ slug = $d.Name; stories = [int]$stories; phase = $phase })
    }
    return @($out)
}

# Pure: combine epic dirs with commit records (@{ ts; subject }) into per-epic build time.
# Per-epic seconds = last commit - first commit for that epic (0 when it has <2 commits).
# Testable without git. Returns @({ slug; stories; seconds }) in the epics' given order.
function Measure-Tier3Epics {
    param([array]$Epics, [array]$Commits)
    $span = @{}   # slug -> @{ min; max }
    foreach ($c in @($Commits)) {
        $slug = Get-Tier3CommitEpic -Subject ([string]$c.subject)
        if (-not $slug) { continue }
        $ts = [long]$c.ts
        if (-not $span.ContainsKey($slug)) { $span[$slug] = @{ min = $ts; max = $ts } }
        else {
            if ($ts -lt $span[$slug].min) { $span[$slug].min = $ts }
            if ($ts -gt $span[$slug].max) { $span[$slug].max = $ts }
        }
    }
    $out = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($e in @($Epics)) {
        $secs = if ($span.ContainsKey($e.slug)) { [double]($span[$e.slug].max - $span[$e.slug].min) } else { 0.0 }
        $out.Add([ordered]@{ slug = [string]$e.slug; stories = [int]$e.stories; seconds = $secs })
    }
    return @($out)
}

# Epic state.json phases that mean the epic reached the end of BUILD (as opposed to READY-TO-BUILD,
# which is a PARKED/planned epic /plan broke into stories but never built).
$script:Tier3BuiltEpicPhases = @('COMPLETE', 'COMPLETE-ON-BRANCH', 'MANUAL-TEST', 'EPIC-END')

# Conventional-commit subject fragments that only appear once an epic has been BUILT to epic-end.
# A parked epic's commits say "plan epic" / "park epic" / "start epic" — never these — so this is the
# signal that separates built from merely-planned. Matched case-insensitively on the subject.
$script:Tier3EpicEndCommitMarkers = 'epic-end|manual test passed|mark epic complete'

# Pure: the DISTINCT epic slugs that reached epic-end, from commit records (@{ ts; subject }). The
# slug is the commit SCOPE (Get-Tier3CommitEpic), so `chore(notes): epic-end review` -> 'notes'.
# Feed it `git log --all` so an epic built on ANY branch/worktree is seen — a plan run builds each
# epic on its own branch and merges only some, so a single-branch view would miss a built epic that
# was branched away. Testable without git.
function Get-Tier3EpicEndSlugs {
    param([array]$Commits)
    $seen = @{}
    foreach ($c in @($Commits)) {
        $subj = [string]$c.subject
        if ($subj -notmatch "(?i)($script:Tier3EpicEndCommitMarkers)") { continue }
        $slug = Get-Tier3CommitEpic -Subject $subj
        if ($slug) { $seen[$slug] = $true }
    }
    return @($seen.Keys)
}

# Gather epic/story counts + per-epic build time from the built app (filesystem + git log).
# Best-effort: no git or no epics yields zeroes, never throws.
function Get-Tier3EpicStats {
    param([Parameter(Mandatory)][string]$Scaffold)
    $epics = @(Get-Tier3EpicDirs -Scaffold $Scaffold)
    # --all: a plan run builds epics on separate branches and merges only some, so the checked-out
    # branch alone would miss a built-then-branched epic (its commits live on another ref).
    $commits = @()
    try {
        foreach ($line in @(& git -C $Scaffold log --all --reverse --format='%ct|%s' 2>$null)) {
            $parts = [string]$line -split '\|', 2
            if ($parts.Count -eq 2) { $commits += @{ ts = [long]$parts[0]; subject = $parts[1] } }
        }
    }
    catch { }
    $perEpic = @(Measure-Tier3Epics -Epics $epics -Commits $commits)
    $stories = 0; foreach ($e in $epics) { $stories += [int]$e.stories }
    # "Built" = the epic reached the end of BUILD, by EITHER signal — so both failure modes of a
    # naive count are covered: a PARKED epic (READY-TO-BUILD, has stories) is NOT counted, and a
    # BUILT epic branched away (empty folder / no phase on this branch) is still caught by its
    # epic-end commit. "Created" is every epic folder the plan wrote. A run that plans 7 but builds 1
    # has epicsBuilt=1, epicsCreated=7 — the completeness signal.
    $endSlugs = @{}; foreach ($s in (Get-Tier3EpicEndSlugs -Commits $commits)) { $endSlugs[$s] = $true }
    $builtEpics = @($epics | Where-Object {
            ($script:Tier3BuiltEpicPhases -contains ([string]$_.phase).ToUpper()) -or $endSlugs.ContainsKey($_.slug)
        }).Count
    return @{ epicsCreated = @($epics).Count; epicsBuilt = $builtEpics; storiesCreated = $stories; epics = $perEpic }
}

# Parse a vitest JSON report (a run of tier-1 + tier-2) into per-tier group summaries for the
# report's "how each group did" table. Pure and testable.
function ConvertFrom-VitestGroupsJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Json)
    $obj = $Json | ConvertFrom-Json
    $groups = [ordered]@{
        'Project & workflow checks (Tier 1)' = @{ tests = 0; passed = 0; failed = 0; skipped = 0; durationSeconds = 0.0; match = 'tier-1-unit' }
        'Recorded run (Tier 2)'              = @{ tests = 0; passed = 0; failed = 0; skipped = 0; durationSeconds = 0.0; match = 'tier-2-recorded-run' }
    }
    foreach ($tr in @($obj.testResults)) {
        $name = ("$($tr.name)") -replace '\\', '/'
        foreach ($label in $groups.Keys) {
            if ($name -notmatch $groups[$label].match) { continue }
            foreach ($a in @($tr.assertionResults)) {
                $groups[$label].tests++
                switch ($a.status) {
                    'passed' { $groups[$label].passed++ }
                    'failed' { $groups[$label].failed++ }
                    default { $groups[$label].skipped++ }   # pending / skipped / todo
                }
            }
            $st = [double](Get-JsonProp $tr 'startTime' 0); $en = [double](Get-JsonProp $tr 'endTime' 0)
            if ($en -gt $st) { $groups[$label].durationSeconds += ($en - $st) / 1000.0 }
        }
    }
    $out = @()
    foreach ($label in $groups.Keys) {
        $g = $groups[$label]
        if ($g.tests -eq 0) { continue }   # tier not present in this run
        $out += @{ name = $label; tests = $g.tests; passed = $g.passed; failed = $g.failed; skipped = $g.skipped; durationSeconds = [Math]::Round($g.durationSeconds, 1) }
    }
    return $out
}

# Run the cheap tiers (Tier 1 + Tier 2) against the template under test and return per-tier
# group summaries. Best-effort — returns @() if vitest can't run. Uses the DEFAULT REPO_ROOT
# (the template), unlike conformance which points REPO_ROOT at the scaffold.
function Get-Tier3LowerTierGroups {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$QaRoot, [int]$TimeoutSeconds = 600)
    $outFile = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-lower-" + [Guid]::NewGuid().ToString('N') + ".json")
    try {
        $inner = "npx vitest run tier-1-unit tier-2-recorded-run --reporter=json > `"$outFile`" 2>nul"
        $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/s /c `"$inner`"" -WorkingDirectory $QaRoot -NoNewWindow -PassThru
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while (-not $p.HasExited) {
            Start-Sleep -Milliseconds 500
            if ($sw.Elapsed.TotalSeconds -ge $TimeoutSeconds) { try { & taskkill /T /F /PID $p.Id 2>$null | Out-Null } catch { }; break }
        }
        if (-not (Test-Path $outFile)) { return @() }
        $json = Get-Content -Raw -Path $outFile
        if ([string]::IsNullOrWhiteSpace($json)) { return @() }
        return @(ConvertFrom-VitestGroupsJson -Json $json)
    }
    catch { return @() }
    finally { try { if (Test-Path $outFile) { Remove-Item $outFile -Force } } catch { } }
}

function Get-Tier3Tools {
    $tools = @()
    foreach ($t in @(@{n = 'node'; a = '--version' }, @{n = 'npm'; a = '--version' }, @{n = 'claude'; a = '--version' })) {
        try {
            if (Get-Command $t.n -ErrorAction SilentlyContinue) {
                $v = (& $t.n $t.a 2>$null | Select-Object -First 1)
                $tools += "$($t.n) $v"
            }
        }
        catch { }
    }
    $tools += "pwsh $($PSVersionTable.PSVersion)"
    return $tools
}

# Build the per-phase timing rows for the run-result, distributing Claude's TOTAL reported
# time across the workflow-phase spans by how much each wrote (output tokens). The single
# 'phase' span (opus/build) carries the whole total; each 'wphase' span (…/spec, …/red, …)
# gets its token-weighted share. Active time comes straight from the (exact) timer spans.
function Get-DistributedPhaseTiming {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][array]$Spans,
        [Parameter(Mandatory)][hashtable]$GateTokens,
        [Parameter(Mandatory)][double]$TotalClaudeSeconds
    )
    $totalTok = 0.0
    foreach ($v in $GateTokens.Values) { $totalTok += [double]$v }

    # A workflow-phase (spec/red/green/save) usually recurs many times across TDD cycles,
    # producing many spans with the same gate name. Aggregate them into ONE row per gate:
    # active = sum of that gate's spans; Claude = the gate's token-weighted share of the
    # total (counted once, not per occurrence).
    $out = @()
    $gateActive = [ordered]@{}   # gate -> summed active
    $gatePath = @{}              # gate -> a representative path (opus/build/<gate>)
    foreach ($s in $Spans) {
        if ($s.level -eq 'phase') {
            $out += [ordered]@{ path = $s.path; activeSeconds = [Math]::Round([double]$s.activeSeconds, 4); claudeSeconds = [Math]::Round($TotalClaudeSeconds, 2) }
        }
        elseif ($s.level -eq 'wphase') {
            $gate = ($s.path -split '/')[-1]
            if (-not $gateActive.Contains($gate)) { $gateActive[$gate] = 0.0; $gatePath[$gate] = $s.path }
            $gateActive[$gate] += [double]$s.activeSeconds
        }
    }
    foreach ($gate in $gateActive.Keys) {
        $claude = if ($totalTok -gt 0 -and $GateTokens.ContainsKey($gate)) { $TotalClaudeSeconds * ([double]$GateTokens[$gate] / $totalTok) } else { 0.0 }
        $out += [ordered]@{ path = $gatePath[$gate]; activeSeconds = [Math]::Round($gateActive[$gate], 4); claudeSeconds = [Math]::Round($claude, 2) }
    }
    return $out
}

# ---- cross-segment progress (so a resumed run accumulates full totals) ----------------------

# Zeroed progress record.
function New-Tier3ProgressZero {
    return @{ segments = 0; turns = 0; tokens = 0; claudeSeconds = 0.0; activeSeconds = 0.0; excludedSeconds = 0.0; gateTokens = @{}; memPeakUsedMB = 0; memBaselineUsedMB = $null; memMinAvailableMB = $null; memTotalMB = $null }
}

# Read a saved progress.json (from a prior segment), or zeros when absent.
function Read-Tier3Progress {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { return New-Tier3ProgressZero }
    try {
        $o = Get-Content -Raw -Path $Path | ConvertFrom-Json
        $gt = @{}
        $gtObj = Get-JsonProp $o 'gateTokens'
        if ($gtObj) { foreach ($p in $gtObj.PSObject.Properties) { $gt[$p.Name] = [int]$p.Value } }
        return @{
            segments          = [int](Get-JsonProp $o 'segments' 0)
            turns             = [int](Get-JsonProp $o 'turns' 0)
            tokens            = [long](Get-JsonProp $o 'tokens' 0)
            claudeSeconds     = [double](Get-JsonProp $o 'claudeSeconds' 0)
            activeSeconds     = [double](Get-JsonProp $o 'activeSeconds' 0)
            excludedSeconds   = [double](Get-JsonProp $o 'excludedSeconds' 0)
            gateTokens        = $gt
            memPeakUsedMB     = [int](Get-JsonProp $o 'memPeakUsedMB' 0)
            memBaselineUsedMB = Get-JsonProp $o 'memBaselineUsedMB'
            memMinAvailableMB = Get-JsonProp $o 'memMinAvailableMB'
            memTotalMB        = Get-JsonProp $o 'memTotalMB'
        }
    }
    catch { return New-Tier3ProgressZero }
}

function Write-Tier3Progress {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][hashtable]$Record)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    try { Set-Content -Path $Path -Value ($Record | ConvertTo-Json -Depth 6) -Encoding utf8 } catch { }
}

# Combine a prior progress record with the just-finished segment. Pure and testable:
# tokens/turns/times ADD; gate tokens add per gate; memory peak = max, baseline/min-avail
# take the extreme across segments; segments increments by one.
function Merge-Tier3Progress {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Prior, [Parameter(Mandatory)][hashtable]$Segment)
    $gt = @{}
    foreach ($k in $Prior.gateTokens.Keys) { $gt[$k] = [int]$Prior.gateTokens[$k] }
    foreach ($k in $Segment.gateTokens.Keys) { $gt[$k] = [int]($gt[$k]) + [int]$Segment.gateTokens[$k] }

    $baseline = if ($null -ne $Prior.memBaselineUsedMB) { [Math]::Min([int]$Prior.memBaselineUsedMB, [int]$Segment.memBaselineUsedMB) } else { $Segment.memBaselineUsedMB }
    $minAvail = if ($null -ne $Prior.memMinAvailableMB) { [Math]::Min([int]$Prior.memMinAvailableMB, [int]$Segment.memMinAvailableMB) } else { $Segment.memMinAvailableMB }

    return @{
        segments          = [int]$Prior.segments + 1
        turns             = [int]$Prior.turns + [int]$Segment.turns
        tokens            = [long]$Prior.tokens + [long]$Segment.tokens
        claudeSeconds     = [double]$Prior.claudeSeconds + [double]$Segment.claudeSeconds
        activeSeconds     = [double]$Prior.activeSeconds + [double]$Segment.activeSeconds
        excludedSeconds   = [double]$Prior.excludedSeconds + [double]$Segment.excludedSeconds
        gateTokens        = $gt
        memPeakUsedMB     = [Math]::Max([int]$Prior.memPeakUsedMB, [int]$Segment.memPeakUsedMB)
        memBaselineUsedMB = $baseline
        memMinAvailableMB = $minAvail
        memTotalMB        = if ($null -ne $Segment.memTotalMB) { $Segment.memTotalMB } else { $Prior.memTotalMB }
    }
}

# Build a memory summary (report shape) from combined progress numbers.
function Get-MemorySummaryFromProgress {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$P, [int]$BudgetMB = 16384, [int]$AssumedVmBaselineMB = 4096)
    if (-not $P.memPeakUsedMB) { return @{ available = $false } }
    $added = [Math]::Max(0, [int]$P.memPeakUsedMB - [int]$P.memBaselineUsedMB)
    $est = $AssumedVmBaselineMB + $added
    return @{
        available = $true; peakUsedMB = [int]$P.memPeakUsedMB; totalMB = [int]$P.memTotalMB
        minAvailableMB = [int]$P.memMinAvailableMB; baselineUsedMB = [int]$P.memBaselineUsedMB
        addedMB = $added; assumedVmBaselineMB = $AssumedVmBaselineMB; estimatedVmUseMB = $est
        budgetMB = $BudgetMB; fitsBudget = ($est -le $BudgetMB)
    }
}

# Snapshot the CURRENT segment's tallies (for Merge with the prior progress).
function Get-Tier3SegmentRecord {
    [CmdletBinding()]
    param($Timer, $Mem, [hashtable]$GateTokens, [int]$Turns, [long]$Tokens, [double]$ClaudeSeconds)
    return @{
        turns = $Turns; tokens = $Tokens; claudeSeconds = $ClaudeSeconds
        activeSeconds = $Timer.CurrentActiveSeconds(); excludedSeconds = $Timer.CurrentExcludedSeconds()
        gateTokens = $GateTokens
        memPeakUsedMB = [int]$Mem.peakUsedMB; memBaselineUsedMB = [int]$Mem.baselineUsedMB
        memMinAvailableMB = [int]$Mem.minAvailableMB; memTotalMB = [int]$Mem.totalMB
    }
}

# ---- PLAN-A scenario: plan an epic ahead, park it ready to build (record-only) --------------
#
# The plan-ahead command's live behaviours (worktree planning, parking on `main` at
# READY-TO-BUILD, creating NO epic branch, resuming straight into BUILD) are read from the
# traces a PLAN-A run leaves in git + generated-docs. The PURE functions below get the
# good/broken Pester coverage; the IO gatherer is best-effort like Get-Tier3EpicStats. Every
# rule id is recorded in the run's rulesMissed, never used to fail the run.

# Pure: the epic slugs in an epic-plan.md's "## Epics" table (the first backticked `<slug>`
# per row). Diffing this set between the setup commit and HEAD tells an epic OUTLINED at
# project setup from a BRAND-NEW one introduced later by /plan.
function Get-Tier3PlanEpicSlugs {
    [CmdletBinding()]
    param([string]$Markdown)
    $slugs = [System.Collections.Generic.List[string]]::new()
    if ([string]::IsNullOrWhiteSpace($Markdown)) { return @() }
    $inEpics = $false
    foreach ($line in ($Markdown -split "`r?`n")) {
        if ($line -match '^\s*##\s+Epics\b') { $inEpics = $true; continue }
        elseif ($line -match '^\s*##\s') { $inEpics = $false; continue }   # the next section ends the table
        if (-not $inEpics -or $line -notmatch '^\s*\|') { continue }        # table rows only
        $m = [regex]::Match($line, '`([a-z0-9]+(?:-[a-z0-9]+)*)`')          # the row's OWN slug is first
        if ($m.Success -and -not $slugs.Contains($m.Groups[1].Value)) { $slugs.Add($m.Groups[1].Value) }
    }
    return @($slugs)
}

# Pure + testable: given the facts a PLAN-A run left behind, the plan rule ids it violated.
# Facts shape (see Get-Tier3PlanFacts):
#   parkedEpics          @({ slug; storyCount; dependsOn=@(); onMain; hasEpicBranch; hasBuildCommits })
#   leftoverPlanBranches @()  leftoverWorktrees @()  projectFactsChanged bool
#   plannedNewEpic bool  resumedToBuild bool  expectNewEpic/expectBlocked/expectResume bool
function Get-Tier3PlanRulesMissed {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Facts)
    $missed = [System.Collections.Generic.List[string]]::new()
    $parked = @($Facts.parkedEpics)

    if ($parked.Count -eq 0) { $missed.Add('plan-no-parked-epic') }         # AC4 — nothing parked

    foreach ($e in $parked) {
        if ($e.hasEpicBranch)         { $missed.Add('plan-created-epic-branch') }  # AC1 — build branch cut
        if ($e.hasBuildCommits)       { $missed.Add('plan-build-committed') }      # AC1 — story code committed
        if ([int]$e.storyCount -le 0) { $missed.Add('plan-stories-missing') }      # AC2 — no story breakdown
        if (-not $e.onMain)           { $missed.Add('plan-not-on-main') }          # AC4 — not parked on main
    }

    if (@($Facts.leftoverPlanBranches).Count -gt 0 -or @($Facts.leftoverWorktrees).Count -gt 0) {
        $missed.Add('plan-worktree-leftover')                                       # AC4 — throwaway not torn down
    }
    if ($Facts.projectFactsChanged) { $missed.Add('plan-facts-changed') }           # AC11 — /plan touched project.md

    # Optional behaviours the scenario asked for — flag only when it drove them.
    if ($Facts.expectNewEpic -and -not $Facts.plannedNewEpic) { $missed.Add('plan-new-epic-missing') }   # AC3b
    if ($Facts.expectBlocked -and -not (@($parked | Where-Object { @($_.dependsOn).Count -gt 0 }).Count -gt 0)) {
        $missed.Add('plan-blocked-ahead-missing')                                   # AC13 — depends-on-unbuilt path
    }
    if ($Facts.expectResume -and -not $Facts.resumedToBuild) { $missed.Add('plan-resume-missing') }      # AC5

    return @($missed | Select-Object -Unique)
}

# Best-effort: read a parsed state.json for one epic (or $null).
function Get-Tier3EpicState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Scaffold, [Parameter(Mandatory)][string]$Slug)
    $p = Join-Path $Scaffold "generated-docs/epics/$Slug/state.json"
    if (-not (Test-Path $p)) { return $null }
    try { return (Get-Content -Raw -Path $p | ConvertFrom-Json) } catch { return $null }
}

# Best-effort: is a path present on a git ref (e.g. 'main')? Used for "parked on main".
function Test-Tier3OnRef {
    [CmdletBinding()]
    param([string]$Scaffold, [string]$Ref, [string]$RelPath)
    try { & git -C $Scaffold cat-file -e "${Ref}:${RelPath}" 2>$null; return ($LASTEXITCODE -eq 0) } catch { return $false }
}

# Best-effort: gather the facts a PLAN-A run leaves (git refs + generated-docs). Never throws
# — missing git/epics yield empty facts, exactly like Get-Tier3EpicStats. -Expect selects
# which optional behaviours the scenario drove (default: all three, as PLAN-A drives them).
function Get-Tier3PlanFacts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Scaffold,
        [string]$WorktreeParent,
        [hashtable]$Expect
    )
    $expect = if ($Expect) { $Expect } else { @{ expectNewEpic = $true; expectBlocked = $true; expectResume = $true } }

    # Branches: an epic/<slug> means build started; a plan/<slug> left behind means teardown missed.
    $branches = @(); try { $branches = @(& git -C $Scaffold branch "--format=%(refname:short)" 2>$null) } catch { }
    $epicBranches = @($branches | Where-Object { $_ -match '^epic/' })
    $leftoverPlanBranches = @($branches | Where-Object { $_ -match '^plan/' })

    # Build commits: feat(<slug>[/story-N]) subjects tell which epics produced story code.
    $subjects = @(); try { $subjects = @(& git -C $Scaffold log "--format=%s" 2>$null) } catch { }
    $buildSlugs = New-Object System.Collections.Generic.HashSet[string]
    foreach ($s in $subjects) { if ($s -match '^\s*feat\(([^)/]+)(?:/[^)]*)?\)') { [void]$buildSlugs.Add($Matches[1]) } }

    # Leftover throwaway worktrees: git's own list, plus sibling ../<project>-plan-* directories.
    $leftoverWorktrees = @()
    try {
        $wt = @(& git -C $Scaffold worktree list --porcelain 2>$null | Where-Object { $_ -match '^worktree ' } | ForEach-Object { ($_ -replace '^worktree ', '').Trim() })
        $leftoverWorktrees += @($wt | Where-Object { $_ -match '-plan-[a-z0-9-]+/?$' })
    } catch { }
    if ($WorktreeParent -and (Test-Path $WorktreeParent)) {
        $base = Split-Path -Leaf $Scaffold
        foreach ($d in (Get-ChildItem -Path $WorktreeParent -Directory -ErrorAction SilentlyContinue)) {
            if ($d.Name -like "$base-plan-*") { $leftoverWorktrees += $d.FullName }
        }
    }
    $leftoverWorktrees = @($leftoverWorktrees | Select-Object -Unique)

    # The setup commit (docs(project)) anchors "outlined at setup" and "project.md unchanged".
    $setupCommit = $null
    try {
        $line = @(& git -C $Scaffold log "--format=%H|%s" 2>$null | Where-Object { $_ -match '\|\s*docs\(project\)' } | Select-Object -Last 1)
        if ($line) { $setupCommit = ($line -split '\|', 2)[0] }
    } catch { }

    $projectFactsChanged = $false
    if ($setupCommit) {
        try { & git -C $Scaffold diff --quiet $setupCommit HEAD -- generated-docs/project.md 2>$null; $projectFactsChanged = ($LASTEXITCODE -ne 0) } catch { }
    }

    # New-vs-outlined: an epic present in the plan at HEAD but absent at the setup commit.
    $setupSlugs = @(); $currentSlugs = @()
    if ($setupCommit) {
        try { $setupSlugs = @(Get-Tier3PlanEpicSlugs -Markdown ((& git -C $Scaffold show "${setupCommit}:generated-docs/epic-plan.md" 2>$null) -join "`n")) } catch { }
    }
    $planPath = Join-Path $Scaffold 'generated-docs/epic-plan.md'
    if (Test-Path $planPath) { $currentSlugs = @(Get-Tier3PlanEpicSlugs -Markdown (Get-Content -Raw -Path $planPath)) }
    $newEpicSlugs = @($currentSlugs | Where-Object { $setupSlugs -notcontains $_ })

    # Prefer the 'main' ref for the parked-on-main check; fall back to HEAD when there's no main.
    $hasMain = $false
    try { & git -C $Scaffold rev-parse --verify --quiet main 2>$null | Out-Null; $hasMain = ($LASTEXITCODE -eq 0) } catch { }
    $parkedRef = if ($hasMain) { 'main' } else { 'HEAD' }

    $parked = [System.Collections.Generic.List[hashtable]]::new()
    $resumedToBuild = $false
    $epicsRoot = Join-Path $Scaffold 'generated-docs/epics'
    if (Test-Path $epicsRoot) {
        foreach ($d in (Get-ChildItem -Path $epicsRoot -Directory -ErrorAction SilentlyContinue)) {
            $st = Get-Tier3EpicState -Scaffold $Scaffold -Slug $d.Name
            if (-not $st) { continue }
            $phase = [string](Get-JsonProp $st 'phase')
            $storyCount = @(Get-ChildItem -Path (Join-Path $d.FullName 'stories') -Filter 'story-*.md' -File -ErrorAction SilentlyContinue).Count
            $epicObj = Get-JsonProp $st 'epic'
            $dependsOn = if ($epicObj) { @(Get-JsonProp $epicObj 'dependsOn' @()) } else { @() }
            $hasBuild = $buildSlugs.Contains($d.Name)
            if ($phase -eq 'READY-TO-BUILD') {
                $onMain = Test-Tier3OnRef -Scaffold $Scaffold -Ref $parkedRef -RelPath "generated-docs/epics/$($d.Name)/state.json"
                $parked.Add(@{
                    slug = $d.Name; storyCount = $storyCount; dependsOn = @($dependsOn)
                    onMain = $onMain
                    hasEpicBranch = (@($epicBranches | Where-Object { $_ -eq "epic/$($d.Name)" }).Count -gt 0)
                    hasBuildCommits = $hasBuild
                })
            }
            # AC5 handoff: an epic that was planned (has stories) later produced build commits.
            if ($hasBuild -and $storyCount -gt 0) { $resumedToBuild = $true }
        }
    }

    return @{
        parkedEpics          = @($parked)
        leftoverPlanBranches = @($leftoverPlanBranches)
        leftoverWorktrees    = @($leftoverWorktrees)
        projectFactsChanged  = $projectFactsChanged
        plannedNewEpic       = (@($newEpicSlugs).Count -gt 0)
        newEpicSlugs         = @($newEpicSlugs)
        resumedToBuild       = $resumedToBuild
        expectNewEpic        = [bool]$expect.expectNewEpic
        expectBlocked        = [bool]$expect.expectBlocked
        expectResume         = [bool]$expect.expectResume
    }
}

# ---- PLAN-B scenario: build one epic while planning the next, concurrently (record-only) ----
#
# The plan-ahead command's HEADLINE promise — plan the next epic in one session WHILE another
# session builds an epic, neither disturbing the other, main staying consistent — needs two
# live Claude sessions at once and a SHARED remote (that's the concurrency model: both talk
# only through origin/main; without a remote /plan drops to its single-session fallback, which
# is what PLAN-A covers). This section adds the bare-remote scaffold, the two prompts, the
# concurrent launcher, and the deterministic (record-only) scoring. As with PLAN-A, the PURE
# functions get good/broken Pester coverage; the live two-process orchestration is proven only
# in a real run.

# Real-git: turn a scaffolded working tree into a repo with a BARE origin it has pushed main to.
# The AI never creates a remote (it only `git push origin HEAD` best-effort), so the harness must
# stand origin up before the sessions run. Idempotent; best-effort — returns ok=$false, never throws.
function New-Tier3BareRemote {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$WorkingDir, [Parameter(Mandatory)][string]$RemoteDir)
    try {
        & git -C $WorkingDir init -q 2>$null
        & git -C $WorkingDir config user.email 'tier3@local' 2>$null
        & git -C $WorkingDir config user.name  'Tier3 Harness' 2>$null
        & git -C $WorkingDir add -A 2>$null
        & git -C $WorkingDir commit -q -m 'chore: scaffold' 2>$null
        & git -C $WorkingDir branch -M main 2>$null
        if (-not (Test-Path $RemoteDir)) { New-Item -ItemType Directory -Path $RemoteDir -Force | Out-Null }
        & git init --bare -q $RemoteDir 2>$null
        & git -C $WorkingDir remote remove origin 2>$null
        & git -C $WorkingDir remote add origin $RemoteDir 2>$null
        & git -C $WorkingDir push -u origin main -q 2>$null
        return @{ ok = (Test-Path (Join-Path $RemoteDir 'HEAD')); remote = $RemoteDir }
    }
    catch { return @{ ok = $false; remote = $RemoteDir; detail = $_.Exception.Message } }
}

# Real-git: a SECOND working tree for the planner, cloned from the shared bare remote — its own
# tree, branch, and state, so "neither session disturbs the other" is genuinely observable.
function New-Tier3PlannerClone {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RemoteDir, [Parameter(Mandatory)][string]$PlannerDir)
    try {
        if (Test-Path $PlannerDir) { Remove-Item $PlannerDir -Recurse -Force }
        & git clone -q $RemoteDir $PlannerDir 2>$null
        & git -C $PlannerDir config user.email 'tier3-planner@local' 2>$null
        & git -C $PlannerDir config user.name  'Tier3 Planner' 2>$null
        return (Test-Path (Join-Path $PlannerDir '.git'))
    }
    catch { return $false }
}

# The bootstrap prompt (single session, before the concurrent pair): set the project up and
# build ONLY the first epic through merge, so main carries the project + epic plan + one merged
# epic and both concurrent sessions have a stable origin/main to branch from.
function Get-Tier3ConcurrentBootstrapPrompt {
    [CmdletBinding()]
    param([string]$AnswersFileName = 'TIER3-ANSWERS.json')
    return @"
You are in a freshly scaffolded Stadium 8 workflow project with a git remote already set up
(origin). Run ``/start`` and set the project up from the documents in documentation/ (project
facts + the epic plan), then build ONLY THE FIRST epic all the way through EPIC-END and merge it
to main. When the first epic is merged, STOP — do not build or plan any further epic.

This is AUTOMATED and NON-INTERACTIVE: for every approval or choice (project facts, sign-in, the
story list, the hands-on checklist, the merge) read the pre-planned answers in ``$AnswersFileName``
at the repo root and proceed WITHOUT stopping. Push your work to origin as the workflow does.
"@
}

# The BUILDER prompt (concurrent session A): build the next epic. Runs at the SAME TIME as the
# planner. It must stay in its own lane — its epic branch — and never plan.
function Get-Tier3ConcurrentBuilderPrompt {
    [CmdletBinding()]
    param([string]$AnswersFileName = 'TIER3-ANSWERS.json')
    return @"
You are in a Stadium 8 project on main, with a git remote (origin). ANOTHER session is planning
the next epic AT THE SAME TIME as you — stay entirely in your own lane and do not disturb it.

Run ``/start``, pick the NEXT epic that is ready to build, and build it fully through EPIC-END,
then merge it to main. Do all your work on that epic's own ``epic/<slug>`` branch. Do NOT run
``/plan``. Do NOT edit another epic's files. This is AUTOMATED and NON-INTERACTIVE: for every
approval or choice, read the pre-planned answers in ``$AnswersFileName`` at the repo root and
proceed WITHOUT stopping. When your epic is merged, STOP.
"@
}

# The PLANNER prompt (concurrent session B): plan the next epic ahead and park it — WHILE the
# builder builds. This is the session whose non-interference we are proving.
function Get-Tier3ConcurrentPlannerPrompt {
    [CmdletBinding()]
    param([string]$AnswersFileName = 'TIER3-ANSWERS.json')
    return @"
You are in a Stadium 8 project on main, with a git remote (origin). ANOTHER session is BUILDING
an epic AT THE SAME TIME as you. Run ``/plan`` to plan a BRAND-NEW epic ahead and PARK it ready
to build, without building it: a "User Settings" epic — a settings page where a signed-in user
can view and change their own display name. Approve its brief and story list from the answers
file, and land the parked plan on main through the remote (origin), exactly as ``/plan`` does.

Do NOT build anything. Do NOT run ``/start``. Do NOT touch the epic the other session is building.
This is AUTOMATED and NON-INTERACTIVE: for every approval or choice, read the pre-planned answers
in ``$AnswersFileName`` at the repo root and proceed WITHOUT stopping. When the epic is parked on
main, STOP.
"@
}

# Pure + testable: given the facts a PLAN-B run left, the concurrent rule ids it violated.
# Facts shape (see Get-Tier3ConcurrentFacts):
#   builtEpicSlug plannedEpicSlug (strings)  overlapSeconds (double)
#   plannerTouchedBuildBranch fsckClean projectFactsChangedByPlanner builderCommitsPreserved
#   plannerPlanOnMain (bools)  epicPlanRowsOnMain (@slugs)  blockedMergeRefused ($true/$false/$null)
#   expectBlocked (bool)
function Get-Tier3ConcurrentRulesMissed {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Facts)
    $missed = [System.Collections.Generic.List[string]]::new()

    # AC7 — both sessions ran AND their wall-clock windows overlapped.
    $bothRan = -not [string]::IsNullOrWhiteSpace([string]$Facts.builtEpicSlug) `
        -and -not [string]::IsNullOrWhiteSpace([string]$Facts.plannedEpicSlug)
    if (-not $bothRan -or [double]$Facts.overlapSeconds -le 0) { $missed.Add('plan-concurrent-ran') }

    # AC8 — the planner never touched the builder's epic branch.
    if ($Facts.plannerTouchedBuildBranch) { $missed.Add('plan-cross-disturb') }

    # AC10 — main is intact and carries BOTH epics' records.
    $rows = @($Facts.epicPlanRowsOnMain)
    $hasBuilt   = ($Facts.builtEpicSlug   -and $rows -contains $Facts.builtEpicSlug)
    $hasPlanned = ($Facts.plannedEpicSlug -and $rows -contains $Facts.plannedEpicSlug)
    if (-not $Facts.fsckClean -or -not $hasBuilt -or -not $hasPlanned) { $missed.Add('plan-main-inconsistent') }

    # AC11 — the planner did not change project-level facts.
    if ($Facts.projectFactsChangedByPlanner) { $missed.Add('plan-facts-changed') }

    # AC12 — no session lost committed work.
    if (-not $Facts.builderCommitsPreserved -or -not $Facts.plannerPlanOnMain) { $missed.Add('plan-lost-work') }

    # AC14 — a dependent epic couldn't merge before its dependency (only when the run tested it;
    # $null means "not exercised" and never flags).
    if ($Facts.expectBlocked -and ($Facts.blockedMergeRefused -eq $false)) { $missed.Add('plan-blocked-until-dep') }

    return @($missed | Select-Object -Unique)
}

# Best-effort: gather PLAN-B facts from the shared remote + the builder tree after both sessions
# finish. Session-known values (slugs, overlap) are passed in; git supplies main's final state.
# Never throws — missing git yields empty/false facts.
function Get-Tier3ConcurrentFacts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RemoteDir,
        [Parameter(Mandatory)][string]$BuilderDir,
        [string]$BuiltEpicSlug,
        [string]$PlannedEpicSlug,
        [double]$OverlapSeconds = 0,
        [hashtable]$Expect
    )
    $expect = if ($Expect) { $Expect } else { @{ expectBlocked = $false } }

    # Refresh the builder tree's view of the remote so origin/main is the post-run truth.
    try { & git -C $BuilderDir fetch origin -q 2>$null } catch { }

    # Read a path as it stands on origin/main.
    function Show-OnMain([string]$RelPath) {
        try { return ((& git -C $BuilderDir show "origin/main:$RelPath" 2>$null) -join "`n") } catch { return $null }
    }

    $epicPlanRowsOnMain = @(Get-Tier3PlanEpicSlugs -Markdown (Show-OnMain 'generated-docs/epic-plan.md'))

    # The planned epic is parked (READY-TO-BUILD) on main.
    $plannerPlanOnMain = $false
    if ($PlannedEpicSlug) {
        $stateRaw = Show-OnMain "generated-docs/epics/$PlannedEpicSlug/state.json"
        if ($stateRaw) { try { $plannerPlanOnMain = ([string]((($stateRaw | ConvertFrom-Json)).phase) -eq 'READY-TO-BUILD') } catch { } }
    }

    # The built epic's story code survived onto main (its feat commits are reachable from main).
    $builderCommitsPreserved = $false
    if ($BuiltEpicSlug) {
        try {
            $subjects = @(& git -C $BuilderDir log origin/main "--format=%s" 2>$null)
            $builderCommitsPreserved = (@($subjects | Where-Object { $_ -match "^\s*feat\($([regex]::Escape($BuiltEpicSlug))(/|\))" }).Count -gt 0)
        } catch { }
    }

    # The planner's work never leaked onto the builder's epic branch (a docs(plan) commit there
    # would be cross-contamination). Absence is the clean signal.
    $plannerTouchedBuildBranch = $false
    if ($BuiltEpicSlug) {
        try {
            $branchSubjects = @(& git -C $BuilderDir log "origin/epic/$BuiltEpicSlug" "--format=%s" 2>$null)
            $plannerTouchedBuildBranch = (@($branchSubjects | Where-Object { $_ -match '^\s*docs\(plan\)' }).Count -gt 0)
        } catch { }
    }

    # project.md on main is unchanged from the bootstrap (the planner must not edit project facts).
    $projectFactsChangedByPlanner = $false
    try {
        $setupLine = @(& git -C $BuilderDir log origin/main "--format=%H|%s" 2>$null | Where-Object { $_ -match '\|\s*docs\(project\)' } | Select-Object -Last 1)
        if ($setupLine) {
            $setupCommit = ($setupLine -split '\|', 2)[0]
            & git -C $BuilderDir diff --quiet $setupCommit origin/main -- generated-docs/project.md 2>$null
            $projectFactsChangedByPlanner = ($LASTEXITCODE -ne 0)
        }
    } catch { }

    # The shared remote's object store is intact.
    $fsckClean = $false
    try { & git -C $RemoteDir fsck --no-progress 2>$null | Out-Null; $fsckClean = ($LASTEXITCODE -eq 0) } catch { }

    return @{
        builtEpicSlug                = $BuiltEpicSlug
        plannedEpicSlug              = $PlannedEpicSlug
        overlapSeconds               = [double]$OverlapSeconds
        epicPlanRowsOnMain           = @($epicPlanRowsOnMain)
        plannerPlanOnMain            = $plannerPlanOnMain
        builderCommitsPreserved      = $builderCommitsPreserved
        plannerTouchedBuildBranch    = $plannerTouchedBuildBranch
        projectFactsChangedByPlanner = $projectFactsChangedByPlanner
        fsckClean                    = $fsckClean
        blockedMergeRefused          = $null
        expectBlocked                = [bool]$expect.expectBlocked
    }
}

# ---- the live run: scaffold -> prompt -> headless claude -> checks -> run-result -------------

# Best-effort: make sure every Chromium component the e2e gate launches is in the (machine-global)
# browser cache BEFORE the AI reaches its epic-end gate — the exact build the app's own Playwright
# resolves, complete with its headless shell, so the gate REUSES the cache. Without that the
# workflow discovers a missing browser mid-run and downloads it under time pressure, and a headless
# session can end before the download finishes, stalling the run at the first epic (exactly what
# truncated the release build). Setup.ps1 also warms it; this covers -SkipSetup and resumed runs.
# Idempotent (a no-op when the cache is already complete) and never throws — on failure the AI
# still installs it itself, as before. Writes a small log next to the run for diagnosis.
#
# -TemplateRoot is the checkout this run builds against, and it must be passed: the version to warm
# comes from THAT app's lockfile. Without it the resolver falls back to the declared range's newest
# published match (^1.59.1 -> 1.62.0 -> chromium-1234) while the app's own `npm install` lands the
# locked 1.59.1 -> chromium-1217 — so the pre-warm reports a complete cache for a build the e2e gate
# never launches, and the gate downloads its browser mid-epic. That is the precise failure this
# function exists to prevent, and the paths it is meant to cover (-SkipSetup, a resumed run, the
# driver loaded on its own) are exactly the ones where setup has NOT already aimed the resolver.
function Install-Tier3Browser {
    [CmdletBinding()]
    param([string]$LogPath, [string]$TemplateRoot)
    $log = [System.Collections.Generic.List[string]]::new()
    $ok  = $false
    # Aim the version resolver at this run's template before anything reads it. Re-aiming also drops
    # any version memoised for another template (e.g. a dev run following a release one).
    if ($TemplateRoot -and (Get-Command Set-Tier3TemplateRoot -ErrorAction SilentlyContinue)) {
        Set-Tier3TemplateRoot -Path $TemplateRoot
        $log.Add("aimed at the template this run builds: $TemplateRoot")
    }
    # Delegate to Setup.ps1 when it's in scope (Run-QATests dot-sources both) so the driver warms
    # EXACTLY the version and components setup verifies — one source of truth. Duplicating a pinned
    # version here is what would let the two drift and hand the gate a build it never launches.
    # Setup's installer already clears a stale __dirlock and re-verifies the executable itself.
    if (Get-Command Install-PlaywrightChromium -ErrorAction SilentlyContinue) {
        try {
            $log.Add("resolved @playwright/test $(Get-Tier3PlaywrightVersion); needs $((Get-Tier3BrowserComponents) -join ', ')")
            if (Test-PlaywrightChromium) {
                $log.Add('cache already complete — the e2e gate will launch from it, nothing to fetch')
                $ok = $true
            }
            else {
                $log.Add("missing: $(@(Get-MissingPlaywrightComponents) -join ', ') — installing")
                Install-PlaywrightChromium
                $ok = Test-PlaywrightChromium
                $log.Add($(if ($ok) { 'cache complete after install' } else { "still missing after install: $(@(Get-MissingPlaywrightComponents) -join ', ')" }))
            }
        }
        catch { $log.Add("playwright install failed: $($_.Exception.Message)") }
    }
    else {
        # Standalone fallback (driver loaded without Setup.ps1, e.g. its own Pester tests): install
        # the floor of the template's range. Browser binary only — never `--with-deps` (see
        # Install-PlaywrightChromium in Setup.ps1: it needs root and hangs on a sudo prompt).
        $ver = if ($env:TIER3_PLAYWRIGHT_VERSION) { $env:TIER3_PLAYWRIGHT_VERSION } else { '1.59.1' }
        $log.Add("Setup.ps1 not loaded — falling back to @playwright/test@$ver")
        try {
            if ($IsWindows) { $out = & cmd.exe /c "npx --yes @playwright/test@$ver install chromium 2>&1" }
            else            { $out = & npx --yes "@playwright/test@$ver" install chromium 2>&1 }
            $log.Add("`$ npx --yes @playwright/test@$ver install chromium (exit $LASTEXITCODE)")
            $log.Add((($out | Out-String).Trim()))
            if ($LASTEXITCODE -eq 0) { $ok = $true }
        }
        catch { $log.Add("npx --yes @playwright/test@$ver install chromium failed: $($_.Exception.Message)") }
    }
    if ($LogPath) { Set-Content -Path $LogPath -Value (($log -join [Environment]::NewLine).Trim()) -Encoding utf8 }
    return $ok
}

function Invoke-Tier3LiveRun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$Benchmark,
        [Parameter(Mandatory)][string]$WorkingDir,
        [Parameter(Mandatory)][string]$TemplateRoot,
        [Parameter(Mandatory)][string]$BenchmarkDir,
        [Parameter(Mandatory)][string]$LiveDir,
        [Parameter(Mandatory)][string]$RunId,
        [string]$Version = '0.1.0',
        [int]$TimeoutSeconds = 86400,
        [string]$ResumeSessionId,
        [ValidateSet('build', 'plan', 'concurrent')][string]$Scenario = 'build'
    )
    $resuming = [bool]$ResumeSessionId

    # PLAN-B is a two-session, shared-remote run with its own orchestration — delegate wholesale.
    if ($Scenario -eq 'concurrent' -and -not $resuming) {
        return (Invoke-Tier3ConcurrentRun -Model $Model -Benchmark $Benchmark -WorkingDir $WorkingDir `
                -TemplateRoot $TemplateRoot -BenchmarkDir $BenchmarkDir -LiveDir $LiveDir -RunId $RunId `
                -Version $Version -TimeoutSeconds $TimeoutSeconds)
    }

    if ($resuming) {
        # Resume an interrupted run: reuse the existing scaffold, continue the same session.
        $prompt = Get-Tier3ResumePrompt
    }
    else {
        New-Tier3Scaffold -TemplateRoot $TemplateRoot -WorkingDir $WorkingDir -BenchmarkDir $BenchmarkDir | Out-Null
        # PLAN-A drives /plan through its park-ahead choreography; the default drives the straight build.
        $prompt = if ($Scenario -eq 'plan') { Get-Tier3PlanPrompt } else { Get-Tier3Prompt }
    }

    if (-not (Test-Path $LiveDir)) { New-Item -ItemType Directory -Path $LiveDir -Force | Out-Null }
    $sessionIdFile = Join-Path $LiveDir 'session.id'
    $progressPath = Join-Path $LiveDir 'progress.json'
    # Prior segments' cumulative totals (present only when resuming an earlier segment).
    $prior = if ($resuming) { Read-Tier3Progress -Path $progressPath } else { New-Tier3ProgressZero }

    # Warm the Playwright browser cache before driving the AI (see Install-Tier3Browser). Done
    # before the run timer starts so this one-off download is never charged to build time.
    # -TemplateRoot is mandatory in spirit: it's what pins the version warmed to the one THIS app
    # installs, on the -SkipSetup / resume paths where setup hasn't already aimed the resolver.
    Install-Tier3Browser -LogPath (Join-Path $LiveDir 'playwright-install.log') -TemplateRoot $TemplateRoot | Out-Null

    $timer = New-Tier3Timer -LiveDir $LiveDir -RunId $RunId
    $timer.Start('run', 'run')    | Out-Null
    $timer.Start($Model, 'model') | Out-Null
    $timer.Start('build', 'phase') | Out-Null

    $mem = New-MemoryPeak   # track peak memory across BOTH the Claude phase and the build

    $g = @{ current = $null; tokens = @{} }
    $onTurn = {
        param($n, $gate, $outTok)
        $timer.Update()
        if ($gate -ne $g.current) {
            if ($null -ne $g.current) { $timer.Stop() | Out-Null }   # close previous wphase
            $timer.Start($gate, 'wphase') | Out-Null
            $g.current = $gate
        }
        if (-not $g.tokens.ContainsKey($gate)) { $g.tokens[$gate] = 0 }
        $g.tokens[$gate] += [int]$outTok                             # per-phase work, for time distribution
        $timer.Start("turn-$n", 'turn') | Out-Null
        $timer.Stop(0.0) | Out-Null
        # Persist a cumulative snapshot each turn, so an interrupt here leaves a resumable trail.
        $segTok = 0; foreach ($v in $g.tokens.Values) { $segTok += [int]$v }
        $seg = Get-Tier3SegmentRecord -Timer $timer -Mem $mem -GateTokens $g.tokens -Turns $n -Tokens $segTok -ClaudeSeconds 0
        Write-Tier3Progress -Path $progressPath -Record (Merge-Tier3Progress -Prior $prior -Segment $seg)
    }.GetNewClosure()

    $onHeartbeat = { $timer.Update() }.GetNewClosure()
    $claudeArgs = @{
        Prompt = $prompt; WorkingDir = $WorkingDir; Model = $Model
        TimeoutSeconds = $TimeoutSeconds; OnTurn = $onTurn; OnHeartbeat = $onHeartbeat
        OutFile = (Join-Path $LiveDir "$RunId-claude.jsonl"); MemoryPeak = $mem; SessionIdFile = $sessionIdFile
    }
    if ($resuming) { $claudeArgs.ResumeSessionId = $ResumeSessionId }
    $res = Invoke-ClaudeHeadless @claudeArgs

    if ($null -ne $g.current) { $timer.Stop() | Out-Null }     # wphase
    $timer.Stop() | Out-Null                                    # phase
    $timer.Stop($res.claudeSeconds) | Out-Null                  # model (total Claude time here)
    $timer.Stop() | Out-Null                                    # run
    $summary = $timer.Summary()

    $built = Test-Tier3Build -WorkingDir $WorkingDir -MemoryPeak $mem

    # Combine this segment with any prior segments (resume), so totals are cumulative.
    $segFinal = Get-Tier3SegmentRecord -Timer $timer -Mem $mem -GateTokens $g.tokens -Turns $res.turns -Tokens $res.tokens -ClaudeSeconds $res.claudeSeconds
    $combined = Merge-Tier3Progress -Prior $prior -Segment $segFinal
    Write-Tier3Progress -Path $progressPath -Record $combined
    $memSummary = Get-MemorySummaryFromProgress -P $combined

    # Per-phase timing: Claude's CUMULATIVE time distributed by cumulative per-phase output tokens.
    $phaseTiming = Get-DistributedPhaseTiming -Spans @($summary.spans) -GateTokens $combined.gateTokens -TotalClaudeSeconds $combined.claudeSeconds

    # Conformance: run the REAL artifact-lint rules against the built app (record-only).
    $qaRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $conf = Get-Tier3Conformance -Scaffold $WorkingDir -QaRoot $qaRoot
    $lintMissed = if ($conf.ran) { @($conf.rulesMissed) } else { @() }

    # PLAN-A: score /plan's live behaviours from the traces it left (record-only).
    $planMissed = @()
    if ($Scenario -eq 'plan') {
        $planFacts = Get-Tier3PlanFacts -Scaffold $WorkingDir -WorktreeParent (Split-Path -Parent $WorkingDir)
        $planMissed = @(Get-Tier3PlanRulesMissed -Facts $planFacts)
    }

    # Epics/stories created + per-epic build time (from the app's git history).
    $epicStats = Get-Tier3EpicStats -Scaffold $WorkingDir

    # Completeness: did the build finish the WHOLE plan, or stop partway (e.g. it stalled at an
    # epic-end gate and ended after epic 1 of 7)? "Planned" = every epic the plan created a brief
    # for; "built" = every epic that actually produced stories. A partial build must never score
    # as a clean pass — it gets its own 'incomplete' verdict and a completeness-weighted pass-rate.
    $epicsPlanned = [int]$epicStats.epicsCreated
    $epicsBuilt   = [int]$epicStats.epicsBuilt
    $complete     = ($epicsPlanned -gt 0 -and $epicsBuilt -ge $epicsPlanned)
    $completeness = if ($epicsPlanned -gt 0) { [Math]::Round([double]$epicsBuilt / $epicsPlanned, 4) } else { 0.0 }

    # Fold build + lint + completeness into the verdict. Conforming = built AND no rules missed
    # AND not timed out AND the whole plan is built. 'incomplete-build' is a missed rule, so a
    # partial run can never be 'conformed'.
    $rulesMissed = @()
    if (-not $built.ok) { $rulesMissed += 'did-not-build' }
    # A PLAN-A run builds only some epics on purpose (it parks the rest), so partial ≠ defect there.
    if (-not $complete -and $Scenario -ne 'plan') { $rulesMissed += 'incomplete-build' }
    $rulesMissed += $lintMissed
    $rulesMissed += $planMissed
    $rulesMissed = @($rulesMissed | Select-Object -Unique)
    $conformed = ($built.ok -and -not $res.timedOut -and $rulesMissed.Count -eq 0 -and ($complete -or $Scenario -eq 'plan'))
    # A PLAN-A run parks epics on purpose, so its partial build is expected — the 'incomplete'
    # verdict/label (meant for a straight build that stalled) must not apply to it.
    $isPlan = ($Scenario -eq 'plan')
    $buildResult = if ($res.timedOut) { 'timed-out' } elseif (-not $built.ok) { 'did-not-build' } elseif (-not $complete -and -not $isPlan) { 'incomplete' } elseif ($conformed) { 'passed' } else { 'non-conforming' }
    # 'incomplete' is distinct from 'pass' and 'recorded-fail': what the run DID build may be
    # clean, but the app isn't finished — surfaced plainly instead of hidden under a green score.
    $verdict = if ($conformed) { 'pass' }
        elseif (-not $complete -and -not $isPlan -and $built.ok -and -not $res.timedOut -and @($lintMissed).Count -eq 0) { 'incomplete' }
        else { 'recorded-fail' }
    # Pass-rate: 1.0 only for a complete, conforming build; the honest epics-built/planned fraction
    # for an incomplete run (so 1-of-7 reads as 14%, not 100%); 0.0 for other failures.
    $passRate = if ($conformed) { 1.0 } elseif ($verdict -eq 'incomplete') { $completeness } else { 0.0 }
    $buildReason = if ($res.timedOut) { 'timed out' }
        elseif (-not $built.ok) { $built.detail }
        elseif ($isPlan -and $conformed) { 'planned and parked epic(s) cleanly, all /plan checks passed' }
        elseif ($isPlan) { 'plan checks missed: ' + (@($planMissed) -join ', ') }
        elseif (-not $complete) { "incomplete — built $epicsBuilt of $epicsPlanned planned epics before the run ended" }
        elseif ($conformed) { 'built and passed all rules' }
        else { 'built, but missed: ' + ($lintMissed -join ', ') }

    return @{
        version = $Version; timestamp = $RunId; model = $res.model; benchmark = $Benchmark
        runBy = $env:USERNAME; machine = $env:COMPUTERNAME
        result = 'pass'   # the Tier 3 score never fails the run
        groups = @()
        tools = @(Get-Tier3Tools)
        timing = @{
            activeSeconds = [Math]::Round($combined.activeSeconds, 4); excludedSeconds = [Math]::Round($combined.excludedSeconds, 4)
            claudeSeconds = [Math]::Round($combined.claudeSeconds, 2); phases = $phaseTiming
        }
        memory = $memSummary
        epicsCreated = $epicStats.epicsCreated
        epicsBuilt = $epicStats.epicsBuilt
        storiesCreated = $epicStats.storiesCreated
        epics = $epicStats.epics
        tier3 = @{
            ran = $true; verdict = $verdict
            scenario = $Scenario
            passRate = $passRate
            epicsPlanned = $epicsPlanned
            epicsBuilt = $epicsBuilt
            complete = $complete
            conformanceScored = $conf.ran
            tokensTotal = $combined.tokens
            segments = $combined.segments
            builds = @(@{ attempt = 1; result = $buildResult; compiled = $built.ok; tokens = $combined.tokens; turns = $combined.turns; reason = $buildReason })
            rulesMissed = @($rulesMissed)
        }
        _scaffold = $WorkingDir
    }
}

# ---- PLAN-B live orchestration (validated only in a real run) --------------------------------

# The per-session state hashtable Read-ClaudeEvent updates (same shape as Invoke-ClaudeHeadless).
function New-Tier3ClaudeState {
    param([string]$Model)
    return @{ turns = 0; sessionId = $null; model = $Model; sawResult = $false; isError = $false; durationMs = 0.0; costUsd = 0.0; tokens = 0; partialTokens = 0; lastType = $null; prevGate = 'spec' }
}

# Launch one headless claude (non-blocking): prompt via stdin file, stream redirected to $OutFile
# (the only reliable capture on Windows). Returns a tracking hashtable for the poll loop.
function Start-Tier3ClaudeProc {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Prompt, [Parameter(Mandatory)][string]$WorkingDir, [string]$Model, [Parameter(Mandatory)][string]$OutFile)
    $promptFile = "$OutFile.prompt.txt"; $errFile = "$OutFile.err"
    Set-Content -Path $promptFile -Value $Prompt -Encoding utf8 -NoNewline
    $inner = 'claude -p --output-format stream-json --verbose --dangerously-skip-permissions'
    if ($Model) { $inner += " --model `"$Model`"" }
    $inner += " < `"$promptFile`" > `"$OutFile`" 2> `"$errFile`""
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/s /c `"$inner`"" -WorkingDirectory $WorkingDir -NoNewWindow -PassThru
    return @{ proc = $p; outFile = $OutFile; promptFile = $promptFile; pos = 0L; state = (New-Tier3ClaudeState -Model $Model); startUtc = $null; endUtc = $null; timedOut = $false }
}

# Run the builder and planner headless sessions AT THE SAME TIME, tailing both in one poll loop
# and stamping each session's wall-clock window so their overlap can be measured. Returns each
# session's totals plus overlapSeconds. (Uses the same background-wait ceiling as the single
# launcher so awaited sub-agents finish rather than being killed at 600s.)
function Invoke-Tier3ConcurrentClaude {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Builder,   # @{ prompt; workingDir; outFile }
        [Parameter(Mandatory)][hashtable]$Planner,
        [string]$Model,
        [int]$TimeoutSeconds = 86400,
        [hashtable]$MemoryPeak,
        [int]$HeartbeatMs = 1000
    )
    $env:CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS = '0'
    $sessions = [ordered]@{
        builder = (Start-Tier3ClaudeProc -Prompt $Builder.prompt -WorkingDir $Builder.workingDir -Model $Model -OutFile $Builder.outFile)
        planner = (Start-Tier3ClaudeProc -Prompt $Planner.prompt -WorkingDir $Planner.workingDir -Model $Model -OutFile $Planner.outFile)
    }
    foreach ($k in @($sessions.Keys)) { $sessions[$k].startUtc = (Get-Date).ToUniversalTime() }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        Start-Sleep -Milliseconds $HeartbeatMs
        if ($MemoryPeak) { Update-MemoryPeak -Tracker $MemoryPeak }
        $allExited = $true
        foreach ($k in @($sessions.Keys)) {
            $s = $sessions[$k]
            if (Test-Path $s.outFile) {
                try {
                    $fs = [System.IO.File]::Open($s.outFile, 'Open', 'Read', 'ReadWrite,Delete')
                    $fs.Seek($s.pos, 'Begin') | Out-Null
                    $sr = New-Object System.IO.StreamReader($fs)
                    $chunk = $sr.ReadToEnd(); $s.pos = $fs.Position
                    $sr.Dispose(); $fs.Dispose()
                    if ($chunk) { foreach ($line in ($chunk -split "`n")) { if (-not [string]::IsNullOrWhiteSpace($line)) { Read-ClaudeEvent -Line $line -State $s.state -OnTurn $null } } }
                }
                catch { }
            }
            if ($s.proc.HasExited) { if (-not $s.endUtc) { $s.endUtc = (Get-Date).ToUniversalTime() } }
            else { $allExited = $false }
        }
        if ($allExited) { break }
        if ($sw.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
            foreach ($k in @($sessions.Keys)) { if (-not $sessions[$k].proc.HasExited) { Stop-ProcessTree -ProcessId $sessions[$k].proc.Id; $sessions[$k].timedOut = $true } }
            break
        }
    }

    $out = @{}
    foreach ($k in @($sessions.Keys)) {
        $s = $sessions[$k]
        if (-not $s.endUtc) { $s.endUtc = (Get-Date).ToUniversalTime() }
        try { if (Test-Path $s.promptFile) { Remove-Item $s.promptFile -Force } } catch { }
        $out[$k] = @{
            turns = $s.state.turns
            tokens = if ($s.state.sawResult) { $s.state.tokens } else { $s.state.partialTokens }
            sessionId = $s.state.sessionId
            claudeSeconds = if ($s.state.durationMs -gt 0) { $s.state.durationMs / 1000.0 } else { 0.0 }
            startUtc = $s.startUtc; endUtc = $s.endUtc
            timedOut = [bool]$s.timedOut; sawResult = $s.state.sawResult
        }
    }
    $b = $out.builder; $p = $out.planner
    $overlapStart = if ($b.startUtc -gt $p.startUtc) { $b.startUtc } else { $p.startUtc }
    $overlapEnd = if ($b.endUtc -lt $p.endUtc) { $b.endUtc } else { $p.endUtc }
    $overlap = [Math]::Max(0.0, ($overlapEnd - $overlapStart).TotalSeconds)
    return @{ builder = $b; planner = $p; overlapSeconds = $overlap }
}

# Pure + testable: from the epics on main after bootstrap vs after the concurrent phase, work out
# which epic the BUILDER built (newly complete) and which the PLANNER parked (newly ready-to-build).
# $Before/$After are @( @{ slug; phase } ). Returns @{ builtEpicSlug; plannedEpicSlug }.
function Resolve-Tier3ConcurrentSlugs {
    [CmdletBinding()]
    param([array]$Before, [array]$After)
    $beforePhase = @{}
    foreach ($e in @($Before)) { $beforePhase[[string]$e.slug] = [string]$e.phase }
    $built = $null; $planned = $null
    foreach ($e in @($After)) {
        $slug = [string]$e.slug; $phase = [string]$e.phase
        $was = if ($beforePhase.ContainsKey($slug)) { $beforePhase[$slug] } else { $null }
        if ($phase -eq 'READY-TO-BUILD' -and $was -ne 'READY-TO-BUILD' -and -not $planned) { $planned = $slug }
        if ($phase -in @('COMPLETE', 'COMPLETE-ON-BRANCH', 'MANUAL-TEST', 'EPIC-END') -and $was -notin @('COMPLETE', 'COMPLETE-ON-BRANCH', 'MANUAL-TEST', 'EPIC-END') -and -not $built) { $built = $slug }
    }
    return @{ builtEpicSlug = $built; plannedEpicSlug = $planned }
}

# Read @( @{ slug; phase } ) for every epic on a given git ref, from a working tree. Best-effort.
function Get-Tier3EpicPhasesOnRef {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$WorkingDir, [string]$Ref = 'origin/main')
    $out = [System.Collections.Generic.List[hashtable]]::new()
    try {
        $files = @(& git -C $WorkingDir ls-tree -r --name-only $Ref 2>$null | Where-Object { $_ -match '^generated-docs/epics/[^/]+/state\.json$' })
        foreach ($f in $files) {
            $slug = ($f -split '/')[2]
            $raw = ((& git -C $WorkingDir show "${Ref}:$f" 2>$null) -join "`n")
            $phase = $null; if ($raw) { try { $phase = [string](($raw | ConvertFrom-Json).phase) } catch { } }
            $out.Add(@{ slug = $slug; phase = $phase })
        }
    }
    catch { }
    return @($out)
}

# The PLAN-B live run: bare remote -> bootstrap (build epic 1) -> build epic 2 || plan epic 3 ->
# score concurrency from git (record-only). Best-effort; produces the standard run-result shape so
# the report/history/charts render it. Validated end to end only in a real run.
function Invoke-Tier3ConcurrentRun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$Benchmark,
        [Parameter(Mandatory)][string]$WorkingDir,
        [Parameter(Mandatory)][string]$TemplateRoot,
        [Parameter(Mandatory)][string]$BenchmarkDir,
        [Parameter(Mandatory)][string]$LiveDir,
        [Parameter(Mandatory)][string]$RunId,
        [string]$Version = '0.1.0',
        [int]$TimeoutSeconds = 86400
    )
    if (-not (Test-Path $LiveDir)) { New-Item -ItemType Directory -Path $LiveDir -Force | Out-Null }
    New-Tier3Scaffold -TemplateRoot $TemplateRoot -WorkingDir $WorkingDir -BenchmarkDir $BenchmarkDir | Out-Null

    # Warm the browser cache once, before any timing starts (same rationale as the single run).
    Install-Tier3Browser -LogPath (Join-Path $LiveDir 'playwright-install.log') -TemplateRoot $TemplateRoot | Out-Null

    # Stand up the shared remote the concurrency model needs.
    $remoteDir = Join-Path $LiveDir 'origin.git'
    $remote = New-Tier3BareRemote -WorkingDir $WorkingDir -RemoteDir $remoteDir

    $mem = New-MemoryPeak
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    # 1) Bootstrap: build epic 1 through merge so both concurrent sessions branch from a stable main.
    $bootRes = Invoke-ClaudeHeadless -Prompt (Get-Tier3ConcurrentBootstrapPrompt) -WorkingDir $WorkingDir -Model $Model `
        -TimeoutSeconds $TimeoutSeconds -OutFile (Join-Path $LiveDir "$RunId-bootstrap.jsonl") -MemoryPeak $mem `
        -SessionIdFile (Join-Path $LiveDir 'session.id')
    $beforeEpics = Get-Tier3EpicPhasesOnRef -WorkingDir $WorkingDir -Ref 'origin/main'

    # 2) Planner gets its own clone of the remote; then build epic 2 || plan epic 3, together.
    $plannerDir = "$WorkingDir-planner"
    $cloneOk = New-Tier3PlannerClone -RemoteDir $remoteDir -PlannerDir $plannerDir
    $conc = Invoke-Tier3ConcurrentClaude `
        -Builder @{ prompt = (Get-Tier3ConcurrentBuilderPrompt); workingDir = $WorkingDir; outFile = (Join-Path $LiveDir "$RunId-builder.jsonl") } `
        -Planner @{ prompt = (Get-Tier3ConcurrentPlannerPrompt); workingDir = $plannerDir;  outFile = (Join-Path $LiveDir "$RunId-planner.jsonl") } `
        -Model $Model -TimeoutSeconds $TimeoutSeconds -MemoryPeak $mem
    $sw.Stop()

    # 3) Work out which epic each session touched, then score concurrency from git (record-only).
    $afterEpics = Get-Tier3EpicPhasesOnRef -WorkingDir $WorkingDir -Ref 'origin/main'
    $slugs = Resolve-Tier3ConcurrentSlugs -Before $beforeEpics -After $afterEpics
    $facts = Get-Tier3ConcurrentFacts -RemoteDir $remoteDir -BuilderDir $WorkingDir `
        -BuiltEpicSlug $slugs.builtEpicSlug -PlannedEpicSlug $slugs.plannedEpicSlug -OverlapSeconds $conc.overlapSeconds
    $concurrentMissed = @(Get-Tier3ConcurrentRulesMissed -Facts $facts)

    $built = Test-Tier3Build -WorkingDir $WorkingDir -MemoryPeak $mem
    $epicStats = Get-Tier3EpicStats -Scaffold $WorkingDir

    $rulesMissed = @()
    if (-not $remote.ok) { $rulesMissed += 'no-shared-remote' }
    if (-not $built.ok)  { $rulesMissed += 'did-not-build' }
    $rulesMissed += $concurrentMissed
    $rulesMissed = @($rulesMissed | Select-Object -Unique)

    $anyTimedOut = ($bootRes.timedOut -or $conc.builder.timedOut -or $conc.planner.timedOut)
    $conformed = ($built.ok -and -not $anyTimedOut -and $remote.ok -and $rulesMissed.Count -eq 0)
    $verdict = if ($conformed) { 'pass' } else { 'recorded-fail' }
    $tokensTotal = [long]$bootRes.tokens + [long]$conc.builder.tokens + [long]$conc.planner.tokens
    $turnsTotal  = [int]$bootRes.turns + [int]$conc.builder.turns + [int]$conc.planner.turns
    $claudeSecs  = [double]$bootRes.claudeSeconds + [double]$conc.builder.claudeSeconds + [double]$conc.planner.claudeSeconds
    $buildReason = if ($conformed) { 'built epic while planning the next, concurrently, with main consistent' }
        elseif (-not $remote.ok) { 'could not stand up the shared remote' }
        elseif (-not $built.ok) { $built.detail }
        else { 'concurrency checks missed: ' + (@($concurrentMissed) -join ', ') }

    $memSummary = Get-MemorySummaryFromProgress -P @{
        memPeakUsedMB = [int]$mem.peakUsedMB; memBaselineUsedMB = [int]$mem.baselineUsedMB
        memMinAvailableMB = [int]$mem.minAvailableMB; memTotalMB = [int]$mem.totalMB
    }

    return @{
        version = $Version; timestamp = $RunId; model = $Model; benchmark = $Benchmark
        runBy = $env:USERNAME; machine = $env:COMPUTERNAME
        result = 'pass'   # the Tier 3 score never fails the run
        groups = @()
        tools = @(Get-Tier3Tools)
        timing = @{ activeSeconds = [Math]::Round($sw.Elapsed.TotalSeconds, 2); excludedSeconds = 0.0; claudeSeconds = [Math]::Round($claudeSecs, 2); phases = @() }
        memory = $memSummary
        epicsCreated = $epicStats.epicsCreated
        epicsBuilt = $epicStats.epicsBuilt
        storiesCreated = $epicStats.storiesCreated
        epics = $epicStats.epics
        tier3 = @{
            ran = $true; verdict = $verdict
            scenario = 'concurrent'
            passRate = if ($conformed) { 1.0 } else { 0.0 }
            overlapSeconds = [Math]::Round([double]$conc.overlapSeconds, 1)
            builtEpicSlug = $slugs.builtEpicSlug
            plannedEpicSlug = $slugs.plannedEpicSlug
            tokensTotal = $tokensTotal
            builds = @(@{ attempt = 1; result = (if ($conformed) { 'passed' } else { 'recorded-fail' }); compiled = $built.ok; tokens = $tokensTotal; turns = $turnsTotal; reason = $buildReason })
            rulesMissed = @($rulesMissed)
        }
        _scaffold = $WorkingDir
        _plannerScaffold = $plannerDir
        _remote = $remoteDir
    }
}
