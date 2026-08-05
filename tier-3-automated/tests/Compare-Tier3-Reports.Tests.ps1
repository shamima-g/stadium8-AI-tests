<#
  Pester tests for Compare-Tier3-Reports.ps1 — the release-vs-dev Tier 3 diff.
  Good case AND broken/edge case for each behaviour; each test uses its own temp folder.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'Compare-Tier3-Reports.ps1')
    . (Join-Path $PSScriptRoot '..' 'history.ps1')

    function New-Sandbox {
        $d = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-cmp-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        return $d
    }
    function Add-Run {
        param([string]$History, [string]$Ts, [string]$Model = 'opus', [string]$Result = 'pass',
              [double]$Active = 800, [double]$Claude = 600, [double]$Tokens = 100000, [double]$PassRate = 1.0,
              [array]$RulesMissed = @())
        Add-Tier3HistoryLine -HistoryPath $History -Record @{
            timestamp = $Ts; model = $Model; benchmark = 'transactions'; result = $Result
            activeSeconds = $Active; claudeSeconds = $Claude; tokensTotal = $Tokens
            passRate = $PassRate; rulesMissed = $RulesMissed
        }
    }
}

Describe 'Select-Tier3LatestRun' {
    It 'PASS: returns the newest (last) row, and filters by model' {
        $sb = New-Sandbox; $h = Join-Path $sb 'h.jsonl'
        Add-Run -History $h -Ts 'T1' -Model 'opus'
        Add-Run -History $h -Ts 'T2' -Model 'sonnet'
        Add-Run -History $h -Ts 'T3' -Model 'opus'
        (Select-Tier3LatestRun -Rows (Get-Tier3History -HistoryPath $h)).timestamp | Should -Be 'T3'
        (Select-Tier3LatestRun -Rows (Get-Tier3History -HistoryPath $h) -Model 'sonnet').timestamp | Should -Be 'T2'
        Remove-Item $sb -Recurse -Force
    }

    It 'FAIL-guard: no matching rows returns $null' {
        $sb = New-Sandbox; $h = Join-Path $sb 'h.jsonl'
        Add-Run -History $h -Ts 'T1' -Model 'opus'
        Select-Tier3LatestRun -Rows (Get-Tier3History -HistoryPath $h) -Model 'haiku' | Should -BeNullOrEmpty
        Remove-Item $sb -Recurse -Force
    }
}

Describe 'Get-Tier3RunMetrics' {
    It 'PASS: flattens fields and counts rules missed' {
        $sb = New-Sandbox; $h = Join-Path $sb 'h.jsonl'
        Add-Run -History $h -Ts 'T1' -Active 900 -Tokens 123456 -PassRate 0.5 -RulesMissed @('shadcn-only','role-per-story')
        $m = Get-Tier3RunMetrics (Select-Tier3LatestRun -Rows (Get-Tier3History -HistoryPath $h))
        $m.activeSeconds | Should -Be 900
        $m.tokensTotal   | Should -Be 123456
        $m.passRate      | Should -Be 0.5
        $m.rulesMissed   | Should -Be 2
        Remove-Item $sb -Recurse -Force
    }

    It 'FAIL-guard: an older record missing newer fields reads them as $null, not a crash' {
        $sb = New-Sandbox; $h = Join-Path $sb 'h.jsonl'
        Add-Tier3HistoryLine -HistoryPath $h -Record @{ timestamp = 'old'; model = 'opus'; benchmark = 'transactions'; result = 'pass' }
        $m = Get-Tier3RunMetrics (Select-Tier3LatestRun -Rows (Get-Tier3History -HistoryPath $h))
        $m.result        | Should -Be 'pass'
        $m.activeSeconds | Should -BeNullOrEmpty
        $m.tokensTotal   | Should -BeNullOrEmpty
        Remove-Item $sb -Recurse -Force
    }
}

Describe 'New-Tier3Comparison — release vs dev diff' {
    It 'PASS: writes a table with each side and the signed B−A delta' {
        $sb = New-Sandbox
        $hA = Join-Path $sb 'a.jsonl'; $hB = Join-Path $sb 'b.jsonl'
        Add-Run -History $hA -Ts 'TA' -Active 800  -Tokens 100000 -PassRate 1.0
        Add-Run -History $hB -Ts 'TB' -Active 1000 -Tokens 120000 -PassRate 0.5 -RulesMissed @('shadcn-only')
        $out = Join-Path $sb 'cmp.md'
        New-Tier3Comparison -Benchmark 'transactions' -LabelA 'release-v1.1.0' -LabelB 'dev-v1.1.0' `
            -HistoryPathA $hA -HistoryPathB $hB -OutFile $out | Out-Null
        $md = Get-Content $out -Raw
        $md | Should -Match 'Tier 3 comparison'
        $md | Should -Match 'release-v1.1.0'
        $md | Should -Match 'dev-v1.1.0'
        $md | Should -Match '\+3m 20s'    # active 800->1000 = +200s
        $md | Should -Match '\+20,000'    # tokens 100k->120k
        $md | Should -Match '-50pp'       # pass-rate 100% -> 50%
        Remove-Item $sb -Recurse -Force
    }

    It 'PASS: renders provenance (command, generated-at, each side''s repository) when supplied' {
        $sb = New-Sandbox
        $hA = Join-Path $sb 'a.jsonl'; $hB = Join-Path $sb 'b.jsonl'
        Add-Run -History $hA -Ts 'TA'
        Add-Run -History $hB -Ts 'TB'
        $out = Join-Path $sb 'cmp.md'
        New-Tier3Comparison -Benchmark 'transactions' -LabelA 'release-v1.1.0' -LabelB 'dev-v1.1.0' `
            -HistoryPathA $hA -HistoryPathB $hB -OutFile $out `
            -Command './Compare-Tier3-Reports.ps1 -Benchmark transactions -A release -ARef v1.1.0 -B dev -BRef v1.1.0' `
            -GeneratedAt '2026-08-04 09:00:00' `
            -RepoA 'https://github.com/Digiata/Stadium-Builder' -RepoB 'https://github.com/stadium-software/stadium-8' | Out-Null
        $md = Get-Content $out -Raw
        $md | Should -Match 'Generated:\*\* 2026-08-04 09:00:00'
        $md | Should -Match 'Command:.*Compare-Tier3-Reports.ps1'
        $md | Should -Match 'Digiata/Stadium-Builder'
        $md | Should -Match 'stadium-software/stadium-8'
        Remove-Item $sb -Recurse -Force
    }

    It 'FAIL-guard: with no provenance supplied, no repository table or command line appears' {
        $sb = New-Sandbox
        $hA = Join-Path $sb 'a.jsonl'; $hB = Join-Path $sb 'b.jsonl'
        Add-Run -History $hA -Ts 'TA'; Add-Run -History $hB -Ts 'TB'
        $out = Join-Path $sb 'cmp.md'
        New-Tier3Comparison -Benchmark 'transactions' -LabelA 'release-v1.1.0' -LabelB 'dev-v1.1.0' `
            -HistoryPathA $hA -HistoryPathB $hB -OutFile $out | Out-Null
        (Get-Content $out -Raw) | Should -Not -Match 'Command:'
        Remove-Item $sb -Recurse -Force
    }

    It 'PASS: flags a model mismatch (unfair comparison)' {
        $sb = New-Sandbox
        $hA = Join-Path $sb 'a.jsonl'; $hB = Join-Path $sb 'b.jsonl'
        Add-Run -History $hA -Ts 'TA' -Model 'opus'
        Add-Run -History $hB -Ts 'TB' -Model 'sonnet'
        $out = Join-Path $sb 'cmp.md'
        New-Tier3Comparison -Benchmark 'transactions' -LabelA 'release-v1.1.0' -LabelB 'dev-v1.1.0' `
            -HistoryPathA $hA -HistoryPathB $hB -OutFile $out | Out-Null
        (Get-Content $out -Raw) | Should -Match 'different AI models'
        Remove-Item $sb -Recurse -Force
    }

    It 'FAIL-guard: a side with no runs errors clearly' {
        $sb = New-Sandbox
        $hA = Join-Path $sb 'a.jsonl'; $hB = Join-Path $sb 'b.jsonl'
        Add-Run -History $hA -Ts 'TA'
        # hB has no history file at all
        { New-Tier3Comparison -Benchmark 'transactions' -LabelA 'release-v1.1.0' -LabelB 'dev-v1.1.0' `
            -HistoryPathA $hA -HistoryPathB $hB -OutFile (Join-Path $sb 'cmp.md') } |
            Should -Throw -ExpectedMessage '*No runs found for*dev-v1.1.0*'
        Remove-Item $sb -Recurse -Force
    }
}
