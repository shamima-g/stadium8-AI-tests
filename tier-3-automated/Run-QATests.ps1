<#
.SYNOPSIS
  Run-QATests.ps1 — the master runner: setup -> tiers -> teardown.

.DESCRIPTION
  Wires the whole automated Tier 3 together. Order: setup (install prerequisites) ->
  run the tier(s) -> write the report + history + charts -> teardown.

  Two ways to produce a run's results:
    * Live (Part 2, not yet wired): drive the Claude command-line tool against the chosen
      benchmark. Marked TODO below.
    * Replay (-ReplayResult <json>): feed a saved run-result to exercise the whole
      reporting/history/charts pipeline WITHOUT a live AI. This is how Part 1 is proven.

  Everything is kept separated per benchmark:
    TestResults/<benchmark>/<model>/<timestamp>/   report, Fail/, setup.log
    TestResults/<benchmark>/tier3-history.jsonl    the growing history
    TestResults/<benchmark>/tier3-metrics.html     the charts page

.EXAMPLE
  ./Run-QATests.ps1 -IncludeTier3 -Tier3Model sonnet -Benchmark transactions
  ./Run-QATests.ps1 -ReplayResult sample-run.json -Benchmark transactions   # no AI
#>

[CmdletBinding()]
param(
    [switch]$IncludeTier3,
    [string]$Tier3Model = 'opus',
    [string]$Benchmark = 'transactions',
    [switch]$KeepDeps,
    [switch]$NoTeardown,
    [switch]$Cleanup,
    [switch]$SkipSetup,
    [switch]$SkipLowerTiers,
    [switch]$Resume,
    [string]$ReplayResult,
    [string]$Timestamp,
    [string]$TestResultsRoot,
    [string]$BuildRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Setup.ps1')
. (Join-Path $PSScriptRoot 'Teardown.ps1')
. (Join-Path $PSScriptRoot 'Generate-Report.ps1')
. (Join-Path $PSScriptRoot 'Generate-Tier3-Html.ps1')
. (Join-Path $PSScriptRoot 'history.ps1')
. (Join-Path $PSScriptRoot 'live-driver.ps1')

# Deep-convert a JSON object (PSCustomObject/array) into nested hashtables/arrays so the
# report writer's .ContainsKey() calls work.
function ConvertTo-HashtableDeep {
    param($InputObject)
    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Collections.IDictionary]) {
        $h = @{}; foreach ($k in $InputObject.Keys) { $h[$k] = ConvertTo-HashtableDeep $InputObject[$k] }; return $h
    }
    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $h = @{}; foreach ($p in $InputObject.PSObject.Properties) { $h[$p.Name] = ConvertTo-HashtableDeep $p.Value }; return $h
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { ConvertTo-HashtableDeep $_ })
    }
    return $InputObject
}

function New-HistoryRecordFromRun {
    param([hashtable]$Run)
    $rec = @{
        timestamp = $Run.timestamp; version = $Run.version; model = $Run.model
        benchmark = $Run.benchmark; result = $Run.result
    }
    if ($Run.ContainsKey('timing') -and $Run.timing) {
        $rec.activeSeconds   = $Run.timing.activeSeconds
        $rec.claudeSeconds   = $Run.timing.claudeSeconds
        $rec.excludedSeconds = $Run.timing.excludedSeconds
        if ($Run.timing.ContainsKey('phases')) { $rec.phases = $Run.timing.phases }
    }
    if ($Run.ContainsKey('tier3') -and $Run.tier3) {
        if ($Run.tier3.ContainsKey('tokensTotal')) { $rec.tokensTotal = $Run.tier3.tokensTotal }
        if ($Run.tier3.ContainsKey('passRate'))    { $rec.passRate    = $Run.tier3.passRate }
        if ($Run.tier3.ContainsKey('rulesMissed')) { $rec.rulesMissed = $Run.tier3.rulesMissed }
        if ($Run.tier3.ContainsKey('verdict'))     { $rec.verdict     = $Run.tier3.verdict }
    }
    if ($Run.ContainsKey('memory') -and $Run.memory -and $Run.memory.available) {
        $rec.peakMemoryUsedMB = $Run.memory.peakUsedMB
        $rec.totalMemoryMB    = $Run.memory.totalMB
        $rec.memoryFits16GB   = $Run.memory.fitsBudget
    }
    return $rec
}

# Find the newest run folder for this benchmark+model that STARTED (has a saved session id)
# but never FINISHED (no report) — the one a -Resume should continue. Returns its timestamp
# (folder name), or $null when there's nothing to resume.
function Find-IncompleteRun {
    param([string]$TestResultsRoot, [string]$Benchmark, [string]$Model)
    $modelDir = Join-Path (Join-Path $TestResultsRoot $Benchmark) $Model
    if (-not (Test-Path $modelDir)) { return $null }
    foreach ($c in (Get-ChildItem -Path $modelDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
        $hasSession = Test-Path (Join-Path $c.FullName 'tier3-live\session.id')
        $hasReport = @(Get-ChildItem -Path $c.FullName -Filter 'report-*.md' -ErrorAction SilentlyContinue).Count -gt 0
        if ($hasSession -and -not $hasReport) { return $c.Name }
    }
    return $null
}

function Invoke-RunQATests {
    param(
        [bool]$IncludeTier3, [string]$Tier3Model, [string]$Benchmark,
        [bool]$KeepDeps, [bool]$NoTeardown, [bool]$Cleanup, [bool]$SkipSetup,
        [bool]$SkipLowerTiers, [bool]$Resume, [string]$ReplayResult, [string]$Timestamp, [string]$TestResultsRoot, [string]$BuildRoot
    )
    if (-not $TestResultsRoot) { $TestResultsRoot = (Join-Path $PSScriptRoot '..' 'TestResults') }
    # The built app is a throwaway working copy — keep it OUT of the test suite, under a temp root.
    if (-not $BuildRoot) { $BuildRoot = 'C:\temp\tier3-builds' }

    # Resume: continue an interrupted run rather than starting a fresh one.
    $resumeSessionId = $null
    if ($Resume) {
        if (-not $Timestamp) {
            $Timestamp = Find-IncompleteRun -TestResultsRoot $TestResultsRoot -Benchmark $Benchmark -Model $Tier3Model
            if (-not $Timestamp) { throw "Nothing to resume: no started-but-unfinished run for $Benchmark/$Tier3Model under $TestResultsRoot." }
        }
    }
    if (-not $Timestamp) { $Timestamp = (Get-Date -Format 'yyyyMMdd-HHmm') }

    $benchResults = Join-Path $TestResultsRoot $Benchmark
    $runFolder    = Join-Path (Join-Path $benchResults $Tier3Model) $Timestamp
    $historyPath  = Join-Path $benchResults 'tier3-history.jsonl'
    $htmlPath     = Join-Path $benchResults 'tier3-metrics.html'
    $buildsDir    = Join-Path (Join-Path (Join-Path $BuildRoot $Benchmark) $Tier3Model) $Timestamp
    New-Item -ItemType Directory -Path $runFolder -Force | Out-Null

    if ($Resume) {
        $sf = Join-Path $runFolder 'tier3-live\session.id'
        if (-not (Test-Path $sf)) { throw "Cannot resume run $Timestamp — no session id at $sf (it may not have started, or already finished)." }
        $resumeSessionId = (Get-Content $sf -Raw).Trim()
    }

    # 1) setup
    if (-not $SkipSetup) {
        $setup = Invoke-Tier3Setup -IncludeTier3 $IncludeTier3 -LogPath (Join-Path $runFolder 'setup.log')
        if (-not $setup.ok -and $IncludeTier3) {
            throw "Setup can't continue — missing: $($setup.blocking -join ', '). See $($runFolder)\setup.log."
        }
    }

    # 2) obtain the run result (live = Part 2, or replay)
    if ($ReplayResult) {
        $run = ConvertTo-HashtableDeep (Get-Content $ReplayResult -Raw | ConvertFrom-Json)
    }
    elseif ($IncludeTier3 -or $Resume) {
        $templateRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path        # the Stadium 8 template (repo root)
        $benchmarkDir = (Join-Path (Join-Path $PSScriptRoot '..' 'benchmark-files') $Benchmark)
        if (-not (Test-Path $benchmarkDir)) { throw "Benchmark '$Benchmark' not found at $benchmarkDir." }
        $liveArgs = @{
            Model = $Tier3Model; Benchmark = $Benchmark; WorkingDir = $buildsDir
            TemplateRoot = $templateRoot; BenchmarkDir = $benchmarkDir
            LiveDir = (Join-Path $runFolder 'tier3-live'); RunId = $Timestamp; Version = '0.1.0'
        }
        if ($resumeSessionId) { $liveArgs.ResumeSessionId = $resumeSessionId }
        $run = Invoke-Tier3LiveRun @liveArgs
    }
    else {
        throw 'Nothing to run: pass -IncludeTier3 (live) or -ReplayResult <json> (replay).'
    }

    # keep model/benchmark/timestamp authoritative from the invocation
    $run.model = $Tier3Model; $run.benchmark = $Benchmark; $run.timestamp = $Timestamp

    # 2b) run the cheap tiers (Tier 1 + Tier 2) so one report covers the whole suite.
    if (-not $SkipLowerTiers -and -not $ReplayResult) {
        $qaRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $lower = Get-Tier3LowerTierGroups -QaRoot $qaRoot
        if (@($lower).Count -gt 0) { $run.groups = @($lower) }
    }

    # 3) report + history + charts
    $reportPath = New-Tier3Report -Run $run -OutDir $runFolder -HistoryPath $historyPath
    Add-Tier3HistoryLine -HistoryPath $historyPath -Record (New-HistoryRecordFromRun -Run $run)
    $null = New-Tier3Html -HistoryPath $historyPath -OutPath $htmlPath -Benchmark $Benchmark
    $null = Update-Tier3Index -TestResultsRoot $TestResultsRoot   # rebuild the top-level master list

    # 4) zip the built app into the run folder (best-effort) BEFORE teardown strips
    #    node_modules/.next, so a snapshot survives even after cleanup.
    $zipPath = $null
    $scaffold = if ($run.ContainsKey('_scaffold')) { $run._scaffold } else { $buildsDir }
    if ($scaffold -and (Test-Path $scaffold)) {
        $zipPath = Join-Path $runFolder ("$Tier3Model-$Timestamp.zip")
        $zipRes = Compress-Tier3App -SourceDir $scaffold -DestZip $zipPath
        if (-not $zipRes.ok) { $zipPath = $null }   # best-effort — never fail the run
    }

    # 5) teardown (best-effort; always after the report + zip are written)
    if (-not $NoTeardown -and (Test-Path $buildsDir)) {
        Invoke-Tier3Teardown -WorkingDir $buildsDir -KeepDeps:$KeepDeps -Full:$Cleanup | Out-Null
    }

    return @{ runFolder = $runFolder; report = $reportPath; history = $historyPath; html = $htmlPath; zip = $zipPath }
}

# Run unless dot-sourced (dot-sourcing exposes the functions for unit tests).
if ($MyInvocation.InvocationName -ne '.') {
    $summary = Invoke-RunQATests -IncludeTier3:$IncludeTier3.IsPresent -Tier3Model $Tier3Model -Benchmark $Benchmark `
        -KeepDeps:$KeepDeps.IsPresent -NoTeardown:$NoTeardown.IsPresent -Cleanup:$Cleanup.IsPresent `
        -SkipSetup:$SkipSetup.IsPresent -SkipLowerTiers:$SkipLowerTiers.IsPresent -Resume:$Resume.IsPresent -ReplayResult $ReplayResult -Timestamp $Timestamp -TestResultsRoot $TestResultsRoot -BuildRoot $BuildRoot
    Write-Host "Report:  $($summary.report)"
    Write-Host "History: $($summary.history)"
    Write-Host "Charts:  $($summary.html)"
    if ($summary.zip) { Write-Host "App zip: $($summary.zip)" }
}
