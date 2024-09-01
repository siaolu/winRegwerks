# winRegwerks
# Optimized Registry Cleanup PowerShell Script

This PowerShell script provides an efficient and comprehensive registry cleanup solution. It scans for and removes various types of invalid registry entries in a single pass, improving performance and reducing system impact.

## Features

1. **Unified Scanning and Cleaning**: Combines scanning and cleaning of multiple registry areas into a single efficient process:
   - Invalid Application Paths
   - Orphaned COM/ActiveX Entries
   - Invalid File Type Associations
   - Broken Uninstall Entries

2. **Enhanced Logging**: 
   - In-memory logging with a single write operation at the end of the script execution.
   - Detailed logging of all actions and errors in a JSON file for easy parsing and analysis.

3. **Improved Performance**:
   - Utilizes efficient PowerShell cmdlets and techniques to reduce execution time.
   - Single-pass approach for scanning and cleaning reduces overall system impact.

4. **Accurate Execution Time Measurement**: 
   - Uses `System.Diagnostics.Stopwatch` for precise timing of each major function.

5. **Robust Registry Backup**: 
   - Creates a timestamped backup of the registry before any cleaning operations.

6. **Simplified User Interaction**: 
   - Single confirmation prompt before cleaning process begins.

7. **Error Handling**: 
   - Comprehensive error catching and logging for improved reliability and debugging.

8. **Flexibility**: 
   - Easily extendable structure for adding new types of registry cleanups in the future.

## Usage

To use the script, run the `winregux1.ps1` file in PowerShell with administrator privileges. You can optionally provide the paths for the log file and registry backup file as parameters.

```powershell
.\ImprovedRegistryCleanup.ps1 -LogFilePath 'C:\RegistryCleanupLog.json' -RegistryBackupPath 'C:\RegistryBackup.reg'
```

If no parameters are provided, the script will use default file paths in the current directory.

## Output

The script provides real-time console output of its progress and writes a detailed JSON log file. The log file includes:
- Timestamps for each operation
- Detailed information about scanned and cleaned entries
- Execution times for major functions
- Any errors encountered during the process

## Caution

While this script is designed to be safe and includes a registry backup feature, it's always recommended to:
1. Review the script before running it.
2. Ensure you have a full system backup before performing any registry cleanup operations.
3. Run the script in a test environment before using it on critical systems.

## Requirements

- Windows PowerShell 5.1 or later
- Administrator privileges

## Contributing

Contributions to improve the script are welcome. Please ensure that any pull requests include appropriate comments and maintain the existing code structure and logging mechanisms.

## License

This script is released under the MIT License. See the LICENSE file for details.