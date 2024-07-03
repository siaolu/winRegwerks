# Import JSON module
Import-Module -Name 'Microsoft.PowerShell.Utility'

# Logger function to log messages with timestamps and store in JSON format
function Log-Message {
    param (
        [string]$message,
        [hashtable]$scanData = $null
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = @{
        Timestamp = $timestamp
        Message   = $message
        ScanData  = $scanData
    }
    $logFile = Join-Path -Path (Get-Location) -ChildPath "RegistryCleanupLog.json"
    $existingLogs = @()
    if (Test-Path $logFile) {
        $existingLogs = Get-Content -Path $logFile | ConvertFrom-Json
    }
    $existingLogs += $logEntry
    $existingLogs | ConvertTo-Json -Depth 10 | Set-Content -Path $logFile
}

# Timer function to measure execution time
function Measure-ExecutionTime {
    param (
        [scriptblock]$Code,
        [string]$FunctionName
    )
    $startTime = Get-Date
    Log-Message "Starting $FunctionName..."
    try {
        & $Code
    } catch {
        Log-Message "Error in $FunctionName: $_"
        throw
    }
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Log-Message "Finished $FunctionName in $($duration.TotalSeconds) seconds."
}

# Function to backup the registry
function Backup-Registry {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path -Path (Get-Location) -ChildPath "RegistryBackup_$timestamp.reg"
    try {
        reg export HKLM $backupPath /y
        if ($?) {
            Log-Message "Registry backup successful: $backupPath"
        } else {
            Log-Message "Registry backup failed."
            throw "Backup failed"
        }
    } catch {
        Log-Message "Error during registry backup: $_"
        throw
    }
}

# Function to scan for invalid application paths
function Scan-InvalidAppPaths {
    $invalidEntries = @()
    $appPaths = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
    foreach ($appPath in $appPaths) {
        $exePath = (Get-ItemProperty -Path $appPath.PSPath).'(Default)'
        if (-not (Test-Path $exePath)) {
            $invalidEntries += $appPath.PSPath
        }
    }
    if ($invalidEntries.Count -gt 0) {
        Log-Message "Found invalid application paths:" -scanData @{ InvalidAppPaths = $invalidEntries }
    }
    return $invalidEntries
}

# Function to clean invalid application paths
function Clean-InvalidAppPaths {
    param (
        [array]$invalidEntries
    )
    if ($invalidEntries -and $invalidEntries.Count -gt 0) {
        foreach ($entry in $invalidEntries) {
            try {
                Remove-Item -Path $entry -Force
                Log-Message "Removed invalid entry: $entry"
            } catch {
                Log-Message "Error removing invalid entry: $entry - $_"
            }
        }
    } else {  
        Log-Message "No invalid application paths to clean."
    }
}

# Function to scan for orphaned COM/ActiveX entries
function Scan-OrphanedComEntries {
    $orphanedEntries = @()
    $comKeys = Get-ChildItem -Path "HKCR:\CLSID"
    foreach ($key in $comKeys) {
        $inprocServer = (Get-ItemProperty -Path $key.PSPath).InprocServer32
        if ($inprocServer -and -not (Test-Path $inprocServer)) {
            $orphanedEntries += $key.PSPath
        }
    }
    if ($orphanedEntries.Count -gt 0) {
        Log-Message "Found orphaned COM/ActiveX entries:" -scanData @{ OrphanedComEntries = $orphanedEntries }
    }
    return $orphanedEntries
}

# Function to clean orphaned COM/ActiveX entries
function Clean-OrphanedComEntries {
    param (
        [array]$orphanedEntries
    )
    if ($orphanedEntries -and $orphanedEntries.Count -gt 0) {
        foreach ($entry in $orphanedEntries) {
            try {
                Remove-Item -Path $entry -Force
                Log-Message "Removed orphaned COM/ActiveX entry: $entry"
            } catch {
                Log-Message "Error removing orphaned COM/ActiveX entry: $entry - $_"
            }
        }
    } else {
        Log-Message "No orphaned COM/ActiveX entries to clean."
    }
}

# Function to scan for invalid file type associations
function Scan-InvalidFileTypes {
    $invalidFileTypes = @()
    $fileTypes = Get-ChildItem -Path "HKCR"
    foreach ($fileType in $fileTypes) {
        if ($fileType.PSIsContainer) {
            $default = (Get-ItemProperty -Path $fileType.PSPath).'(Default)'
            if ($default -and -not (Get-Item -Path "HKCR:\$default" -ErrorAction SilentlyContinue)) {
                $invalidFileTypes += $fileType.PSPath
            }
        }
    }
    if ($invalidFileTypes.Count -gt 0) {
        Log-Message "Found invalid file type associations:" -scanData @{ InvalidFileTypes = $invalidFileTypes }
    }
    return $invalidFileTypes
}

# Function to clean invalid file type associations
function Clean-InvalidFileTypes {
    param (
        [array]$invalidFileTypes
    )
    if ($invalidFileTypes -and $invalidFileTypes.Count -gt 0) {
        foreach ($entry in $invalidFileTypes) {
            try {
                Remove-Item -Path $entry -Force
                Log-Message "Removed invalid file type association: $entry"
            } catch {
                Log-Message "Error removing invalid file type association: $entry - $_"
            }
        }
    } else {
        Log-Message "No invalid file type associations to clean."
    }
}

# Function to scan for broken uninstall entries
function Scan-BrokenUninstallEntries {
    $brokenEntries = @()
    $uninstallKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    foreach ($key in $uninstallKeys) {
        $uninstallString = (Get-ItemProperty -Path $key.PSPath).UninstallString
        if ($uninstallString -and -not (Test-Path $uninstallString)) {
            $brokenEntries += $key.PSPath
        }
    }
    if ($brokenEntries.Count -gt 0) {
        Log-Message "Found broken uninstall entries:" -scanData @{ BrokenUninstallEntries = $brokenEntries }
    }
    return $brokenEntries
}

# Function to clean broken uninstall entries
function Clean-BrokenUninstallEntries {
    param (
        [array]$brokenEntries
    )
    if ($brokenEntries -and $brokenEntries.Count -gt 0) {
        foreach ($entry in $brokenEntries) {
            try {
                Remove-Item -Path $entry -Force
                Log-Message "Removed broken uninstall entry: $entry"
            } catch {
                Log-Message "Error removing broken uninstall entry: $entry - $_"
            }
        }
    } else {
        Log-Message "No broken uninstall entries to clean."
    }
}

# Main script
Log-Message "Starting registry scan and clean process..."

# Backup the registry
Measure-ExecutionTime -Code { Backup-Registry } -FunctionName "Backup-Registry"

# Scan for invalid application paths
$invalidAppPaths = Measure-ExecutionTime -Code { Scan-InvalidAppPaths } -FunctionName "Scan-InvalidAppPaths"

# Scan for orphaned COM/ActiveX entries
$orphanedComEntries = Measure-ExecutionTime -Code { Scan-OrphanedComEntries } -FunctionName "Scan-OrphanedComEntries"

# Scan for invalid file type associations
$invalidFileTypes = Measure-ExecutionTime -Code { Scan-InvalidFileTypes } -FunctionName "Scan-InvalidFileTypes"

# Scan for broken uninstall entries
$brokenUninstallEntries = Measure-ExecutionTime -Code { Scan-BrokenUninstallEntries } -FunctionName "Scan-BrokenUninstallEntries"

# User confirmation for cleaning
$confirmation = $null
$attemptCount = 0
while ($null -eq $confirmation -and $attemptCount -lt 3) {
    $userInput = Read-Host "Do you want to clean the found invalid entries? (Y/N)"
    switch ($userInput) {
        'Y' {
            $confirmation = $true
        }
        'N' {
            $confirmation = $false
        }
        default {
            Log-Message "Invalid input. Please enter 'Y' or 'N'."
            $attemptCount++
        }
    }
}
if ($confirmation -eq $true) {
    if ($invalidAppPaths.Count -gt 0) {
        Measure-ExecutionTime -Code { Clean-InvalidAppPaths -invalidEntries $invalidAppPaths } -FunctionName "Clean-InvalidAppPaths"
    }
    if ($orphanedComEntries.Count -gt 0) {
        Measure-ExecutionTime -Code { Clean-OrphanedComEntries -orphanedEntries $orphanedComEntries } -FunctionName "Clean-OrphanedComEntries"
    }
    if ($invalidFileTypes.Count -gt 0) {
        Measure-ExecutionTime -Code { Clean-InvalidFileTypes -invalidFileTypes $invalidFileTypes } -FunctionName "Clean-InvalidFileTypes"
    }
    if ($brokenUninstallEntries.Count -gt 0) {
        Measure-ExecutionTime -Code { Clean-BrokenUninstallEntries -brokenEntries $brokenUninstallEntries } -FunctionName "Clean-BrokenUninstallEntries"
    }
    Log-Message "Cleaning process completed."
} elseif ($confirmation -eq $false) {
    Log-Message "Cleaning process aborted by user."
} else {
    Log-Message "Cleaning process not executed due to repeated invalid inputs."
}