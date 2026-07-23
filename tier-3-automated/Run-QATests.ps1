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
    [string]$Target,
    [string]$Ref,
    [switch]$KeepDeps,
    [switch]$KeepRawLogs,
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
    if ($Run.ContainsKey('templateTarget') -and $Run.templateTarget) { $rec.templateTarget = $Run.templateTarget }
    if ($Run.ContainsKey('epicsCreated'))   { $rec.epicsCreated   = $Run.epicsCreated }
    if ($Run.ContainsKey('epicsBuilt'))     { $rec.epicsBuilt     = $Run.epicsBuilt }
    if ($Run.ContainsKey('storiesCreated')) { $rec.storiesCreated = $Run.storiesCreated }
    if ($Run.ContainsKey('epics') -and $Run.epics) { $rec.epics = $Run.epics }
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

# The results/label slug for a target@ref, or $null when building the local template.
# e.g. ('release','v1.1.0') -> 'release-v1.1.0'; ('dev',$null) -> 'dev-default'.
function Get-Tier3TargetLabel {
    param([string]$Target, [string]$Ref)
    if (-not $Target) { return $null }
    $r = if ($Ref) { $Ref } else { 'default' }
    return "$Target-$r"
}

# Resolve the template Tier 3 builds against.
#   * No -Target  → the template the QA suite is nested in (../..). The default, and the
#     original behaviour.
#   * -Target dev|release [-Ref <tag|branch>] → clone that channel (repo URL from
#     targets.json) into .targets/<target>-<ref>/ and build against THAT checkout — the
#     Tier 3 counterpart to `npm run test:target`. -Ref defaults to the repo's default
#     branch. This is what lets one run aim at dev vs release at a specific version.
# $Cloner is injectable ({ param($repo,$ref,$dest) ... }) so tests need no network.
function Resolve-Tier3Template {
    [CmdletBinding()]
    param(
        [string]$Target,
        [string]$Ref,
        [Parameter(Mandatory)][string]$QaRoot,
        [scriptblock]$Cloner
    )
    if (-not $Target) {
        return @{ root = (Resolve-Path (Join-Path $QaRoot '..')).Path; label = $null; ref = $null }
    }
    $targetsFile = Join-Path $QaRoot 'targets.json'
    if (-not (Test-Path $targetsFile)) { throw "No targets.json at $targetsFile — cannot resolve target '$Target'." }
    $targets = (Get-Content $targetsFile -Raw | ConvertFrom-Json).targets
    $known = @($targets.PSObject.Properties.Name)
    if ($known -notcontains $Target) { throw "Unknown target '$Target'. Known targets: $($known -join ', ')." }
    $repo  = $targets.$Target.repo
    $label = Get-Tier3TargetLabel -Target $Target -Ref $Ref
    $dest  = Join-Path (Join-Path $QaRoot '.targets') $label
    if (-not $Cloner) {
        $Cloner = {
            param($repoUrl, $gitRef, $destPath)
            if (Test-Path $destPath) { Remove-Item $destPath -Recurse -Force }
            New-Item -ItemType Directory -Path (Split-Path $destPath -Parent) -Force | Out-Null
            $cloneArgs = @('clone', '--depth', '1')
            if ($gitRef) { $cloneArgs += @('--branch', $gitRef) }
            $cloneArgs += @($repoUrl, $destPath)
            & git @cloneArgs
            if ($LASTEXITCODE -ne 0) {
                if (Test-Path $destPath) { Remove-Item $destPath -Recurse -Force }
                throw "git clone failed for $repoUrl @ $(if ($gitRef) { $gitRef } else { '(default branch)' }) — check the ref exists."
            }
        }
    }
    & $Cloner $repo $Ref $dest
    return @{ root = (Resolve-Path $dest).Path; label = $label; repo = $repo; ref = $Ref }
}

# Gzip the bulky raw Claude stream log(s) in a run's live folder. The raw stream is the
# single biggest artifact (~7 MB) and nothing re-reads it after the run; gzipping drops it
# ~75% and it's still openable with any gzip tool. Best-effort: a hiccup never fails a run.
function Compress-Tier3Logs {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$LiveDir)
    $compressed = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path $LiveDir)) { return @{ ok = $true; compressed = $compressed } }
    Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
    foreach ($f in (Get-ChildItem -Path $LiveDir -Filter '*-claude.jsonl' -File -ErrorAction SilentlyContinue)) {
        try {
            $src = $f.FullName; $dst = "$src.gz"
            $in = [System.IO.File]::OpenRead($src)
            try {
                $out = [System.IO.File]::Create($dst)
                try {
                    $gz = New-Object System.IO.Compression.GZipStream($out, [System.IO.Compression.CompressionLevel]::Optimal)
                    try { $in.CopyTo($gz) } finally { $gz.Dispose() }
                }
                finally { $out.Dispose() }
            }
            finally { $in.Dispose() }
            Remove-Item -LiteralPath $src -Force -ErrorAction Stop
            $compressed.Add($dst)
        }
        catch { <# best-effort per file — leave the raw log if it can't be compressed #> }
    }
    return @{ ok = $true; compressed = $compressed }
}

function Invoke-RunQATests {
    param(
        [bool]$IncludeTier3, [string]$Tier3Model, [string]$Benchmark,
        [string]$Target, [string]$Ref,
        [bool]$KeepDeps, [bool]$KeepRawLogs, [bool]$NoTeardown, [bool]$Cleanup, [bool]$SkipSetup,
        [bool]$SkipLowerTiers, [bool]$Resume, [string]$ReplayResult, [string]$Timestamp, [string]$TestResultsRoot, [string]$BuildRoot
    )
    if (-not $TestResultsRoot) { $TestResultsRoot = (Join-Path $PSScriptRoot '..' 'TestResults') }
    # The built app is a throwaway working copy — keep it OUT of the test suite, under a temp root.
    if (-not $BuildRoot) { $BuildRoot = 'C:\temp\tier3-builds' }

    # When aimed at a target (dev/release @ ref), everything for this run is filed under
    # its own "<benchmark>@<target>-<ref>" world so its history, charts, and estimates
    # never mix with the local-template runs — the same "separated per benchmark" rule,
    # extended to the target. Without -Target this is just "<benchmark>", as before.
    $targetLabel = Get-Tier3TargetLabel -Target $Target -Ref $Ref
    $resultsKey  = if ($targetLabel) { "$Benchmark@$targetLabel" } else { $Benchmark }

    # Resume: continue an interrupted run rather than starting a fresh one.
    $resumeSessionId = $null
    if ($Resume) {
        if (-not $Timestamp) {
            $Timestamp = Find-IncompleteRun -TestResultsRoot $TestResultsRoot -Benchmark $resultsKey -Model $Tier3Model
            if (-not $Timestamp) { throw "Nothing to resume: no started-but-unfinished run for $resultsKey/$Tier3Model under $TestResultsRoot." }
        }
    }
    if (-not $Timestamp) { $Timestamp = (Get-Date -Format 'yyyyMMdd-HHmm') }

    $benchResults = Join-Path $TestResultsRoot $resultsKey
    $runFolder    = Join-Path (Join-Path $benchResults $Tier3Model) $Timestamp
    $historyPath  = Join-Path $benchResults 'tier3-history.jsonl'
    $htmlPath     = Join-Path $benchResults 'tier3-metrics.html'
    $buildsDir    = Join-Path (Join-Path (Join-Path $BuildRoot $resultsKey) $Tier3Model) $Timestamp
    New-Item -ItemType Directory -Path $runFolder -Force | Out-Null

    if ($Resume) {
        $sf = Join-Path $runFolder 'tier3-live\session.id'
        if (-not (Test-Path $sf)) { throw "Cannot resume run $Timestamp — no session id at $sf (it may not have started, or already finished)." }
        $resumeSessionId = (Get-Content $sf -Raw).Trim()
    }

    # 1) setup — every prerequisite is mandatory. If setup couldn't make the machine fully
    #    ready (anything missing, failed to install, or failed to verify), the tests do NOT
    #    run: abort here with the exact list so nothing starts on a half-ready machine.
    if (-not $SkipSetup) {
        $setup = Invoke-Tier3Setup -IncludeTier3 $IncludeTier3 -LogPath (Join-Path $runFolder 'setup.log')
        if (-not $setup.ok) {
            throw "Setup can't continue — these prerequisites are missing or not working: $($setup.blocking -join ', '). Tests will not run until every prerequisite is present. See $($runFolder)\setup.log."
        }
    }

    # 2) obtain the run result (live = Part 2, or replay)
    if ($ReplayResult) {
        $run = ConvertTo-HashtableDeep (Get-Content $ReplayResult -Raw | ConvertFrom-Json)
    }
    elseif ($IncludeTier3 -or $Resume) {
        # Default: build against the template the suite is nested in. With -Target, clone
        # that channel@ref and build against it instead (see Resolve-Tier3Template).
        $qaRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $tmpl = Resolve-Tier3Template -Target $Target -Ref $Ref -QaRoot $qaRoot
        $templateRoot = $tmpl.root
        $versionLabel = if ($Target) { if ($Ref) { $Ref } else { 'default' } } else { '0.1.0' }
        $benchmarkDir = (Join-Path (Join-Path $PSScriptRoot '..' 'benchmark-files') $Benchmark)
        if (-not (Test-Path $benchmarkDir)) { throw "Benchmark '$Benchmark' not found at $benchmarkDir." }
        $liveArgs = @{
            Model = $Tier3Model; Benchmark = $Benchmark; WorkingDir = $buildsDir
            TemplateRoot = $templateRoot; BenchmarkDir = $benchmarkDir
            LiveDir = (Join-Path $runFolder 'tier3-live'); RunId = $Timestamp; Version = $versionLabel
        }
        if ($resumeSessionId) { $liveArgs.ResumeSessionId = $resumeSessionId }
        $run = Invoke-Tier3LiveRun @liveArgs
    }
    else {
        throw 'Nothing to run: pass -IncludeTier3 (live) or -ReplayResult <json> (replay).'
    }

    # keep model/benchmark/timestamp authoritative from the invocation
    $run.model = $Tier3Model; $run.benchmark = $Benchmark; $run.timestamp = $Timestamp
    if ($targetLabel) { $run.templateTarget = $targetLabel }   # which template channel@ref this run built against

    # 2b) run the cheap tiers (Tier 1 + Tier 2) so one report covers the whole suite.
    if (-not $SkipLowerTiers -and -not $ReplayResult) {
        $qaRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
        $lower = Get-Tier3LowerTierGroups -QaRoot $qaRoot
        if (@($lower).Count -gt 0) { $run.groups = @($lower) }
    }

    # 3) report + history + charts
    $reportPath = New-Tier3Report -Run $run -OutDir $runFolder -HistoryPath $historyPath
    Add-Tier3HistoryLine -HistoryPath $historyPath -Record (New-HistoryRecordFromRun -Run $run)
    $null = New-Tier3Html -HistoryPath $historyPath -OutPath $htmlPath -Benchmark $resultsKey
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

    # 4b) shrink the bulky raw Claude stream log (~75% smaller) unless asked to keep it raw.
    if (-not $KeepRawLogs) { $null = Compress-Tier3Logs -LiveDir (Join-Path $runFolder 'tier3-live') }

    # 5) teardown (best-effort; always after the report + zip are written)
    if (-not $NoTeardown -and (Test-Path $buildsDir)) {
        Invoke-Tier3Teardown -WorkingDir $buildsDir -KeepDeps:$KeepDeps -Full:$Cleanup | Out-Null
    }

    return @{ runFolder = $runFolder; report = $reportPath; history = $historyPath; html = $htmlPath; zip = $zipPath }
}

# Run unless dot-sourced (dot-sourcing exposes the functions for unit tests).
if ($MyInvocation.InvocationName -ne '.') {
    $summary = Invoke-RunQATests -IncludeTier3:$IncludeTier3.IsPresent -Tier3Model $Tier3Model -Benchmark $Benchmark `
        -Target $Target -Ref $Ref `
        -KeepDeps:$KeepDeps.IsPresent -KeepRawLogs:$KeepRawLogs.IsPresent -NoTeardown:$NoTeardown.IsPresent -Cleanup:$Cleanup.IsPresent `
        -SkipSetup:$SkipSetup.IsPresent -SkipLowerTiers:$SkipLowerTiers.IsPresent -Resume:$Resume.IsPresent -ReplayResult $ReplayResult -Timestamp $Timestamp -TestResultsRoot $TestResultsRoot -BuildRoot $BuildRoot
    Write-Host "Report:  $($summary.report)"
    Write-Host "History: $($summary.history)"
    Write-Host "Charts:  $($summary.html)"
    if ($summary.zip) { Write-Host "App zip: $($summary.zip)" }
}
