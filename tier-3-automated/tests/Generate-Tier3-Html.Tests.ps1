<#
  Pester tests for Generate-Tier3-Html.ps1 — the self-contained charts page.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Generate-Tier3-Html.ps1')
    . (Join-Path $PSScriptRoot '..' 'history.ps1')

    function New-Workspace {
        $d = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-html-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        return $d
    }
    function Seed {
        param([string]$HistoryPath, [string]$Model = 'opus', [string]$Result = 'pass', [array]$Rules = @(), [double]$Active = 100, [string]$Ts = '20260710-0600')
        Add-Tier3HistoryLine -HistoryPath $HistoryPath -Record @{
            timestamp = $Ts; version = '0.1.0'; model = $Model; benchmark = 'transactions'; result = $Result
            activeSeconds = $Active; claudeSeconds = ($Active * 0.8); tokensTotal = 50000; passRate = 1.0
            rulesMissed = $Rules
        }
    }
}

Describe 'Master index (index.md across benchmarks)' {
    It 'PASS: lists each benchmark with its runs and a report link' {
        $ws = New-Workspace
        $results = Join-Path $ws 'TestResults'
        Seed -HistoryPath (Join-Path $results 'transactions\tier3-history.jsonl') -Model 'opus' -Ts '20260710-1124'
        Seed -HistoryPath (Join-Path $results 'payments\tier3-history.jsonl') -Model 'sonnet' -Ts '20260710-1200'
        $index = Update-Tier3Index -TestResultsRoot $results
        Test-Path $index | Should -BeTrue
        $md = Get-Content $index -Raw
        $md | Should -Match '## transactions'
        $md | Should -Match '## payments'
        $md | Should -Match 'transactions/opus/20260710-1124/report-0\.1\.0-20260710-1124\.md'
        Remove-Item $ws -Recurse -Force
    }
    It 'FAIL-guard: an empty results root yields a "no runs" index, not an error' {
        $ws = New-Workspace
        $results = Join-Path $ws 'TestResults'; New-Item -ItemType Directory -Path $results -Force | Out-Null
        $index = Update-Tier3Index -TestResultsRoot $results
        (Get-Content $index -Raw) | Should -Match 'No runs recorded yet'
        Remove-Item $ws -Recurse -Force
    }
}

Describe 'Empty history' {
    It 'PASS: writes a valid "no runs yet" page' {
        $ws = New-Workspace
        $out = New-Tier3Html -HistoryPath (Join-Path $ws 'tier3-history.jsonl') -OutPath (Join-Path $ws 'tier3-metrics.html') -Benchmark 'transactions'
        Test-Path $out | Should -BeTrue
        $html = Get-Content $out -Raw
        $html | Should -Match 'No Tier 3 runs'
        $html | Should -Match '<!doctype html>'
        Remove-Item $ws -Recurse -Force
    }
}

Describe 'Self-contained (no internet)' {
    It 'PASS: the page references no external http/https resources' {
        $ws = New-Workspace
        $h = Join-Path $ws 'tier3-history.jsonl'
        Seed -HistoryPath $h
        $out = New-Tier3Html -HistoryPath $h -OutPath (Join-Path $ws 'tier3-metrics.html') -Benchmark 'transactions'
        $html = Get-Content $out -Raw
        $html | Should -Not -Match 'http://'
        $html | Should -Not -Match 'https://'
        $html | Should -Not -Match '<script'
        Remove-Item $ws -Recurse -Force
    }
}

Describe 'Last-10-per-model + content' {
    It 'PASS: shows a section per model and caps at 10 rows' {
        $ws = New-Workspace
        $h = Join-Path $ws 'tier3-history.jsonl'
        1..12 | ForEach-Object { Seed -HistoryPath $h -Model 'opus' -Ts "202607$($_.ToString('00'))" }
        Seed -HistoryPath $h -Model 'sonnet' -Ts '20260701'
        $out = New-Tier3Html -HistoryPath $h -OutPath (Join-Path $ws 'tier3-metrics.html') -Benchmark 'transactions'
        $html = Get-Content $out -Raw
        $html | Should -Match '<h3>opus</h3>'
        $html | Should -Match '<h3>sonnet</h3>'
        # 12 opus runs recorded but only 10 shown in the opus table
        $opusSection = [regex]::Match($html, '<h3>opus</h3>.*?</table>', 'Singleline').Value
        ([regex]::Matches($opusSection, '<tr>')).Count | Should -Be 11   # 1 header + 10 rows
        Remove-Item $ws -Recurse -Force
    }

    It 'PASS: tallies most-flagged rules across runs' {
        $ws = New-Workspace
        $h = Join-Path $ws 'tier3-history.jsonl'
        Seed -HistoryPath $h -Rules @('shadcn-only', 'plain-language')
        Seed -HistoryPath $h -Rules @('shadcn-only')
        $out = New-Tier3Html -HistoryPath $h -OutPath (Join-Path $ws 'tier3-metrics.html') -Benchmark 'transactions'
        $html = Get-Content $out -Raw
        $html | Should -Match 'Most-flagged rules'
        # shadcn-only flagged twice
        $html | Should -Match 'shadcn-only'
        Remove-Item $ws -Recurse -Force
    }

    It 'FAIL-guard: a run missing newer fields still renders (no crash)' {
        $ws = New-Workspace
        $h = Join-Path $ws 'tier3-history.jsonl'
        # an old-style line without tokensTotal / passRate / rulesMissed
        Add-Tier3HistoryLine -HistoryPath $h -Record @{ timestamp = 'old'; version = '0.0.1'; model = 'opus'; benchmark = 'transactions'; result = 'pass' }
        $out = New-Tier3Html -HistoryPath $h -OutPath (Join-Path $ws 'tier3-metrics.html') -Benchmark 'transactions'
        (Get-Content $out -Raw) | Should -Match '<h3>opus</h3>'
        Remove-Item $ws -Recurse -Force
    }
}
