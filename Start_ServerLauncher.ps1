# HypeTek Server Launcher - startup bootstrap
# Initializes the bundled default appearance for new installations only.
# Existing user settings are preserved.

Add-Type -AssemblyName System.Drawing

$BaseDir = $PSScriptRoot

function Test-DirectoryWritable {
    param([string]$Path)
    try {
        $probe = Join-Path $Path ('.hypetek-theme-probe-' + $PID + '.tmp')
        [System.IO.File]::WriteAllText($probe, 'test', [System.Text.Encoding]::UTF8)
        Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

function Get-LauncherDataDir {
    if (Test-DirectoryWritable $BaseDir) { return $BaseDir }
    $local = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($local)) { $local = $env:LOCALAPPDATA }
    $dir = Join-Path $local 'HypeTek\ServerLauncher'
    if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    return $dir
}

function Save-Png {
    param([System.Drawing.Bitmap]$Bitmap,[string]$Path)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { [void](New-Item -ItemType Directory -Path $parent -Force) }
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function New-CyberWallpaper {
    param([string]$Path)
    $w=1600; $h=900
    $bmp=[System.Drawing.Bitmap]::new($w,$h)
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $rect=[System.Drawing.Rectangle]::new(0,0,$w,$h)
        $brush=[System.Drawing.Drawing2D.LinearGradientBrush]::new($rect,[System.Drawing.Color]::FromArgb(7,13,25),[System.Drawing.Color]::FromArgb(12,28,44),90.0)
        $g.FillRectangle($brush,$rect); $brush.Dispose()

        $rand=[System.Random]::new(42)
        for($x=0;$x -lt $w;$x+=48){
            $bh=$rand.Next(220,650); $y=$h-$bh
            $body=[System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(225,8,16,28))
            $g.FillRectangle($body,$x,$y,39,$bh); $body.Dispose()
            for($wy=$y+24;$wy -lt $h-35;$wy+=34){
                $c=if((($x/48)+($wy/34))%3 -eq 0){[System.Drawing.Color]::FromArgb(190,0,213,255)}else{[System.Drawing.Color]::FromArgb(180,255,35,110)}
                $light=[System.Drawing.SolidBrush]::new($c)
                $g.FillRectangle($light,$x+8,$wy,22,5); $light.Dispose()
            }
        }

        $haze=[System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(80,0,180,220))
        $g.FillRectangle($haze,0,590,$w,5); $haze.Dispose()

        for($i=0;$i -lt 25;$i++){
            $yy=610+($i*11); $alpha=[Math]::Max(8,70-($i*2))
            $pen1=[System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb($alpha,0,205,255),2)
            $pen2=[System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb($alpha,255,40,110),2)
            $g.DrawLine($pen1,100,$yy,720+$i*8,$yy); $g.DrawLine($pen2,880-$i*7,$yy,1510,$yy)
            $pen1.Dispose(); $pen2.Dispose()
        }

        # Abstract operator silhouette on the left; center/right remain readable.
        $sil=[System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(175,3,8,16))
        $g.FillEllipse($sil,105,135,300,300); $g.FillPie($sil,45,330,470,600,190,160); $sil.Dispose()
        $edge=[System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180,0,210,255),5)
        $g.DrawArc($edge,105,135,300,300,120,180); $edge.Dispose()
        $edge2=[System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(160,255,35,110),4)
        $g.DrawArc($edge2,70,280,430,500,205,95); $edge2.Dispose()
        $shade=[System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(70,0,0,0))
        $g.FillRectangle($shade,500,0,1100,900); $shade.Dispose()
    } finally { $g.Dispose() }
    try { Save-Png $bmp $Path } finally { $bmp.Dispose() }
}

function New-NeonIcon {
    param([string]$Kind,[string]$Path)
    $bmp=[System.Drawing.Bitmap]::new(96,96)
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $cyan=[System.Drawing.Color]::FromArgb(0,215,255); $pink=[System.Drawing.Color]::FromArgb(255,55,145)
        $pen=[System.Drawing.Pen]::new($cyan,6); $pen2=[System.Drawing.Pen]::new($pink,4)
        switch($Kind){
            'Server' { $g.DrawRectangle($pen,22,18,52,60); $g.DrawLine($pen,22,40,74,40); $g.DrawLine($pen,22,58,74,58); $g.DrawEllipse($pen2,30,27,4,4); $g.DrawEllipse($pen2,30,48,4,4) }
            'PC' { $g.DrawRectangle($pen,16,18,64,46); $g.DrawLine($pen,48,64,48,77); $g.DrawLine($pen,31,78,65,78) }
            'Laptop' { $g.DrawRectangle($pen,20,18,56,45); $g.DrawLine($pen,13,75,83,75); $g.DrawLine($pen,20,63,13,75); $g.DrawLine($pen,76,63,83,75) }
            'Website' { $g.DrawEllipse($pen,16,16,64,64); $g.DrawLine($pen,16,48,80,48); $g.DrawArc($pen,31,16,34,64,90,180); $g.DrawArc($pen,31,16,34,64,270,180) }
            'NAS' { $g.DrawRectangle($pen,24,13,48,70); $g.DrawRectangle($pen2,31,24,34,14); $g.DrawRectangle($pen2,31,47,34,14); $g.DrawEllipse($pen2,32,68,5,5) }
            'Router' { $g.DrawRectangle($pen,18,48,60,27); $g.DrawLine($pen,31,48,23,20); $g.DrawLine($pen,65,48,73,20); $g.DrawArc($pen2,30,23,36,25,210,120) }
            'Raspberry' { $g.DrawEllipse($pen2,26,29,44,44); $g.DrawEllipse($pen2,19,20,26,24); $g.DrawEllipse($pen2,51,20,26,24); $g.DrawLine($pen,38,18,48,8); $g.DrawLine($pen,56,18,48,8) }
            'VM' { $pts=[System.Drawing.Point[]]@([System.Drawing.Point]::new(48,13),[System.Drawing.Point]::new(76,30),[System.Drawing.Point]::new(76,64),[System.Drawing.Point]::new(48,82),[System.Drawing.Point]::new(20,64),[System.Drawing.Point]::new(20,30)); $g.DrawPolygon($pen,$pts); $g.DrawLine($pen,20,30,48,48); $g.DrawLine($pen,76,30,48,48); $g.DrawLine($pen,48,48,48,82) }
            default { $g.DrawEllipse($pen,18,18,60,60); $g.DrawLine($pen2,31,48,65,48) }
        }
        $pen.Dispose(); $pen2.Dispose()
    } finally { $g.Dispose() }
    try { Save-Png $bmp $Path } finally { $bmp.Dispose() }
}

$DataDir=Get-LauncherDataDir
$AssetsDir=Join-Path $DataDir 'assets'; $IconDir=Join-Path $AssetsDir 'icons'
if(-not(Test-Path -LiteralPath $AssetsDir)){[void](New-Item -ItemType Directory -Path $AssetsDir -Force)}
if(-not(Test-Path -LiteralPath $IconDir)){[void](New-Item -ItemType Directory -Path $IconDir -Force)}

$wallpaper=Join-Path $AssetsDir 'default-wallpaper.png'
if(-not(Test-Path -LiteralPath $wallpaper)){New-CyberWallpaper $wallpaper}
foreach($kind in @('Server','PC','Laptop','Website','NAS','Router','Raspberry','VM','Generic')){
    $iconPath=Join-Path $IconDir ($kind.ToLowerInvariant()+'.png')
    if(-not(Test-Path -LiteralPath $iconPath)){New-NeonIcon $kind $iconPath}
}

$settingsFile=Join-Path $DataDir 'settings.json'
if(-not(Test-Path -LiteralPath $settingsFile)){
    $defaults=[ordered]@{Language='de';DefaultButtonColor='#153A52';BackgroundImage='assets\default-wallpaper.png';BackgroundMode='Cover';BackgroundDim=26}
    [System.IO.File]::WriteAllText($settingsFile,($defaults|ConvertTo-Json),(New-Object System.Text.UTF8Encoding($true)))
}

& (Join-Path $BaseDir 'ServerLauncher.ps1')
