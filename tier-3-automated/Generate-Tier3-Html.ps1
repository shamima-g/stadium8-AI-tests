<#
.SYNOPSIS
  Generate-Tier3-Html.ps1 — builds a benchmark's self-contained charts page.

.DESCRIPTION
  Reads one benchmark's history (history.ps1) and writes a single self-contained HTML
  file (all CSS inline, no internet needed): the last 10 runs per model (the headline),
  a bar chart of time taken (overall active vs Claude's own), a per-version summary, the
  most-flagged rules, and a raw records table with the pass-rate.

  Because the page is rebuilt from the history every run, it re-bases itself — there is
  nothing to hand-edit. No live AI involved.
#>

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'history.ps1')

function Get-Prop {
    param($Object, [string]$Name, $Default = $null)
    if ($Object -and ($Object.PSObject.Properties.Name -contains $Name)) { return $Object.$Name }
    return $Default
}

function ConvertTo-HtmlText {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    return $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

function Format-Secs {
    param($Seconds)
    if ($null -eq $Seconds) { return '—' }
    $s = [double]$Seconds
    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    if ($s -lt 60) { return ($s.ToString('0.#', $inv) + 's') }
    $m = [Math]::Floor($s / 60); $r = [Math]::Round($s - ($m * 60))
    return ('{0}m {1}s' -f $m, $r)
}

# Rebuild the top-level master list (TestResults/index.md): every Tier 3 run across all
# benchmarks, newest first, grouped by app, linking to each run's report. Rebuilt each run.
function Update-Tier3Index {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$TestResultsRoot)
    if (-not (Test-Path $TestResultsRoot)) { New-Item -ItemType Directory -Path $TestResultsRoot -Force | Out-Null }
    $L = [System.Collections.Generic.List[string]]::new()
    $L.Add('# Tier 3 — all runs'); $L.Add('')
    $L.Add('Every automated Tier 3 run, newest first, grouped by app. This page is rebuilt after each run.')
    $L.Add('')

    $benchDirs = @(Get-ChildItem -Path $TestResultsRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
    $any = $false
    foreach ($b in $benchDirs) {
        $hist = Join-Path $b.FullName 'tier3-history.jsonl'
        if (-not (Test-Path $hist)) { continue }
        $rows = @(Get-Tier3History -HistoryPath $hist)
        if ($rows.Count -eq 0) { continue }
        [array]::Reverse($rows)   # newest first
        $any = $true
        $L.Add("## $($b.Name)")
        $L.Add('')
        $L.Add("[charts & trends]($($b.Name)/tier3-metrics.html)")
        $L.Add('')
        $L.Add('| When | Model | Result | Verdict | Active | Claude | Peak RAM | Tokens | Report |')
        $L.Add('|---|---|:--:|---|--:|--:|--:|--:|---|')
        foreach ($r in $rows) {
            $ts = Get-Prop $r 'timestamp' '—'
            $model = Get-Prop $r 'model' '—'
            $ver = Get-Prop $r 'version' '0.1.0'
            $result = if ((Get-Prop $r 'result' '') -eq 'pass') { '✅' } else { '❌' }
            $verdict = Get-Prop $r 'verdict' '—'
            $active = Format-Secs (Get-Prop $r 'activeSeconds')
            $claude = Format-Secs (Get-Prop $r 'claudeSeconds')
            $ram = Get-Prop $r 'peakMemoryUsedMB'; $ramText = if ($null -eq $ram) { '—' } else { "$([Math]::Round([double]$ram / 1024, 1)) GB" }
            $tok = Get-Prop $r 'tokensTotal'; $tokText = if ($null -eq $tok) { '—' } else { ([double]$tok).ToString('N0', [System.Globalization.CultureInfo]::InvariantCulture) }
            $reportRel = "$($b.Name)/$model/$ts/report-$ver-$ts.md"
            $L.Add("| $ts | $model | $result | $verdict | $active | $claude | $ramText | $tokText | [open]($reportRel) |")
        }
        $L.Add('')
    }
    if (-not $any) { $L.Add('_No runs recorded yet._') }

    $indexPath = Join-Path $TestResultsRoot 'index.md'
    Set-Content -Path $indexPath -Value ($L -join "`n") -Encoding utf8
    return $indexPath
}

function New-Tier3Html {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HistoryPath,
        [Parameter(Mandatory)][string]$OutPath,
        [string]$Benchmark = '',
        [int]$PerModel = 10
    )

    $rows = @(Get-Tier3History -HistoryPath $HistoryPath)
    $css = @'
<style>
  :root { color-scheme: light dark; }
  body { font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif; margin: 2rem auto; max-width: 60rem; padding: 0 1rem; line-height: 1.5; }
  h1 { margin-bottom: .25rem; } h2 { margin-top: 2rem; border-bottom: 1px solid #8884; padding-bottom: .25rem; }
  table { border-collapse: collapse; width: 100%; margin: .5rem 0; font-size: .92rem; }
  th, td { border: 1px solid #8883; padding: .35rem .5rem; text-align: left; }
  th { background: #8881; }
  td.num { text-align: right; font-variant-numeric: tabular-nums; }
  .bar { display: inline-block; height: .8rem; border-radius: 2px; }
  .bar-active { background: #4a90d9; } .bar-claude { background: #7bc043; }
  .muted { color: #8889; } .pass { color: #2e8b57; } .fail { color: #c0392b; }
  .chartrow { display:flex; align-items:center; gap:.5rem; margin:.15rem 0; }
  .chartrow .lbl { width: 9rem; font-size:.82rem; }
  caption { text-align:left; color:#8889; font-size:.82rem; margin-bottom:.25rem; }
  .legend { display:flex; gap:1.25rem; align-items:center; font-size:.82rem; color:#8889; margin:.25rem 0 .75rem; }
  .legend .swatch { display:inline-block; width:.8rem; height:.8rem; border-radius:2px; margin-right:.35rem; vertical-align:-1px; }
  .vchart { display:flex; align-items:flex-end; gap:1.1rem; height:17rem; padding-top:1.25rem; border-bottom:1px solid #8883; overflow-x:auto; }
  .vgroup { display:flex; flex-direction:column; align-items:center; gap:.4rem; min-width:3.25rem; flex:0 0 auto; }
  .vbars { display:flex; align-items:flex-end; gap:.3rem; height:13rem; }
  .vbar { width:1.15rem; min-height:2px; border-radius:3px 3px 0 0; position:relative; }
  .vbar .val { position:absolute; top:-1.15rem; left:50%; transform:translateX(-50%); font-size:.68rem; color:#8889; white-space:nowrap; }
  .vlbl { font-size:.72rem; line-height:1.2; text-align:center; color:#8889; max-width:5rem; word-break:break-word; }
</style>
'@

    $title = if ($Benchmark) { "Tier 3 — $Benchmark" } else { 'Tier 3 history' }
    $H = [System.Collections.Generic.List[string]]::new()
    $H.Add('<!doctype html><html lang="en"><head><meta charset="utf-8">')
    $H.Add("<meta name=""viewport"" content=""width=device-width, initial-scale=1""><title>$(ConvertTo-HtmlText $title)</title>")
    $H.Add($css)
    $H.Add('</head><body>')
    $H.Add("<h1>$(ConvertTo-HtmlText $title)</h1>")
    $H.Add("<p class=""muted"">$($rows.Count) run(s) recorded. Newest first.</p>")

    if ($rows.Count -eq 0) {
        $H.Add('<p>No Tier 3 runs have been recorded yet. Run one, and this page fills in.</p>')
        $H.Add('</body></html>')
        $dir = Split-Path -Parent $OutPath
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Set-Content -Path $OutPath -Value ($H -join "`n") -Encoding utf8
        return $OutPath
    }

    # ---- last 10 per model (headline) ----
    $H.Add('<h2>Last 10 runs per model</h2>')
    $recent = Get-Tier3RecentPerModel -HistoryPath $HistoryPath -PerModel $PerModel
    foreach ($model in $recent.Keys) {
        $H.Add("<h3>$(ConvertTo-HtmlText $model)</h3>")
        $H.Add('<table><tr><th>When</th><th>Result</th><th>Active</th><th>Claude</th><th>Peak RAM</th><th>Tokens</th><th>Pass-rate</th><th>Rules missed</th></tr>')
        foreach ($r in $recent[$model]) {
            $result = Get-Prop $r 'result' '—'
            $cls = if ($result -eq 'pass') { 'pass' } else { 'fail' }
            $active = Format-Secs (Get-Prop $r 'activeSeconds')
            $claude = Format-Secs (Get-Prop $r 'claudeSeconds')
            $ram = Get-Prop $r 'peakMemoryUsedMB'; $ramText = if ($null -eq $ram) { '—' } else { "$([Math]::Round([double]$ram / 1024, 1)) GB" }
            $tokens = Get-Prop $r 'tokensTotal'; $tokensText = if ($null -eq $tokens) { '—' } else { ([double]$tokens).ToString('N0', [System.Globalization.CultureInfo]::InvariantCulture) }
            $pr = Get-Prop $r 'passRate'; $prText = if ($null -eq $pr) { '—' } else { "$([Math]::Round([double]$pr * 100))%" }
            $missed = Get-Prop $r 'rulesMissed' @(); if ($null -eq $missed) { $missed = @() }; $missed = @($missed | Where-Object { $null -ne $_ -and "$_" -ne '' })
            $missedText = if ($missed.Count) { ConvertTo-HtmlText ($missed -join ', ') } else { '<span class="muted">none</span>' }
            $H.Add("<tr><td>$(ConvertTo-HtmlText (Get-Prop $r 'timestamp' '—'))</td><td class=""$cls"">$(ConvertTo-HtmlText $result)</td><td class=""num"">$active</td><td class=""num"">$claude</td><td class=""num"">$ramText</td><td class=""num"">$tokensText</td><td class=""num"">$prText</td><td>$missedText</td></tr>")
        }
        $H.Add('</table>')
    }

    # ---- time taken chart (overall active vs Claude) ----
    $H.Add('<h2>Time taken — overall (active) vs Claude''s own</h2>')
    $newest = @($rows); [array]::Reverse($newest); $newest = @($newest | Select-Object -First 15)
    $maxSecs = 1.0
    foreach ($r in $newest) { foreach ($v in @((Get-Prop $r 'activeSeconds' 0), (Get-Prop $r 'claudeSeconds' 0))) { if ([double]$v -gt $maxSecs) { $maxSecs = [double]$v } } }
    $H.Add('<div class="legend"><span><span class="swatch" style="background:#4a90d9"></span>Active (overall)</span><span><span class="swatch" style="background:#7bc043"></span>Claude''s own</span></div>')
    $H.Add('<div class="vchart">')
    foreach ($r in $newest) {
        $a = [double](Get-Prop $r 'activeSeconds' 0); $c = [double](Get-Prop $r 'claudeSeconds' 0)
        $ah = [Math]::Round(($a / $maxSecs) * 100); $ch = [Math]::Round(($c / $maxSecs) * 100)
        $lbl = ConvertTo-HtmlText ("$(Get-Prop $r 'model' '?') $(Get-Prop $r 'timestamp' '')")
        $H.Add("<div class=""vgroup""><div class=""vbars""><div class=""vbar bar-active"" style=""height:$ah%"" title=""Active $(Format-Secs $a)""><span class=""val"">$(Format-Secs $a)</span></div><div class=""vbar bar-claude"" style=""height:$ch%"" title=""Claude $(Format-Secs $c)""><span class=""val"">$(Format-Secs $c)</span></div></div><div class=""vlbl"">$lbl</div></div>")
    }
    $H.Add('</div>')

    # ---- epics — per-epic build time (latest run), actual vs average ----
    $latest = $newest[0]   # newest-first
    $latestEpics = Get-Prop $latest 'epics' @()
    if ($null -ne $latestEpics -and @($latestEpics).Count -gt 0) {
        # per-slug average build seconds across every recorded run (the estimate bar)
        $slugSecs = @{}
        foreach ($r in $rows) {
            foreach ($e in @(Get-Prop $r 'epics' @())) {
                $slug = Get-Prop $e 'slug'
                if (-not $slug) { continue }
                if (-not $slugSecs.ContainsKey($slug)) { $slugSecs[$slug] = [System.Collections.Generic.List[double]]::new() }
                $slugSecs[$slug].Add([double](Get-Prop $e 'seconds' 0))
            }
        }
        $ec = Get-Prop $latest 'epicsCreated' (@($latestEpics).Count)
        $sc = Get-Prop $latest 'storiesCreated' 0
        $H.Add('<h2>Epics — time to build each one (latest run)</h2>')
        $H.Add("<p class=""muted"">Latest run created <strong>$ec</strong> epic(s) and <strong>$sc</strong> story(ies).</p>")
        $maxE = 1.0
        foreach ($e in @($latestEpics)) { $v = [double](Get-Prop $e 'seconds' 0); if ($v -gt $maxE) { $maxE = $v } }
        foreach ($slug in $slugSecs.Keys) { $avg = [double]((($slugSecs[$slug]) | Measure-Object -Average).Average); if ($avg -gt $maxE) { $maxE = $avg } }
        $H.Add('<div class="legend"><span><span class="swatch" style="background:#4a90d9"></span>Actual this run</span><span><span class="swatch" style="background:#7bc043"></span>Average across runs</span></div>')
        $H.Add('<div class="vchart">')
        foreach ($e in @($latestEpics)) {
            $slug = Get-Prop $e 'slug' '?'; $stories = Get-Prop $e 'stories' 0
            $actual = [double](Get-Prop $e 'seconds' 0)
            $ah = [Math]::Round(($actual / $maxE) * 100)
            $lbl = ConvertTo-HtmlText "$slug ($stories st.)"
            $avgBar = ''
            if ($slugSecs.ContainsKey($slug)) {
                $avg = [double]((($slugSecs[$slug]) | Measure-Object -Average).Average)
                $ch = [Math]::Round(($avg / $maxE) * 100)
                $avgBar = "<div class=""vbar bar-claude"" style=""height:$ch%"" title=""Average $(Format-Secs $avg)""><span class=""val"">$(Format-Secs $avg)</span></div>"
            }
            $H.Add("<div class=""vgroup""><div class=""vbars""><div class=""vbar bar-active"" style=""height:$ah%"" title=""Actual $(Format-Secs $actual)""><span class=""val"">$(Format-Secs $actual)</span></div>$avgBar</div><div class=""vlbl"">$lbl</div></div>")
        }
        $H.Add('</div>')
    }

    # ---- most-flagged rules ----
    $ruleTally = @{}
    foreach ($r in $rows) {
        $missedList = Get-Prop $r 'rulesMissed' @()
        if ($null -eq $missedList) { $missedList = @() }
        foreach ($m in @($missedList)) {
            if ($null -eq $m -or "$m" -eq '') { continue }
            if (-not $ruleTally.ContainsKey($m)) { $ruleTally[$m] = 0 }
            $ruleTally[$m]++
        }
    }
    $H.Add('<h2>Most-flagged rules (what to make clearer)</h2>')
    if ($ruleTally.Keys.Count -eq 0) {
        $H.Add('<p class="muted">No rules have been flagged. 🎉</p>')
    }
    else {
        $H.Add('<table><tr><th>Rule</th><th>Times flagged</th></tr>')
        foreach ($k in ($ruleTally.Keys | Sort-Object { $ruleTally[$_] } -Descending)) {
            $H.Add("<tr><td>$(ConvertTo-HtmlText $k)</td><td class=""num"">$($ruleTally[$k])</td></tr>")
        }
        $H.Add('</table>')
    }

    # ---- per-version summary ----
    $H.Add('<h2>By version</h2>')
    $H.Add('<table><tr><th>Version</th><th>Runs</th><th>Avg active</th><th>Avg Claude</th></tr>')
    foreach ($ver in ($rows | ForEach-Object { Get-Prop $_ 'version' '—' } | Sort-Object -Unique)) {
        $forVer = @($rows | Where-Object { (Get-Prop $_ 'version' '—') -eq $ver })
        $avgA = ($forVer | ForEach-Object { [double](Get-Prop $_ 'activeSeconds' 0) } | Measure-Object -Average).Average
        $avgC = ($forVer | ForEach-Object { [double](Get-Prop $_ 'claudeSeconds' 0) } | Measure-Object -Average).Average
        $H.Add("<tr><td>$(ConvertTo-HtmlText $ver)</td><td class=""num"">$($forVer.Count)</td><td class=""num"">$(Format-Secs $avgA)</td><td class=""num"">$(Format-Secs $avgC)</td></tr>")
    }
    $H.Add('</table>')

    $H.Add('</body></html>')

    $dir = Split-Path -Parent $OutPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $OutPath -Value ($H -join "`n") -Encoding utf8
    return $OutPath
}
