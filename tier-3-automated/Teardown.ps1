<#
.SYNOPSIS
  Teardown.ps1 — clean up after a run: keep what matters, remove what's not necessary.

.DESCRIPTION
  Runs at the end of a run (the caller runs it AFTER the report + zip are written).
  It KEEPS the app's source, generated-docs, git history, and all of TestResults; it
  REMOVES only the heavy, rebuildable bits (node_modules, build caches, temp scratch).

  Switches:
    (default)   remove node_modules + build caches under the working folder
    -KeepDeps   leave node_modules in place (app stays instantly runnable)
    -Full       remove the ENTIRE working folder (the results zip still survives)

  Best-effort by design: a cleanup hiccup is reported, never thrown — the caller's own
  temp handling is the real safety net. No live AI involved.
#>

Set-StrictMode -Version Latest

# Folders considered "not necessary" — heavy and always rebuildable.
$script:JunkDirNames = @('node_modules', '.next', '.turbo', 'coverage', '.vite', 'dist', '.cache')

function Invoke-Tier3Teardown {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$WorkingDir,
        [switch]$KeepDeps,
        [switch]$Full
    )
    $removed = [System.Collections.Generic.List[string]]::new()
    $result = @{ removed = $removed; ok = $true; note = '' }

    if (-not (Test-Path $WorkingDir)) {
        $result.note = "Working folder not found (nothing to do): $WorkingDir"
        return $result
    }

    try {
        if ($Full) {
            Remove-Item -Path $WorkingDir -Recurse -Force -ErrorAction Stop
            $removed.Add($WorkingDir)
            return $result
        }

        $targets = $script:JunkDirNames
        if ($KeepDeps) { $targets = @($targets | Where-Object { $_ -ne 'node_modules' }) }

        foreach ($name in $targets) {
            Get-ChildItem -Path $WorkingDir -Directory -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq $name } |
                ForEach-Object {
                    try {
                        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
                        $removed.Add($_.FullName)
                    }
                    catch {
                        $result.ok = $false
                        $result.note = "Some items could not be removed (locked?): $($_.Exception.Message)"
                    }
                }
        }
    }
    catch {
        $result.ok = $false
        $result.note = "Teardown hit a problem (ignored): $($_.Exception.Message)"
    }

    return $result
}
