# HypeTek Server Launcher v3.6 — Preview Notes

v3.6 refreshes the out-of-box appearance without taking control away from existing users.

## New
- HypeTek cyberpunk wallpaper is bundled and enabled on fresh installs.
- Custom neon device icons are bundled with the application.
- Tile addresses are visible below the server name.
- Device types receive matching neon accent borders.
- Settings include a small **Default design** button.

## Upgrade behavior
Existing `settings.json` files are respected. Updating from v3.5 does not replace a user's wallpaper or colors automatically.

To try the new appearance on an existing installation:
1. Open Settings.
2. Click **Default design**.
3. Click **Apply**.

Saved servers are not modified.

## Packaging
The release ZIP must include the full `resources/` folder next to `ServerLauncher.ps1`.
