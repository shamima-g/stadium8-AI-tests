<#
.SYNOPSIS
  Run-Experiment.ps1 — the "/plan vs no /plan" experiment: run each arm N times, then
  aggregate tokens, time, and PEAK MEMORY into one saved comparison report.

.DESCRIPTION
  A measurement study, not a test (see ../README.md). It drives the existing Tier 3 harness
  (tier-3-automated/Run-QATests.ps1) once per (arm × run), reads the per-scenario history the
  harness already records, and writes a median+spread comparison — the cost axis (tokens),
  the speed axis (Claude time + wall-clock), and the resource axis (peak memory / fits-16 GB)
  — side by side per arm, with baseline→arm deltas.

  Everything is flexible: the benchmark, the model, the template channel+version, which arms,
  and how many runs per arm. Arms are interleaved by default (A B B A …) to counterbalance
  calendar drift, per the experiment plan.

  Raw runs land in the harness's own worlds (TestResults/<benchmark>[-plan|-concurrent]);
  this experiment's report lands in ./results/.

.EXAMPLE
  # Pilot: 3 runs each of build vs plan on the minimal bench, default model, local template
  ./Run-Experiment.ps1

.EXAMPLE
  # Full: pick benchmark, model, template channel+version, arms, and runs/arm
  ./Run-Experiment.ps1 -Benchmark transactions -Model sonnet -Target dev -Ref v1.2.0 `
    -Arms build,plan,concurrent -Runs 5

.EXAMPLE
  # Re-generate the report from history already recorded, without launching any run
  ./Run-Experiment.ps1 -SkipRuns -Runs 5
#>
[CmdletBinding()]
param(
    [string]$Benchmark = 'minimal-concurrent',
    [string]$Model = 'opus',
    [string]$Target,
    [string]$Ref,
    [ValidateSet('build', 'plan', 'concurrent')][string[]]$Arms = @('build', 'plan'),
    [int]$Runs = 3,
    [switch]$SkipRuns,
    [switch]$NoInterleave,
    [switch]$RunLowerTiers,
    [string]$TestResultsRoot,
    [string]$OutDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Tier3Dir = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' 'tier-3-automated')).Path
# Reuse harness helpers directly: Get-Tier3History (history.ps1) + Format-Duration / Format-Tokens
# (Generate-Report.ps1). Both are pure libraries (function-scoped params only), so dot-sourcing them
# here is clean. New-Tier3Comparison lives in Compare-Tier3-Reports.ps1, which DOES have a top-level
# param block — dot-sourcing it at script scope would leak its defaults (Benchmark='transactions',
# Model=$null, …) over ours, so it's loaded inside New-Tier3QuickDiff (isolated) instead.
. (Join-Path $script:Tier3Dir 'history.ps1')
. (Join-Path $script:Tier3Dir 'Generate-Report.ps1')

# ---- pure helpers (unit-tested in tests/Run-Experiment.Tests.ps1) ---------------------------

# Read a property off a history row (PSCustomObject) or a plain hashtable (tests). $null if absent.
function Get-ExpProp {
    param($Obj, [string]$Name)
    if ($null -eq $Obj) { return $null }
    if ($Obj -is [System.Collections.IDictionary]) { if ($Obj.Contains($Name)) { return $Obj[$Name] } return $null }
    if ($Obj.PSObject.Properties.Name -contains $Name) { return $Obj.$Name }
    return $null
}

# The TestResults world key for an arm, matching Run-QATests.ps1's own routing exactly:
#   build -> <bench>            plan -> <bench>-plan            concurrent -> <bench>-concurrent
# with -Target adding the @<target>-<ref> segment (ref defaults to 'default').
function Get-ExperimentResultsKey {
    param([Parameter(Mandatory)][string]$Benchmark, [Parameter(Mandatory)][string]$Scenario, [string]$Target, [string]$Ref)
    $key = $Benchmark
    if ($Target) { $r = if ($Ref) { $Ref } else { 'default' }; $key = "$Benchmark@$Target-$r" }
    switch ($Scenario) {
        'plan'       { $key = "$key-plan" }
        'concurrent' { $key = "$key-concurrent" }
    }
    return $key
}

# Median of a set of numbers (nulls dropped). Even count -> mean of the two middle values.
function Get-Median {
    param($Values)
    $nums = @()
    foreach ($x in @($Values)) { if ($null -ne $x) { $nums += [double]$x } }
    if ($nums.Count -eq 0) { return $null }
    $s = @($nums | Sort-Object)
    $n = $s.Count
    if ($n % 2 -eq 1) { return $s[[int](($n - 1) / 2)] }
    return ($s[$n / 2 - 1] + $s[$n / 2]) / 2.0
}

# From an arm's history rows, keep this batch: filter to the model, take the last $Runs
# (newest are last in file order). $Runs -le 0 keeps all.
function Select-BatchRuns {
    param($Rows, [string]$Model, [int]$Runs)
    $r = @($Rows)
    if ($Model) { $r = @($r | Where-Object { (Get-ExpProp $_ 'model') -eq $Model }) }
    if ($Runs -gt 0 -and $r.Count -gt $Runs) { $r = @($r[($r.Count - $Runs)..($r.Count - 1)]) }
    return $r
}

# Per-metric median/min/max/n over a set of rows. Pure.
function Get-ArmAggregate {
    param($Rows, [Parameter(Mandatory)][string[]]$Keys)
    $agg = @{}
    foreach ($k in $Keys) {
        $vals = @()
        foreach ($row in @($Rows)) { $vals += , (Get-ExpProp $row $k) }
        $nums = @($vals | Where-Object { $null -ne $_ } | ForEach-Object { [double]$_ })
        $agg[$k] = @{
            n      = $nums.Count
            median = (Get-Median $nums)
            min    = if ($nums.Count) { ($nums | Measure-Object -Minimum).Minimum } else { $null }
            max    = if ($nums.Count) { ($nums | Measure-Object -Maximum).Maximum } else { $null }
        }
    }
    return $agg
}

# The metrics compared, in display order. `better` documents direction; 'memory' is the added axis.
function Get-ExperimentMetricSpecs {
    return @(
        @{ key = 'tokensTotal';      label = 'Tokens (proxy)';    kind = 'tokens';   better = 'lower' }
        @{ key = 'claudeSeconds';    label = "Claude's own time"; kind = 'duration'; better = 'lower' }
        @{ key = 'activeSeconds';    label = 'Wall-clock';        kind = 'duration'; better = 'lower' }
        @{ key = 'peakMemoryUsedMB'; label = 'Peak memory';       kind = 'memory';   better = 'lower' }
        @{ key = 'passRate';         label = 'Pass-rate';         kind = 'percent';  better = 'higher' }
        @{ key = 'epicsBuilt';       label = 'Epics built';       kind = 'count';    better = 'n/a' }
    )
}

function Format-Memory { param($Mb) if ($null -eq $Mb) { return '—' } return ('{0:N1} GB' -f ([double]$Mb / 1024.0)) }

# Format a metric value by kind (reuses Format-Duration / Format-Tokens from the harness).
function Format-ExpValue {
    param($Value, [string]$Kind)
    if ($null -eq $Value) { return '—' }
    switch ($Kind) {
        'duration' { return (Format-Duration ([double]$Value)) }
        'tokens'   { return (Format-Tokens $Value) }
        'memory'   { return (Format-Memory $Value) }
        'percent'  { return ('{0}%' -f [Math]::Round([double]$Value * 100)) }
        'count'    { return ([string][int]$Value) }
        default    { return [string]$Value }
    }
}

# "median [min–max]" cell for an aggregate metric.
function Format-ExpSpread {
    param($Stat, [string]$Kind)
    if ($null -eq $Stat -or $null -eq $Stat.median) { return '—' }
    $m = Format-ExpValue -Value $Stat.median -Kind $Kind
    if ($Stat.n -le 1 -or $null -eq $Stat.min) { return $m }
    return ('{0} [{1}–{2}]' -f $m, (Format-ExpValue -Value $Stat.min -Kind $Kind), (Format-ExpValue -Value $Stat.max -Kind $Kind))
}

# Signed baseline→arm delta of two medians ('—' when either is missing).
function Format-ExpDelta {
    param($BaseStat, $ArmStat, [string]$Kind)
    if ($null -eq $BaseStat -or $null -eq $ArmStat -or $null -eq $BaseStat.median -or $null -eq $ArmStat.median) { return '—' }
    $d = [double]$ArmStat.median - [double]$BaseStat.median
    $sign = if ($d -ge 0) { '+' } else { '-' }
    $mag = [Math]::Abs($d)
    switch ($Kind) {
        'duration' { return "$sign$(Format-Duration $mag)" }
        'tokens'   { return "$sign$(Format-Tokens $mag)" }
        'memory'   { return "$sign$(Format-Memory $mag)" }
        'percent'  { return "$sign$([Math]::Round($mag * 100))pp" }
        default    { return "$sign$([int]$mag)" }
    }
}

# Build the whole experiment report as a markdown string. Pure — the caller writes it to disk.
function New-ExperimentReport {
    param(
        [Parameter(Mandatory)][hashtable]$Setup,       # benchmark, model, template, arms, runs, interleave, generatedAt
        [Parameter(Mandatory)][hashtable]$Aggregates,  # arm -> aggregate hashtable (Get-ArmAggregate)
        [Parameter(Mandatory)][hashtable]$RawRows,     # arm -> array of batch rows
        [Parameter(Mandatory)][string]$Baseline
    )
    $specs = Get-ExperimentMetricSpecs
    $arms = @($Setup.arms)
    $L = [System.Collections.Generic.List[string]]::new()
    $add = { param($x) $L.Add([string]$x) }

    & $add "# Experiment report — /plan vs no /plan"
    & $add ''
    & $add "**Benchmark:** ``$($Setup.benchmark)`` · **Model:** ``$($Setup.model)`` · **Template:** $($Setup.template)"
    & $add "**Arms:** $($arms -join ', ') · **Runs/arm:** $($Setup.runs) · **Order:** $($Setup.order) · **Generated:** $($Setup.generatedAt)"
    & $add ''
    & $add '> Measurement study — record-only, never a pass/fail. Read the two axes separately (cost vs speed)'
    & $add '> and treat `Tokens (proxy)` as a rough figure only (it counts cheap cache-reads at par); see Notes.'
    & $add ''

    # --- aggregate table: arms x metrics (median [min-max]) ---
    & $add '## Aggregate — median [min–max] per arm'
    & $add ''
    $header = '| Metric | ' + (($arms | ForEach-Object { "$_" }) -join ' | ') + ' |'
    $sep = '|---|' + (($arms | ForEach-Object { '--:' }) -join '|') + '|'
    & $add $header
    & $add $sep
    foreach ($spec in $specs) {
        $cells = foreach ($a in $arms) { Format-ExpSpread -Stat $Aggregates[$a][$spec.key] -Kind $spec.kind }
        $dir = if ($spec.better -eq 'lower') { ' (lower better)' } elseif ($spec.better -eq 'higher') { ' (higher better)' } else { '' }
        & $add ('| {0}{1} | {2} |' -f $spec.label, $dir, ($cells -join ' | '))
    }
    & $add ''

    # --- delta table: baseline vs each other arm (median difference) ---
    $others = @($arms | Where-Object { $_ -ne $Baseline })
    if ($others.Count -gt 0) {
        & $add "## Δ vs baseline (``$Baseline``) — median difference"
        & $add ''
        & $add ('| Metric | ' + (($others | ForEach-Object { "Δ $_" }) -join ' | ') + ' |')
        & $add ('|---|' + (($others | ForEach-Object { '--:' }) -join '|') + '|')
        foreach ($spec in $specs) {
            if ($spec.better -eq 'n/a') { continue }
            $cells = foreach ($a in $others) { Format-ExpDelta -BaseStat $Aggregates[$Baseline][$spec.key] -ArmStat $Aggregates[$a][$spec.key] -Kind $spec.kind }
            & $add ('| {0} | {1} |' -f $spec.label, ($cells -join ' | '))
        }
        & $add ''
    }

    # --- peak memory callout (the added axis) ---
    & $add '## Peak memory (resource axis)'
    & $add ''
    & $add 'Peak whole-system RAM while the run worked (the harness''s memory sampler). A `concurrent`'
    & $add 'arm runs **two Claude sessions at once**, so expect its peak to sit *above* the single-session arms —'
    & $add 'this answers "does planning-while-building blow the RAM budget?".'
    & $add ''
    & $add '| Arm | Peak memory (median [min–max]) | Fits 16 GB? (runs) |'
    & $add '|---|--:|:--:|'
    foreach ($a in $arms) {
        $peak = Format-ExpSpread -Stat $Aggregates[$a]['peakMemoryUsedMB'] -Kind 'memory'
        $fits = @($RawRows[$a] | ForEach-Object { Get-ExpProp $_ 'memoryFits16GB' })
        $yes = @($fits | Where-Object { $_ -eq $true }).Count
        $tot = @($fits | Where-Object { $null -ne $_ }).Count
        $fitsCell = if ($tot -gt 0) { "$yes / $tot" } else { '—' }
        & $add ('| {0} | {1} | {2} |' -f $a, $peak, $fitsCell)
    }
    & $add ''

    # --- raw runs per arm ---
    & $add '## Raw runs (this batch)'
    foreach ($a in $arms) {
        & $add ''
        & $add "### $a"
        $rows = @($RawRows[$a])
        if ($rows.Count -eq 0) { & $add '_no runs found for this arm/model in history_'; continue }
        & $add '| Timestamp | epicsBuilt | passRate | tokens | Claude time | wall-clock | peak mem | fits 16 GB |'
        & $add '|---|--:|--:|--:|--:|--:|--:|:--:|'
        foreach ($row in $rows) {
            $fits = Get-ExpProp $row 'memoryFits16GB'
            $fitsTxt = if ($null -eq $fits) { '—' } elseif ($fits) { 'yes' } else { 'no' }
            & $add ('| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |' -f `
                (Get-ExpProp $row 'timestamp'),
                (Format-ExpValue -Value (Get-ExpProp $row 'epicsBuilt') -Kind 'count'),
                (Format-ExpValue -Value (Get-ExpProp $row 'passRate') -Kind 'percent'),
                (Format-ExpValue -Value (Get-ExpProp $row 'tokensTotal') -Kind 'tokens'),
                (Format-ExpValue -Value (Get-ExpProp $row 'claudeSeconds') -Kind 'duration'),
                (Format-ExpValue -Value (Get-ExpProp $row 'activeSeconds') -Kind 'duration'),
                (Format-ExpValue -Value (Get-ExpProp $row 'peakMemoryUsedMB') -Kind 'memory'),
                $fitsTxt)
        }
    }
    & $add ''

    & $add '## Notes / guardrails'
    & $add ''
    & $add '- **Cost ≠ Tokens (proxy).** `tokensTotal` sums cache-reads at par with fresh input, so it overstates'
    & $add '  /plan''s cost. For a real cost figure use USD / the cache-split from the `workflow-insights` skill.'
    & $add '- **Same-deliverable only.** Compare arms only when `epicsBuilt` matches (a 2-epic benchmark makes'
    & $add '  `plan` build the same app as `build`). Different epic counts ⇒ the token/time delta is meaningless.'
    & $add '- **`concurrent` double-counts tokens** (two sessions re-read context) and its wall-clock is the *union*'
    & $add '  of two overlapping sessions — read its `overlapSeconds` from the run''s tier3 block, don''t sum it in.'
    & $add '- **Small n.** With a few runs the spread often swamps the difference; treat a delta inside the'
    & $add '  [min–max] band as "no measurable difference", not a result.'
    return ($L -join "`n")
}

# ---- orchestration --------------------------------------------------------------------------

# Isolated wrapper around the harness's own comparator. Compare-Tier3-Reports.ps1 has a top-level
# param block; dot-sourcing it HERE keeps its leaked defaults inside this function's scope, and we
# capture our args into distinct locals first so the leak can't overwrite them before the call.
function New-Tier3QuickDiff {
    [CmdletBinding()]
    param([string]$Benchmark, [string]$LabelA, [string]$LabelB, [string]$HistoryPathA, [string]$HistoryPathB, [string]$Model, [string]$OutFile)
    $b = $Benchmark; $la = $LabelA; $lb = $LabelB; $ha = $HistoryPathA; $hb = $HistoryPathB; $m = $Model; $o = $OutFile
    . (Join-Path $script:Tier3Dir 'Compare-Tier3-Reports.ps1')   # defines New-Tier3Comparison (params leak locally only)
    New-Tier3Comparison -Benchmark $b -LabelA $la -LabelB $lb -HistoryPathA $ha -HistoryPathB $hb -Model $m -OutFile $o | Out-Null
}

# Interleaved arm schedule (A B B A …) so calendar drift is counterbalanced. Even cycles reverse.
function Get-ExperimentSchedule {
    param([string[]]$Arms, [int]$Runs, [switch]$NoInterleave)
    $order = [System.Collections.Generic.List[string]]::new()
    for ($cycle = 0; $cycle -lt $Runs; $cycle++) {
        $seq = if (-not $NoInterleave -and ($cycle % 2 -eq 1)) { @($Arms[($Arms.Count - 1)..0]) } else { @($Arms) }
        foreach ($a in $seq) { $order.Add($a) }
    }
    return @($order)
}

function Invoke-Experiment {
    [CmdletBinding()]
    param(
        [string]$Benchmark, [string]$Model, [string]$Target, [string]$Ref,
        [string[]]$Arms, [int]$Runs, [switch]$SkipRuns, [switch]$NoInterleave, [switch]$RunLowerTiers,
        [string]$TestResultsRoot, [string]$OutDir
    )
    if (-not $TestResultsRoot) { $TestResultsRoot = (Join-Path $PSScriptRoot '..' '..' 'TestResults') }
    if (-not $OutDir) { $OutDir = (Join-Path $PSScriptRoot 'results') }
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    $stamp = (Get-Date -Format 'yyyyMMdd-HHmmss')

    # 1) Run the arms (unless -SkipRuns). Interleaved by default.
    if (-not $SkipRuns) {
        $schedule = Get-ExperimentSchedule -Arms $Arms -Runs $Runs -NoInterleave:$NoInterleave
        $rq = Join-Path $script:Tier3Dir 'Run-QATests.ps1'
        $i = 0
        foreach ($arm in $schedule) {
            $i++
            Write-Host "[experiment] run $i/$($schedule.Count): scenario=$arm benchmark=$Benchmark model=$Model" -ForegroundColor Cyan
            $rqArgs = @{
                IncludeTier3 = $true; Scenario = $arm; Benchmark = $Benchmark; Tier3Model = $Model
                Timestamp    = (Get-Date -Format 'yyyyMMdd-HHmmss')
            }
            if ($Target) { $rqArgs.Target = $Target }
            if ($Ref) { $rqArgs.Ref = $Ref }
            if (-not $RunLowerTiers) { $rqArgs.SkipLowerTiers = $true }   # the study is about the tier-3 scenario cost
            & $rq @rqArgs
        }
    }
    else {
        Write-Host "[experiment] -SkipRuns: aggregating existing history only" -ForegroundColor Yellow
    }

    # 2) Read each arm's history world, keep this batch, aggregate.
    $keys = @('tokensTotal', 'claudeSeconds', 'activeSeconds', 'peakMemoryUsedMB', 'passRate', 'epicsBuilt')
    $aggregates = @{}; $rawRows = @{}
    foreach ($arm in $Arms) {
        $world = Get-ExperimentResultsKey -Benchmark $Benchmark -Scenario $arm -Target $Target -Ref $Ref
        $hist = Join-Path (Join-Path $TestResultsRoot $world) 'tier3-history.jsonl'
        $rows = if (Test-Path $hist) { @(Get-Tier3History -HistoryPath $hist) } else { @() }
        $batch = Select-BatchRuns -Rows $rows -Model $Model -Runs $Runs
        $rawRows[$arm] = $batch
        $aggregates[$arm] = Get-ArmAggregate -Rows $batch -Keys $keys
        Write-Host "[experiment] $arm ($world): $(@($batch).Count) run(s) in this batch"
    }

    # 3) Write the aggregate comparison report.
    $templateLabel = if ($Target) { "$Target @ $(if ($Ref) { $Ref } else { 'default' })" } else { 'local checkout' }
    $orderLabel = if ($NoInterleave) { 'sequential' } else { 'interleaved (A B B A …)' }
    $setup = @{
        benchmark = $Benchmark; model = $Model; template = $templateLabel; arms = $Arms
        runs = $Runs; order = $orderLabel
        generatedAt = $stamp
    }
    $baseline = $Arms[0]
    $md = New-ExperimentReport -Setup $setup -Aggregates $aggregates -RawRows $rawRows -Baseline $baseline
    $reportPath = Join-Path $OutDir "plan-experiment-$Benchmark-$stamp.md"
    Set-Content -Path $reportPath -Value $md -Encoding utf8
    Write-Host "[experiment] report: $reportPath" -ForegroundColor Green

    # 4) Also drop the harness's own latest-run quick diff for baseline vs each other arm (best-effort).
    foreach ($arm in @($Arms | Where-Object { $_ -ne $baseline })) {
        try {
            $keyA = Get-ExperimentResultsKey -Benchmark $Benchmark -Scenario $baseline -Target $Target -Ref $Ref
            $keyB = Get-ExperimentResultsKey -Benchmark $Benchmark -Scenario $arm -Target $Target -Ref $Ref
            $histA = Join-Path (Join-Path $TestResultsRoot $keyA) 'tier3-history.jsonl'
            $histB = Join-Path (Join-Path $TestResultsRoot $keyB) 'tier3-history.jsonl'
            if ((Test-Path $histA) -and (Test-Path $histB)) {
                $quick = Join-Path $OutDir "quickdiff-$baseline-vs-$arm-$stamp.md"
                New-Tier3QuickDiff -Benchmark $Benchmark -LabelA $baseline -LabelB $arm `
                    -HistoryPathA $histA -HistoryPathB $histB -Model $Model -OutFile $quick
                Write-Host "[experiment] quick diff: $quick"
            }
        }
        catch { Write-Host "[experiment] quick diff for $arm skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
    }

    return @{ report = $reportPath; aggregates = $aggregates; rawRows = $rawRows }
}

# Run unless dot-sourced (dot-sourcing exposes the pure functions for the Pester tests).
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Experiment -Benchmark $Benchmark -Model $Model -Target $Target -Ref $Ref `
        -Arms $Arms -Runs $Runs -SkipRuns:$SkipRuns -NoInterleave:$NoInterleave -RunLowerTiers:$RunLowerTiers `
        -TestResultsRoot $TestResultsRoot -OutDir $OutDir | Out-Null
}
