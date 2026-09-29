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

Describe 'Target label slug' {
    It 'PASS: null with no target; formats target-ref; defaults a missing ref to "default"' {
        Get-Tier3TargetLabel -Target ''       -Ref ''        | Should -BeNullOrEmpty
        Get-Tier3TargetLabel -Target 'release' -Ref 'v1.1.0' | Should -Be 'release-v1.1.0'
        Get-Tier3TargetLabel -Target 'dev'                    | Should -Be 'dev-default'
    }
}

Describe 'Resolve-Tier3Template' {
    It 'PASS: no target returns the parent (local) template and a null label — the default' {
        $qa = New-Sandbox
        $res = Resolve-Tier3Template -QaRoot $qa
        $res.label | Should -BeNullOrEmpty
        $res.root  | Should -Be (Resolve-Path (Join-Path $qa '..')).Path
        Remove-Item $qa -Recurse -Force
    }

    It 'PASS: a target clones the channel@ref (repo from targets.json) and returns its checkout' {
        $qa = New-Sandbox
        Set-Content -Path (Join-Path $qa 'targets.json') -Encoding utf8 -Value '{"targets":{"dev":{"repo":"https://example.test/dev"},"release":{"repo":"https://example.test/rel"}}}'
        $seen = @{}
        $cloner = { param($repo, $ref, $dest) $seen.repo = $repo; $seen.ref = $ref; $seen.dest = $dest; New-Item -ItemType Directory -Path $dest -Force | Out-Null }
        $res = Resolve-Tier3Template -Target 'release' -Ref 'v1.1.0' -QaRoot $qa -Cloner $cloner
        $res.label   | Should -Be 'release-v1.1.0'
        $seen.repo   | Should -Be 'https://example.test/rel'
        $seen.ref    | Should -Be 'v1.1.0'
        $res.root    | Should -Match 'release-v1\.1\.0$'
        Remove-Item $qa -Recurse -Force
    }

    It 'FAIL-guard: an unknown target throws and lists the known ones' {
        $qa = New-Sandbox
        Set-Content -Path (Join-Path $qa 'targets.json') -Encoding utf8 -Value '{"targets":{"dev":{"repo":"r1"},"release":{"repo":"r2"}}}'
        { Resolve-Tier3Template -Target 'nope' -QaRoot $qa -Cloner { param($a,$b,$c) } } |
            Should -Throw -ExpectedMessage '*Unknown target*release*'
        Remove-Item $qa -Recurse -Force
    }

    It 'FAIL-guard: a missing targets.json is a clear error, not a crash' {
        $qa = New-Sandbox
        { Resolve-Tier3Template -Target 'dev' -QaRoot $qa } | Should -Throw -ExpectedMessage '*targets.json*'
        Remove-Item $qa -Recurse -Force
    }

    It 'PASS: -TemplateRoot builds against a local checkout (no clone) — label local-*, ref local (B4)' {
        $qa = New-Sandbox
        $tmpl = New-Sandbox; New-Item -ItemType Directory -Path (Join-Path $tmpl '.claude') -Force | Out-Null
        # Tripwire: the clone branch must NEVER run for a local checkout.
        $res = Resolve-Tier3Template -TemplateRoot $tmpl -QaRoot $qa -Cloner { throw 'clone must not happen for -TemplateRoot' }
        $res.root  | Should -Be (Resolve-Path $tmpl).Path
        $res.label | Should -Match '^local-'
        $res.ref   | Should -Be 'local'
        Remove-Item $qa, $tmpl -Recurse -Force
    }

    It 'PASS: an empty/unset -TemplateRoot falls through to the default (the call site always passes it) (B4)' {
        $qa = New-Sandbox
        (Resolve-Tier3Template -TemplateRoot '' -QaRoot $qa).label   | Should -BeNullOrEmpty
        (Resolve-Tier3Template -TemplateRoot $null -QaRoot $qa).root | Should -Be (Resolve-Path (Join-Path $qa '..')).Path
        Remove-Item $qa -Recurse -Force
    }

    It 'FAIL-guard: a -TemplateRoot whose .claude is a FILE (not a dir) is rejected (B4)' {
        $qa = New-Sandbox; $tmpl = New-Sandbox
        Set-Content -Path (Join-Path $tmpl '.claude') -Value 'not a dir' -Encoding utf8
        { Resolve-Tier3Template -TemplateRoot $tmpl -QaRoot $qa } | Should -Throw -ExpectedMessage '*not a Stadium-8 template*'
        Remove-Item $qa, $tmpl -Recurse -Force
    }

    It 'FAIL-guard: a non-existent -TemplateRoot is a clear error (B4)' {
        $qa = New-Sandbox
        { Resolve-Tier3Template -TemplateRoot (Join-Path $qa 'nope') -QaRoot $qa } |
            Should -Throw -ExpectedMessage '*does not exist*'
        Remove-Item $qa -Recurse -Force
    }

    It 'FAIL-guard: a -TemplateRoot without a .claude/ template is rejected (B4)' {
        $qa = New-Sandbox; $tmpl = New-Sandbox   # no .claude
        { Resolve-Tier3Template -TemplateRoot $tmpl -QaRoot $qa } |
            Should -Throw -ExpectedMessage '*not a Stadium-8 template*'
        Remove-Item $qa, $tmpl -Recurse -Force
    }

    It 'FAIL-guard: -Target and -TemplateRoot together is rejected (B4)' {
        $qa = New-Sandbox; $tmpl = New-Sandbox; New-Item -ItemType Directory -Path (Join-Path $tmpl '.claude') -Force | Out-Null
        { Resolve-Tier3Template -Target 'dev' -TemplateRoot $tmpl -QaRoot $qa } |
            Should -Throw -ExpectedMessage '*not both*'
        Remove-Item $qa, $tmpl -Recurse -Force
    }
}

Describe 'Targeted run — dev/release @ ref (kept separate)' {
    It 'PASS: -Target files results under <benchmark>@<target>-<ref> and records the template' {
        $sb = New-Sandbox
        $sample = Join-Path $sb 'sample-run.json'; Write-SampleResult -Path $sample
        $results = Join-Path $sb 'TestResults'
        Invoke-RunQATests -IncludeTier3 $false -Tier3Model 'opus' -Benchmark 'transactions' `
            -Target 'release' -Ref 'v1.1.0' `
            -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true `
            -ReplayResult $sample -Timestamp 'TS1' -TestResultsRoot $results | Out-Null
        $key = 'transactions@release-v1.1.0'
        Test-Path (Join-Path $results "$key\opus\TS1\report-0.1.0-TS1.md") | Should -BeTrue
        Test-Path (Join-Path $results "$key\tier3-history.jsonl")          | Should -BeTrue
        (Get-Content (Join-Path $results "$key\tier3-history.jsonl") -Raw) | Should -Match 'release-v1.1.0'
        @(Select-String -Path (Join-Path $results "$key\opus\TS1\report-0.1.0-TS1.md") -Pattern 'Template' -SimpleMatch).Count | Should -BeGreaterThan 0
        Remove-Item $sb -Recurse -Force
    }

    It 'PASS: release and dev runs land in separate histories (nothing mixed) — the compare setup' {
        $sb = New-Sandbox
        $sample = Join-Path $sb 'sample-run.json'; Write-SampleResult -Path $sample
        $results = Join-Path $sb 'TestResults'
        Invoke-RunQATests -IncludeTier3 $false -Tier3Model 'opus' -Benchmark 'transactions' `
            -Target 'release' -Ref 'v1.1.0' -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true `
            -ReplayResult $sample -Timestamp 'TS1' -TestResultsRoot $results | Out-Null
        Invoke-RunQATests -IncludeTier3 $false -Tier3Model 'opus' -Benchmark 'transactions' `
            -Target 'dev' -Ref 'v1.1.0' -KeepDeps $false -NoTeardown $true -Cleanup $false -SkipSetup $true `
            -ReplayResult $sample -Timestamp 'TS1' -TestResultsRoot $results | Out-Null
        Test-Path (Join-Path $results 'transactions@release-v1.1.0\tier3-history.jsonl') | Should -BeTrue
        Test-Path (Join-Path $results 'transactions@dev-v1.1.0\tier3-history.jsonl')     | Should -BeTrue
        @(Get-Content (Join-Path $results 'transactions@release-v1.1.0\tier3-history.jsonl')).Count | Should -Be 1
        Remove-Item $sb -Recurse -Force
    }
}

Describe 'Compress-Tier3Logs — shrink the raw stream log' {
    It 'PASS: gzips each *-claude.jsonl and removes the raw file' {
        $sb = New-Sandbox
        $live = Join-Path $sb 'tier3-live'; New-Item -ItemType Directory -Path $live -Force | Out-Null
        $raw = Join-Path $live 'TS1-claude.jsonl'
        Set-Content -Path $raw -Value (1..500 | ForEach-Object { '{"type":"assistant","i":' + $_ + '}' }) -Encoding utf8
        Set-Content -Path (Join-Path $live 'session.id') -Value 'sess-abc' -Encoding utf8   # must be left alone
        $res = Compress-Tier3Logs -LiveDir $live
        $res.ok | Should -BeTrue
        Test-Path $raw          | Should -BeFalse   # raw removed
        Test-Path "$raw.gz"     | Should -BeTrue    # gzip written
        Test-Path (Join-Path $live 'session.id') | Should -BeTrue   # untouched
        (Get-Item "$raw.gz").Length | Should -BeLessThan (($raw.Length) + 100000)  # sanity: a real file
        Remove-Item $sb -Recurse -Force
    }

    It 'FAIL-guard: a missing live folder is a no-op, not an error' {
        (Compress-Tier3Logs -LiveDir (Join-Path ([System.IO.Path]::GetTempPath()) 'no-such-live-xyz')).ok | Should -BeTrue
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
