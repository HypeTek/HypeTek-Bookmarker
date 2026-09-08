# Changelog

All notable changes to **HypeTek Bookmarker** (formerly HypeTek Server Launcher) are documented here.

## [3.7.2] - 2026-09-09

### Added
- Native `HypeTek-Bookmarker.exe` launcher as the primary user-facing start method.
- Custom HypeTek application icon for Explorer, title bar and taskbar.
- Reproducible Windows EXE build workflow under `.github/workflows/`.
- Native launcher source under `src/BookmarkerLauncher.cs`.

### Changed
- Normal startup no longer opens a visible PowerShell console window.
- The EXE hosts the existing PowerShell application core in-process instead of launching `powershell.exe` as the visible application.
- Local Windows PowerShell ExecutionPolicy settings such as `Restricted` no longer block normal EXE startup.
- `Start_Bookmarker.vbs` and `Start_Bookmarker.bat` remain available as fallback and troubleshooting launchers.

### Compatibility / safety
- Existing `servers.json`, `settings.json` and `%LOCALAPPDATA%\HypeTek\ServerLauncher` data remain compatible.
- The internal `ServerLauncher.ps1` filename is retained.
- Enterprise controls such as AppLocker or WDAC are not bypassed.
- No administrator rights are required.

## [3.7.1] - 2026-09-08

### Changed
- Updated the bundled default cyberpunk wallpaper.
- Removed the duplicate HypeTek text embedded in the background artwork.
- Rebuilt all bundled wallpaper size variants from the updated artwork.

## [3.7] - 2026-09-08

### Rebrand
- Product renamed from **HypeTek Server Launcher** to **HypeTek Bookmarker**.
- Main UI terminology now uses broader entries/bookmarks instead of treating every target as a server.
- New HypeTek Bookmarker header artwork and README preview.
- Added `Start_Bookmarker.vbs` and `Start_Bookmarker.bat` as the recommended launchers.

### Compatibility
- Existing `servers.json` and `settings.json` files remain compatible.
- `%LOCALAPPDATA%\HypeTek\ServerLauncher` is intentionally retained so existing installations keep their configuration.
- `ServerLauncher.ps1` remains the internal core filename for this transition release.
- No automatic migration or deletion of saved entries is performed.

## [3.6] - 2026-09-08

### Added
- Bundled HypeTek cyberpunk default wallpaper for fresh installations.
- Persistent transparent HypeTek header logo that remains visible with custom wallpapers.
- Bundled neon PNG icon set for Server, PC, Laptop, Website, NAS, Router, Raspberry Pi, VM and Generic targets.
- Server addresses shown below tile labels.
- Device-type accent borders for server tiles.
- Optional Drag & Drop / right-click help text in Settings.
- Subtle **Default design** action in Settings.

### Changed
- Fresh installations start with the bundled wallpaper, a darker default tile color and 28% background dimming.
- Existing installations keep their current settings; the new appearance is not forced on upgrades.
- Bundled application artwork is stored under `resources/`, while user-selected wallpapers continue to use `assets/`.
- Default window width increased to 1060 DIPs.
- One-row startup height tuned to **359 DIPs**; additional tile rows grow automatically by 118 DIPs.
- Window auto-height no longer forces a manually enlarged window smaller.

### Safety / compatibility
- The Default design action resets appearance settings only and does not modify or delete saved servers.
- Missing bundled icon files fall back to the existing Windows glyphs.

## [3.5] - 2026-08-24

### Added
- Compact per-server icon dropdown in the add/edit dialog.
- New manual icon types: Server, PC, Laptop, Website and NAS.
- Additional useful icon types: Router, Raspberry Pi, VM and Generic.
- Automatic icon mode remains available.

### Changed
- Icon selection is visually smaller and placed beside the button-color controls.
- Existing v3.4.x icon values remain compatible.

## [3.4.2] - 2026-08-24

### Fixed
- Added writable per-user data fallback under `%LOCALAPPDATA%\HypeTek\ServerLauncher` for protected installation folders.
- Added one-time migration of existing portable configuration.
- Background assets and error logging now use the same writable data location.

## [3.4.1] - 2026-08-17

### Fixed
- Fixed a PowerShell variable-name collision in server tile icon rendering.
- Manual/automatic server icons now render correctly without the launcher closing.

## [3.4] - 2026-08-17

### Added
- Manually selectable server-tile icons in the add/edit dialog.
- Automatic icon detection remains available as the default icon mode.

### Documentation
- Updated README and release package references for v3.4.

## [3.3] - 2026-08-17

### Added
- Automatic device symbols on server tiles.
- Symbol detection for common server roles such as Raspberry Pi, NAS/storage, virtual machines, network/security services and generic web targets.

### Documentation
- Updated README and release package references for v3.3.

## [3.2] - 2026-08-17

### Added
- Drag & Drop reordering for server tiles.
- The new tile order is persisted immediately in `servers.json`.
- Server tiles provide native WPF drag feedback while being moved.
- Multilingual Drag & Drop hint in German, English and Russian.

### Documentation
- Refreshed GitHub README with HypeTek branding, badges and a release download button.
- Added dedicated v3.2 release notes.

## [3.1] - 2026-08-17

### Fixed
- Prevented dialog controls and Save/Cancel buttons from being clipped with Windows display scaling.
- Fixed gear/settings button padding and sizing.
- Increased settings dialog spacing for better DPI compatibility.

### Included from 3.0
- Migrated the UI from WinForms to WPF.
- Full-window background image instead of separate duplicated image areas.
- Server entries displayed as individual tiles without empty placeholders.
- Dynamic layout for configured server entries.
- Scrollable server area for larger collections.
- Background image support for BMP, PNG, JPG/JPEG, GIF and TIFF.
- Fill, Fit and Stretch background modes.
- Adjustable background dimming.
- Default and per-server button colors.
- German, English and Russian localization.
- Right-click actions for editing and deleting server entries.
