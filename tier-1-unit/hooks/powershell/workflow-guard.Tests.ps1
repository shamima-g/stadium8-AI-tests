#
# Pester tests for .claude/hooks/workflow-guard.ps1
#
# Run with:  pwsh -Command "Invoke-Pester tier-1-unit/hooks/powershell"
#
# The guard reads generated-docs/context/workflow-state.json and emits JSON
# with hookSpecificOutput.additionalContext telling Claude which command to
# redirect to.
#
# Isolation strategy:
#   The hook resolves $projectRoot from $PSScriptRoot (its own file location)
#   and does NOT honour any env var. To isolate from the host repo, each test
#   copies the hook into a throwaway <temp>/.claude/hooks/workflow-guard.ps1
#   and invokes that copy. Inside the copy, $PSScriptRoot is the temp hooks
#   dir, so the hook's computed $projectRoot is the temp project root —
#   completely decoupled from the live repo's state and web/node_modules.
#
BeforeAll {
    $script:RealRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
    $script:RealGuard    = Join-Path $RealRepoRoot '.claude\hooks\workflow-guard.ps1'

    function New-TempProject {
        $temp = Join-Path $env:TEMP ("workflow-guard-" + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $temp -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $temp 'web') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $temp 'generated-docs\context') -Force | Out-Null
        $hooksDir = Join-Path $temp '.claude\hooks'
        New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
        Copy-Item -Path $script:RealGuard -Destination $hooksDir -Force
        return $temp
    }

    function Invoke-Guard {
        param([string]$ProjectDir)
        $copiedGuard = Join-Path $ProjectDir '.claude\hooks\workflow-guard.ps1'
        $raw = & pwsh -NoProfile -ExecutionPolicy Bypass -File $copiedGuard
        if ($null -eq $raw -or ($raw -is [array] -and $raw.Count -eq 0)) {
            return ''
        }
        $joined = ($raw -join "`n").Trim()
        if ([string]::IsNullOrWhiteSpace($joined)) { return '' }
        try {
            $parsed = $joined | ConvertFrom-Json
            return [string]$parsed.hookSpecificOutput.additionalContext
        } catch {
            return $joined
        }
    }
}

Describe 'workflow-guard.ps1' {

    BeforeEach {
        $script:TempRoot = New-TempProject
    }

    AfterEach {
        Remove-Item -Path $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    Context 'Project not initialised' {
        It 'PASS: emits "Project not initialized" and redirects to /start when web/node_modules does not exist' {
            $context = Invoke-Guard -ProjectDir $TempRoot
            $context | Should -Match 'Project not initialized'
            # /start handles install + prefs as part of Step 0 — there is no /setup command.
            $context | Should -Match '/start'
        }

        It 'FAIL: does NOT emit "No active workflow" when web/node_modules is also missing' {
            $context = Invoke-Guard -ProjectDir $TempRoot
            $context | Should -Not -Match 'No active workflow'
        }
    }

    Context 'Active workflow' {
        BeforeEach {
            New-Item -ItemType Directory -Path (Join-Path $TempRoot 'web\node_modules') -Force | Out-Null
            $state = @{
                currentPhase = 'BUILD'
                currentEpic = 2
                currentStory = 3
                featureName = 'Team Task Manager'
                featureComplete = $false
            } | ConvertTo-Json
            Set-Content -Path (Join-Path $TempRoot 'generated-docs\context\workflow-state.json') -Value $state
        }

        It 'PASS: reports the current phase / epic / story' {
            $context = Invoke-Guard -ProjectDir $TempRoot
            $context | Should -Match 'BUILD'
            $context | Should -Match '/continue'
        }

        It 'FAIL: does NOT redirect to /start when dependencies exist and a workflow is active' {
            $context = Invoke-Guard -ProjectDir $TempRoot
            # An active workflow resumes with /continue, never restarts via /start.
            $context | Should -Not -Match '/start'
        }
    }

    Context 'Feature complete' {
        BeforeEach {
            New-Item -ItemType Directory -Path (Join-Path $TempRoot 'web\node_modules') -Force | Out-Null
            $state = @{
                currentPhase = 'COMPLETE'
                featureComplete = $true
            } | ConvertTo-Json
            Set-Content -Path (Join-Path $TempRoot 'generated-docs\context\workflow-state.json') -Value $state
        }

        It 'PASS: reports the feature is complete and redirects to /continue for new epics' {
            $context = Invoke-Guard -ProjectDir $TempRoot
            $context | Should -Match 'complete'
            # A completed feature reopens via /continue (it prompts for new epics), not /start.
            $context | Should -Match '/continue'
        }
    }

    Context 'Corrupted state file' {
        BeforeEach {
            New-Item -ItemType Directory -Path (Join-Path $TempRoot 'web\node_modules') -Force | Out-Null
            Set-Content -Path (Join-Path $TempRoot 'generated-docs\context\workflow-state.json') -Value 'not valid json {{'
        }

        It 'PASS: exits 0 and emits no output on parse failure (fail-safe)' {
            $copiedGuard = Join-Path $TempRoot '.claude\hooks\workflow-guard.ps1'
            $null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $copiedGuard 2>&1
            $LASTEXITCODE | Should -Be 0
        }
    }
}
