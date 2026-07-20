<#
.SYNOPSIS
  history.ps1 — the growing, per-benchmark Tier 3 run history.

.DESCRIPTION
  Every Tier 3 run appends ONE line to its benchmark's history file
  (TestResults/<benchmark>/tier3-history.jsonl). The file is never rewritten, so
  trends survive across versions and layout changes. Older lines that lack newer
  fields still work — a missing field simply reads back as $null (shown as "—").

  This module is the single writer/reader used by the report (for estimate-vs-actual)
  and by the charts page. It is deliberately tiny and has no live-AI dependency.
#>

Set-StrictMode -Version Latest

# Append one run's record as a single JSON line. Creates the folder if needed.
function Add-Tier3HistoryLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HistoryPath,
        [Parameter(Mandatory)][hashtable]$Record
    )
    $dir = Split-Path -Parent $HistoryPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $line = ($Record | ConvertTo-Json -Compress -Depth 8)
    Add-Content -Path $HistoryPath -Value $line -Encoding utf8
}

# Read the history back as objects, newest last (file order). Optional model/benchmark filter.
function Get-Tier3History {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HistoryPath,
        [string]$Model,
        [string]$Benchmark
    )
    if (-not (Test-Path $HistoryPath)) { return @() }
    $rows = @(
        Get-Content -Path $HistoryPath -Encoding utf8 |
            Where-Object { $_.Trim().Length -gt 0 } |
            ForEach-Object { $_ | ConvertFrom-Json }
    )
    if ($PSBoundParameters.ContainsKey('Model'))     { $rows = @($rows | Where-Object { $_.model -eq $Model }) }
    if ($PSBoundParameters.ContainsKey('Benchmark')) { $rows = @($rows | Where-Object { $_.benchmark -eq $Benchmark }) }
    return $rows
}

# The most recent N runs per model, newest first — the "last 10 per model" view.
function Get-Tier3RecentPerModel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HistoryPath,
        [int]$PerModel = 10
    )
    $rows = @(Get-Tier3History -HistoryPath $HistoryPath)
    $result = [ordered]@{}
    foreach ($model in ($rows | ForEach-Object { $_.model } | Sort-Object -Unique)) {
        $forModel = @($rows | Where-Object { $_.model -eq $model })
        # newest first, then take N
        [array]::Reverse($forModel)
        $result[$model] = @($forModel | Select-Object -First $PerModel)
    }
    return $result
}

# Average per-phase active/Claude seconds across past runs (same model + benchmark) —
# the basis for the report's "estimate" column. Returns a hashtable keyed by phase path.
# Empty when there is no comparable history yet (so the first run shows no estimate).
function Get-Tier3PhaseEstimates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HistoryPath,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$Benchmark
    )
    $rows = @(Get-Tier3History -HistoryPath $HistoryPath -Model $Model -Benchmark $Benchmark)
    $byPhase = @{}   # path -> list of @{active; claude}
    foreach ($row in $rows) {
        if (-not ($row.PSObject.Properties.Name -contains 'phases') -or $null -eq $row.phases) { continue }
        foreach ($p in $row.phases) {
            if (-not $byPhase.ContainsKey($p.path)) { $byPhase[$p.path] = [System.Collections.Generic.List[object]]::new() }
            $byPhase[$p.path].Add(@{ active = [double]$p.activeSeconds; claude = [double]$p.claudeSeconds })
        }
    }
    $estimates = @{}
    foreach ($path in $byPhase.Keys) {
        $samples = $byPhase[$path]
        $estimates[$path] = @{
            activeSeconds = [Math]::Round((($samples | ForEach-Object { $_.active }) | Measure-Object -Average).Average, 2)
            claudeSeconds = [Math]::Round((($samples | ForEach-Object { $_.claude }) | Measure-Object -Average).Average, 2)
            samples       = $samples.Count
        }
    }
    return $estimates
}

# Average WHOLE-RUN active/Claude seconds across past runs (same model + benchmark) —
# the basis for the report's MACRO estimate (estimated total time to build the app),
# the run-level counterpart to Get-Tier3PhaseEstimates. Returns a hashtable
# @{ activeSeconds; claudeSeconds; samples } or $null when there is no comparable
# history yet (so the first run shows no macro estimate). claudeSeconds is $null when
# no matching run recorded it (older lines).
function Get-Tier3RunEstimate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HistoryPath,
        [Parameter(Mandatory)][string]$Model,
        [Parameter(Mandatory)][string]$Benchmark
    )
    $rows = @(
        Get-Tier3History -HistoryPath $HistoryPath -Model $Model -Benchmark $Benchmark |
            Where-Object { $_.PSObject.Properties.Name -contains 'activeSeconds' -and $null -ne $_.activeSeconds }
    )
    if ($rows.Count -eq 0) { return $null }
    $claudeVals = @(
        $rows |
            Where-Object { $_.PSObject.Properties.Name -contains 'claudeSeconds' -and $null -ne $_.claudeSeconds } |
            ForEach-Object { [double]$_.claudeSeconds }
    )
    return @{
        activeSeconds = [Math]::Round((($rows | ForEach-Object { [double]$_.activeSeconds }) | Measure-Object -Average).Average, 2)
        claudeSeconds = if ($claudeVals.Count -gt 0) { [Math]::Round(($claudeVals | Measure-Object -Average).Average, 2) } else { $null }
        samples       = $rows.Count
    }
}
