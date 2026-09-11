# Microsoft Store / MSIX workstream

Status: experimental branch `feature/ms-store-msix`. Stable v3.7.2 on `main` remains untouched.

## Goal

Prepare HypeTek Bookmarker as a packaged Win32/MSIX Microsoft Store candidate while keeping the existing portable ZIP release unchanged.

## Store hardening already in place

- explicit non-elevated `asInvoker` EXE manifest
- no `allowElevation` capability
- `runFullTrust` only for packaged Win32 desktop execution
- explicit `PerMonitorV2` DPI declarations plus early runtime `SetProcessDpiAwarenessContext(-4)`
- CI extraction/verification of the final embedded EXE manifest
- writable per-user startup log under `%LOCALAPPDATA%\HypeTek\Bookmarker\logs`
- legacy `%LOCALAPPDATA%\HypeTek\ServerLauncher` data path retained for compatibility
- ephemeral development certificate for sideload testing only
- local WACK runner and runtime DPI probe included with the artifact

## Run #10 icon cleanup

Real Windows 11 testing of the first HB Store builds showed two shell-specific visual issues: a blue/plated taskbar background and the older dark Start-menu icon surviving reinstall/cache cleanup.

Run #10 addresses both directly:

- development package version bumped to `3.7.2.1`
- new manifest asset base names (`HBLogo44`, `HBLogo150`, `HBStoreLogo`, `HBWide310x150`) so Windows cannot reuse the previous asset URI cache
- bright transparent HB artwork retained as the visual source
- committed multi-size `resources/app.ico` for the EXE and WPF window/dialog identity instead of the former single-frame generated ICO
- scale-qualified `HBLogo44.scale-*` assets
- `targetsize-*` assets for shell surfaces
- explicit `targetsize-*_altform-unplated.png` variants for Start/taskbar surfaces
- CI checks that required unplated assets exist and retain transparent corners

## Development identity

- Identity: `HypeTek.Bookmarker.Dev`
- Publisher: `CN=HypeTek Development`
- Version: `3.7.2.1`

These values are development-only. Do not finalize Store identity until Partner Center assigns the real identity/publisher values.

## Validation sequence for Run #10

1. Download and fully extract the newest `HypeTek-Bookmarker-Store-Test` artifact.
2. Run `Install-StoreTest.ps1` from elevated Windows PowerShell 5.1.
3. Launch **HypeTek Bookmarker** from Start.
4. First check the Start-menu, taskbar and title-bar icons for a bright freestanding HB shield with no dark/blue plate.
5. Smoke-test existing entries, add/edit/delete/reorder, settings/wallpaper and opening an address in the default browser.
6. Leave the app open and run `Test-DpiAwareness.ps1`; target is `PerMonitorV2` / PASS.
7. Close the app and run `Run-WackLocal.ps1` elevated.
8. Review the generated WACK XML.

## Remaining Store gates

- [ ] Run #10 icon cleanup confirmed on Windows 11
- [ ] Existing entries/settings load in packaged build
- [ ] Add/edit/delete/reorder persistence confirmed after restart
- [ ] Default-browser launch confirmed
- [ ] Wallpaper/settings persistence confirmed
- [ ] Runtime DPI context confirmed as `PerMonitorV2`
- [ ] Local WACK report reviewed with zero FAIL results
- [ ] HypeTek publishing/Partner Center account ready
- [ ] Final Store app name reserved
- [ ] Microsoft-assigned identity/publisher copied into manifest
- [ ] Final listing text/screenshots/assets reviewed
- [ ] Final Store-identity candidate rebuilt and certified

Do not merge this branch into stable `main` merely to publish the current portable version. Store-specific packaging remains isolated until the Store publication path is ready.
