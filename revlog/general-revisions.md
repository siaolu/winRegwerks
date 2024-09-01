---
noteId: "f7e0acf0392311ef8cdb578e9e75e760"
tags: []

# Revisions

## Version 1.0 (03Jul2024)
- Initial release

## Version 1.1 (03JUL2024)
### Improvements

Improved Logging: 
The Log-Message function now creates a new log file for each script run, or appends to an existing log file if it's present. This reduces the overhead of logging and ensures that the log file doesn't grow too large over time.

Increased Modularity: 
The script now includes additional functions (Get-FileInfo, Copy-FileToDesktop, Remove-OldFiles, and Create-Directory) that can be used independently of the registry cleanup functionality.

Enhanced Configuration: 
The script now accepts parameters for the log file path, registry backup path, and the number of days for the Remove-OldFiles function. This makes the script more flexible and easier to use.

Simplified Remove-OldFiles: 
The Remove-OldFiles function has been simplified by using the Get-ChildItem cmdlet with the -Exclude parameter to exclude the newer files, making the function more efficient and easier to understand.

Optimized Copy-FileToDesktop: 
The Copy-FileToDesktop function now uses the Join-Path cmdlet to construct the destination path, which is more efficient than string manipulation.

### Bug Fixes
- Fixed issue(s):
    Item(1):Inefficient Logging: The Log-Message function appends the log entries to the existing log file every time it's called. This can lead to performance issues and unnecessary disk I/O, especially if the script is run frequently.

- Resolved unnecessary complexity / improved modularity


01Sept Revision Summary: 

1. Efficiency:
   - Combined separate scanning and cleaning functions into a single `Scan-and-Clean-Registry` function, reducing redundant registry traversals.
   - Used more efficient PowerShell cmdlets like `ForEach-Object` instead of foreach loops.
   - Implemented in-memory logging with a single write to file at the end, reducing I/O operations.

2. Speed:
   - Used `[System.Diagnostics.Stopwatch]` for more accurate timing measurements.
   - Reduced the number of registry traversals by combining scans.

3. Robustness:
   - Added error handling and logging for all critical operations.
   - Used `ErrorAction Stop` in Remove-Item to ensure errors are caught and logged.

4. Readability:
   - Added more comments explaining the purpose of each section.
   - Reorganized the code structure for better flow and understanding.

5. Flexibility:
   - Used a hashtable to store invalid entries, making it easier to add new categories in the future.

6. User Interaction:
   - Simplified the user confirmation process to a single prompt.

7. Logging:
   - Improved logging by storing entries in memory and writing to file once at the end.
   - Added more detailed logging throughout the script.

Info: Highlights:
- uses single-pass approach for scanning and cleaning 
- reduces the overall execution time
- improved error handling and logging 
- syslog like flow capture script operations 