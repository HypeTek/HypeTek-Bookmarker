#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$cer = Join-Path $root 'HypeTek-Bookmarker-Store-Test.cer'
$msix = Join-Path $root 'HypeTek-Bookmarker-v3.7.2.2-Store-Test.msix'
$packageName = 'HypeTek.Bookmarker.Dev'
$publisherSubject = 'CN=HypeTek Development'

if (-not (Test-Path -LiteralPath $cer)) { throw "Certificate not found: $cer" }
if (-not (Test-Path -LiteralPath $msix)) { throw "MSIX not found: $msix" }

Write-Host 'HypeTek Bookmarker - Store test installer'
Write-Host 'This admin prompt is ONLY for development package setup.'
Write-Host 'The installed application itself runs without elevation.'
Write-Host ''

$existing = @(Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue)
foreach ($pkg in $existing) {
    Write-Host ("Removing previous Store test package: {0} {1}" -f $pkg.Name, $pkg.Version)
    Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
}

$staleCerts = @(Get-ChildItem 'Cert:\LocalMachine\TrustedPeople' | Where-Object { $_.Subject -eq $publisherSubject })
foreach ($oldCert in $staleCerts) {
    Write-Host ("Removing stale development certificate: {0}" -f $oldCert.Thumbprint)
    Remove-Item -LiteralPath $oldCert.PSPath -Force
}

$cert = Import-Certificate -FilePath $cer -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople'
Write-Host ('Trusted development certificate: {0}' -f $cert.Thumbprint)

Add-AppxPackage -Path $msix
Write-Host ''
Write-Host 'MSIX 3.7.2.2 installed. Launch HypeTek Bookmarker from the Start menu.'
Write-Host 'Existing Bookmarker data under %LOCALAPPDATA%\HypeTek\ServerLauncher is intentionally retained.'
