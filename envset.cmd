@echo off

REM Set the paths for the PowerShell scripts and log file
set REGISTRY_CLEANUP_SCRIPT=winregux1.ps1
set TEST_SCRIPT=winregtst.ps1
set LOG_FILE_PATH=C:\RegistryCleanupLog.json
set REGISTRY_BACKUP_PATH=C:\RegistryBackup.reg

REM Check if PowerShell is installed
where powershell.exe > nul 2>&1
if %errorlevel% neq 0 (
    echo PowerShell is not installed or not in the system PATH. Please install PowerShell and try again.
    goto end
)

:menu
cls
echo Windows Registry Utility
echo ========================
echo 1. Run Registry Cleanup (winregux1.ps1)
echo 2. Run Test Suite (winregtst.ps1)
echo 3. Exit
echo.
set /p choice=Enter your choice (1-3): 

if "%choice%"=="1" goto run_cleanup
if "%choice%"=="2" goto run_tests
if "%choice%"=="3" goto end

echo Invalid choice. Please try again.
timeout /t 2 >nul
goto menu

:run_cleanup
echo Running Registry Cleanup...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0%REGISTRY_CLEANUP_SCRIPT%' -LogFilePath '%LOG_FILE_PATH%' -RegistryBackupPath '%REGISTRY_BACKUP_PATH%'"
echo.
echo Registry Cleanup completed. Press any key to return to the menu.
pause >nul
goto menu

:run_tests
echo Running Test Suite...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0%TEST_SCRIPT%"
echo.
echo Test Suite completed. Press any key to return to the menu.
pause >nul
goto menu

:end
echo Exiting...
timeout /t 2 >nul