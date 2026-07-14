<#
.SYNOPSIS
  memory.ps1 — sample system memory during a run and track the peak.

.DESCRIPTION
  For the "what are Stadium 8's minimum RAM needs?" question, the run samples how much
  physical memory the machine is using while Claude builds and while the app compiles, and
  records the PEAK. The build (Node / Next.js) is the memory-hungry part, so both the
  Claude phase and the npm install/build phase are sampled.

  Metric: whole-system physical memory in use (total - free), plus the low-water mark of
  available memory. This is the honest proxy for "how much RAM the machine needed" — note
  it includes everything else running, so on a big host it over-states what a lean 16 GB VM
  would need. The truest answer is still to run on a real 16 GB VM; this records the
  evidence either way.

  Windows uses Win32_OperatingSystem; other OSes fall back to /proc/meminfo. If neither is
  available the tracker degrades to nulls rather than throwing.
#>

Set-StrictMode -Version Latest

# One snapshot of physical memory (all values in MB), or $null when unavailable.
function Get-MemoryStatus {
    [CmdletBinding()]
    param()
    try {
        if ($IsWindows -or $null -eq $IsWindows) {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
            $totalMB = [Math]::Round([double]$os.TotalVisibleMemorySize / 1024)
            $freeMB = [Math]::Round([double]$os.FreePhysicalMemory / 1024)
            return @{ totalMB = $totalMB; availableMB = $freeMB; usedMB = ($totalMB - $freeMB) }
        }
        elseif (Test-Path '/proc/meminfo') {
            $info = @{}
            foreach ($line in Get-Content '/proc/meminfo') {
                if ($line -match '^(\w+):\s+(\d+)\s+kB') { $info[$Matches[1]] = [double]$Matches[2] }
            }
            $totalMB = [Math]::Round($info['MemTotal'] / 1024)
            $availMB = [Math]::Round((if ($info.ContainsKey('MemAvailable')) { $info['MemAvailable'] } else { $info['MemFree'] }) / 1024)
            return @{ totalMB = $totalMB; availableMB = $availMB; usedMB = ($totalMB - $availMB) }
        }
    }
    catch { }
    return $null
}

# Start a peak tracker seeded with the current snapshot (or nulls if unavailable).
# baselineUsedMB is the memory already in use before the run — so we can separate the
# machine's starting load from what the run itself ADDS (the number that actually answers
# "how much RAM does the build need").
function New-MemoryPeak {
    [CmdletBinding()]
    param()
    $s = Get-MemoryStatus
    if ($null -eq $s) {
        return @{ totalMB = $null; peakUsedMB = $null; minAvailableMB = $null; baselineUsedMB = $null; samples = 0; available = $false }
    }
    return @{ totalMB = $s.totalMB; peakUsedMB = $s.usedMB; minAvailableMB = $s.availableMB; baselineUsedMB = $s.usedMB; samples = 1; available = $true }
}

# Sample once and raise the peak-used / lower the min-available. Best-effort, never throws.
function Update-MemoryPeak {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Tracker)
    $s = Get-MemoryStatus
    if ($null -eq $s) { return }
    if (-not $Tracker.available) {
        $Tracker.available = $true; $Tracker.totalMB = $s.totalMB
        $Tracker.peakUsedMB = $s.usedMB; $Tracker.minAvailableMB = $s.availableMB
        $Tracker.baselineUsedMB = $s.usedMB
    }
    if ($s.usedMB -gt $Tracker.peakUsedMB) { $Tracker.peakUsedMB = $s.usedMB }
    if ($s.availableMB -lt $Tracker.minAvailableMB) { $Tracker.minAvailableMB = $s.availableMB }
    $Tracker.samples++
}

# Summarise a tracker for the run-result. Reports the whole-system peak AND the run's
# INCREMENTAL memory (peak minus the starting baseline) — the latter is what actually
# answers "how much RAM does the build need". The 16 GB verdict is based on the increment
# plus a modest assumed OS baseline for a lean VM (default 4 GB), NOT on this machine's
# whole-system peak (which is inflated by whatever else was already running).
function Get-MemorySummary {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Tracker, [int]$BudgetMB = 16384, [int]$AssumedVmBaselineMB = 4096)
    if (-not $Tracker.available -or $null -eq $Tracker.peakUsedMB) {
        return @{ available = $false; peakUsedMB = $null; totalMB = $null; minAvailableMB = $null; baselineUsedMB = $null; addedMB = $null; estimatedVmUseMB = $null; fitsBudget = $null; budgetMB = $BudgetMB; assumedVmBaselineMB = $AssumedVmBaselineMB }
    }
    $added = [Math]::Max(0, [int]$Tracker.peakUsedMB - [int]$Tracker.baselineUsedMB)
    $estimatedVmUse = $AssumedVmBaselineMB + $added
    return @{
        available           = $true
        peakUsedMB          = [int]$Tracker.peakUsedMB
        totalMB             = [int]$Tracker.totalMB
        minAvailableMB      = [int]$Tracker.minAvailableMB
        baselineUsedMB      = [int]$Tracker.baselineUsedMB
        addedMB             = $added
        assumedVmBaselineMB = $AssumedVmBaselineMB
        estimatedVmUseMB    = $estimatedVmUse
        budgetMB            = $BudgetMB
        fitsBudget          = ($estimatedVmUse -le $BudgetMB)
        samples             = $Tracker.samples
    }
}
