<#
.SYNOPSIS
  Generate-Report.ps1 — writes the plain-English report for one Tier 3 run.

.DESCRIPTION
  Takes a run-result object (produced by the runner) plus the run's timing summary,
  and writes:
    * report-<version>-<timestamp>.md   — the human-readable report
    * Fail/<timestamp>.md               — only when there is something to report

  Sections: a run summary (with the MACRO estimate — estimated whole-run time next to
  the actual); a per-group breakdown; (when Tier 3 ran) a §2.1 attempts table and a §2.2
  timing table with a GRANULAR estimate next to the actual time per phase; the installed
  tools; and a §3.1 failure diagnosis that names each problem with a plain reason and
  "possible solutions".

  The report never fails the run on the Tier 3 score — a below-par Tier 3 run still gets
  its §2.1 row, its §3.1 block, and a Fail/<stamp>.md; it just doesn't turn anything red.

  Estimates come from the benchmark's history (history.ps1). No live AI involved.

  The RUN OBJECT (hashtable) shape (all times in seconds):
    version, timestamp, dateHuman, model, benchmark, runBy, machine, result ('pass'|'fail')
    groups   = @( @{ name; tests; passed; failed; skipped; durationSeconds; tokens } , … )
    tools    = @( 'node v20.x', 'pwsh 7.5', … )
    timing   = <Summary() from timing.ps1: activeSeconds, excludedSeconds, claudeSeconds, phases[] >
    tier3    = @{                # present only when the live run happened
        ran; verdict ('pass'|'recorded-fail'); passRate; tokensTotal;
        builds = @( @{ attempt; result; compiled; tokens; turns; reason } , … );
        rulesMissed = @( 'shadcn-only', … )
    }
#>

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'history.ps1')

# Plain-English fixes for each known rule / failure kind (used in §3.1).
$script:Tier3FixHints = @{
    'no-suppressions'     = 'Remove the @ts-ignore / @ts-expect-error / @ts-nocheck / eslint-disable and fix the underlying error properly.'
    'shadcn-only'         = 'Replace the hand-rolled HTML primitive with the matching Shadcn component from @/components/ui/.'
    'exact-api-paths'     = 'Use the exact path from the data-service description and route the call through the shared API client (never a raw fetch()).'
    'central-styling'     = 'Move the colour/font/spacing into the central tokens in globals.css and reference the token, not a literal value.'
    'role-per-story'      = 'Add a non-empty role line to the story file.'
    'plain-language'      = 'Reword the user-facing checklist to drop engineering jargon (tsc, ESLint, isLoading, Skeleton, gate numbers, …).'
    'playwright-per-story'= 'Add a live Playwright test for the routable story (test.fixme is not allowed on routable stories).'
    'timed-out'           = 'The build ran past the time limit — re-run, or raise the limit, and check for an endless retry loop.'
    'did-not-build'       = "The app didn't compile — open the build log in this run folder and fix the reported build error."
    'setup'               = 'Setup failed before the run — check the setup log and install the prerequisite it named.'
}

function Format-Duration {
    param([double]$Seconds)
    if ($Seconds -lt 0) { $Seconds = 0 }
    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    if ($Seconds -lt 60) { return ($Seconds.ToString('0.#', $inv) + 's') }
    $m = [Math]::Floor($Seconds / 60)
    $s = [Math]::Round($Seconds - ($m * 60))
    return ('{0}m {1}s' -f $m, $s)
}

function Format-Tokens {
    param($Tokens)
    if ($null -eq $Tokens) { return '—' }
    return ([double]$Tokens).ToString('N0', [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-RunFailures {
    param([hashtable]$Run)
    $failures = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($g in @($Run.groups)) {
        if ([int]$g.failed -gt 0) {
            $failures.Add(@{ kind = 'group'; title = "Group '$($g.name)' had $($g.failed) failing test(s)"; hint = 'Open the group in the report detail and fix each failing test.' })
        }
    }
    if ($Run.ContainsKey('tier3') -and $Run.tier3 -and $Run.tier3.ran) {
        foreach ($rule in @($Run.tier3.rulesMissed)) {
            $hint = if ($script:Tier3FixHints.ContainsKey($rule)) { $script:Tier3FixHints[$rule] } else { 'Review the rule and correct the generated code.' }
            $failures.Add(@{ kind = 'rule'; title = "Tier 3 rule not met: $rule"; hint = $hint })
        }
        foreach ($b in @($Run.tier3.builds)) {
            if ($b.result -ne 'passed') {
                $reasonKey = "$($b.result)"
                $hint = if ($script:Tier3FixHints.ContainsKey($reasonKey)) { $script:Tier3FixHints[$reasonKey] } else { "$($b.reason)" }
                $failures.Add(@{ kind = 'build'; title = "Build attempt $($b.attempt): $($b.result)"; hint = $hint })
            }
        }
    }
    return $failures
}

function New-Tier3Report {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Run,
        [Parameter(Mandatory)][string]$OutDir,
        [string]$HistoryPath
    )
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

    $dateHuman = if ($Run.ContainsKey('dateHuman') -and $Run.dateHuman) { $Run.dateHuman } else { $Run.timestamp }
    $L = [System.Collections.Generic.List[string]]::new()
    $add = { param($x) $L.Add([string]$x) }

    # ---- title + summary ----
    & $add "# Tier 3 report — $dateHuman"
    & $add ''
    & $add "A plain-language summary of the automated Tier 3 run for the **$($Run.benchmark)** app."
    & $add ''
    $resultIcon = if ($Run.result -eq 'pass') { '✅ Passed' } else { '❌ Needs attention' }
    & $add '## The run'
    & $add ''
    & $add '| | |'
    & $add '|---|---|'
    & $add "| Result | $resultIcon |"
    & $add "| App (benchmark) | $($Run.benchmark) |"
    & $add "| AI model | $($Run.model) |"
    & $add "| Version tested | $($Run.version) |"
    & $add "| Run by | $($Run.runBy) on $($Run.machine) |"
    & $add "| When | $dateHuman |"
    if ($Run.ContainsKey('timing') -and $Run.timing) {
        # Macro estimate: the average whole-run time from comparable past runs (same
        # model + benchmark), shown next to the actual so you can see at a glance whether
        # this run took longer or shorter than usual overall. Empty on the first run.
        $runEst = $null
        if ($HistoryPath) { $runEst = Get-Tier3RunEstimate -HistoryPath $HistoryPath -Model $Run.model -Benchmark $Run.benchmark }
        & $add "| Active time | $(Format-Duration ([double]$Run.timing.activeSeconds)) |"
        if ($runEst) {
            $estActive = [double]$runEst.activeSeconds
            $diff = [double]$Run.timing.activeSeconds - $estActive
            $sign = if ($diff -ge 0) { '+' } else { '-' }
            & $add "| Estimated active time | $(Format-Duration $estActive) (this run $sign$(Format-Duration ([Math]::Abs($diff))) vs estimate) |"
        }
        & $add "| Claude's own time | $(Format-Duration ([double]$Run.timing.claudeSeconds)) |"
        if ($runEst -and $null -ne $runEst.claudeSeconds) {
            & $add "| Estimated Claude time | $(Format-Duration ([double]$runEst.claudeSeconds)) |"
        }
        & $add "| Paused / excluded | $(Format-Duration ([double]$Run.timing.excludedSeconds)) |"
    }
    if ($Run.ContainsKey('memory') -and $Run.memory -and $Run.memory.available) {
        $m = $Run.memory
        $addedGB = [Math]::Round([double]$m.addedMB / 1024, 1)
        $peakGB = [Math]::Round([double]$m.peakUsedMB / 1024, 1)
        $fits = if ($m.fitsBudget) { '✅ yes' } else { '❌ no' }
        & $add "| Memory the run added | $addedGB GB (whole-machine peak $peakGB GB) |"
        & $add "| Fits in 16 GB? | $fits |"
    }
    $tier3Ran = ($Run.ContainsKey('tier3') -and $Run.tier3 -and $Run.tier3.ran)
    if ($tier3Ran) {
        & $add "| Total AI tokens | $(Format-Tokens $Run.tier3.tokensTotal) |"
        $verdictText = if ($Run.tier3.verdict -eq 'pass') { '✅ met the rules' } else { '⚠️ fell short (recorded, not failed)' }
        & $add "| Tier 3 verdict | $verdictText |"
        if ($Run.tier3.ContainsKey('passRate')) { & $add "| Build pass-rate | $([Math]::Round([double]$Run.tier3.passRate * 100))% |" }
    }
    & $add ''

    # ---- minimum RAM (memory used during the build) ----
    if ($Run.ContainsKey('memory') -and $Run.memory -and $Run.memory.available) {
        $m = $Run.memory
        $peakGB = [Math]::Round([double]$m.peakUsedMB / 1024, 1)
        $totalGB = [Math]::Round([double]$m.totalMB / 1024, 1)
        $baseGB = [Math]::Round([double]$m.baselineUsedMB / 1024, 1)
        $addedGB = [Math]::Round([double]$m.addedMB / 1024, 1)
        $minAvailGB = [Math]::Round([double]$m.minAvailableMB / 1024, 1)
        $vmBaseGB = [Math]::Round([double]$m.assumedVmBaselineMB / 1024, 1)
        $estGB = [Math]::Round([double]$m.estimatedVmUseMB / 1024, 1)
        & $add '## Memory (minimum RAM)'
        & $add ''
        & $add "**The run itself added about $addedGB GB of memory.** (Whole-machine use peaked at $peakGB GB, but the machine was already using $baseGB GB before the run started — so the run's own footprint is the difference, ~$addedGB GB. Least free at any moment: $minAvailGB GB, on a machine with $totalGB GB.)"
        & $add ''
        if ($m.fitsBudget) {
            & $add "**A 16 GB machine should cope.** Allowing ~$vmBaseGB GB for a lean VM's own operating system plus the ~$addedGB GB this run added comes to about **$estGB GB** — comfortably under 16 GB."
        }
        else {
            & $add "**A 16 GB machine may be tight.** A lean VM's ~$vmBaseGB GB operating system plus the ~$addedGB GB this run added comes to about **$estGB GB**, which is close to or over 16 GB."
        }
        & $add ''
        & $add "> How to read this: the headline is the **added** memory, not the whole-machine peak — the peak is inflated by everything else that happened to be running here. The 16 GB verdict assumes a lean VM uses ~$vmBaseGB GB for its OS. To be 100% certain, run once on an actual 16 GB VM; this is the evidence toward that."
        & $add ''
    }

    # ---- per-group breakdown ----
    if ($Run.ContainsKey('groups') -and @($Run.groups).Count -gt 0) {
        & $add '## How each group of tests did'
        & $add ''
        & $add '| Group | Tests | Passed | Failed | Skipped | Time | Tokens |'
        & $add '|---|--:|--:|--:|--:|--:|--:|'
        foreach ($g in @($Run.groups)) {
            $tok = if ($g.ContainsKey('tokens')) { Format-Tokens $g.tokens } else { '—' }
            & $add ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} |" -f $g.name, $g.tests, $g.passed, $g.failed, $g.skipped, (Format-Duration ([double]$g.durationSeconds)), $tok)
        }
        & $add ''
    }

    # ---- §2.1 attempts (Tier 3 only) ----
    if ($tier3Ran -and @($Run.tier3.builds).Count -gt 0) {
        & $add '## 2.1 Build attempts'
        & $add ''
        & $add '| Attempt | Result | Compiled? | Tokens | Turns | Reason |'
        & $add '|--:|---|:--:|--:|--:|---|'
        foreach ($b in @($Run.tier3.builds)) {
            $compiled = if ($b.compiled) { 'yes' } else { 'no' }
            & $add ("| {0} | {1} | {2} | {3} | {4} | {5} |" -f $b.attempt, $b.result, $compiled, (Format-Tokens $b.tokens), $b.turns, $b.reason)
        }
        & $add ''
    }

    # ---- §2.2 timing: estimate vs actual per phase ----
    if ($Run.ContainsKey('timing') -and $Run.timing -and @($Run.timing.phases).Count -gt 0) {
        $estimates = @{}
        if ($HistoryPath) {
            $estimates = Get-Tier3PhaseEstimates -HistoryPath $HistoryPath -Model $Run.model -Benchmark $Run.benchmark
        }
        & $add '## 2.2 Where the time went (estimate vs actual)'
        & $add ''
        & $add '| Phase | Estimated | Actual | Difference | Claude time |'
        & $add '|---|--:|--:|--:|--:|'
        foreach ($p in @($Run.timing.phases)) {
            $actual = [double]$p.activeSeconds
            if ($estimates.ContainsKey($p.path)) {
                $est = [double]$estimates[$p.path].activeSeconds
                $diff = $actual - $est
                $sign = if ($diff -ge 0) { '+' } else { '-' }
                $diffText = "$sign$(Format-Duration ([Math]::Abs($diff)))"
                $estText = Format-Duration $est
            }
            else {
                $estText = '—'; $diffText = '—'
            }
            & $add ("| {0} | {1} | {2} | {3} | {4} |" -f $p.path, $estText, (Format-Duration $actual), $diffText, (Format-Duration ([double]$p.claudeSeconds)))
        }
        & $add ''
    }

    # ---- installed tools ----
    if ($Run.ContainsKey('tools') -and @($Run.tools).Count -gt 0) {
        & $add '## Tools on record'
        & $add ''
        foreach ($t in @($Run.tools)) { & $add "- $t" }
        & $add ''
    }

    # ---- §3.1 failure diagnosis ----
    $failures = Get-RunFailures -Run $Run
    if (@($failures).Count -gt 0) {
        & $add '## 3.1 What needs attention, and how to fix it'
        & $add ''
        foreach ($f in $failures) {
            & $add "**$($f.title)**"
            & $add ''
            & $add "- Possible fix: $($f.hint)"
            & $add ''
        }
    }

    # ---- write report ----
    $reportName = "report-$($Run.version)-$($Run.timestamp).md"
    $reportPath = Join-Path $OutDir $reportName
    Set-Content -Path $reportPath -Value ($L -join "`n") -Encoding utf8

    # ---- Fail file, only when there is something to report ----
    if (@($failures).Count -gt 0) {
        $failDir = Join-Path $OutDir 'Fail'
        if (-not (Test-Path $failDir)) { New-Item -ItemType Directory -Path $failDir -Force | Out-Null }
        $failPath = Join-Path $failDir "$($Run.timestamp).md"
        $failLines = [System.Collections.Generic.List[string]]::new()
        $failLines.Add("# Things that need attention — $dateHuman ($($Run.benchmark))")
        $failLines.Add('')
        foreach ($f in $failures) {
            $failLines.Add("## $($f.title)")
            $failLines.Add("- Possible fix: $($f.hint)")
            $failLines.Add('')
        }
        Set-Content -Path $failPath -Value ($failLines -join "`n") -Encoding utf8
    }

    return $reportPath
}
