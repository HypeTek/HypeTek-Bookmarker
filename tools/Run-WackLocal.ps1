#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$PackageName = 'HypeTek.Bookmarker.Dev',
    [string]$ReportDirectory = (Join-Path $env:USERPROFILE 'Documents\HypeTek\Bookmarker\WACK')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$appCertCandidates = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\App Certification Kit\appcert.exe'),
    (Join-Path $env:ProgramFiles 'Windows Kits\10\App Certification Kit\appcert.exe')
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

$appCert = $appCertCandidates | Select-Object -First 1
if (-not $appCert) {
    throw @'
Windows App Certification Kit (appcert.exe) was not found.
Install the current Windows SDK / Windows App Certification Kit and run this script again.
Typical path: C:\Program Files (x86)\Windows Kits\10\App Certification Kit\appcert.exe
'@
}

$packages = @(Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue | Sort-Object Version -Descending)
if ($packages.Count -eq 0) {
    throw "Installed Store-test package '$PackageName' was not found. Install the current MSIX first with Install-StoreTest.ps1."
}

$package = $packages[0]
New-Item -ItemType Directory -Path $ReportDirectory -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportPath = Join-Path $ReportDirectory "HypeTek-Bookmarker-WACK-$stamp.xml"

Write-Host 'HypeTek Bookmarker - Windows App Certification Kit' -ForegroundColor Cyan
Write-Host ("WACK:    {0}" -f $appCert)
Write-Host ("Package: {0}" -f $package.PackageFullName)
Write-Host ("Report:  {0}" -f $reportPath)
Write-Host ''
Write-Host 'The certification test may launch and close the app automatically. Do not use the machine heavily while the test is running.' -ForegroundColor Yellow
Write-Host ''

Get-Process -Name 'HypeTek-Bookmarker' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host '[1/2] Resetting Windows App Certification Kit state...'
& $appCert reset
$resetExit = $LASTEXITCODE
if ($resetExit -ne 0) { throw "appcert.exe reset failed with exit code $resetExit." }

Write-Host '[2/2] Running certification tests...'
& $appCert test -packagefullname $package.PackageFullName -reportoutputpath $reportPath
$testExit = $LASTEXITCODE

Write-Host ''
if (Test-Path -LiteralPath $reportPath) {
    Write-Host ("WACK report created: {0}" -f $reportPath) -ForegroundColor Green
    try {
        $raw = Get-Content -LiteralPath $reportPath -Raw -Encoding UTF8
        if ($raw -match '(?i)OVERALL_RESULT\s*=\s*["'']PASS["'']') {
            Write-Host 'Detected overall result: PASS' -ForegroundColor Green
        }
        elseif ($raw -match '(?i)OVERALL_RESULT\s*=\s*["'']FAIL["'']') {
            Write-Host 'Detected overall result: FAIL' -ForegroundColor Red
        }
        elseif ($raw -match '(?i)OVERALL_RESULT\s*=\s*["'']WARNING["'']') {
            Write-Host 'Detected overall result: WARNING' -ForegroundColor Yellow
        }
    }
    catch { Write-Host 'The report was created; automatic summary parsing was skipped.' -ForegroundColor Yellow }
}
else {
    Write-Warning 'No WACK report file was found at the expected path.'
}

Write-Host ("appcert.exe test exit code: {0}" -f $testExit)
Write-Host 'Send the generated WACK XML back for review before Store submission.' -ForegroundColor Cyan
if ($testExit -ne 0) { exit $testExit }
exit 0
