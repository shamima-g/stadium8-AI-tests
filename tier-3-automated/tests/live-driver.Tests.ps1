<#
  Pester tests for live-driver.ps1 — the no-AI pieces (scaffold, prompt, event parsing,
  build check). The actual `claude` spawn is exercised only in a real run, not here.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'live-driver.ps1')

    function New-FakeTemplate {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-tmpl-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.claude\agents') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'web\src') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'node_modules\junk') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'AI-tests') -Force | Out-Null
        Set-Content -Path (Join-Path $root 'CLAUDE.md') -Value '# template' -Encoding utf8
        Set-Content -Path (Join-Path $root 'web\src\keep.ts') -Value 'export {}' -Encoding utf8
        Set-Content -Path (Join-Path $root 'node_modules\junk\big.js') -Value 'x' -Encoding utf8
        Set-Content -Path (Join-Path $root 'AI-tests\should-not-copy.txt') -Value 'x' -Encoding utf8
        return $root
    }
    function New-FakeBenchmark {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-bench-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'frontend\docs') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'backend') -Force | Out-Null
        Set-Content -Path (Join-Path $root 'frontend\docs\brief.md') -Value '# brief' -Encoding utf8
        Set-Content -Path (Join-Path $root 'backend\BRD.md') -Value '# brd' -Encoding utf8
        Set-Content -Path (Join-Path $root 'answers.json') -Value '{"signIn":{"choice":"your own server (BFF)"}}' -Encoding utf8
        return $root
    }
}

Describe 'Scaffold — copy template + drop docs, skip the junk' {
    It 'PASS: copies the template but excludes AI-tests/node_modules; puts docs in documentation/' {
        $tmpl = New-FakeTemplate
        $bench = New-FakeBenchmark
        $work = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-work-" + [Guid]::NewGuid().ToString('N'))
        New-Tier3Scaffold -TemplateRoot $tmpl -WorkingDir $work -BenchmarkDir $bench | Out-Null

        Test-Path (Join-Path $work 'CLAUDE.md')              | Should -BeTrue
        Test-Path (Join-Path $work 'web\src\keep.ts')        | Should -BeTrue
        Test-Path (Join-Path $work '.claude\agents')         | Should -BeTrue
        Test-Path (Join-Path $work 'node_modules')           | Should -BeFalse   # excluded
        Test-Path (Join-Path $work 'AI-tests')               | Should -BeFalse   # excluded
        Test-Path (Join-Path $work 'documentation\brief.md') | Should -BeTrue    # frontend docs dropped in
        Test-Path (Join-Path $work 'documentation\backend\BRD.md') | Should -BeTrue
        Test-Path (Join-Path $work 'TIER3-ANSWERS.json') | Should -BeTrue        # answers file dropped in for the gates
        Remove-Item $tmpl, $bench, $work -Recurse -Force
    }
}

Describe 'Prompt — real /start + /continue, answers file for the gates' {
    It 'PASS: drives /start and /continue, non-interactive, points at the answers file' {
        $prompt = Get-Tier3Prompt
        $prompt | Should -Match '/start'
        $prompt | Should -Match '/continue'
        $prompt | Should -Match 'NON-INTERACTIVE'
        $prompt | Should -Match 'TIER3-ANSWERS\.json'
        $prompt | Should -Match 'BFF'
    }
    It 'PASS: the resume prompt continues via /continue using the answers file' {
        $rp = Get-Tier3ResumePrompt
        $rp | Should -Match 'interrupted'
        $rp | Should -Match '/continue'
        $rp | Should -Match 'TIER3-ANSWERS\.json'
    }
}

Describe 'Event parsing — Read-ClaudeEvent updates state and fires OnTurn' {
    It 'PASS: assistant events count turns + guess gate; result captures totals' {
        $state = @{ turns = 0; sessionId = $null; model = 'opus'; sawResult = $false; isError = $false; durationMs = 0.0; costUsd = 0.0; tokens = 0; partialTokens = 0; lastType = $null; prevGate = 'spec' }
        $seen = New-Object System.Collections.Generic.List[string]
        $onTurn = { param($n, $g) $seen.Add("$n=$g") }

        Read-ClaudeEvent -Line '{"type":"system","session_id":"abc","model":"opus"}' -State $state -OnTurn $onTurn
        Read-ClaudeEvent -Line '{"type":"assistant","message":{"usage":{"input_tokens":10,"output_tokens":5},"content":[{"type":"tool_use","name":"Write","input":{"file_path":"web/src/app/page.tsx"}}]}}' -State $state -OnTurn $onTurn
        Read-ClaudeEvent -Line '{"type":"result","is_error":false,"duration_ms":5000,"total_cost_usd":0.12,"usage":{"input_tokens":10,"output_tokens":5}}' -State $state -OnTurn $onTurn

        $state.turns      | Should -Be 1
        $state.sessionId  | Should -Be 'abc'
        $state.sawResult  | Should -BeTrue
        $state.durationMs | Should -Be 5000
        @($seen)[0]       | Should -Be '1=green'      # a web/src .tsx write => green
    }

    It 'FAIL-guard: a non-JSON line is ignored, not fatal' {
        $state = @{ turns = 0; sessionId = $null; model = $null; sawResult = $false; isError = $false; durationMs = 0.0; costUsd = 0.0; tokens = 0; partialTokens = 0; lastType = $null; prevGate = 'spec' }
        { Read-ClaudeEvent -Line 'not json at all' -State $state -OnTurn $null } | Should -Not -Throw
        $state.turns | Should -Be 0
    }
}

Describe 'Per-phase Claude-time distribution' {
    It 'PASS: the build phase gets the whole time; workflow-phases split by output tokens' {
        $spans = @(
            @{ path = 'opus/build'; level = 'phase'; activeSeconds = 100; claudeSeconds = 0 },
            @{ path = 'opus/build/spec'; level = 'wphase'; activeSeconds = 20; claudeSeconds = 0 },
            @{ path = 'opus/build/green'; level = 'wphase'; activeSeconds = 60; claudeSeconds = 0 },
            @{ path = 'opus/build/turn-1'; level = 'turn'; activeSeconds = 5; claudeSeconds = 0 }  # ignored
        )
        $gateTokens = @{ spec = 25; green = 75 }   # total 100 -> spec 25%, green 75%
        $phases = Get-DistributedPhaseTiming -Spans $spans -GateTokens $gateTokens -TotalClaudeSeconds 400

        $build = $phases | Where-Object { $_.path -eq 'opus/build' }
        $spec = $phases | Where-Object { $_.path -eq 'opus/build/spec' }
        $green = $phases | Where-Object { $_.path -eq 'opus/build/green' }
        $build.claudeSeconds | Should -Be 400          # whole build
        $spec.claudeSeconds  | Should -Be 100          # 25% of 400
        $green.claudeSeconds | Should -Be 300          # 75% of 400
        @($phases | Where-Object { $_.path -like '*turn-*' }).Count | Should -Be 0   # turns excluded
        Remove-Variable phases
    }

    It 'PASS: recurring gates (many red/green cycles) collapse into one row per gate' {
        $spans = @(
            @{ path = 'opus/build'; level = 'phase'; activeSeconds = 100; claudeSeconds = 0 },
            @{ path = 'opus/build/red'; level = 'wphase'; activeSeconds = 10; claudeSeconds = 0 },
            @{ path = 'opus/build/green'; level = 'wphase'; activeSeconds = 20; claudeSeconds = 0 },
            @{ path = 'opus/build/red'; level = 'wphase'; activeSeconds = 30; claudeSeconds = 0 },   # red again
            @{ path = 'opus/build/green'; level = 'wphase'; activeSeconds = 40; claudeSeconds = 0 }   # green again
        )
        $gateTokens = @{ red = 50; green = 50 }
        $phases = Get-DistributedPhaseTiming -Spans $spans -GateTokens $gateTokens -TotalClaudeSeconds 200
        @($phases | Where-Object { $_.path -eq 'opus/build/red' }).Count | Should -Be 1     # one row, not two
        ($phases | Where-Object { $_.path -eq 'opus/build/red' }).activeSeconds | Should -Be 40   # 10 + 30 summed
        ($phases | Where-Object { $_.path -eq 'opus/build/red' }).claudeSeconds | Should -Be 100  # 50% of 200, once
        Remove-Variable phases
    }

    It 'FAIL-guard: zero total tokens gives 0 to workflow-phases (no divide-by-zero)' {
        $spans = @(@{ path = 'opus/build/spec'; level = 'wphase'; activeSeconds = 10; claudeSeconds = 0 })
        $phases = Get-DistributedPhaseTiming -Spans $spans -GateTokens @{} -TotalClaudeSeconds 100
        ($phases | Where-Object { $_.path -eq 'opus/build/spec' }).claudeSeconds | Should -Be 0
    }
}

Describe 'Cross-segment progress (resume accumulation)' {
    It 'PASS: Merge adds tokens/turns/times, sums gate tokens, and takes memory extremes' {
        $prior = @{ segments = 1; turns = 100; tokens = 1000; claudeSeconds = 500; activeSeconds = 400; excludedSeconds = 60; gateTokens = @{ red = 50 }; memPeakUsedMB = 20000; memBaselineUsedMB = 18000; memMinAvailableMB = 5000; memTotalMB = 32000 }
        $seg = @{ turns = 50; tokens = 800; claudeSeconds = 300; activeSeconds = 200; excludedSeconds = 10; gateTokens = @{ red = 30; green = 20 }; memPeakUsedMB = 22000; memBaselineUsedMB = 17000; memMinAvailableMB = 4000; memTotalMB = 32000 }
        $c = Merge-Tier3Progress -Prior $prior -Segment $seg
        $c.segments        | Should -Be 2
        $c.turns           | Should -Be 150
        $c.tokens          | Should -Be 1800
        $c.claudeSeconds   | Should -Be 800
        $c.activeSeconds   | Should -Be 600
        $c.gateTokens.red  | Should -Be 80      # 50 + 30
        $c.gateTokens.green | Should -Be 20
        $c.memPeakUsedMB   | Should -Be 22000   # max
        $c.memBaselineUsedMB | Should -Be 17000 # min
        $c.memMinAvailableMB | Should -Be 4000  # min
    }

    It 'PASS: a first (non-resume) run merges zeros -> equals the single segment' {
        $seg = @{ turns = 10; tokens = 100; claudeSeconds = 50; activeSeconds = 40; excludedSeconds = 5; gateTokens = @{ spec = 100 }; memPeakUsedMB = 9000; memBaselineUsedMB = 8000; memMinAvailableMB = 6000; memTotalMB = 16000 }
        $c = Merge-Tier3Progress -Prior (New-Tier3ProgressZero) -Segment $seg
        $c.segments | Should -Be 1
        $c.tokens   | Should -Be 100
        $c.turns    | Should -Be 10
    }

    It 'PASS: progress round-trips through disk (including gate tokens)' {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-prog-" + [Guid]::NewGuid().ToString('N'))
        $p = Join-Path $dir 'progress.json'
        $rec = @{ segments = 2; turns = 150; tokens = 1800; claudeSeconds = 800; activeSeconds = 600; excludedSeconds = 70; gateTokens = @{ red = 80; green = 20 }; memPeakUsedMB = 22000; memBaselineUsedMB = 17000; memMinAvailableMB = 4000; memTotalMB = 32000 }
        Write-Tier3Progress -Path $p -Record $rec
        $back = Read-Tier3Progress -Path $p
        $back.tokens         | Should -Be 1800
        $back.segments       | Should -Be 2
        $back.gateTokens.red | Should -Be 80
        $back.memPeakUsedMB  | Should -Be 22000
        Remove-Item $dir -Recurse -Force
    }

    It 'FAIL-guard: a missing progress file reads as zeros' {
        $z = Read-Tier3Progress -Path (Join-Path ([System.IO.Path]::GetTempPath()) 'no-progress-xyz.json')
        $z.segments | Should -Be 0
        $z.tokens   | Should -Be 0
    }

    It 'PASS: memory summary from combined progress computes added + 16 GB verdict' {
        $c = @{ memPeakUsedMB = 22000; memBaselineUsedMB = 17000; memMinAvailableMB = 4000; memTotalMB = 32000 }
        $m = Get-MemorySummaryFromProgress -P $c
        $m.addedMB          | Should -Be 5000               # 22000 - 17000
        $m.estimatedVmUseMB | Should -Be 9096               # 4096 + 5000
        $m.fitsBudget       | Should -BeTrue                # 9096 < 16384
    }
}

Describe 'App zip — snapshot the built app, skip the heavy junk' {
    It 'PASS: zips the source but excludes node_modules/.next; skips nothing readable' {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-zip-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'web\src') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'web\node_modules\pkg') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'web\.next\cache') -Force | Out-Null
        Set-Content -Path (Join-Path $root 'CLAUDE.md') -Value '# t' -Encoding utf8
        Set-Content -Path (Join-Path $root 'web\src\page.tsx') -Value 'export {}' -Encoding utf8
        Set-Content -Path (Join-Path $root 'web\node_modules\pkg\index.js') -Value 'x' -Encoding utf8
        Set-Content -Path (Join-Path $root 'web\.next\cache\c.bin') -Value 'x' -Encoding utf8

        $zip = Join-Path $root 'app.zip'
        $res = Compress-Tier3App -SourceDir $root -DestZip $zip
        $res.ok | Should -BeTrue
        Test-Path $zip | Should -BeTrue

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $names = [System.IO.Compression.ZipFile]::OpenRead($zip).Entries.FullName
        ($names -contains 'CLAUDE.md')       | Should -BeTrue
        ($names -contains 'web/src/page.tsx') | Should -BeTrue
        ($names -join '|') | Should -Not -Match 'node_modules'
        ($names -join '|') | Should -Not -Match '\.next'
        Remove-Item $root -Recurse -Force
    }

    It 'FAIL-guard: a missing source returns ok=false, never throws' {
        $res = Compress-Tier3App -SourceDir (Join-Path ([System.IO.Path]::GetTempPath()) 'no-such-src-xyz') -DestZip (Join-Path ([System.IO.Path]::GetTempPath()) 'x.zip')
        $res.ok | Should -BeFalse
    }
}

Describe 'Conformance scoring — reuse the real artifact-lint rules' {
    It 'PASS: maps failed artifact-lint files to rule ids; clean files are not flagged' {
        $json = @'
{
  "numTotalTests": 6, "numFailedTests": 2,
  "testResults": [
    { "name": "C:/x/AI-tests/tier-1-unit/artifact-lint/shadcn-imports-only.test.ts",
      "assertionResults": [ {"status":"passed","title":"sample"}, {"status":"failed","title":"real web/src"} ] },
    { "name": "C:/x/AI-tests/tier-1-unit/artifact-lint/api-path-exactness.test.ts",
      "assertionResults": [ {"status":"passed","title":"sample"}, {"status":"passed","title":"real"} ] },
    { "name": "C:/x/AI-tests/tier-1-unit/artifact-lint/role-field-in-stories.test.ts",
      "assertionResults": [ {"status":"failed","title":"role missing"} ] }
  ]
}
'@
        $missed = ConvertFrom-VitestArtifactJson -Json $json
        $missed | Should -Contain 'shadcn-only'      # had a failing assertion
        $missed | Should -Contain 'role-per-story'   # had a failing assertion
        $missed | Should -Not -Contain 'exact-api-paths'  # all passed
        @($missed).Count | Should -Be 2
    }

    It 'PASS: a fully clean run yields no missed rules' {
        $json = '{"numTotalTests":2,"numFailedTests":0,"testResults":[{"name":"tier-1-unit/artifact-lint/shadcn-imports-only.test.ts","assertionResults":[{"status":"passed","title":"a"}]}]}'
        @(ConvertFrom-VitestArtifactJson -Json $json).Count | Should -Be 0
    }
}

Describe 'Lower-tier group parsing (Tier 1 / Tier 2)' {
    It 'PASS: groups assertions by tier and counts pass/fail/skip' {
        $json = @'
{
  "testResults": [
    { "name": "C:/x/AI-tests/tier-1-unit/scripts/a.test.ts", "startTime": 1000, "endTime": 3000,
      "assertionResults": [ {"status":"passed"}, {"status":"passed"}, {"status":"failed"} ] },
    { "name": "C:/x/AI-tests/tier-2-recorded-run/recorded-run.test.ts", "startTime": 3000, "endTime": 3500,
      "assertionResults": [ {"status":"passed"}, {"status":"pending"} ] }
  ]
}
'@
        $groups = ConvertFrom-VitestGroupsJson -Json $json
        $t1 = $groups | Where-Object { $_.name -match 'Tier 1' }
        $t2 = $groups | Where-Object { $_.name -match 'Tier 2' }
        $t1.tests   | Should -Be 3
        $t1.passed  | Should -Be 2
        $t1.failed  | Should -Be 1
        $t1.durationSeconds | Should -Be 2      # (3000-1000)/1000
        $t2.skipped | Should -Be 1              # the 'pending' one
    }
    It 'FAIL-guard: a tier with no tests is omitted' {
        $json = '{"testResults":[{"name":"tier-1-unit/x.test.ts","startTime":0,"endTime":0,"assertionResults":[{"status":"passed"}]}]}'
        $groups = ConvertFrom-VitestGroupsJson -Json $json
        @($groups | Where-Object { $_.name -match 'Tier 2' }).Count | Should -Be 0
    }
}

Describe 'Build check — recorded, never gating' {
    It 'PASS: a working dir with no web/ app is reported as not-built (not an error)' {
        $work = Join-Path ([System.IO.Path]::GetTempPath()) ("tier3-nobuild-" + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $work -Force | Out-Null
        $r = Test-Tier3Build -WorkingDir $work
        $r.ok | Should -BeFalse
        $r.detail | Should -Match 'no web'
        Remove-Item $work -Recurse -Force
    }
}
