<#
  Pester tests for memory.ps1 — the peak-memory sampler.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'memory.ps1')
}

Describe 'Get-MemoryStatus' {
    It 'PASS: reports positive total and used memory on this machine' {
        $s = Get-MemoryStatus
        $s | Should -Not -BeNullOrEmpty
        $s.totalMB     | Should -BeGreaterThan 0
        $s.usedMB      | Should -BeGreaterThan 0
        $s.usedMB      | Should -BeLessOrEqual $s.totalMB
    }
}

Describe 'Peak tracking' {
    It 'PASS: the peak never decreases and samples accumulate across updates' {
        $t = New-MemoryPeak
        $t.available | Should -BeTrue
        $startPeak = $t.peakUsedMB
        $startSamples = $t.samples
        Update-MemoryPeak -Tracker $t
        Update-MemoryPeak -Tracker $t
        $t.peakUsedMB | Should -BeGreaterOrEqual $startPeak      # monotonic
        $t.samples    | Should -BeGreaterThan $startSamples
        $t.minAvailableMB | Should -BeLessOrEqual $t.totalMB
    }
}

Describe 'Get-MemorySummary — the 16 GB call' {
    It 'PASS: fitsBudget is true under a generous budget, false under a tiny one' {
        $t = New-MemoryPeak
        (Get-MemorySummary -Tracker $t -BudgetMB 1048576).fitsBudget | Should -BeTrue   # 1 TB budget
        (Get-MemorySummary -Tracker $t -BudgetMB 1).fitsBudget       | Should -BeFalse  # 1 MB budget
    }
    It 'PASS: reports the budget it was checked against (default 16 GB)' {
        $t = New-MemoryPeak
        (Get-MemorySummary -Tracker $t).budgetMB | Should -Be 16384
    }
    It 'FAIL-guard: an unavailable tracker summarises to nulls, not an error' {
        $t = @{ available = $false; totalMB = $null; peakUsedMB = $null; minAvailableMB = $null; samples = 0 }
        $s = Get-MemorySummary -Tracker $t
        $s.available  | Should -BeFalse
        $s.fitsBudget | Should -BeNullOrEmpty
    }
}
