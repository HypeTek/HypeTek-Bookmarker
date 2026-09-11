# Microsoft Store / MSIX workstream

Status: experimental branch `feature/ms-store-msix`. Stable v3.7.2 on `main` remains untouched.

## Goal

Prepare HypeTek Bookmarker as a packaged Win32/MSIX Microsoft Store candidate while keeping the existing portable ZIP release unchanged.

## Lessons carried over from CPU Throttling

This Store path deliberately includes the problems already discovered on HypeTek CPU Throttling instead of rediscovering them during certification:

- explicit non-elevated `asInvoker` EXE manifest
- no `allowElevation` capability
- `runFullTrust` only for packaged Win32 desktop execution
- explicit `PerMonitorV2` DPI declarations in the embedded native manifest
- early runtime `SetProcessDpiAwarenessContext(-4)` call before WPF/UI creation
- CI extraction of the final compiled EXE manifest with `mt.exe`
- per-user writable launcher log instead of writing beside the EXE in `WindowsApps`
- local WACK runner included with the test artifact
- runtime DPI probe included with the test artifact
- ephemeral development certificate for sideload testing only

## Product icon / Store visuals

The Store branch now has a dedicated **HB (HypeTek Bookmarker)** product icon at:

`resources/bookmarker-icon.png`

This PNG is the visual master for the packaged app:

- CI wraps the PNG in an ICO container for the compiled EXE icon.
- The native launcher applies the same PNG to the WPF main window and dialogs.
- Store/MSIX tile assets are generated from the same source during CI.

This keeps Explorer/EXE, taskbar/window chrome and Store visuals consistent and avoids the ICO-to-bitmap conversion problem found in the first packaging experiment.

`Build Store Test MSIX` run #5 validates this icon path end-to-end. Parser/contract checks, manifest validation, x64 EXE compilation, embedded-manifest verification, Store asset generation, MSIX packaging, signing, signature verification and artifact upload all pass.

Run #5 artifact digest:

`sha256:943648805496c44124bdc00f46508a6abff8dd2af09546caee45b4bd89acdff1`

## Compatibility

The PowerShell core already detects a protected/read-only program directory. Inside `C:\Program Files\WindowsApps`, its write probe fails by design and it falls back to the existing compatibility data path:

`%LOCALAPPDATA%\HypeTek\ServerLauncher`

That legacy path is intentionally retained so existing Bookmarker/Server Launcher entries and settings remain available. The Store-specific native launcher writes startup failures to:

`%LOCALAPPDATA%\HypeTek\Bookmarker\logs\startup.log`

The application itself requires no administrator rights. Administrator elevation is needed only by the development installer to trust the temporary self-signed CI certificate. A real Store package is signed through the Microsoft publication flow.

## Development identity

The sideload package currently uses:

- Identity: `HypeTek.Bookmarker.Dev`
- Publisher: `CN=HypeTek Development`
- Version: `3.7.2.0`

These are development-only values. Do not finalize Store identity until the HypeTek publishing/Partner Center path is ready and Microsoft has assigned the real identity/publisher values.

## Validation sequence

1. Download the newest `HypeTek-Bookmarker-Store-Test` artifact.
2. Extract the complete ZIP.
3. Run `Install-StoreTest.ps1` from an elevated Windows PowerShell 5.1 session.
4. Launch **HypeTek Bookmarker** normally from Start.
5. Confirm the new HB icon appears in Start/taskbar/window chrome.
6. Smoke-test existing entries, adding/editing/deleting an entry, drag-and-drop ordering, settings/wallpaper and opening at least one address in the default browser.
7. Leave the app open and run `Test-DpiAwareness.ps1` from a normal PowerShell session. Target: `PerMonitorV2` / PASS.
8. Close the app.
9. Run `Run-WackLocal.ps1` from elevated Windows PowerShell 5.1.
10. Review/upload the generated WACK XML.

## Store-readiness checklist

- [x] Stable `main` kept separate.
- [x] Dedicated Store/MSIX branch.
- [x] Native Store manifest uses `asInvoker`.
- [x] No `allowElevation` capability.
- [x] Packaged Win32 `runFullTrust` manifest.
- [x] `PerMonitorV2` in Store EXE manifest.
- [x] Early runtime DPI API fallback before UI creation.
- [x] Startup log moved to a writable per-user path for the Store branch.
- [x] Existing per-user Bookmarker data path retained for compatibility.
- [x] PowerShell helper/parser checks in CI.
- [x] CI verifies the manifest embedded in the final EXE.
- [x] Dedicated HB Bookmarker icon source added.
- [x] EXE/WPF/Store visuals derive from the same HB icon source.
- [x] HB icon Store build passes CI end-to-end (run #5).
- [x] Ephemeral sideload certificate/signing path.
- [x] Local WACK runner prepared.
- [x] Runtime DPI probe prepared.
- [ ] Store-test MSIX installs and launches on real Windows 11 hardware.
- [ ] New HB icon confirmed in Start/taskbar/window chrome on real hardware.
- [ ] Existing entries/settings load in packaged build.
- [ ] Add/edit/delete/reorder persistence confirmed after restart.
- [ ] Default-browser launch confirmed from packaged build.
- [ ] Wallpaper/settings changes confirmed in packaged build.
- [ ] Runtime DPI context confirmed as `PerMonitorV2`.
- [ ] Local WACK report reviewed with zero FAIL results.
- [ ] HypeTek publishing/Partner Center account ready.
- [ ] Final Store app name reserved.
- [ ] Microsoft-assigned identity/publisher copied into manifest.
- [ ] Final listing text/screenshots/assets reviewed.
- [ ] Final Store-identity candidate rebuilt and certified.

## Important

Do not merge this branch into stable `main` merely to publish the current portable version. The Store-specific packaging path should remain isolated until the Microsoft Store publication path is actually ready.
