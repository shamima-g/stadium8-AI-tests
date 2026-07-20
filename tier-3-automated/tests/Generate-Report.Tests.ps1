<#
  Pester tests for Generate-Report.ps1 — the Tier 3 report writer.
  Good case AND broken/edge case for each behaviour; each test uses its own temp folder.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Generate-Report.ps1')
    . (Join-Path $PSScriptRoot '..' 'history.ps1')

    function New-OutDir {
        $d = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-report-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        return $d
    }
    function Base-Run {
        return @{
            version = '0.1.0'; timestamp = '20260710-0630'; dateHuman = '10 July 2026, 6:30am'
            model = 'opus'; benchmark = 'transactions'; runBy = 'shamima-g'; machine = 'HOST'
            result = 'pass'
            groups = @(
                @{ name = 'Tier 1'; tests = 280; passed = 280; failed = 0; skipped = 3; durationSeconds = 18.5; tokens = 0 }
            )
            tools  = @('node v20.11', 'pwsh 7.5')
            timing = @{ activeSeconds = 900; excludedSeconds = 60; claudeSeconds = 800; phases = @(
                @{ path = 'opus/build'; activeSeconds = 150; claudeSeconds = 120 }
            ) }
            memory = @{ available = $true; peakUsedMB = 11264; totalMB = 32768; minAvailableMB = 21504; baselineUsedMB = 10240; addedMB = 1024; assumedVmBaselineMB = 4096; estimatedVmUseMB = 5120; budgetMB = 16384; fitsBudget = $true }
        }
    }
}

Describe 'A clean run' {
    It 'PASS: writes the report, includes the summary, and writes NO Fail file' {
        $out = New-OutDir
        $path = New-Tier3Report -Run (Base-Run) -OutDir $out
        Test-Path $path | Should -BeTrue
        $md = Get-Content $path -Raw
        $md | Should -Match 'Tier 3 report'
        $md | Should -Match '✅ Passed'
        $md | Should -Match 'How each group of tests did'
        Test-Path (Join-Path $out 'Fail') | Should -BeFalse
        Remove-Item $out -Recurse -Force
    }
}

Describe 'A run with a failing test group' {
    It 'PASS: writes a Fail file and a §3.1 diagnosis' {
        $out = New-OutDir
        $run = Base-Run
        $run.result = 'fail'
        $run.groups = @(@{ name = 'Tier 1'; tests = 10; passed = 8; failed = 2; skipped = 0; durationSeconds = 5; tokens = 0 })
        $path = New-Tier3Report -Run $run -OutDir $out
        (Get-Content $path -Raw) | Should -Match 'What needs attention'
        Test-Path (Join-Path $out 'Fail\20260710-0630.md') | Should -BeTrue
        Remove-Item $out -Recurse -Force
    }
}

Describe 'A Tier 3 run that fell short (recorded, not failed)' {
    It 'PASS: shows §2.1 attempts, a fix hint, and a Fail file — but result stays pass' {
        $out = New-OutDir
        $run = Base-Run
        $run.result = 'pass'   # the Tier 3 score never turns the run red
        $run.tier3 = @{
            ran = $true; verdict = 'recorded-fail'; passRate = 0.5; tokensTotal = 123456
            builds = @(
                @{ attempt = 1; result = 'non-conforming'; compiled = $true; tokens = 60000; turns = 22; reason = 'missed a rule' }
            )
            rulesMissed = @('shadcn-only')
        }
        $path = New-Tier3Report -Run $run -OutDir $out
        $md = Get-Content $path -Raw
        $md | Should -Match '2.1 Build attempts'
        $md | Should -Match '✅ Passed'                       # result still pass
        $md | Should -Match 'fell short'                       # verdict recorded
        $md | Should -Match 'Shadcn component'                 # the fix hint for shadcn-only
        Test-Path (Join-Path $out 'Fail\20260710-0630.md') | Should -BeTrue   # written down
        Remove-Item $out -Recurse -Force
    }
}

Describe 'Estimate vs actual (§2.2)' {
    It 'PASS: with matching history, shows an estimate and a difference' {
        $out = New-OutDir
        $hist = Join-Path $out 'tier3-history.jsonl'
        # a past run of the same model+benchmark, phase opus/build took 100s active
        Add-Tier3HistoryLine -HistoryPath $hist -Record @{
            timestamp = 'past'; model = 'opus'; benchmark = 'transactions'; result = 'pass'
            phases = @(@{ path = 'opus/build'; activeSeconds = 100; claudeSeconds = 90 })
        }
        # this run's opus/build took 150s => estimate ~100, diff +50s
        $path = New-Tier3Report -Run (Base-Run) -OutDir $out -HistoryPath $hist
        $md = Get-Content $path -Raw
        $md | Should -Match 'estimate vs actual'
        $md | Should -Match '\+50'                              # +50s slower than estimate
        Remove-Item $out -Recurse -Force
    }

    It 'FAIL-guard: with no history, the estimate column shows a dash' {
        $out = New-OutDir
        $path = New-Tier3Report -Run (Base-Run) -OutDir $out   # no -HistoryPath
        $md = Get-Content $path -Raw
        # the opus/build row exists but with a dash estimate
        $md | Should -Match 'opus/build \| — \|'
        Remove-Item $out -Recurse -Force
    }
}

Describe 'Macro estimate — estimated whole-run time (The run table)' {
    It 'PASS: with matching history, shows an estimated active time and the vs-estimate difference' {
        $out = New-OutDir
        $hist = Join-Path $out 'tier3-history.jsonl'
        # a past run of the same model+benchmark: whole run took 800s active, 700s Claude
        Add-Tier3HistoryLine -HistoryPath $hist -Record @{
            timestamp = 'past'; model = 'opus'; benchmark = 'transactions'; result = 'pass'
            activeSeconds = 800; claudeSeconds = 700
        }
        # this run's whole-run active is 900s => estimate 800s, diff +100s (1m 40s)
        $path = New-Tier3Report -Run (Base-Run) -OutDir $out -HistoryPath $hist
        $md = Get-Content $path -Raw
        $md | Should -Match 'Estimated active time'
        $md | Should -Match 'vs estimate'
        $md | Should -Match '\+1m 40s'                          # 900 actual - 800 estimate
        $md | Should -Match 'Estimated Claude time'
        Remove-Item $out -Recurse -Force
    }

    It 'FAIL-guard: with no history, no macro estimate row appears (actual only)' {
        $out = New-OutDir
        $path = New-Tier3Report -Run (Base-Run) -OutDir $out   # no -HistoryPath
        $md = Get-Content $path -Raw
        $md | Should -Match 'Active time'
        $md | Should -Not -Match 'Estimated active time'
        Remove-Item $out -Recurse -Force
    }
}

Describe 'Memory (minimum RAM) section' {
    It 'PASS: reports peak memory and the 16 GB verdict when memory is present' {
        $out = New-OutDir
        $path = New-Tier3Report -Run (Base-Run) -OutDir $out
        $md = Get-Content $path -Raw
        $md | Should -Match 'Memory \(minimum RAM\)'
        $md | Should -Match 'added about 1 GB'      # addedMB 1024 -> 1 GB (the headline)
        $md | Should -Match 'Fits in 16 GB'
        $md | Should -Match 'should cope'
        Remove-Item $out -Recurse -Force
    }

    It 'PASS: says it may be tight when the run adds enough to exceed 16 GB on a lean VM' {
        $out = New-OutDir
        $run = Base-Run
        # a big increment: 13 GB added + 4 GB assumed VM baseline = 17 GB estimated => over 16 GB
        $run.memory = @{ available = $true; peakUsedMB = 30720; totalMB = 32768; minAvailableMB = 2048; baselineUsedMB = 17408; addedMB = 13312; assumedVmBaselineMB = 4096; estimatedVmUseMB = 17408; budgetMB = 16384; fitsBudget = $false }
        $path = New-Tier3Report -Run $run -OutDir $out
        (Get-Content $path -Raw) | Should -Match 'may be tight'
        Remove-Item $out -Recurse -Force
    }
}

Describe 'Formatting helpers' {
    It 'PASS: durations format as seconds or m/s' {
        Format-Duration 5    | Should -Be '5s'
        Format-Duration 90   | Should -Be '1m 30s'
    }
    It 'PASS: tokens format with separators; null => dash' {
        Format-Tokens 123456 | Should -Be '123,456'
        Format-Tokens $null  | Should -Be '—'
    }
}
