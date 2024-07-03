@echo off

REM Set the paths for the PowerShell script and log file
set POWERSHELL_SCRIPT=RegistryCleanup.ps1
set LOG_FILE_PATH=C:\RegistryCleanupLog.json
set REGISTRY_BACKUP_PATH=C:\RegistryBackup.reg

REM Check if PowerShell is installed
where powershell.exe > nul 2>&1
if %errorlevel% neq 0 (
    echo PowerShell is not installed or not in the system PATH. Please install PowerShell and try again.
    goto end
)

REM Execute the PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0%POWERSHELL_SCRIPT%' -LogFilePath '%LOG_FILE_PATH%' -RegistryBackupPath '%REGISTRY_BACKUP_PATH%'"

:end
pause