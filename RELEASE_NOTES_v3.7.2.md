# HypeTek Bookmarker v3.7.2

v3.7.2 makes the Bookmarker easier to start for normal Windows users by adding a native executable launcher.

## Highlights

- New **`HypeTek-Bookmarker.exe`** as the primary launcher
- HypeTek application icon in Explorer, the title bar and the Windows taskbar
- No visible PowerShell console window during normal startup
- Normal EXE startup works even when the local Windows PowerShell script ExecutionPolicy is set to `Restricted`
- Existing PowerShell application core and user configuration remain compatible
- `Start_Bookmarker.vbs` and `Start_Bookmarker.bat` remain included as fallback / troubleshooting launchers

## Compatibility

Existing installations can keep using their current configuration:

- `servers.json`
- `settings.json`
- `%LOCALAPPDATA%\HypeTek\ServerLauncher`

The internal `ServerLauncher.ps1` filename is intentionally retained for compatibility.

## Security note

The native launcher does **not** bypass enterprise application-control technologies such as AppLocker or WDAC. It only avoids the ordinary local PowerShell script ExecutionPolicy from blocking the application when the script is hosted by the Bookmarker EXE itself.

The executable is currently **not code-signed**, so Windows SmartScreen may show an unknown-publisher warning on some systems.

## Installation

1. Download `HypeTek_Bookmarker_v3.7.2_Windows_MIT.zip`.
2. Extract the complete archive.
3. Double-click `HypeTek-Bookmarker.exe`.

For troubleshooting, use `Start_Bookmarker.bat`.

## Requirements

- Windows 10 / 11
- Windows PowerShell 5.1 components included with Windows
- .NET Framework / WPF components included with Windows
- No administrator rights required

## License

MIT License — Copyright © 2026 HypeTek
