# v3.6.4 - Window sizing correction

- Corrects the one-row startup height after introducing the 88-DIP persistent header logo.
- One-row window now starts at 350 DIPs instead of 330 DIPs.
- Bottom breathing room is intended to mirror the gap between the Add Server button and the first tile.
- Additional tile rows still grow automatically by 118 DIPs per row.
- Existing wallpaper, header-logo overlay and ShowHint setting are unchanged.

# Changelog

All notable changes to HypeTek Server Launcher are documented here.

## [3.6] - Unreleased

### v3.6.2 preview UI polish
- Larger default startup window (1060 × 570) so the branded header and wallpaper are not cramped.
- Window auto-height no longer shrinks the launcher back to the old compact size.
- New persistent setting to show/hide the Drag & Drop / right-click help text.
- Keeps the persistent transparent HypeTek header logo and resilient bundled wallpaper fallback.

### Added
- Bundled HypeTek cyberpunk default wallpaper for fresh installations.
- Bundled neon PNG icon set for Server, PC, Laptop, Website, NAS, Router, Raspberry Pi, VM and Generic targets.
- Server addresses are now shown below tile labels.
- Device-type accent borders for server tiles.
- Subtle **Default design** action in Settings.

### Changed
- Fresh installations now start with the bundled wallpaper, a darker default tile color and 28% background dimming.
- Product title is consistently shown as **HypeTek Server Launcher** in all interface languages.
- Existing installations keep their current settings; the new appearance is not forced on upgrades.
- Bundled application artwork is stored under `resources/`, while user-selected wallpapers continue to use `assets/`.

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

### v3.6.3 Preview - compact adaptive start height
- Default start width remains 1060 px, but the one-row start height returns to a compact 330 px.
- Bottom spacing below the last tile now approximately mirrors the gap between the Add button and the first tile.
- Additional server rows grow the window by one full tile row (118 px) up to three visible rows.
- Existing manual larger window sizes are not forced smaller during refresh.
