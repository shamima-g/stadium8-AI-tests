<#
  Pester tests for history.ps1 — the per-benchmark run history.
  Good case AND broken/edge case for each behaviour; each test cleans up its temp file.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'history.ps1')

    function New-HistoryPath {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-history-" + [Guid]::NewGuid().ToString('N'))
        return (Join-Path $dir 'tier3-history.jsonl')
    }
    function Rec {
        param([string]$Model = 'opus', [string]$Benchmark = 'transactions', [array]$Phases = @())
        return @{ timestamp = '20260710-0600'; model = $Model; benchmark = $Benchmark; result = 'pass'; phases = $Phases }
    }
}

Describe 'Append, never rewrite' {
    It 'PASS: each call adds exactly one line and leaves earlier lines intact' {
        $h = New-HistoryPath
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Model 'opus')
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Model 'sonnet')
        @(Get-Content $h).Count | Should -Be 2
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Model 'opus')
        @(Get-Content $h).Count | Should -Be 3
        # first line still the original opus record
        ((Get-Content $h)[0] | ConvertFrom-Json).model | Should -Be 'opus'
        Remove-Item (Split-Path $h) -Recurse -Force
    }

    It 'FAIL-guard: reading a missing history file returns empty, not an error' {
        $h = New-HistoryPath
        @(Get-Tier3History -HistoryPath $h).Count | Should -Be 0
    }
}

Describe 'Filtering and last-N-per-model' {
    It 'PASS: filters by model and benchmark' {
        $h = New-HistoryPath
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Model 'opus'   -Benchmark 'transactions')
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Model 'sonnet' -Benchmark 'transactions')
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Model 'opus'   -Benchmark 'other')
        @(Get-Tier3History -HistoryPath $h -Model 'opus').Count | Should -Be 2
        @(Get-Tier3History -HistoryPath $h -Model 'opus' -Benchmark 'transactions').Count | Should -Be 1
        Remove-Item (Split-Path $h) -Recurse -Force
    }

    It 'PASS: last-N-per-model returns newest first, capped at N, grouped by model' {
        $h = New-HistoryPath
        1..12 | ForEach-Object {
            $r = Rec -Model 'opus'; $r.timestamp = "202607$($_.ToString('00'))"
            Add-Tier3HistoryLine -HistoryPath $h -Record $r
        }
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Model 'sonnet')
        $recent = Get-Tier3RecentPerModel -HistoryPath $h -PerModel 10
        @($recent['opus']).Count   | Should -Be 10          # capped at 10 of the 12
        @($recent['sonnet']).Count | Should -Be 1
        $recent['opus'][0].timestamp | Should -Be '20260712' # newest first
        Remove-Item (Split-Path $h) -Recurse -Force
    }
}

Describe 'Phase estimates (basis for estimate-vs-actual)' {
    It 'PASS: averages per-phase active/Claude seconds across matching runs' {
        $h = New-HistoryPath
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Phases @(
            @{ path = 'opus/build'; activeSeconds = 100; claudeSeconds = 80 }
        ))
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Phases @(
            @{ path = 'opus/build'; activeSeconds = 200; claudeSeconds = 120 }
        ))
        $est = Get-Tier3PhaseEstimates -HistoryPath $h -Model 'opus' -Benchmark 'transactions'
        $est['opus/build'].activeSeconds | Should -Be 150
        $est['opus/build'].claudeSeconds | Should -Be 100
        $est['opus/build'].samples       | Should -Be 2
        Remove-Item (Split-Path $h) -Recurse -Force
    }

    It 'FAIL-guard: no comparable history yields no estimate (first run shows none)' {
        $h = New-HistoryPath
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Model 'opus' -Phases @(
            @{ path = 'opus/build'; activeSeconds = 100; claudeSeconds = 80 }
        ))
        # different model => no matching history for sonnet
        $est = Get-Tier3PhaseEstimates -HistoryPath $h -Model 'sonnet' -Benchmark 'transactions'
        $est.Keys.Count | Should -Be 0
        Remove-Item (Split-Path $h) -Recurse -Force
    }

    It 'FAIL-guard: an older line with no phases field is skipped, not fatal' {
        $h = New-HistoryPath
        Add-Tier3HistoryLine -HistoryPath $h -Record @{ timestamp = 'old'; model = 'opus'; benchmark = 'transactions'; result = 'pass' }
        Add-Tier3HistoryLine -HistoryPath $h -Record (Rec -Phases @(
            @{ path = 'opus/build'; activeSeconds = 100; claudeSeconds = 80 }
        ))
        $est = Get-Tier3PhaseEstimates -HistoryPath $h -Model 'opus' -Benchmark 'transactions'
        $est['opus/build'].samples | Should -Be 1
        Remove-Item (Split-Path $h) -Recurse -Force
    }
}

Describe 'Run estimate (basis for the MACRO estimate)' {
    It 'PASS: averages whole-run active/Claude seconds across matching runs' {
        $h = New-HistoryPath
        Add-Tier3HistoryLine -HistoryPath $h -Record @{ timestamp = 'r1'; model = 'opus'; benchmark = 'transactions'; result = 'pass'; activeSeconds = 800;  claudeSeconds = 600 }
        Add-Tier3HistoryLine -HistoryPath $h -Record @{ timestamp = 'r2'; model = 'opus'; benchmark = 'transactions'; result = 'pass'; activeSeconds = 1000; claudeSeconds = 800 }
        $est = Get-Tier3RunEstimate -HistoryPath $h -Model 'opus' -Benchmark 'transactions'
        $est.activeSeconds | Should -Be 900
        $est.claudeSeconds | Should -Be 700
        $est.samples       | Should -Be 2
        Remove-Item (Split-Path $h) -Recurse -Force
    }

    It 'PASS: filters by model + benchmark (a different model is not averaged in)' {
        $h = New-HistoryPath
        Add-Tier3HistoryLine -HistoryPath $h -Record @{ timestamp = 'r1'; model = 'opus';   benchmark = 'transactions'; result = 'pass'; activeSeconds = 800; claudeSeconds = 600 }
        Add-Tier3HistoryLine -HistoryPath $h -Record @{ timestamp = 'r2'; model = 'sonnet'; benchmark = 'transactions'; result = 'pass'; activeSeconds = 200; claudeSeconds = 100 }
        $est = Get-Tier3RunEstimate -HistoryPath $h -Model 'opus' -Benchmark 'transactions'
        $est.activeSeconds | Should -Be 800
        $est.samples       | Should -Be 1
        Remove-Item (Split-Path $h) -Recurse -Force
    }

    It 'FAIL-guard: no comparable history yields $null (first run shows no macro estimate)' {
        $h = New-HistoryPath
        Add-Tier3HistoryLine -HistoryPath $h -Record @{ timestamp = 'r1'; model = 'opus'; benchmark = 'transactions'; result = 'pass'; activeSeconds = 800; claudeSeconds = 600 }
        Get-Tier3RunEstimate -HistoryPath $h -Model 'sonnet' -Benchmark 'transactions' | Should -BeNullOrEmpty
        Remove-Item (Split-Path $h) -Recurse -Force
    }

    It 'FAIL-guard: an older line with no activeSeconds is skipped; claude missing => $null claude' {
        $h = New-HistoryPath
        Add-Tier3HistoryLine -HistoryPath $h -Record @{ timestamp = 'old'; model = 'opus'; benchmark = 'transactions'; result = 'pass' }
        Add-Tier3HistoryLine -HistoryPath $h -Record @{ timestamp = 'r1';  model = 'opus'; benchmark = 'transactions'; result = 'pass'; activeSeconds = 500 }
        $est = Get-Tier3RunEstimate -HistoryPath $h -Model 'opus' -Benchmark 'transactions'
        $est.activeSeconds | Should -Be 500
        $est.samples       | Should -Be 1     # the no-activeSeconds line is not counted
        $est.claudeSeconds | Should -BeNullOrEmpty
        Remove-Item (Split-Path $h) -Recurse -Force
    }
}
