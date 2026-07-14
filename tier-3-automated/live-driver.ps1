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
            $State.sawResult = $true
            $State.isError = [bool](Get-JsonProp $evt 'is_error' $false)
            $d = Get-JsonProp $evt 'duration_ms'; if ($null -ne $d) { $State.durationMs = [double]$d }
            $c = Get-JsonProp $evt 'total_cost_usd'; if ($null -ne $c) { $State.costUsd = [double]$c }
            $rs = Get-JsonProp $evt 'session_id'; if ($rs) { $State.sessionId = $rs }
            $u = Get-JsonProp $evt 'usage'
            if ($u) {
                $sum = 0
                foreach ($k in @('input_tokens', 'output_tokens', 'cache_creation_input_tokens', 'cache_read_input_tokens')) { $sum += [int](Get-JsonProp $u $k 0) }
                $State.tokens = $sum
            }
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

# ---- the live run: scaffold -> prompt -> headless claude -> checks -> run-result -------------

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
        [string]$ResumeSessionId
    )
    $resuming = [bool]$ResumeSessionId
    if ($resuming) {
        # Resume an interrupted run: reuse the existing scaffold, continue the same session.
        $prompt = Get-Tier3ResumePrompt
    }
    else {
        New-Tier3Scaffold -TemplateRoot $TemplateRoot -WorkingDir $WorkingDir -BenchmarkDir $BenchmarkDir | Out-Null
        $prompt = Get-Tier3Prompt
    }

    if (-not (Test-Path $LiveDir)) { New-Item -ItemType Directory -Path $LiveDir -Force | Out-Null }
    $sessionIdFile = Join-Path $LiveDir 'session.id'
    $progressPath = Join-Path $LiveDir 'progress.json'
    # Prior segments' cumulative totals (present only when resuming an earlier segment).
    $prior = if ($resuming) { Read-Tier3Progress -Path $progressPath } else { New-Tier3ProgressZero }

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

    # Fold build + lint into the verdict. Conforming = built AND no rules missed AND not timed out.
    $rulesMissed = @()
    if (-not $built.ok) { $rulesMissed += 'did-not-build' }
    $rulesMissed += $lintMissed
    $conformed = ($built.ok -and -not $res.timedOut -and $rulesMissed.Count -eq 0)
    $buildResult = if ($res.timedOut) { 'timed-out' } elseif (-not $built.ok) { 'did-not-build' } elseif ($conformed) { 'passed' } else { 'non-conforming' }
    $verdict = if ($conformed) { 'pass' } else { 'recorded-fail' }

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
        tier3 = @{
            ran = $true; verdict = $verdict
            passRate = if ($conformed) { 1.0 } else { 0.0 }
            conformanceScored = $conf.ran
            tokensTotal = $combined.tokens
            segments = $combined.segments
            builds = @(@{ attempt = 1; result = $buildResult; compiled = $built.ok; tokens = $combined.tokens; turns = $combined.turns; reason = $(if ($res.timedOut) { 'timed out' } elseif (-not $built.ok) { $built.detail } elseif ($conformed) { 'built and passed all rules' } else { 'built, but missed: ' + ($lintMissed -join ', ') }) })
            rulesMissed = @($rulesMissed)
        }
        _scaffold = $WorkingDir
    }
}
