---
noteId: "f7e0acf0392311ef8cdb578e9e75e760"
tags: []

# Revisions

## Version 1.0 (Date)
- Initial release

## Version 1.1 (Date)
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

- Resolved unecessary complexity / improved modularity

