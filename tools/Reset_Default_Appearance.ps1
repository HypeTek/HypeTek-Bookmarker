# Restores only the HypeTek default appearance.
# Server entries are never touched.

Add-Type -AssemblyName PresentationFramework

$BaseDir = Split-Path -Parent $PSScriptRoot

function Test-DirectoryWritable {
    param([string]$Path)
    try {
        $probe = Join-Path $Path ('.hypetek-reset-probe-' + $PID + '.tmp')
        [System.IO.File]::WriteAllText($probe,'test',[System.Text.Encoding]::UTF8)
        Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

$DataDir = $BaseDir
if (-not (Test-DirectoryWritable $BaseDir)) {
    $local=[Environment]::GetFolderPath('LocalApplicationData')
    if([string]::IsNullOrWhiteSpace($local)){$local=$env:LOCALAPPDATA}
    $DataDir=Join-Path $local 'HypeTek\ServerLauncher'
}
$settingsFile=Join-Path $DataDir 'settings.json'

$answer=[System.Windows.MessageBox]::Show(
    'Das HypeTek-Standarddesign wiederherstellen? Server und Server-Reihenfolge bleiben unveraendert.',
    'HypeTek Server Launcher',
    'YesNo',
    'Question'
)
if($answer -ne 'Yes'){ exit 0 }

$lang='de'
if(Test-Path -LiteralPath $settingsFile){
    try{
        $old=(Get-Content -LiteralPath $settingsFile -Raw)|ConvertFrom-Json
        if($old.Language){$lang=[string]$old.Language}
    }catch{}
}
$defaults=[ordered]@{
    Language=$lang
    DefaultButtonColor='#153A52'
    BackgroundImage='assets\default-wallpaper.png'
    BackgroundMode='Cover'
    BackgroundDim=26
}
if(-not(Test-Path -LiteralPath $DataDir)){[void](New-Item -ItemType Directory -Path $DataDir -Force)}
[System.IO.File]::WriteAllText($settingsFile,($defaults|ConvertTo-Json),(New-Object System.Text.UTF8Encoding($true)))

[System.Windows.MessageBox]::Show(
    'Standarddesign wiederhergestellt. Die Aenderung ist beim naechsten Start sichtbar.',
    'HypeTek Server Launcher',
    'OK',
    'Information'
)|Out-Null
