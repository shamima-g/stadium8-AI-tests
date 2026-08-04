<#
  Pester tests for Run-Experiment.ps1 — the pure aggregation/reporting pieces. The live runs
  (Run-QATests spawns) are exercised only in a real experiment, not here.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Run-Experiment.ps1')

    # A fake history row (what Get-Tier3History yields, minus the fields we don't read).
    function New-Row {
        param([string]$Model = 'opus', [double]$Tokens, [double]$Claude, [double]$Active, [double]$Peak, [double]$Pass = 1.0, [int]$Epics = 2, [bool]$Fits = $true, [string]$Ts = '20260101-0000')
        return @{ model = $Model; tokensTotal = $Tokens; claudeSeconds = $Claude; activeSeconds = $Active; peakMemoryUsedMB = $Peak; passRate = $Pass; epicsBuilt = $Epics; memoryFits16GB = $Fits; timestamp = $Ts }
    }
}

Describe 'Results-key routing matches Run-QATests exactly' {
    It 'PASS: build has no suffix; plan/concurrent add theirs; target adds @<target>-<ref>' {
        Get-ExperimentResultsKey -Benchmark 'minimal' -Scenario 'build'      | Should -Be 'minimal'
        Get-ExperimentResultsKey -Benchmark 'minimal' -Scenario 'plan'       | Should -Be 'minimal-plan'
        Get-ExperimentResultsKey -Benchmark 'minimal' -Scenario 'concurrent' | Should -Be 'minimal-concurrent'
        Get-ExperimentResultsKey -Benchmark 'minimal' -Scenario 'plan' -Target 'dev' -Ref 'v1.2.0' | Should -Be 'minimal@dev-v1.2.0-plan'
    }
    It 'FAIL-guard: a target with no ref defaults the ref segment to "default"' {
        Get-ExperimentResultsKey -Benchmark 'minimal' -Scenario 'build' -Target 'release' | Should -Be 'minimal@release-default'
    }
}

Describe 'Median' {
    It 'PASS: odd count returns the middle; even count averages the two middle' {
        Get-Median @(3, 1, 2)        | Should -Be 2
        Get-Median @(10, 20, 30, 40) | Should -Be 25
        Get-Median @(7)              | Should -Be 7
    }
    It 'FAIL-guard: nulls are dropped; an all-null/empty set returns $null' {
        Get-Median @(2, $null, 4)    | Should -Be 3
        Get-Median @()               | Should -BeNullOrEmpty
        Get-Median @($null, $null)   | Should -BeNullOrEmpty
    }
}

Describe 'Batch selection — filter by model, keep the last N' {
    It 'PASS: keeps only the model, then the newest N rows' {
        $rows = @(
            (New-Row -Model 'opus' -Tokens 1 -Ts 'a'), (New-Row -Model 'sonnet' -Tokens 2 -Ts 'b'),
            (New-Row -Model 'opus' -Tokens 3 -Ts 'c'), (New-Row -Model 'opus' -Tokens 4 -Ts 'd')
        )
        $batch = Select-BatchRuns -Rows $rows -Model 'opus' -Runs 2
        @($batch).Count | Should -Be 2
        (Get-ExpProp $batch[0] 'timestamp') | Should -Be 'c'   # the last 2 opus rows
        (Get-ExpProp $batch[1] 'timestamp') | Should -Be 'd'
    }
    It 'FAIL-guard: fewer rows than N keeps them all; no model match keeps none' {
        $rows = @((New-Row -Model 'opus' -Tokens 1), (New-Row -Model 'opus' -Tokens 2))
        @(Select-BatchRuns -Rows $rows -Model 'opus' -Runs 5).Count | Should -Be 2
        @(Select-BatchRuns -Rows $rows -Model 'haiku' -Runs 5).Count | Should -Be 0
    }
}

Describe 'Aggregate — median/min/max/n per metric, including peak memory' {
    It 'PASS: computes stats over the batch for every requested key' {
        $rows = @(
            (New-Row -Tokens 1000 -Claude 100 -Active 120 -Peak 18000),
            (New-Row -Tokens 2000 -Claude 200 -Active 240 -Peak 20000),
            (New-Row -Tokens 3000 -Claude 300 -Active 360 -Peak 22000)
        )
        $agg = Get-ArmAggregate -Rows $rows -Keys @('tokensTotal', 'peakMemoryUsedMB')
        $agg['tokensTotal'].median | Should -Be 2000
        $agg['tokensTotal'].min    | Should -Be 1000
        $agg['tokensTotal'].max    | Should -Be 3000
        $agg['tokensTotal'].n      | Should -Be 3
        $agg['peakMemoryUsedMB'].median | Should -Be 20000   # the added resource axis
    }
    It 'FAIL-guard: a metric absent from the rows aggregates to n=0 / null median, not an error' {
        $agg = Get-ArmAggregate -Rows @((New-Row -Tokens 5)) -Keys @('costUsd')
        $agg['costUsd'].n      | Should -Be 0
        $agg['costUsd'].median | Should -BeNullOrEmpty
    }
}

Describe 'Interleave schedule — counterbalances calendar drift' {
    It 'PASS: default interleave reverses arm order on alternate cycles (A B B A)' {
        $s = Get-ExperimentSchedule -Arms @('build', 'plan') -Runs 2
        @($s) -join ',' | Should -Be 'build,plan,plan,build'
    }
    It 'PASS: -NoInterleave keeps a fixed order each cycle' {
        $s = Get-ExperimentSchedule -Arms @('build', 'plan') -Runs 2 -NoInterleave
        @($s) -join ',' | Should -Be 'build,plan,build,plan'
    }
}

Describe 'Report — the saved comparison, with the peak-memory axis' {
    It 'PASS: renders the aggregate, delta, and a dedicated peak-memory section' {
        $keys = @('tokensTotal', 'claudeSeconds', 'activeSeconds', 'peakMemoryUsedMB', 'passRate', 'epicsBuilt')
        $buildRows = @((New-Row -Tokens 1000 -Claude 100 -Active 120 -Peak 18000), (New-Row -Tokens 1200 -Claude 110 -Active 130 -Peak 18500))
        $planRows = @((New-Row -Tokens 1400 -Claude 130 -Active 150 -Peak 18200), (New-Row -Tokens 1500 -Claude 140 -Active 160 -Peak 18800))
        $agg = @{ build = (Get-ArmAggregate -Rows $buildRows -Keys $keys); plan = (Get-ArmAggregate -Rows $planRows -Keys $keys) }
        $raw = @{ build = $buildRows; plan = $planRows }
        $setup = @{ benchmark = 'minimal'; model = 'opus'; template = 'local checkout'; arms = @('build', 'plan'); runs = 2; order = 'interleaved'; generatedAt = 'x' }

        $md = New-ExperimentReport -Setup $setup -Aggregates $agg -RawRows $raw -Baseline 'build'
        $md | Should -Match 'Experiment report'
        $md | Should -Match 'Peak memory \(resource axis\)'   # the added axis has its own section
        $md | Should -Match 'Δ vs baseline'                   # baseline->arm deltas rendered
        $md | Should -Match 'Fits 16 GB'
        $md | Should -Match 'build'
        $md | Should -Match 'plan'
    }
    It 'FAIL-guard: an arm with no runs renders a "no runs" note, not a crash' {
        $keys = @('tokensTotal', 'peakMemoryUsedMB')
        $agg = @{ build = (Get-ArmAggregate -Rows @() -Keys $keys); plan = (Get-ArmAggregate -Rows @() -Keys $keys) }
        $setup = @{ benchmark = 'minimal'; model = 'opus'; template = 'local'; arms = @('build', 'plan'); runs = 0; order = 'x'; generatedAt = 'x' }
        $md = New-ExperimentReport -Setup $setup -Aggregates $agg -RawRows @{ build = @(); plan = @() } -Baseline 'build'
        $md | Should -Match 'no runs found'
    }
}
