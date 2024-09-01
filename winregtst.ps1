# Test module for winregux1 Registry Cleanup Script
# Save this as Test-Winregux1.psm1

using module Microsoft.PowerShell.Utility

# Import the main script to test its functions
# Assuming the main script is named winregux1.ps1 and is in the same directory
. .\winregux1.ps1

# Mock function to simulate registry entries
function New-MockRegistryKey {
    param (
        [string]$Path,
        [hashtable]$Properties
    )
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    $Properties.GetEnumerator() | ForEach-Object {
        New-ItemProperty -Path $Path -Name $_.Key -Value $_.Value -Force | Out-Null
    }
}

# Test function for Log-Message
function Test-LogMessage {
    $testMessage = "Test log message"
    $testScanData = @{ TestKey = "TestValue" }
    
    Log-Message -message $testMessage -scanData $testScanData
    
    $lastLogEntry = $script:logEntries[-1]
    
    Assert-NotNull $lastLogEntry "Log entry should not be null"
    Assert-AreEqual $testMessage $lastLogEntry.Message "Log message should match"
    Assert-AreEqual $testScanData $lastLogEntry.ScanData "Scan data should match"
}

# Test function for Measure-ExecutionTime
function Test-MeasureExecutionTime {
    $testFunctionName = "TestFunction"
    $testCode = { Start-Sleep -Milliseconds 100 }
    
    $output = Measure-ExecutionTime -Code $testCode -FunctionName $testFunctionName
    
    Assert-True ($output -match "Starting $testFunctionName...") "Should log start of function"
    Assert-True ($output -match "Finished $testFunctionName in \d+\.\d+ seconds") "Should log execution time"
}

# Test function for Backup-Registry
function Test-BackupRegistry {
    $testBackupPath = "TestDrive:\TestBackup.reg"
    
    Mock reg { return 0 } -Verifiable
    
    Backup-Registry -RegistryBackupPath $testBackupPath
    
    Assert-MockCalled reg -Times 1 -ParameterFilter { $args[0] -eq "export" -and $args[1] -eq "HKLM" }
    Assert-True (Test-Path $testBackupPath) "Backup file should be created"
}

# Test function for Scan-and-Clean-Registry
function Test-ScanAndCleanRegistry {
    # Create mock invalid registry entries
    New-MockRegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\InvalidApp.exe" -Properties @{
        "(Default)" = "C:\NonExistentPath\InvalidApp.exe"
    }
    New-MockRegistryKey -Path "HKCR:\CLSID\{12345678-1234-1234-1234-123456789012}" -Properties @{
        "InprocServer32" = "C:\NonExistentPath\InvalidCOM.dll"
    }
    
    # Run the scan and clean function
    $output = Scan-and-Clean-Registry
    
    # Check if invalid entries were detected
    Assert-True ($output -match "Found invalid entries:") "Should detect invalid entries"
    Assert-True ($output -match "AppPaths") "Should detect invalid App Paths"
    Assert-True ($output -match "ComEntries") "Should detect invalid COM entries"
    
    # Clean up mock registry entries
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\InvalidApp.exe" -Force
    Remove-Item -Path "HKCR:\CLSID\{12345678-1234-1234-1234-123456789012}" -Force
}

# Main test function to run all tests
function Run-AllTests {
    $tests = @(
        "Test-LogMessage",
        "Test-MeasureExecutionTime",
        "Test-BackupRegistry",
        "Test-ScanAndCleanRegistry"
    )
    
    $totalTests = $tests.Count
    $passedTests = 0
    
    foreach ($test in $tests) {
        try {
            & $test
            Write-Host "Test $test passed." -ForegroundColor Green
            $passedTests++
        }
        catch {
            Write-Host "Test $test failed: $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`nTest Summary:"
    Write-Host "Total tests: $totalTests"
    Write-Host "Passed tests: $passedTests"
    Write-Host "Failed tests: $($totalTests - $passedTests)"
}

# Helper assertion functions
function Assert-NotNull($actual, $message) {
    if ($null -eq $actual) { throw "Assertion failed: $message" }
}

function Assert-AreEqual($expected, $actual, $message) {
    if ($expected -ne $actual) { throw "Assertion failed: $message. Expected: $expected, Actual: $actual" }
}

function Assert-True($condition, $message) {
    if (-not $condition) { throw "Assertion failed: $message" }
}

# Export the main test function
Export-ModuleMember -Function Run-AllTests