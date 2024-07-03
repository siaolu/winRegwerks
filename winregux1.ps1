<#
.SYNOPSIS
    Performs various file and directory operations.

.DESCRIPTION
    This PowerShell script provides the following functions:

    1. Get-FileInfo: Retrieves information about a file or directory.
    2. Copy-FileToDesktop: Copies a file to the user's desktop.
    3. Remove-OldFiles: Deletes files that are older than a specified number of days.
    4. Create-Directory: Creates a new directory with the specified name.

.PARAMETER LogFilePath
    The path to the log file.

.PARAMETER RegistryBackupPath
    The path to the registry backup file.

.PARAMETER DaysOld
    The number of days after which files should be considered old and deleted.

.EXAMPLE
    PS> .\RegistryCleanup.ps1 -LogFilePath 'C:\RegistryCleanupLog.json' -RegistryBackupPath 'C:\RegistryBackup.reg' -DaysOld 30
    Runs the complete registry cleanup process, including scanning, logging, and cleaning of invalid entries.

.NOTES
    Author: Your Name
    Date: July 3, 2024
#>

param (
    [string]$LogFilePath = "RegistryCleanupLog.json",
    [string]$RegistryBackupPath = "RegistryBackup.reg",
    [int]$DaysOld = 30
)

# Logger function to log messages with timestamps and store in JSON format
function Log-Message {
    param (
        [string]$message,
        [hashtable]$scanData = $null
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = [ordered]@{
        Timestamp = $timestamp
        Message   = $message
        ScanData  = $scanData
    }

    try {
        $logFilePath = Join-Path -Path (Split-Path -Parent -Path $LogFilePath) -ChildPath (Split-Path -Leaf -Path $LogFilePath)
        $logContent = [System.Collections.ArrayList]@()
        if (Test-Path $logFilePath) {
            $logContent.AddRange((Get-Content -Path $logFilePath | ConvertFrom-Json))
        }
        $logContent.Add($logEntry) | Out-Null
        $logContent | ConvertTo-Json -Depth 10 | Set-Content -Path $logFilePath
    } catch {
        Write-Host "Error writing to log file: $_"
    }
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
    } finally {
        $endTime = Get-Date
        $duration = $endTime - $startTime
        Log-Message "Finished $FunctionName in $($duration.TotalSeconds) seconds."
    }
}

# Function to backup the registry
function Backup-Registry {
    param (
        [string]$RegistryBackupPath = "RegistryBackup.reg"
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path -Path (Split-Path -Parent -Path $RegistryBackupPath) -ChildPath "RegistryBackup_$timestamp.reg"

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

# Function to get file or directory information
function Get-FileInfo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Get-ChildItem -Path $Path
}

# Function to copy a file to the desktop
function Copy-FileToDesktop {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourcePath
    )

    $destPath = Join-Path -Path ([Environment]::GetFolderPath("Desktop")) -ChildPath (Split-Path -Leaf -Path $SourcePath)
    Copy-Item -Path $SourcePath -Destination $destPath
}

# Function to remove old files
function Remove-OldFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [int]$DaysOld = 30
    )

    $olderThan = (Get-Date).AddDays(-$DaysOld)
    Get-ChildItem -Path $Path -Exclude @((Get-ChildItem -Path $Path | Where-Object { $_.LastWriteTime -ge $olderThan }).Name) | Remove-Item
}

# Function to create a new directory
function Create-Directory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    New-Item -ItemType Directory -Name $Name
}

# Main script
Log-Message "Starting registry scan and clean process..."

# Backup the registry
Measure-ExecutionTime -Code { Backup-Registry -RegistryBackupPath $RegistryBackupPath } -FunctionName "Backup-Registry"

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
    switch ($userInput.ToUpper()) {
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