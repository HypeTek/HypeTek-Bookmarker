<p align="center">
  <img src="docs/default-theme.jpg" alt="HypeTek Bookmarker default cyberpunk theme" width="820">
</p>

<h1 align="center">HypeTek Bookmarker</h1>

<p align="center">
  A lightweight, portable bookmark launcher for Windows 10/11 that opens servers, NAS systems and web interfaces with one click.
</p>

<p align="center">
  <img alt="Windows 10/11" src="https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows&logoColor=white">
  <img alt="PowerShell 5.1" src="https://img.shields.io/badge/PowerShell-5.1-5391FE?logo=powershell&logoColor=white">
  <img alt="Version 3.7.2" src="https://img.shields.io/badge/version-3.7.2-2ea44f">
  <img alt="MIT License" src="https://img.shields.io/badge/license-MIT-blue">
</p>

## Features

- **Native `HypeTek-Bookmarker.exe` launcher** for simple double-click startup
- Custom HypeTek application icon in Explorer, title bar and taskbar
- No visible PowerShell console for normal startup
- **One-click bookmark access** in your default browser
- **Drag & Drop reordering** with persistent tile order
- Add, edit and delete bookmark entries
- Hostnames, IP addresses, FQDNs and custom ports
- Multiple entries can use the same host with different ports
- Per-entry button colors plus a configurable default color
- **Bundled HypeTek cyberpunk default wallpaper for fresh installs**
- Custom wallpaper support: **BMP, PNG, JPG/JPEG, GIF and TIFF**
- Wallpaper modes: Fill, Fit and Stretch
- Adjustable wallpaper dimming
- **Bundled neon device icon set** for Server, PC, Laptop, Website, NAS, Router, Raspberry Pi, VM and Generic targets
- Automatic icon detection or manual per-entry icon selection
- Saved address shown below each tile label
- Icon-specific neon accent borders
- Languages: **Deutsch, English, Русский**
- Compact dynamic layout with scrolling for larger collections
- Right-click a tile to edit or delete it
- Portable: no installer and no administrator rights required
- **Subtle “Default design” reset** in Settings; it resets appearance only and never deletes bookmark entries

## Download

Stable ready-to-use builds are published under **GitHub Releases**.

1. Open **Releases** on the right side of the repository page.
2. Download the newest Windows ZIP.
3. Extract the complete archive, including the `resources` folder.
4. Double-click **`HypeTek-Bookmarker.exe`**.

For fallback or troubleshooting you can still use:

- `Start_Bookmarker.vbs` — silent PowerShell-based fallback launcher
- `Start_Bookmarker.bat` — troubleshooting launcher that keeps a console open

The native EXE hosts the existing PowerShell application core in-process. A normal local PowerShell ExecutionPolicy such as `Restricted` therefore does not block the EXE startup. Enterprise application-control technologies such as AppLocker or WDAC are not bypassed.

## Usage

1. Start `HypeTek-Bookmarker.exe`.
2. Click **Add entry**.
3. Enter a label and address.
4. Optionally choose an individual button color and icon.
5. Click a tile to open it.
6. Hold the left mouse button and drag a tile onto another tile to change the order.
7. Right-click a tile to edit or delete it.
8. Use the gear button to change language, default color, wallpaper and display settings.

Addresses without a protocol automatically use `http://`.

```text
192.168.1.10
server.local
server.local:8080
desktop-njdiu99.hydra-wrasse.ts.net
https://server.local:8443
```

## Default appearance

The bundled cyberpunk appearance is used automatically only when no `settings.json` exists yet.

Existing installations keep their current wallpaper, colors and settings after updating. To switch an existing installation to the bundled appearance, open **Settings** and use the small **Default design** button, then click **Apply**.

The reset affects only:

- default button color
- wallpaper
- wallpaper mode
- wallpaper dimming

It does **not** change or delete saved bookmarks.

## Bundled resources

The application ships with the visual resources required for the default appearance:

```text
resources/
├─ app.ico
├─ default-wallpaper.png
├─ default-wallpaper.jpg
├─ header-logo.png
├─ device-icons.png
├─ wall-800-q42.jpg
├─ wall-960-q45.jpg
├─ wall-1024-q48.jpg
├─ wall-1280-q55.jpg
└─ icons/
```

The launcher reads bundled device symbols from the resource set and falls back to Windows glyphs if an icon cannot be loaded.

## Configuration & privacy

In a normal writable folder, user configuration is stored next to the program:

```text
servers.json
settings.json
assets/
Error.txt
```

`assets/` is reserved for **user-selected wallpapers** and is intentionally excluded from the Git repository. Bundled project artwork lives in `resources/`.

If the launcher is placed under `C:\Program Files`, `C:\Program Files (x86)` or another protected/read-only location, personal data is stored automatically in:

```text
%LOCALAPPDATA%\HypeTek\ServerLauncher
```

No administrator rights are required.

The launcher does not send saved addresses or settings anywhere.

## Rebrand compatibility

The project was renamed from **HypeTek Server Launcher** to **HypeTek Bookmarker**. Existing configurations remain compatible. The internal `%LOCALAPPDATA%\HypeTek\ServerLauncher` data path and the core `ServerLauncher.ps1` filename are intentionally retained for now so upgrades do not lose saved entries or settings.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 components included with Windows
- WPF / .NET Framework components included with Windows

No additional runtime is required on supported Windows installations.

## Repository files

```text
HypeTek-Bookmarker.exe   Release package primary launcher (built by GitHub Actions)
ServerLauncher.ps1       Main application core (legacy filename kept for compatibility)
Start_Bookmarker.vbs     Silent fallback launcher
Start_Bookmarker.bat     Troubleshooting launcher
resources/               Bundled wallpaper, app icon and device icons
src/BookmarkerLauncher.cs Native EXE launcher source
.github/workflows/       Reproducible Windows EXE build workflow
docs/                    README screenshots
README.md                Project documentation
CHANGELOG.md             Version history
SECURITY.md              Security information
LICENSE                  MIT License
```

## Version

Stable release: **v3.7.2 HypeTek Bookmarker**

### v3.7.2 highlights

- Native `HypeTek-Bookmarker.exe` as the normal user-facing launcher
- HypeTek application icon in Explorer, window chrome and taskbar
- No visible PowerShell console during normal startup
- EXE startup works even when the ordinary local Windows PowerShell script ExecutionPolicy is disabled/restricted
- Existing PowerShell application core, settings and bookmark data remain compatible
- VBS and BAT launchers retained as fallback/troubleshooting options

## Deutsch

Der **HypeTek Bookmarker** ist ein portabler Windows-Bookmarker für Weboberflächen, NAS, Server, PCs und andere Netzwerkziele.

Ab **v3.7.2** startet die Anwendung für normale Nutzer bequem über **`HypeTek-Bookmarker.exe`**. Das eigene HypeTek-Logo erscheint dabei als Anwendungsicon, und beim normalen Start wird kein PowerShell-Konsolenfenster angezeigt. Die bisherigen VBS-/BAT-Starter bleiben als Fallback und für die Fehlersuche erhalten.

Eine frische Installation bringt bereits das HypeTek-Cyberpunk-Wallpaper und passende Gerätesymbole mit. Bestehende Konfigurationen werden beim Update **nicht überschrieben**. Der Design-Reset verändert ausschließlich Darstellungseinstellungen und löscht keine Einträge.

## License

HypeTek Bookmarker is released under the **MIT License**.

Copyright © 2026 HypeTek. See [`LICENSE`](LICENSE) for the full license text.
