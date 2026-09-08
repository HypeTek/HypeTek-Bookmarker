# HypeTek Bookmarker v3.7 — Rebrand Preview

v3.7 introduces the new **HypeTek Bookmarker** name while keeping the proven v3.6 code and configuration format compatible.

## Rebrand
- Product name changed from **HypeTek Server Launcher** to **HypeTek Bookmarker**.
- UI terminology is broader: saved targets are now presented as entries/bookmarks instead of only servers.
- New Bookmarker-branded header artwork and launcher aliases.

## Compatibility
- Existing `servers.json` and `settings.json` files remain fully compatible.
- The internal `%LOCALAPPDATA%\HypeTek\ServerLauncher` path remains unchanged intentionally.
- `ServerLauncher.ps1` remains the core filename for this transition release.
- Existing `Start_ServerLauncher.vbs` / `.bat` files remain valid.
- New `Start_Bookmarker.vbs` / `.bat` launchers are the recommended entry points.

## Base functionality
All v3.6 functionality remains available, including custom wallpapers, persistent HypeTek header branding, device icons, Drag & Drop ordering, appearance reset and adaptive window sizing.
