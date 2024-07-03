# winRegwerks
# Registry Cleanup PowerShell Script

This PowerShell script provides a comprehensive registry cleanup solution. It scans for and removes various types of invalid registry entries, including:

1. **Invalid Application Paths**: Removes invalid entries in the `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths` registry key.
2. **Orphaned COM/ActiveX Entries**: Removes orphaned entries in the `HKCR:\CLSID` registry key.
3. **Invalid File Type Associations**: Removes invalid entries in the `HKCR` registry key.
4. **Broken Uninstall Entries**: Removes broken entries in the `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall` registry key.

The script also includes the following features:

- **Logging**: All actions and errors are logged in a JSON file.
- **Execution Time Measurement**: The execution time of each function is measured and logged.
- **Registry Backup**: The registry is backed up before any cleaning operations are performed.
- **User Confirmation**: The user is prompted to confirm the cleaning process before it is executed.

## Usage

To use the script, run the `RegistryCleanup.ps1` file in PowerShell. You can optionally provide the paths for the log file and registry backup file as parameters.

```powershell
.\RegistryCleanup.ps1 -LogFilePath 'C:\RegistryCleanupLog.json' -RegistryBackupPath 'C:\RegistryBackup.reg'