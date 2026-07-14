<#
  Integration tests for Run-QATests.ps1 — the master runner.
  Uses -ReplayResult so the whole pipeline runs WITHOUT a live AI (Part 1 proof).
#>

BeforeAll {
    # Dot-source exposes Invoke-RunQATests without running the script's main.
    . (Join-Path $PSScriptRoot '..' 'Run-QATests.ps1')

    function New-Sandbox {
        $d = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-run-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        return $d
    }
    function Write-SampleResult {
        param([string]$Path)
        $json = @'
{
  "version":"0.1.0","timestamp":"placeholder","model":"opus","benchmark":"transactions",
  "runBy":"tester","machine":"HOST","result":"pass",
  "groups":[{"name":"Tier 1","tests":280,"passed":280,"failed":0,"skipped":3,"durationSeconds":18.5,"tokens":0}],
  "tools":["node v20.11","pwsh 7.5"],
  "timing":{"activeSeconds":900,"excludedSeconds":60,"claudeSeconds":800,
    "phases":[{"path":"opus/build","activeSeconds":150,"claudeSeconds":120}]},
  "tier3":{"ran":true,"verdict":"pass","passRate":1.0,"tokensTotal":123456,
    "builds":[{"attempt":1,"result":"passed","compiled":true,"tokens":123456,"turns":30,"reason":"ok"}],
    "rulesMissed":[]}
}
'@
        Set-Content -Path $Path -Value $json -Encoding utf8
    }
}

Describe 'Replay mode — full pipeline, no live AI' {
    It 'PASS: writes report + history + charts under the per-benchmark run folder' {
        $sb = New-Sandbox
        $sample = Join-Path $sb 'sample-run.json'; Write-SampleResult -Path $sample
        $results = Join-Path $sb 'TestResults'
        $summary = Invoke-RunQATests -IncludeTier3 $false -Tier3Model 'opus' -Benchmark 'transactions' `
            -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true `
            -ReplayResult $sample -Timestamp 'TS1' -TestResultsRoot $results

        $expectedReport = Join-Path $results 'transactions\opus\TS1\report-0.1.0-TS1.md'
        Test-Path $expectedReport | Should -BeTrue
        Test-Path (Join-Path $results 'transactions\tier3-history.jsonl') | Should -BeTrue
        Test-Path (Join-Path $results 'transactions\tier3-metrics.html')  | Should -BeTrue
        @(Select-String -Path $expectedReport -Pattern 'Build attempts' -SimpleMatch).Count | Should -BeGreaterThan 0
        @(Select-String -Path (Join-Path $results 'transactions\tier3-metrics.html') -Pattern 'opus' -SimpleMatch).Count | Should -BeGreaterThan 0
        Remove-Item $sb -Recurse -Force
    }

    It 'PASS: a second run appends to the SAME per-benchmark history' {
        $sb = New-Sandbox
        $sample = Join-Path $sb 'sample-run.json'; Write-SampleResult -Path $sample
        $results = Join-Path $sb 'TestResults'
        Invoke-RunQATests -IncludeTier3 $false -Tier3Model 'opus' -Benchmark 'transactions' `
            -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true `
            -ReplayResult $sample -Timestamp 'TS1' -TestResultsRoot $results | Out-Null
        Invoke-RunQATests -IncludeTier3 $false -Tier3Model 'sonnet' -Benchmark 'transactions' `
            -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true `
            -ReplayResult $sample -Timestamp 'TS2' -TestResultsRoot $results | Out-Null
        @(Get-Content (Join-Path $results 'transactions\tier3-history.jsonl')).Count | Should -Be 2
        Remove-Item $sb -Recurse -Force
    }

    It 'PASS: different benchmarks stay in separate folders (nothing mixed)' {
        $sb = New-Sandbox
        $sample = Join-Path $sb 'sample-run.json'; Write-SampleResult -Path $sample
        $results = Join-Path $sb 'TestResults'
        Invoke-RunQATests -IncludeTier3 $false -Tier3Model 'opus' -Benchmark 'transactions' `
            -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true `
            -ReplayResult $sample -Timestamp 'TS1' -TestResultsRoot $results | Out-Null
        Invoke-RunQATests -IncludeTier3 $false -Tier3Model 'opus' -Benchmark 'payments' `
            -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true `
            -ReplayResult $sample -Timestamp 'TS1' -TestResultsRoot $results | Out-Null
        Test-Path (Join-Path $results 'transactions\tier3-history.jsonl') | Should -BeTrue
        Test-Path (Join-Path $results 'payments\tier3-history.jsonl')     | Should -BeTrue
        Remove-Item $sb -Recurse -Force
    }
}

Describe 'Resume — find the interrupted run' {
    BeforeAll {
        function New-RunFolder {
            param([string]$Root, [string]$Ts, [switch]$WithSession, [switch]$WithReport)
            $f = Join-Path $Root "transactions\opus\$Ts"
            New-Item -ItemType Directory -Path (Join-Path $f 'tier3-live') -Force | Out-Null
            if ($WithSession) { Set-Content -Path (Join-Path $f 'tier3-live\session.id') -Value 'sess-abc' -Encoding utf8 }
            if ($WithReport) { Set-Content -Path (Join-Path $f 'report-0.1.0-x.md') -Value '# r' -Encoding utf8 }
            return $f
        }
    }

    It 'PASS: returns the newest started-but-unfinished run (session, no report)' {
        $sb = New-Sandbox; $results = Join-Path $sb 'TestResults'
        New-RunFolder -Root $results -Ts '20260710-0900' -WithSession -WithReport | Out-Null  # finished
        New-RunFolder -Root $results -Ts '20260710-1000' -WithSession | Out-Null              # interrupted (older)
        New-RunFolder -Root $results -Ts '20260710-1100' -WithSession | Out-Null              # interrupted (newest)
        Find-IncompleteRun -TestResultsRoot $results -Benchmark 'transactions' -Model 'opus' | Should -Be '20260710-1100'
        Remove-Item $sb -Recurse -Force
    }

    It 'PASS: a finished run (has report) is not offered for resume' {
        $sb = New-Sandbox; $results = Join-Path $sb 'TestResults'
        New-RunFolder -Root $results -Ts '20260710-0900' -WithSession -WithReport | Out-Null
        Find-IncompleteRun -TestResultsRoot $results -Benchmark 'transactions' -Model 'opus' | Should -BeNullOrEmpty
        Remove-Item $sb -Recurse -Force
    }

    It 'FAIL-guard: -Resume with nothing to resume errors clearly' {
        $sb = New-Sandbox
        { Invoke-RunQATests -IncludeTier3 $false -Tier3Model 'opus' -Benchmark 'transactions' `
            -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true -Resume $true `
            -ReplayResult '' -Timestamp '' -TestResultsRoot (Join-Path $sb 'TestResults') } |
            Should -Throw -ExpectedMessage '*Nothing to resume*'
        Remove-Item $sb -Recurse -Force
    }
}

Describe 'Boundaries and errors' {
    It 'FAIL-guard: the live path rejects an unknown benchmark before doing anything costly' {
        $sb = New-Sandbox
        { Invoke-RunQATests -IncludeTier3 $true -Tier3Model 'opus' -Benchmark 'no-such-benchmark-xyz' `
            -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true `
            -ReplayResult '' -Timestamp 'TS1' -TestResultsRoot (Join-Path $sb 'TestResults') } |
            Should -Throw -ExpectedMessage '*not found*'
        Remove-Item $sb -Recurse -Force
    }

    It 'FAIL-guard: no live and no replay is a clear error' {
        $sb = New-Sandbox
        { Invoke-RunQATests -IncludeTier3 $false -Tier3Model 'opus' -Benchmark 'transactions' `
            -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true `
            -ReplayResult '' -Timestamp 'TS1' -TestResultsRoot (Join-Path $sb 'TestResults') } |
            Should -Throw -ExpectedMessage '*Nothing to run*'
        Remove-Item $sb -Recurse -Force
    }
}
