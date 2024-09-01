<#
.SYNOPSIS
    Performs various registry cleanup operations with improved efficiency and robustness.

.DESCRIPTION
    This PowerShell script provides the following optimized functions:
    1. Log-Message: Logs messages with timestamps and stores them in a JSON log file.
    2. Measure-ExecutionTime: Measures the execution time of a given script block and logs the results.
    3. Backup-Registry: Backs up the registry to a file.
    4. Scan-and-Clean-Registry: Scans and cleans various registry issues in a single pass.

.PARAMETER LogFilePath
    The path to the log file.

.PARAMETER RegistryBackupPath
    The path to the registry backup file.

.EXAMPLE
    PS> .\winregux1.ps1 -LogFilePath 'C:\RegistryCleanupLog.json' -RegistryBackupPath 'C:\RegistryBackup.reg'
    Runs the optimized registry cleanup process, including scanning, logging, and cleaning of invalid entries.

.NOTES
    fused by dasLuftwafa
    Date: 91Sept2024
#>

param (
    [string]$LogFilePath = "RegistryCleanupLog.json",
    [string]$RegistryBackupPath = "RegistryBackup.reg"
)

# Import necessary modules
Import-Module Microsoft.PowerShell.Utility

# Initialize an array to store log entries
$script:logEntries = @()

# Logger function to log messages with timestamps
function Log-Message {
    param (
        [string]$message,
        [hashtable]$scanData = $null
    )

    $logEntry = [ordered]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Message   = $message
        ScanData  = $scanData
    }
    $script:logEntries += $logEntry
    Write-Host $message
}

# Function to write log entries to file
function Write-LogToFile {
    $script:logEntries | ConvertTo-Json -Depth 10 | Set-Content -Path $LogFilePath
}

# Timer function to measure execution time
function Measure-ExecutionTime {
    param (
        [scriptblock]$Code,
        [string]$FunctionName
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Log-Message "Starting $FunctionName..."

    try {
        & $Code
    }
    catch {
        Log-Message "Error in $FunctionName: $_"
        throw
    }
    finally {
        $stopwatch.Stop()
        Log-Message "Finished $FunctionName in $($stopwatch.Elapsed.TotalSeconds) seconds."
    }
}

# Function to backup the registry
function Backup-Registry {
    param (
        [string]$RegistryBackupPath
    )

    $backupPath = [System.IO.Path]::ChangeExtension($RegistryBackupPath, "$(Get-Date -Format 'yyyyMMdd-HHmmss').reg")

    try {
        reg export HKLM $backupPath /y
        if ($LASTEXITCODE -eq 0) {
            Log-Message "Registry backup successful: $backupPath"
        }
        else {
            throw "Backup failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Log-Message "Error during registry backup: $_"
        throw
    }
}

# Function to scan and clean various registry issues
function Scan-and-Clean-Registry {
    $invalidEntries = @{
        AppPaths = @()
        ComEntries = @()
        FileTypes = @()
        UninstallEntries = @()
    }

    # Scan and clean App Paths
    Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths" | ForEach-Object {
        $exePath = (Get-ItemProperty -Path $_.PSPath).'(Default)'
        if ($exePath -and -not (Test-Path $exePath)) {
            $invalidEntries.AppPaths += $_.PSPath
        }
    }

    # Scan and clean COM/ActiveX entries
    Get-ChildItem -Path "HKCR:\CLSID" | ForEach-Object {
        $inprocServer = (Get-ItemProperty -Path $_.PSPath).InprocServer32
        if ($inprocServer -and -not (Test-Path $inprocServer)) {
            $invalidEntries.ComEntries += $_.PSPath
        }
    }

    # Scan and clean file type associations
    Get-ChildItem -Path "HKCR" | Where-Object { $_.PSIsContainer } | ForEach-Object {
        $default = (Get-ItemProperty -Path $_.PSPath).'(Default)'
        if ($default -and -not (Get-Item -Path "HKCR:\$default" -ErrorAction SilentlyContinue)) {
            $invalidEntries.FileTypes += $_.PSPath
        }
    }

    # Scan and clean uninstall entries
    Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object {
        $uninstallString = (Get-ItemProperty -Path $_.PSPath).UninstallString
        if ($uninstallString -and -not (Test-Path $uninstallString)) {
            $invalidEntries.UninstallEntries += $_.PSPath
        }
    }

    # Log scan results
    Log-Message "Scan completed. Found invalid entries:" -scanData $invalidEntries

    # Clean invalid entries if user confirms
    $confirmation = Read-Host "Do you want to clean the found invalid entries? (Y/N)"
    if ($confirmation -eq 'Y') {
        $invalidEntries.GetEnumerator() | ForEach-Object {
            $category = $_.Key
            $entries = $_.Value
            $entries | ForEach-Object {
                try {
                    Remove-Item -Path $_ -Force -ErrorAction Stop
                    Log-Message "Removed invalid $category entry: $_"
                }
                catch {
                    Log-Message "Error removing invalid $category entry: $_ - $_"
                }
            }
        }
        Log-Message "Cleaning process completed."
    }
    else {
        Log-Message "Cleaning process aborted by user."
    }
}

# Main script
Log-Message "Starting optimized registry scan and clean process..."

# Backup the registry
Measure-ExecutionTime -Code { Backup-Registry -RegistryBackupPath $RegistryBackupPath } -FunctionName "Backup-Registry"

# Scan and clean registry
Measure-ExecutionTime -Code { Scan-and-Clean-Registry } -FunctionName "Scan-and-Clean-Registry"

# Write logs to file
Write-LogToFile

Log-Message "Registry cleanup process completed."