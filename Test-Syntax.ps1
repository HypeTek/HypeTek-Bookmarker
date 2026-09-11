# HypeTek Bookmarker - Store parser/static contract test
# Windows PowerShell 5.1+

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath
$files = @(
    (Join-Path $root 'ServerLauncher.ps1'),
    (Join-Path $root 'store\Install-StoreTest.ps1'),
    (Join-Path $root 'tools\Run-WackLocal.ps1'),
    (Join-Path $root 'tools\Test-DpiAwareness.ps1')
)

$failed = $false
foreach ($file in $files) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$errors)
    if ($errors.Count -eq 0) {
        Write-Host "OK  $file" -ForegroundColor Green
    } else {
        $failed = $true
        Write-Host "ERR $file" -ForegroundColor Red
        foreach ($e in $errors) {
            Write-Host ("  Line {0}, Column {1}: {2}" -f $e.Extent.StartLineNumber,$e.Extent.StartColumnNumber,$e.Message) -ForegroundColor Red
        }
    }
}

$launcher = Get-Content (Join-Path $root 'src\BookmarkerLauncher.cs') -Raw
foreach ($needle in @('SetProcessDpiAwarenessContext','DpiAwarenessContextPerMonitorAwareV2','TryEnablePerMonitorV2Dpi','LocalApplicationData','HypeTek", "Bookmarker", "logs')) {
    if ($launcher -notlike ('*' + $needle + '*')) {
        $failed = $true
        Write-Host "ERR launcher contract missing: $needle" -ForegroundColor Red
    } else {
        Write-Host "OK  launcher contract: $needle" -ForegroundColor Green
    }
}

if ($failed) { exit 1 }
Write-Host 'All Store helper scripts parse and the launcher contract is complete.' -ForegroundColor Green
exit 0
