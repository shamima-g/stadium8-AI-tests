<#
.SYNOPSIS
  Compare-Tier3-Reports.ps1 — diff two Tier 3 targeted runs of the same app
  (e.g. release vs dev), side by side.

.DESCRIPTION
  Each targeted run is filed under TestResults/<benchmark>@<target>-<ref>/. This reads
  the latest run from each side's history, lines up the key metrics — result, active
  time, Claude's own time, AI tokens, build pass-rate, rules missed, peak memory — and
  writes a markdown comparison with the A→B delta for each. Read-only over existing
  results: it runs nothing and needs no AI.

  For a fair comparison pass the same -Model on both sides (times/tokens differ by
  model); with no -Model it takes the newest run on each side.

.EXAMPLE
  ./Compare-Tier3-Reports.ps1 -Benchmark transactions -A release -ARef v1.1.0 -B dev -BRef v1.1.0
#>
[CmdletBinding()]
param(
    [string]$Benchmark = 'transactions',
    [string]$A,
    [string]$ARef,
    [string]$B,
    [string]$BRef,
    [string]$Model,
    [string]$TestResultsRoot,
    [string]$OutFile
)

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'history.ps1')
. (Join-Path $PSScriptRoot 'Generate-Report.ps1')   # for Format-Duration / Format-Tokens (no main; safe to dot-source)

# Read a property off a JSON record (PSCustomObject), or $null when absent.
function Get-Tier3Prop {
    param($Obj, [string]$Name)
    if ($null -eq $Obj) { return $null }
    if ($Obj.PSObject.Properties.Name -contains $Name) { return $Obj.$Name }
    return $null
}

# The newest run from a set of history rows (optionally a given model). Rows are
# newest-last (file order), so the last match is the newest. $null when none.
function Select-Tier3LatestRun {
    param([array]$Rows, [string]$Model)
    $r = @($Rows)
    if ($Model) { $r = @($r | Where-Object { $_.model -eq $Model }) }
    if ($r.Count -eq 0) { return $null }
    return $r[$r.Count - 1]
}

# Flatten a history record into the metrics we compare. Missing fields read as $null.
function Get-Tier3RunMetrics {
    param($Run)
    if ($null -eq $Run) { return $null }
    $rules = Get-Tier3Prop $Run 'rulesMissed'
    $active = Get-Tier3Prop $Run 'activeSeconds'
    $claude = Get-Tier3Prop $Run 'claudeSeconds'
    $tokens = Get-Tier3Prop $Run 'tokensTotal'
    $pass   = Get-Tier3Prop $Run 'passRate'
    $peak   = Get-Tier3Prop $Run 'peakMemoryUsedMB'
    return [ordered]@{
        timestamp     = Get-Tier3Prop $Run 'timestamp'
        model         = Get-Tier3Prop $Run 'model'
        result        = Get-Tier3Prop $Run 'result'
        activeSeconds = if ($null -ne $active) { [double]$active } else { $null }
        claudeSeconds = if ($null -ne $claude) { [double]$claude } else { $null }
        tokensTotal   = if ($null -ne $tokens) { [double]$tokens } else { $null }
        passRate      = if ($null -ne $pass)   { [double]$pass }   else { $null }
        rulesMissed   = if ($null -ne $rules)  { @($rules).Count } else { $null }
        peakMemoryMB  = if ($null -ne $peak)   { [double]$peak }   else { $null }
    }
}

# The metric rows compared, in display order: @{ metric; a; b; kind }.
function Compare-Tier3Metrics {
    param($Ma, $Mb)
    return @(
        @{ metric = 'Result';            a = $Ma.result;        b = $Mb.result;        kind = 'text' }
        @{ metric = 'Active time';       a = $Ma.activeSeconds; b = $Mb.activeSeconds; kind = 'duration' }
        @{ metric = "Claude's own time"; a = $Ma.claudeSeconds; b = $Mb.claudeSeconds; kind = 'duration' }
        @{ metric = 'AI tokens';         a = $Ma.tokensTotal;   b = $Mb.tokensTotal;   kind = 'tokens' }
        @{ metric = 'Build pass-rate';   a = $Ma.passRate;      b = $Mb.passRate;      kind = 'percent' }
        @{ metric = 'Rules missed';      a = $Ma.rulesMissed;   b = $Mb.rulesMissed;   kind = 'count' }
        @{ metric = 'Peak memory (MB)';  a = $Ma.peakMemoryMB;  b = $Mb.peakMemoryMB;  kind = 'count' }
    )
}

function Format-Tier3Metric {
    param($Value, [string]$Kind)
    if ($null -eq $Value) { return '—' }
    switch ($Kind) {
        'duration' { return (Format-Duration ([double]$Value)) }
        'tokens'   { return (Format-Tokens $Value) }
        'percent'  { return ('{0}%' -f [Math]::Round([double]$Value * 100)) }
        'count'    { return ([string][int]$Value) }
        default    { return [string]$Value }
    }
}

# Signed A→B delta for a numeric metric ('—' for text or when either side is missing).
function Format-Tier3Delta {
    param($A, $B, [string]$Kind)
    if ($Kind -eq 'text' -or $null -eq $A -or $null -eq $B) { return '—' }
    $d = [double]$B - [double]$A
    $sign = if ($d -ge 0) { '+' } else { '-' }
    $mag = [Math]::Abs($d)
    switch ($Kind) {
        'duration' { return "$sign$(Format-Duration $mag)" }
        'tokens'   { return "$sign$(Format-Tokens $mag)" }
        'percent'  { return "$sign$([Math]::Round($mag * 100))pp" }
        default    { return "$sign$([int]$mag)" }
    }
}

# Read both sides' latest run, render the comparison markdown, write it, return the path.
function New-Tier3Comparison {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Benchmark,
        [Parameter(Mandatory)][string]$LabelA,
        [Parameter(Mandatory)][string]$LabelB,
        [Parameter(Mandatory)][string]$HistoryPathA,
        [Parameter(Mandatory)][string]$HistoryPathB,
        [string]$Model,
        [string]$Command,
        [string]$GeneratedAt,
        [string]$RepoA,
        [string]$RepoB,
        [Parameter(Mandatory)][string]$OutFile
    )
    $runA = Select-Tier3LatestRun -Rows (Get-Tier3History -HistoryPath $HistoryPathA) -Model $Model
    $runB = Select-Tier3LatestRun -Rows (Get-Tier3History -HistoryPath $HistoryPathB) -Model $Model
    if ($null -eq $runA) { throw "No runs found for '$LabelA' at $HistoryPathA — run Tier 3 against that target first." }
    if ($null -eq $runB) { throw "No runs found for '$LabelB' at $HistoryPathB — run Tier 3 against that target first." }

    $ma = Get-Tier3RunMetrics $runA
    $mb = Get-Tier3RunMetrics $runB
    $rows = Compare-Tier3Metrics -Ma $ma -Mb $mb

    $tick = [string][char]96   # a literal backtick, for wrapping the command in `code`
    $L = [System.Collections.Generic.List[string]]::new()
    $add = { param($x) $L.Add([string]$x) }
    & $add "# Tier 3 comparison — $Benchmark"
    & $add ''
    & $add "**A: $LabelA** (run $($ma.timestamp), model $($ma.model)) vs **B: $LabelB** (run $($mb.timestamp), model $($mb.model))."
    & $add ''
    # Provenance: which repo/version each side is, when the diff was produced, and the command.
    if ($RepoA -or $RepoB) {
        & $add '| Side | Repository | Version tested |'
        & $add '|---|---|---|'
        & $add "| A · $LabelA | $(if ($RepoA) { $RepoA } else { '—' }) | $LabelA |"
        & $add "| B · $LabelB | $(if ($RepoB) { $RepoB } else { '—' }) | $LabelB |"
        & $add ''
    }
    $meta = [System.Collections.Generic.List[string]]::new()
    if ($GeneratedAt) { $meta.Add("**Generated:** $GeneratedAt") }
    if ($Command) { $meta.Add("**Command:** $tick$Command$tick") }
    if ($meta.Count -gt 0) { & $add ($meta -join '  ·  '); & $add '' }
    if ($ma.model -ne $mb.model) {
        & $add "> ⚠️ The two sides used different AI models ($($ma.model) vs $($mb.model)) — times and tokens are not directly comparable. Re-run with a matching model for a fair diff."
        & $add ''
    }
    & $add "| Metric | A · $LabelA | B · $LabelB | Δ (B − A) |"
    & $add '|---|--:|--:|--:|'
    foreach ($r in $rows) {
        $av = Format-Tier3Metric -Value $r.a -Kind $r.kind
        $bv = Format-Tier3Metric -Value $r.b -Kind $r.kind
        $dv = Format-Tier3Delta  -A $r.a -B $r.b -Kind $r.kind
        & $add ("| {0} | {1} | {2} | {3} |" -f $r.metric, $av, $bv, $dv)
    }
    & $add ''
    & $add '<sub>Δ is B minus A. For time, tokens, rules-missed and memory, lower is better; for pass-rate, higher is better. Read-only summary built from each target''s saved history.</sub>'

    $dir = Split-Path -Parent $OutFile
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $OutFile -Value ($L -join "`n") -Encoding utf8
    return $OutFile
}

# Run unless dot-sourced (dot-sourcing exposes the functions for unit tests).
if ($MyInvocation.InvocationName -ne '.') {
    if (-not $A -or -not $B) { throw "Both -A and -B are required (e.g. -A release -ARef v1.1.0 -B dev -BRef v1.1.0)." }
    if (-not $TestResultsRoot) { $TestResultsRoot = (Join-Path $PSScriptRoot '..' 'TestResults') }
    $labelA = "$A-$(if ($ARef) { $ARef } else { 'default' })"
    $labelB = "$B-$(if ($BRef) { $BRef } else { 'default' })"
    $keyA = "$Benchmark@$labelA"
    $keyB = "$Benchmark@$labelB"
    $histA = Join-Path (Join-Path $TestResultsRoot $keyA) 'tier3-history.jsonl'
    $histB = Join-Path (Join-Path $TestResultsRoot $keyB) 'tier3-history.jsonl'
    if (-not $OutFile) { $OutFile = Join-Path $TestResultsRoot "compare-tier3-$keyA--vs--$keyB.md" }

    # Provenance for the report: the command, when it ran, and each side's repo (from targets.json).
    $genAt = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $cmdParts = [System.Collections.Generic.List[string]]::new()
    $cmdParts.Add('./Compare-Tier3-Reports.ps1'); $cmdParts.Add("-Benchmark $Benchmark")
    $cmdParts.Add("-A $A"); if ($ARef) { $cmdParts.Add("-ARef $ARef") }
    $cmdParts.Add("-B $B"); if ($BRef) { $cmdParts.Add("-BRef $BRef") }
    if ($Model) { $cmdParts.Add("-Model $Model") }
    $cmd = ($cmdParts -join ' ')
    $repoA = $null; $repoB = $null
    $targetsFile = Join-Path $PSScriptRoot '..' 'targets.json'
    if (Test-Path $targetsFile) {
        $tg = (Get-Content $targetsFile -Raw | ConvertFrom-Json).targets
        $names = @($tg.PSObject.Properties.Name)
        if ($names -contains $A) { $repoA = $tg.$A.repo }
        if ($names -contains $B) { $repoB = $tg.$B.repo }
    }

    $out = New-Tier3Comparison -Benchmark $Benchmark -LabelA $labelA -LabelB $labelB `
        -HistoryPathA $histA -HistoryPathB $histB -Model $Model `
        -Command $cmd -GeneratedAt $genAt -RepoA $repoA -RepoB $repoB -OutFile $OutFile
    Write-Host "Comparison written to: $out"
    Get-Content $out | Write-Host
}
