# HypeTek Bookmarker V3.7 Preview
# Windows 10/11 - Windows PowerShell 5.1 - WPF

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:BaseDir = $PSScriptRoot
$script:BundledAssetsDir = Join-Path $script:BaseDir 'resources'
$script:DefaultWallpaperToken = '@default'

# Use the program folder while it is writable (portable mode). If the launcher
# is placed in a protected location such as C:\Program Files, store user data
# under LocalAppData instead so normal users never need administrator rights.
$script:DataDir = $script:BaseDir
try {
    $probe = Join-Path $script:BaseDir ('.hypetek-write-test-' + $PID + '.tmp')
    [System.IO.File]::WriteAllText($probe,'test',[System.Text.Encoding]::UTF8)
    Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
} catch {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($localAppData)) { $localAppData = $env:LOCALAPPDATA }
    $script:DataDir = Join-Path $localAppData 'HypeTek\ServerLauncher'
    if (-not (Test-Path -LiteralPath $script:DataDir)) {
        [void](New-Item -ItemType Directory -Path $script:DataDir -Force)
    }

    # One-time migration: if a portable configuration exists next to the
    # program, copy it into the user-writable data folder without overwriting
    # an existing per-user configuration.
    foreach($name in @('servers.json','settings.json')) {
        $source = Join-Path $script:BaseDir $name
        $target = Join-Path $script:DataDir $name
        if ((Test-Path -LiteralPath $source) -and -not (Test-Path -LiteralPath $target)) {
            Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction SilentlyContinue
        }
    }
    $sourceAssets = Join-Path $script:BaseDir 'assets'
    $targetAssets = Join-Path $script:DataDir 'assets'
    if ((Test-Path -LiteralPath $sourceAssets) -and -not (Test-Path -LiteralPath $targetAssets)) {
        Copy-Item -LiteralPath $sourceAssets -Destination $targetAssets -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$script:ServersFile = Join-Path $script:DataDir 'servers.json'
$script:SettingsFile = Join-Path $script:DataDir 'settings.json'
$script:AssetsDir = Join-Path $script:DataDir 'assets'
$script:ErrorFile = Join-Path $script:DataDir 'Error.txt'
$script:Servers = @()
$script:Settings = $null
$script:Window = $null
$script:ServerPanel = $null
$script:BackgroundImageControl = $null
$script:DimOverlay = $null
$script:HeaderLogo = $null
$script:TitleText = $null
$script:SubtitleText = $null
$script:AddButton = $null
$script:GearButton = $null
$script:HintText = $null
$script:EmptyText = $null
$script:ServerButtonStyle = $null
$script:IconSprite = $null
$script:DragStartPoint = New-Object System.Windows.Point 0,0
$script:LastDragEnd = [datetime]::MinValue

$script:Translations = @{
    de = @{
        Title='HypeTek Bookmarker'; Subtitle='Server, NAS & Weboberflächen mit einem Klick öffnen'; Add='Eintrag hinzufügen';
        Settings='Einstellungen'; Name='Bezeichnung'; Address='Adresse'; Color='Buttonfarbe';
        Default='Standard'; Save='Speichern'; Cancel='Abbrechen'; Edit='Bearbeiten'; Delete='Löschen';
        DeleteConfirm='Diesen Eintrag wirklich löschen?'; Language='Sprache'; DefaultColor='Standard-Buttonfarbe';
        Background='Hintergrundbild'; Choose='Auswählen'; Remove='Entfernen'; Apply='Übernehmen';
        NoServers='Noch keine Einträge vorhanden.'; InvalidAddress='Bitte eine Adresse eingeben.';
        InvalidName='Bitte eine Buttonbeschriftung eingeben.'; BrowseImage='Hintergrundbild auswählen';
        OpenError='Die Adresse konnte nicht geöffnet werden.'; AppSettings='Bookmarker-Einstellungen';
        NewServer='Neuer Eintrag'; EditServer='Eintrag bearbeiten'; Error='Fehler';
        Hint='Drag & Drop: Reihenfolge ändern  •  Rechtsklick: Bearbeiten oder Löschen'; BackgroundNone='Kein Hintergrundbild ausgewählt';
        BackgroundMode='Bildanpassung'; ModeCover='Ausfüllen'; ModeFit='Einpassen'; ModeStretch='Strecken';
        BackgroundDim='Hintergrund abdunkeln'; Percent='%'; DefaultWallpaper='HypeTek Standard-Wallpaper'; ResetDesign='Standarddesign'; ResetDesignHint='Setzt nur Farben, Wallpaper und Darstellung zurück – Einträge bleiben unverändert.';
        ShowHint='Hilfstext für Drag & Drop / Rechtsklick anzeigen'; ColorChoose='Farbe wählen'; AddressExample='z. B. 192.168.1.10 oder https://server.local:8443'; Icon='Symbol'; IconAuto='Automatisch'; IconServer='Server'; IconPC='PC'; IconLaptop='Laptop'; IconWebsite='Website'; IconNAS='NAS'; IconRouter='Router'; IconRaspberry='Raspberry Pi'; IconVM='VM / Virtualisierung'; IconGeneric='Allgemein'
    }
    en = @{
        Title='HypeTek Bookmarker'; Subtitle='Open servers, NAS & web interfaces with one click'; Add='Add entry';
        Settings='Settings'; Name='Label'; Address='Address'; Color='Button color';
        Default='Default'; Save='Save'; Cancel='Cancel'; Edit='Edit'; Delete='Delete';
        DeleteConfirm='Really delete this entry?'; Language='Language'; DefaultColor='Default button color';
        Background='Background image'; Choose='Choose'; Remove='Remove'; Apply='Apply';
        NoServers='No entries added yet.'; InvalidAddress='Please enter an address.';
        InvalidName='Please enter a button label.'; BrowseImage='Choose background image';
        OpenError='The address could not be opened.'; AppSettings='Bookmarker settings';
        NewServer='New entry'; EditServer='Edit entry'; Error='Error';
        Hint='Drag & drop: reorder entries  •  Right-click: edit or delete'; BackgroundNone='No background image selected';
        BackgroundMode='Image scaling'; ModeCover='Fill'; ModeFit='Fit'; ModeStretch='Stretch';
        BackgroundDim='Darken background'; Percent='%'; DefaultWallpaper='HypeTek default wallpaper'; ResetDesign='Default design'; ResetDesignHint='Resets only colors, wallpaper and appearance – saved entries stay unchanged.';
        ShowHint='Show drag & drop / right-click help text'; ColorChoose='Choose color'; AddressExample='e.g. 192.168.1.10 or https://server.local:8443'; Icon='Icon'; IconAuto='Automatic'; IconServer='Server'; IconPC='PC'; IconLaptop='Laptop'; IconWebsite='Website'; IconNAS='NAS'; IconRouter='Router'; IconRaspberry='Raspberry Pi'; IconVM='VM / Virtualization'; IconGeneric='Generic'
    }
    ru = @{
        Title='HypeTek Bookmarker'; Subtitle='Серверы, NAS и веб-интерфейсы в один клик'; Add='Добавить запись';
        Settings='Настройки'; Name='Название'; Address='Адрес'; Color='Цвет кнопки';
        Default='По умолчанию'; Save='Сохранить'; Cancel='Отмена'; Edit='Изменить'; Delete='Удалить';
        DeleteConfirm='Удалить эту запись?'; Language='Язык'; DefaultColor='Цвет кнопок по умолчанию';
        Background='Фоновое изображение'; Choose='Выбрать'; Remove='Удалить'; Apply='Применить';
        NoServers='Записей пока нет.'; InvalidAddress='Введите адрес.';
        InvalidName='Введите название кнопки.'; BrowseImage='Выберите фоновое изображение';
        OpenError='Не удалось открыть адрес.'; AppSettings='Настройки Bookmarker';
        NewServer='Новая запись'; EditServer='Изменить запись'; Error='Ошибка';
        Hint='Drag & Drop: изменить порядок  •  Правый клик: изменить или удалить'; BackgroundNone='Фоновое изображение не выбрано';
        BackgroundMode='Масштаб изображения'; ModeCover='Заполнить'; ModeFit='Вписать'; ModeStretch='Растянуть';
        BackgroundDim='Затемнение фона'; Percent='%'; DefaultWallpaper='Стандартные обои HypeTek'; ResetDesign='Стандартный дизайн'; ResetDesignHint='Сбрасывает только цвета, обои и оформление – записи не изменяются.';
        ShowHint='Показывать подсказку Drag & Drop / правый клик'; ColorChoose='Выбрать цвет'; AddressExample='например 192.168.1.10 или https://server.local:8443'; Icon='Символ'; IconAuto='Автоматически'; IconServer='Сервер'; IconPC='ПК'; IconLaptop='Ноутбук'; IconWebsite='Веб-сайт'; IconNAS='NAS'; IconRouter='Роутер'; IconRaspberry='Raspberry Pi'; IconVM='VM / виртуализация'; IconGeneric='Общее'
    }
}

function Write-LauncherError {
    param([object]$ErrorObject)
    try {
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $text = "$stamp`r`n$($ErrorObject | Out-String)`r`n"
        [System.IO.File]::WriteAllText($script:ErrorFile, $text, (New-Object System.Text.UTF8Encoding($true)))
    } catch {}
}

function Write-Utf8Bom {
    param([string]$Path,[string]$Text)
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($true)))
}

function Get-T {
    param([string]$Key)
    $lang='de'
    if ($script:Settings -and $script:Settings.Language) { $lang=[string]$script:Settings.Language }
    if (-not $script:Translations.ContainsKey($lang)) { $lang='de' }
    return [string]$script:Translations[$lang][$Key]
}

function Ensure-Data {
    if (-not (Test-Path -LiteralPath $script:AssetsDir)) { [void](New-Item -ItemType Directory -Path $script:AssetsDir -Force) }
    if (-not (Test-Path -LiteralPath $script:ServersFile)) { Write-Utf8Bom $script:ServersFile '[]' }
    if (-not (Test-Path -LiteralPath $script:SettingsFile)) {
        $default=[ordered]@{ Language='de'; DefaultButtonColor='#163A52'; BackgroundImage=$script:DefaultWallpaperToken; BackgroundMode='Cover'; BackgroundDim=28; ShowHint=$true }
        Write-Utf8Bom $script:SettingsFile ($default | ConvertTo-Json)
    }
}

function Load-Data {
    Ensure-Data
    try {
        $raw=Get-Content -LiteralPath $script:ServersFile -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) { $script:Servers=@() }
        else { $p=$raw | ConvertFrom-Json -ErrorAction Stop; if ($null -eq $p) {$script:Servers=@()} else {$script:Servers=@($p)} }
    } catch { Write-LauncherError $_; $script:Servers=@() }
    try {
        $script:Settings=(Get-Content -LiteralPath $script:SettingsFile -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-LauncherError $_
        $script:Settings=[pscustomobject]@{ Language='de'; DefaultButtonColor='#163A52'; BackgroundImage=$script:DefaultWallpaperToken; BackgroundMode='Cover'; BackgroundDim=28; ShowHint=$true }
    }
    if (-not $script:Settings.PSObject.Properties['Language']) { $script:Settings | Add-Member -NotePropertyName Language -NotePropertyValue 'de' -Force }
    if (-not $script:Settings.PSObject.Properties['DefaultButtonColor']) { $script:Settings | Add-Member -NotePropertyName DefaultButtonColor -NotePropertyValue '#2F80C1' -Force }
    if (-not $script:Settings.PSObject.Properties['BackgroundImage']) { $script:Settings | Add-Member -NotePropertyName BackgroundImage -NotePropertyValue $script:DefaultWallpaperToken -Force }
    if (-not $script:Settings.PSObject.Properties['BackgroundMode']) { $script:Settings | Add-Member -NotePropertyName BackgroundMode -NotePropertyValue 'Cover' -Force }
    if (-not $script:Settings.PSObject.Properties['BackgroundDim']) { $script:Settings | Add-Member -NotePropertyName BackgroundDim -NotePropertyValue 45 -Force }
    if (-not $script:Settings.PSObject.Properties['ShowHint']) { $script:Settings | Add-Member -NotePropertyName ShowHint -NotePropertyValue $true -Force }
}

function Save-Servers {
    $json=if ($script:Servers.Count -eq 0) {'[]'} else {$script:Servers | ConvertTo-Json -Depth 6}
    Write-Utf8Bom $script:ServersFile $json
}
function Save-Settings { Write-Utf8Bom $script:SettingsFile ($script:Settings | ConvertTo-Json -Depth 6) }

function Get-Brush {
    param([string]$Hex,[string]$Fallback='#2F80C1')
    try { $bc=New-Object System.Windows.Media.BrushConverter; return $bc.ConvertFromString($(if([string]::IsNullOrWhiteSpace($Hex)){$Fallback}else{$Hex})) }
    catch { $bc=New-Object System.Windows.Media.BrushConverter; return $bc.ConvertFromString($Fallback) }
}

function Open-ServerAddress {
    param([string]$Address)
    try {
        $url=$Address.Trim()
        if ($url -notmatch '^[a-zA-Z][a-zA-Z0-9+.-]*://') { $url='http://' + $url }
        Start-Process $url
    } catch {
        Write-LauncherError $_
        [System.Windows.MessageBox]::Show((Get-T 'OpenError'),(Get-T 'Error'),'OK','Error') | Out-Null
    }
}

function Get-ServerSymbol {
    param([string]$Name,[string]$Address,[string]$Icon='Auto')

    function New-SymbolResult {
        param([string]$Key,[string]$Glyph,[string]$Font='Segoe UI Emoji')
        return [pscustomobject]@{ IconKey=$Key; Glyph=$Glyph; Font=$Font }
    }

    switch([string]$Icon){
        'Server'    { return New-SymbolResult 'server' '🖧' }
        'PC'        { return New-SymbolResult 'pc' '🖥' }
        'Laptop'    { return New-SymbolResult 'laptop' '💻' }
        'Website'   { return New-SymbolResult 'website' '🌐' }
        'NAS'       { return New-SymbolResult 'nas' '🗄' }
        'Router'    { return New-SymbolResult 'router' '📡' }
        'Raspberry' { return New-SymbolResult 'raspberry' '🍓' }
        'VM'        { return New-SymbolResult 'vm' '⬡' 'Segoe UI Symbol' }
        'Generic'   { return New-SymbolResult 'generic' '🔗' }
        # Compatibility with icon values written by v3.4.x
        'Storage'   { return New-SymbolResult 'nas' '🗄' }
        'Security'  { return New-SymbolResult 'router' '📡' }
        'Web'       { return New-SymbolResult 'website' '🌐' }
    }

    # Automatic mode: resolve a matching bundled icon while keeping the old
    # emoji glyph as a safe fallback if an asset is missing.
    $text=((([string]$Name)+' '+([string]$Address)).ToLowerInvariant())
    if($text -match 'rasp|raspberry|pi-hole|pihole'){ return New-SymbolResult 'raspberry' '🍓' }
    elseif($text -match 'nas|truenas|synology|qnap|storage'){ return New-SymbolResult 'nas' '🗄' }
    elseif($text -match 'laptop|notebook'){ return New-SymbolResult 'laptop' '💻' }
    elseif($text -match 'desktop|workstation|\bpc\b'){ return New-SymbolResult 'pc' '🖥' }
    elseif($text -match 'proxmox|hyper-v|esxi|vmware|vcenter|virtual|\bvm\b|commander'){ return New-SymbolResult 'vm' '⬡' 'Segoe UI Symbol' }
    elseif($text -match 'router|gateway|firewall|vpn|opnsense|pfsense'){ return New-SymbolResult 'router' '📡' }
    elseif($text -match 'www\.|website|web|nginx|apache|http'){ return New-SymbolResult 'website' '🌐' }
    elseif($text -match 'server'){ return New-SymbolResult 'server' '🖧' }
    else { return New-SymbolResult 'generic' '🔗' }
}

function Get-ServerAccentColor {
    param([string]$Name,[string]$Address,[string]$Icon='Auto')
    $symbol=Get-ServerSymbol -Name $Name -Address $Address -Icon $Icon
    switch([string]$symbol.IconKey){
        'nas'       { return '#FF962E' }
        'vm'        { return '#B06CFF' }
        'router'    { return '#35E6A6' }
        'raspberry' { return '#FF5B9E' }
        'website'   { return '#34B7FF' }
        default     { return '#00D9FF' }
    }
}

function Get-BundledIconSource {
    param([string]$IconKey)
    try{
        if($null -eq $script:IconSprite){
            $spritePath=Join-Path $script:BundledAssetsDir 'device-icons.png'
            if(-not(Test-Path -LiteralPath $spritePath)){return $null}
            $bi=New-Object System.Windows.Media.Imaging.BitmapImage
            $bi.BeginInit()
            $bi.CacheOption='OnLoad'
            $bi.UriSource=New-Object System.Uri -ArgumentList $spritePath
            $bi.EndInit()
            $bi.Freeze()
            $script:IconSprite=$bi
        }

        $index=9
        switch([string]$IconKey){
            'auto'      {$index=0}
            'server'    {$index=1}
            'pc'        {$index=2}
            'laptop'    {$index=3}
            'website'   {$index=4}
            'nas'       {$index=5}
            'router'    {$index=6}
            'raspberry' {$index=7}
            'vm'        {$index=8}
            'generic'   {$index=9}
        }
        $x=($index % 5)*128
        $y=[int]([Math]::Floor($index / 5)*128)
        $rect=New-Object System.Windows.Int32Rect -ArgumentList $x,$y,128,128
        $crop=New-Object System.Windows.Media.Imaging.CroppedBitmap -ArgumentList $script:IconSprite,$rect
        $crop.Freeze()
        return $crop
    }catch{
        Write-LauncherError $_
        return $null
    }
}

function New-ServerTileContent {
    param([string]$Name,[string]$Address,[string]$Icon='Auto')
    $symbol=Get-ServerSymbol -Name $Name -Address $Address -Icon $Icon
    $stack=New-Object System.Windows.Controls.StackPanel
    $stack.Orientation='Vertical'
    $stack.HorizontalAlignment='Center'
    $stack.VerticalAlignment='Center'

    $visualAdded=$false
    $bundledIcon=Get-BundledIconSource -IconKey ([string]$symbol.IconKey)
    if($null -ne $bundledIcon){
        $iconImage=New-Object System.Windows.Controls.Image
        $iconImage.Source=$bundledIcon
        $iconImage.Width=34
        $iconImage.Height=34
        $iconImage.Stretch='Uniform'
        $iconImage.HorizontalAlignment='Center'
        $iconImage.Margin='0,0,0,3'
        [void]$stack.Children.Add($iconImage)
        $visualAdded=$true
    }

    if(-not $visualAdded){
        $iconText=New-Object System.Windows.Controls.TextBlock
        $iconText.Text=[string]$symbol.Glyph
        $iconText.FontFamily=[string]$symbol.Font
        $iconText.FontSize=24
        $iconText.HorizontalAlignment='Center'
        $iconText.TextAlignment='Center'
        $iconText.Margin='0,0,0,4'
        [void]$stack.Children.Add($iconText)
    }

    $label=New-Object System.Windows.Controls.TextBlock
    $label.Text=[string]$Name
    $label.Foreground=[System.Windows.Media.Brushes]::White
    $label.FontSize=14.5
    $label.FontWeight='SemiBold'
    $label.TextAlignment='Center'
    $label.TextWrapping='Wrap'
    $label.MaxWidth=190
    $label.HorizontalAlignment='Center'
    [void]$stack.Children.Add($label)

    $addressText=New-Object System.Windows.Controls.TextBlock
    $addressText.Text=[string]$Address
    $addressText.Foreground=Get-Brush '#BFEFFF'
    $addressText.FontSize=10.5
    $addressText.TextAlignment='Center'
    $addressText.TextTrimming='CharacterEllipsis'
    $addressText.MaxWidth=195
    $addressText.HorizontalAlignment='Center'
    $addressText.Margin='0,2,0,0'
    [void]$stack.Children.Add($addressText)

    return $stack
}

function New-DialogWindow {
    param([string]$Title,[double]$Width=520,[double]$Height=360)
    $w=New-Object System.Windows.Window
    $w.Title=$Title; $w.Width=$Width; $w.Height=$Height
    $w.WindowStartupLocation='CenterOwner'; $w.ResizeMode='NoResize'; $w.ShowInTaskbar=$false
    $w.Background=Get-Brush '#1C1F26'; $w.Foreground=[System.Windows.Media.Brushes]::White
    $w.FontFamily='Segoe UI'; $w.FontSize=14
    if ($script:Window) { $w.Owner=$script:Window }
    return $w
}

function New-TextBox {
    $tb=New-Object System.Windows.Controls.TextBox
    $tb.Height=34; $tb.Padding='8,5'; $tb.Background=Get-Brush '#292D36'; $tb.Foreground=[System.Windows.Media.Brushes]::White
    $tb.BorderBrush=Get-Brush '#535966'; $tb.BorderThickness='1'; $tb.FontSize=14
    return $tb
}

function New-FlatButton {
    param([string]$Text,[double]$Width=110,[string]$Color='#353A45')
    $b=New-Object System.Windows.Controls.Button
    $b.Content=$Text; $b.Width=$Width; $b.Height=36; $b.Margin='6,0,0,0'; $b.Padding='10,4'; $b.Cursor='Hand'
    $b.Background=Get-Brush $Color; $b.Foreground=[System.Windows.Media.Brushes]::White
    $b.BorderBrush=Get-Brush '#66707D'; $b.BorderThickness='1'; $b.FontWeight='SemiBold'
    return $b
}

function Show-ServerDialog {
    param([int]$Index=-1)
    $isEdit=($Index -ge 0 -and $Index -lt $script:Servers.Count)
    $dlg=New-DialogWindow $(if($isEdit){Get-T 'EditServer'}else{Get-T 'NewServer'}) 520 450

    # Robustes Auto-Layout: keine festen Zeilenhoehen, damit Beschriftungen und Buttons
    # bei unterschiedlicher Windows-Skalierung / Sprache nicht abgeschnitten werden.
    $root=New-Object System.Windows.Controls.Grid
    $root.Margin='24'
    $rowMain=New-Object System.Windows.Controls.RowDefinition; $rowMain.Height='*'
    $rowButtons=New-Object System.Windows.Controls.RowDefinition; $rowButtons.Height='Auto'
    [void]$root.RowDefinitions.Add($rowMain); [void]$root.RowDefinitions.Add($rowButtons)
    $dlg.Content=$root

    $fields=New-Object System.Windows.Controls.StackPanel
    [System.Windows.Controls.Grid]::SetRow($fields,0)
    [void]$root.Children.Add($fields)

    $lblName=New-Object System.Windows.Controls.TextBlock
    $lblName.Text=Get-T 'Name'
    $lblName.Margin='0,0,0,5'
    [void]$fields.Children.Add($lblName)

    $txtName=New-TextBox
    $txtName.Margin='0,0,0,14'
    [void]$fields.Children.Add($txtName)

    $lblAddr=New-Object System.Windows.Controls.TextBlock
    $lblAddr.Text=Get-T 'Address'
    $lblAddr.Margin='0,0,0,5'
    [void]$fields.Children.Add($lblAddr)

    $txtAddr=New-TextBox
    [void]$fields.Children.Add($txtAddr)

    $example=New-Object System.Windows.Controls.TextBlock
    $example.Text=Get-T 'AddressExample'
    $example.Foreground=Get-Brush '#AEB6C4'
    $example.FontSize=12
    $example.Margin='2,4,0,14'
    $example.TextWrapping='Wrap'
    [void]$fields.Children.Add($example)

    # Color remains the primary customization. The icon selector is deliberately
    # compact and sits beside it instead of taking a full section in the dialog.
    $customLabels=New-Object System.Windows.Controls.Grid
    $customLabels.Margin='0,0,0,5'
    $cl1=New-Object System.Windows.Controls.ColumnDefinition; $cl1.Width='*'
    $cl2=New-Object System.Windows.Controls.ColumnDefinition; $cl2.Width='190'
    [void]$customLabels.ColumnDefinitions.Add($cl1); [void]$customLabels.ColumnDefinitions.Add($cl2)

    $lblColor=New-Object System.Windows.Controls.TextBlock
    $lblColor.Text=Get-T 'Color'
    [System.Windows.Controls.Grid]::SetColumn($lblColor,0)
    [void]$customLabels.Children.Add($lblColor)

    $lblIcon=New-Object System.Windows.Controls.TextBlock
    $lblIcon.Text=Get-T 'Icon'
    $lblIcon.FontSize=12
    $lblIcon.Foreground=Get-Brush '#B6BECA'
    $lblIcon.Margin='12,0,0,0'
    [System.Windows.Controls.Grid]::SetColumn($lblIcon,1)
    [void]$customLabels.Children.Add($lblIcon)
    [void]$fields.Children.Add($customLabels)

    $colorRow=New-Object System.Windows.Controls.Grid
    $cr1=New-Object System.Windows.Controls.ColumnDefinition; $cr1.Width='*'
    $cr2=New-Object System.Windows.Controls.ColumnDefinition; $cr2.Width='190'
    [void]$colorRow.ColumnDefinitions.Add($cr1); [void]$colorRow.ColumnDefinitions.Add($cr2)
    [void]$fields.Children.Add($colorRow)

    $colorButtons=New-Object System.Windows.Controls.StackPanel
    $colorButtons.Orientation='Horizontal'
    [System.Windows.Controls.Grid]::SetColumn($colorButtons,0)
    [void]$colorRow.Children.Add($colorButtons)

    $cmbIcon=New-Object System.Windows.Controls.ComboBox
    $cmbIcon.Height=32
    $cmbIcon.Width=178
    $cmbIcon.Margin='12,0,0,0'
    $cmbIcon.HorizontalAlignment='Left'
    $cmbIcon.FontSize=12.5
    [void]$cmbIcon.Items.Add(('✦  ' + (Get-T 'IconAuto')))
    [void]$cmbIcon.Items.Add(('🖧  ' + (Get-T 'IconServer')))
    [void]$cmbIcon.Items.Add(('🖥  ' + (Get-T 'IconPC')))
    [void]$cmbIcon.Items.Add(('💻  ' + (Get-T 'IconLaptop')))
    [void]$cmbIcon.Items.Add(('🌐  ' + (Get-T 'IconWebsite')))
    [void]$cmbIcon.Items.Add(('🗄  ' + (Get-T 'IconNAS')))
    [void]$cmbIcon.Items.Add(('📡  ' + (Get-T 'IconRouter')))
    [void]$cmbIcon.Items.Add(('🍓  ' + (Get-T 'IconRaspberry')))
    [void]$cmbIcon.Items.Add(('⬡  ' + (Get-T 'IconVM')))
    [void]$cmbIcon.Items.Add(('🔗  ' + (Get-T 'IconGeneric')))
    $cmbIcon.SelectedIndex=0
    [System.Windows.Controls.Grid]::SetColumn($cmbIcon,1)
    [void]$colorRow.Children.Add($cmbIcon)

    $colorBtn=New-FlatButton (Get-T 'ColorChoose') 150 '#2F80C1'
    $colorBtn.Margin='0'
    $defaultBtn=New-FlatButton (Get-T 'Default') 120 '#353A45'
    $colorBtn.Tag=''

    if ($isEdit) {
        $txtName.Text=[string]$script:Servers[$Index].Name
        $txtAddr.Text=[string]$script:Servers[$Index].Address
        if ($script:Servers[$Index].PSObject.Properties['Color']) { $colorBtn.Tag=[string]$script:Servers[$Index].Color }
        if ($script:Servers[$Index].PSObject.Properties['Icon']) {
            switch([string]$script:Servers[$Index].Icon){
                'Server' {$cmbIcon.SelectedIndex=1}
                'PC' {$cmbIcon.SelectedIndex=2}
                'Laptop' {$cmbIcon.SelectedIndex=3}
                'Website' {$cmbIcon.SelectedIndex=4}
                'NAS' {$cmbIcon.SelectedIndex=5}
                'Router' {$cmbIcon.SelectedIndex=6}
                'Raspberry' {$cmbIcon.SelectedIndex=7}
                'VM' {$cmbIcon.SelectedIndex=8}
                'Generic' {$cmbIcon.SelectedIndex=9}
                # Compatibility with v3.4.x values
                'Storage' {$cmbIcon.SelectedIndex=5}
                'Security' {$cmbIcon.SelectedIndex=6}
                'Web' {$cmbIcon.SelectedIndex=4}
                default {$cmbIcon.SelectedIndex=0}
            }
        }
    }

    $previewHex=if([string]::IsNullOrWhiteSpace([string]$colorBtn.Tag)){[string]$script:Settings.DefaultButtonColor}else{[string]$colorBtn.Tag}
    $colorBtn.Background=Get-Brush $previewHex
    [void]$colorButtons.Children.Add($colorBtn)
    [void]$colorButtons.Children.Add($defaultBtn)

    $colorBtn.Add_Click({
        $cd=New-Object System.Windows.Forms.ColorDialog
        try { $cd.Color=[System.Drawing.ColorTranslator]::FromHtml($(if([string]::IsNullOrWhiteSpace([string]$colorBtn.Tag)){[string]$script:Settings.DefaultButtonColor}else{[string]$colorBtn.Tag})) } catch {}
        if ($cd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $hex=('#{0:X2}{1:X2}{2:X2}' -f $cd.Color.R,$cd.Color.G,$cd.Color.B)
            $colorBtn.Tag=$hex
            $colorBtn.Background=Get-Brush $hex
        }
    })
    $defaultBtn.Add_Click({
        $colorBtn.Tag=''
        $colorBtn.Background=Get-Brush ([string]$script:Settings.DefaultButtonColor)
    })

    $buttons=New-Object System.Windows.Controls.StackPanel
    $buttons.Orientation='Horizontal'
    $buttons.HorizontalAlignment='Right'
    $buttons.Margin='0,18,0,0'
    [System.Windows.Controls.Grid]::SetRow($buttons,1)
    [void]$root.Children.Add($buttons)

    $saveBtn=New-FlatButton (Get-T 'Save') 110 '#008DF3'
    $saveBtn.Height=38
    $cancelBtn=New-FlatButton (Get-T 'Cancel') 110 '#353A45'
    $cancelBtn.Height=38
    [void]$buttons.Children.Add($saveBtn)
    [void]$buttons.Children.Add($cancelBtn)

    $cancelBtn.Add_Click({ $dlg.DialogResult=$false; $dlg.Close() })
    $saveBtn.Add_Click({
        if ([string]::IsNullOrWhiteSpace($txtName.Text)) {
            [System.Windows.MessageBox]::Show((Get-T 'InvalidName'),(Get-T 'Error'),'OK','Warning')|Out-Null
            return
        }
        if ([string]::IsNullOrWhiteSpace($txtAddr.Text)) {
            [System.Windows.MessageBox]::Show((Get-T 'InvalidAddress'),(Get-T 'Error'),'OK','Warning')|Out-Null
            return
        }
        $icon='Auto'
        switch([int]$cmbIcon.SelectedIndex){
            1 {$icon='Server'}
            2 {$icon='PC'}
            3 {$icon='Laptop'}
            4 {$icon='Website'}
            5 {$icon='NAS'}
            6 {$icon='Router'}
            7 {$icon='Raspberry'}
            8 {$icon='VM'}
            9 {$icon='Generic'}
            default {$icon='Auto'}
        }
        $obj=[pscustomobject]@{ Name=$txtName.Text.Trim(); Address=$txtAddr.Text.Trim(); Color=[string]$colorBtn.Tag; Icon=$icon }
        if ($isEdit) { $script:Servers[$Index]=$obj } else { $script:Servers += $obj }
        Save-Servers
        $dlg.DialogResult=$true
        $dlg.Close()
    })

    $result=$dlg.ShowDialog()
    if ($result -eq $true) { Refresh-ServerButtons }
}

function Test-ImageFile {
    param([string]$Path)
    try {
        $bi=New-Object System.Windows.Media.Imaging.BitmapImage
        $bi.BeginInit(); $bi.CacheOption='OnLoad'; $bi.UriSource=New-Object System.Uri -ArgumentList $Path; $bi.EndInit(); $bi.Freeze(); return $true
    } catch { Write-LauncherError $_; return $false }
}

function Show-SettingsDialog {
    $dlg=New-DialogWindow (Get-T 'AppSettings') 600 620
    $grid=New-Object System.Windows.Controls.Grid; $grid.Margin='24'; $dlg.Content=$grid
    for($i=0;$i -lt 12;$i++){ $r=New-Object System.Windows.Controls.RowDefinition; $r.Height='Auto'; [void]$grid.RowDefinitions.Add($r) }

    $lblLang=New-Object System.Windows.Controls.TextBlock; $lblLang.Text=Get-T 'Language'; [System.Windows.Controls.Grid]::SetRow($lblLang,0); [void]$grid.Children.Add($lblLang)
    $cmbLang=New-Object System.Windows.Controls.ComboBox; $cmbLang.Height=34; $cmbLang.Margin='0,5,0,16'; $cmbLang.Items.Add('Deutsch')|Out-Null; $cmbLang.Items.Add('English')|Out-Null; $cmbLang.Items.Add('Русский')|Out-Null
    switch([string]$script:Settings.Language){'en'{$cmbLang.SelectedIndex=1};'ru'{$cmbLang.SelectedIndex=2};default{$cmbLang.SelectedIndex=0}}
    [System.Windows.Controls.Grid]::SetRow($cmbLang,1); [void]$grid.Children.Add($cmbLang)

    $lblColor=New-Object System.Windows.Controls.TextBlock; $lblColor.Text=Get-T 'DefaultColor'; [System.Windows.Controls.Grid]::SetRow($lblColor,2); [void]$grid.Children.Add($lblColor)
    $defColor=New-FlatButton (Get-T 'ColorChoose') 180 ([string]$script:Settings.DefaultButtonColor); $defColor.Margin='0,5,0,16'; $defColor.Tag=[string]$script:Settings.DefaultButtonColor
    $defColor.Add_Click({
        $cd=New-Object System.Windows.Forms.ColorDialog
        try {$cd.Color=[System.Drawing.ColorTranslator]::FromHtml([string]$defColor.Tag)}catch{}
        if($cd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){$hex=('#{0:X2}{1:X2}{2:X2}' -f $cd.Color.R,$cd.Color.G,$cd.Color.B);$defColor.Tag=$hex;$defColor.Background=Get-Brush $hex}
    })
    [System.Windows.Controls.Grid]::SetRow($defColor,3); [void]$grid.Children.Add($defColor)

    $lblBg=New-Object System.Windows.Controls.TextBlock; $lblBg.Text=Get-T 'Background'; [System.Windows.Controls.Grid]::SetRow($lblBg,4); [void]$grid.Children.Add($lblBg)
    $bgRow=New-Object System.Windows.Controls.Grid; $bgRow.Margin='0,5,0,16';
    $c1=New-Object System.Windows.Controls.ColumnDefinition; $c1.Width='*'; $c2=New-Object System.Windows.Controls.ColumnDefinition; $c2.Width='Auto'; $c3=New-Object System.Windows.Controls.ColumnDefinition; $c3.Width='Auto'; [void]$bgRow.ColumnDefinitions.Add($c1);[void]$bgRow.ColumnDefinitions.Add($c2);[void]$bgRow.ColumnDefinitions.Add($c3)
    $bgText=New-TextBox; $bgText.IsReadOnly=$true; $bgText.Tag=[string]$script:Settings.BackgroundImage; $bgText.Text=if([string]::IsNullOrWhiteSpace([string]$bgText.Tag)){Get-T 'BackgroundNone'}elseif([string]$bgText.Tag -eq $script:DefaultWallpaperToken){Get-T 'DefaultWallpaper'}else{[string]$bgText.Tag}; [System.Windows.Controls.Grid]::SetColumn($bgText,0); [void]$bgRow.Children.Add($bgText)
    $choose=New-FlatButton (Get-T 'Choose') 90 '#353A45'; [System.Windows.Controls.Grid]::SetColumn($choose,1); [void]$bgRow.Children.Add($choose)
    $remove=New-FlatButton (Get-T 'Remove') 90 '#353A45'; [System.Windows.Controls.Grid]::SetColumn($remove,2); [void]$bgRow.Children.Add($remove)
    [System.Windows.Controls.Grid]::SetRow($bgRow,5); [void]$grid.Children.Add($bgRow)
    $choose.Add_Click({
        $ofd=New-Object Microsoft.Win32.OpenFileDialog; $ofd.Title=Get-T 'BrowseImage'; $ofd.Filter='Images|*.bmp;*.png;*.jpg;*.jpeg;*.gif;*.tif;*.tiff|BMP|*.bmp|PNG|*.png|JPEG|*.jpg;*.jpeg|GIF|*.gif|TIFF|*.tif;*.tiff|All files|*.*'
        if($ofd.ShowDialog($dlg) -eq $true){
            if(-not (Test-ImageFile $ofd.FileName)){[System.Windows.MessageBox]::Show((Get-T 'OpenError'),(Get-T 'Error'),'OK','Error')|Out-Null;return}
            try {
                if(-not(Test-Path $script:AssetsDir)){[void](New-Item -ItemType Directory -Path $script:AssetsDir -Force)}
                $ext=[System.IO.Path]::GetExtension($ofd.FileName).ToLowerInvariant(); $rel=Join-Path 'assets' ('background'+$ext); $abs=Join-Path $script:DataDir $rel
                Get-ChildItem -LiteralPath $script:AssetsDir -Filter 'background.*' -File -ErrorAction SilentlyContinue | Where-Object{$_.FullName -ne $abs} | Remove-Item -Force -ErrorAction SilentlyContinue
                if([System.IO.Path]::GetFullPath($ofd.FileName) -ne [System.IO.Path]::GetFullPath($abs)){Copy-Item -LiteralPath $ofd.FileName -Destination $abs -Force}
                $bgText.Tag=$rel; $bgText.Text=$rel
            } catch {Write-LauncherError $_}
        }
    })
    $remove.Add_Click({$bgText.Tag='';$bgText.Text=Get-T 'BackgroundNone'})

    $modeGrid=New-Object System.Windows.Controls.Grid; $modeGrid.Margin='0,0,0,16'; $mc1=New-Object System.Windows.Controls.ColumnDefinition;$mc1.Width='*';$mc2=New-Object System.Windows.Controls.ColumnDefinition;$mc2.Width='220';[void]$modeGrid.ColumnDefinitions.Add($mc1);[void]$modeGrid.ColumnDefinitions.Add($mc2)
    $lblMode=New-Object System.Windows.Controls.TextBlock;$lblMode.Text=Get-T 'BackgroundMode';$lblMode.VerticalAlignment='Center';[void]$modeGrid.Children.Add($lblMode)
    $cmbMode=New-Object System.Windows.Controls.ComboBox;$cmbMode.Height=32;$cmbMode.Items.Add((Get-T 'ModeCover'))|Out-Null;$cmbMode.Items.Add((Get-T 'ModeFit'))|Out-Null;$cmbMode.Items.Add((Get-T 'ModeStretch'))|Out-Null; switch([string]$script:Settings.BackgroundMode){'Fit'{$cmbMode.SelectedIndex=1};'Stretch'{$cmbMode.SelectedIndex=2};default{$cmbMode.SelectedIndex=0}};[System.Windows.Controls.Grid]::SetColumn($cmbMode,1);[void]$modeGrid.Children.Add($cmbMode);[System.Windows.Controls.Grid]::SetRow($modeGrid,6);[void]$grid.Children.Add($modeGrid)

    $dimGrid=New-Object System.Windows.Controls.Grid;$dimGrid.Margin='0,0,0,18';$dc1=New-Object System.Windows.Controls.ColumnDefinition;$dc1.Width='180';$dc2=New-Object System.Windows.Controls.ColumnDefinition;$dc2.Width='*';$dc3=New-Object System.Windows.Controls.ColumnDefinition;$dc3.Width='55';[void]$dimGrid.ColumnDefinitions.Add($dc1);[void]$dimGrid.ColumnDefinitions.Add($dc2);[void]$dimGrid.ColumnDefinitions.Add($dc3)
    $lblDim=New-Object System.Windows.Controls.TextBlock;$lblDim.Text=Get-T 'BackgroundDim';$lblDim.VerticalAlignment='Center';[void]$dimGrid.Children.Add($lblDim)
    $slider=New-Object System.Windows.Controls.Slider;$slider.Minimum=0;$slider.Maximum=80;$slider.TickFrequency=5;$slider.Value=[double]$script:Settings.BackgroundDim;$slider.Margin='10,0';[System.Windows.Controls.Grid]::SetColumn($slider,1);[void]$dimGrid.Children.Add($slider)
    $dimVal=New-Object System.Windows.Controls.TextBlock;$dimVal.Text=([int]$slider.Value).ToString()+' %';$dimVal.VerticalAlignment='Center';$dimVal.HorizontalAlignment='Right';[System.Windows.Controls.Grid]::SetColumn($dimVal,2);[void]$dimGrid.Children.Add($dimVal);$slider.Add_ValueChanged({$dimVal.Text=([int]$slider.Value).ToString()+' %'});[System.Windows.Controls.Grid]::SetRow($dimGrid,7);[void]$grid.Children.Add($dimGrid)

    $chkHint=New-Object System.Windows.Controls.CheckBox;$chkHint.Content=Get-T 'ShowHint';$chkHint.IsChecked=[bool]$script:Settings.ShowHint;$chkHint.Margin='0,0,0,12';$chkHint.Foreground=[System.Windows.Media.Brushes]::White;$chkHint.FontSize=12.5;[System.Windows.Controls.Grid]::SetRow($chkHint,8);[void]$grid.Children.Add($chkHint)

    $buttonGrid=New-Object System.Windows.Controls.Grid;$buttonGrid.Margin='0,16,0,0'
    $bc1=New-Object System.Windows.Controls.ColumnDefinition;$bc1.Width='*';$bc2=New-Object System.Windows.Controls.ColumnDefinition;$bc2.Width='Auto';[void]$buttonGrid.ColumnDefinitions.Add($bc1);[void]$buttonGrid.ColumnDefinitions.Add($bc2)
    $reset=New-FlatButton ('↺  '+(Get-T 'ResetDesign')) 165 '#252A33';$reset.Height=30;$reset.FontSize=11;$reset.Opacity=0.72;$reset.HorizontalAlignment='Left';$reset.Margin='0';$reset.ToolTip=Get-T 'ResetDesignHint';[System.Windows.Controls.Grid]::SetColumn($reset,0);[void]$buttonGrid.Children.Add($reset)
    $buttons=New-Object System.Windows.Controls.StackPanel;$buttons.Orientation='Horizontal';$buttons.HorizontalAlignment='Right';$apply=New-FlatButton (Get-T 'Apply') 110 '#008DF3';$cancel=New-FlatButton (Get-T 'Cancel') 110 '#353A45';[void]$buttons.Children.Add($apply);[void]$buttons.Children.Add($cancel);[System.Windows.Controls.Grid]::SetColumn($buttons,1);[void]$buttonGrid.Children.Add($buttons);[System.Windows.Controls.Grid]::SetRow($buttonGrid,10);[void]$grid.Children.Add($buttonGrid)
    $reset.Add_Click({
        $defColor.Tag='#163A52';$defColor.Background=Get-Brush '#163A52'
        $bgText.Tag=$script:DefaultWallpaperToken;$bgText.Text=Get-T 'DefaultWallpaper'
        $cmbMode.SelectedIndex=0
        $slider.Value=28
        $chkHint.IsChecked=$true
    })
    $cancel.Add_Click({$dlg.DialogResult=$false;$dlg.Close()})
    $apply.Add_Click({
        $lang='de';if($cmbLang.SelectedIndex -eq 1){$lang='en'}elseif($cmbLang.SelectedIndex -eq 2){$lang='ru'}
        $mode='Cover';if($cmbMode.SelectedIndex -eq 1){$mode='Fit'}elseif($cmbMode.SelectedIndex -eq 2){$mode='Stretch'}
        $script:Settings.Language=$lang;$script:Settings.DefaultButtonColor=[string]$defColor.Tag;$script:Settings.BackgroundImage=[string]$bgText.Tag;$script:Settings.BackgroundMode=$mode;$script:Settings.BackgroundDim=[int]$slider.Value;$script:Settings.ShowHint=[bool]$chkHint.IsChecked
        Save-Settings;$dlg.DialogResult=$true;$dlg.Close()
    })
    $result=$dlg.ShowDialog(); if($result -eq $true){Apply-Language;Apply-HintVisibility;Apply-Background;Refresh-ServerButtons}
}

function Get-HeaderLogoPath {
    $candidates=@(
        (Join-Path $script:BundledAssetsDir 'header-logo.png'),
        (Join-Path $script:BundledAssetsDir 'header-logo.webp'),
        (Join-Path $script:BundledAssetsDir 'header-logo.jpg')
    )
    foreach($candidate in $candidates){
        if(Test-Path -LiteralPath $candidate){ return $candidate }
    }
    return $null
}

function Get-DefaultWallpaperPath {
    $candidates=@(
        (Join-Path $script:BundledAssetsDir 'default-wallpaper.png'),
        (Join-Path $script:BundledAssetsDir 'default-wallpaper.jpg'),
        (Join-Path $script:BundledAssetsDir 'wall-1280-q55.jpg'),
        (Join-Path $script:BundledAssetsDir 'wall-1024-q48.jpg'),
        (Join-Path $script:BundledAssetsDir 'wall-960-q45.jpg'),
        (Join-Path $script:BundledAssetsDir 'wall-800-q42.jpg')
    )
    foreach($candidate in $candidates){
        if(Test-Path -LiteralPath $candidate){ return $candidate }
    }
    return $null
}

function Apply-HeaderLogo {
    if(-not $script:HeaderLogo){ return }
    $script:HeaderLogo.Source=$null
    $path=Get-HeaderLogoPath
    if([string]::IsNullOrWhiteSpace($path)){ return }
    try{
        $bi=New-Object System.Windows.Media.Imaging.BitmapImage
        $bi.BeginInit()
        $bi.CacheOption='OnLoad'
        $bi.UriSource=New-Object System.Uri -ArgumentList $path
        $bi.EndInit()
        $bi.Freeze()
        $script:HeaderLogo.Source=$bi
        $script:HeaderLogo.Visibility='Visible'
    }catch{
        Write-LauncherError $_
        $script:HeaderLogo.Visibility='Collapsed'
    }
}

function Apply-Background {
    if(-not $script:BackgroundImageControl){return}
    $script:BackgroundImageControl.Source=$null
    $bg=[string]$script:Settings.BackgroundImage
    if(-not [string]::IsNullOrWhiteSpace($bg)){
        if($bg -eq $script:DefaultWallpaperToken){
            $path=Get-DefaultWallpaperPath
        }else{
            $path=Join-Path $script:DataDir $bg
        }
        if(Test-Path -LiteralPath $path){
            try{
                $bi=New-Object System.Windows.Media.Imaging.BitmapImage;$bi.BeginInit();$bi.CacheOption='OnLoad';$bi.UriSource=New-Object System.Uri -ArgumentList $path;$bi.EndInit();$bi.Freeze();$script:BackgroundImageControl.Source=$bi
                switch([string]$script:Settings.BackgroundMode){'Fit'{$script:BackgroundImageControl.Stretch='Uniform'};'Stretch'{$script:BackgroundImageControl.Stretch='Fill'};default{$script:BackgroundImageControl.Stretch='UniformToFill'}}
                $dim=[Math]::Max(0,[Math]::Min(80,[int]$script:Settings.BackgroundDim));$a=[int][Math]::Round(255*$dim/100.0);$script:DimOverlay.Background=Get-Brush ('#{0:X2}000000' -f $a) '#73000000'
                return
            }catch{Write-LauncherError $_}
        }
    }
    $script:DimOverlay.Background=Get-Brush '#00000000'
}

function Apply-Language {
    if(-not $script:Window){return}
    $script:Window.Title=Get-T 'Title'
    if($script:TitleText){$script:TitleText.Text=Get-T 'Title'}
    if($script:SubtitleText){$script:SubtitleText.Text=Get-T 'Subtitle'}
    $script:AddButton.Content='+  '+(Get-T 'Add');$script:HintText.Text=Get-T 'Hint';$script:GearButton.ToolTip=Get-T 'Settings'
    if($script:EmptyText){$script:EmptyText.Text=Get-T 'NoServers'}
}

function Apply-HintVisibility {
    if(-not $script:HintText){ return }
    if([bool]$script:Settings.ShowHint){
        $script:HintText.Visibility='Visible'
    }else{
        $script:HintText.Visibility='Collapsed'
    }
}

function Update-WindowHeight {
    if(-not $script:Window){return}
    $count=[Math]::Max(1,$script:Servers.Count)
    $rows=[int][Math]::Ceiling($count/3.0)
    $visible=[Math]::Min(3,$rows)

    # One visible row: leave approximately the same breathing room below the
    # last tile as there is between the Add button and the first tile. The
    # 88-DIP header logo made the old 330-DIP base too short and clipped the
    # first tile. Each extra row adds one complete tile including its margins.
    $target=359+(($visible-1)*118)
    $target=[Math]::Min(586,$target)

    # Grow automatically when more rows are needed, but never fight a user who
    # has manually made the window larger.
    if($script:Window.WindowState -eq 'Normal' -and $script:Window.Height -lt $target){
        $script:Window.Height=$target
    }
}

function Move-ServerItem {
    param([int]$FromIndex,[int]$ToIndex)
    if($FromIndex -lt 0 -or $FromIndex -ge $script:Servers.Count){return}
    if($ToIndex -lt 0){$ToIndex=0}
    if($ToIndex -ge $script:Servers.Count){$ToIndex=$script:Servers.Count-1}
    if($FromIndex -eq $ToIndex){return}

    # Die JSON-Reihenfolge ist zugleich die sichtbare Reihenfolge. Dadurch bleibt
    # ein Drag-&-Drop-Umsortieren ohne zusaetzliches Order-Feld dauerhaft erhalten.
    $list=New-Object System.Collections.ArrayList
    foreach($server in $script:Servers){[void]$list.Add($server)}
    $item=$list[$FromIndex]
    $list.RemoveAt($FromIndex)
    $list.Insert($ToIndex,$item)
    $script:Servers=@($list.ToArray())
    Save-Servers
    Refresh-ServerButtons
}

function Start-ServerDrag {
    param($Sender,$EventArgs)
    if($EventArgs.LeftButton -ne [System.Windows.Input.MouseButtonState]::Pressed){return}
    $pos=$EventArgs.GetPosition($script:Window)
    $dx=[Math]::Abs($pos.X-$script:DragStartPoint.X)
    $dy=[Math]::Abs($pos.Y-$script:DragStartPoint.Y)
    if($dx -lt [System.Windows.SystemParameters]::MinimumHorizontalDragDistance -and $dy -lt [System.Windows.SystemParameters]::MinimumVerticalDragDistance){return}

    try{
        $data=New-Object System.Windows.DataObject
        $data.SetData('HypeTekServerIndex',[int]$Sender.Tag)
        $Sender.Opacity=0.55
        [void][System.Windows.DragDrop]::DoDragDrop($Sender,$data,[System.Windows.DragDropEffects]::Move)
    } finally {
        $Sender.Opacity=1.0
        $script:LastDragEnd=Get-Date
    }
}

function Refresh-ServerButtons {
    if(-not $script:ServerPanel){return}
    $script:ServerPanel.Children.Clear();$script:EmptyText=$null;Update-WindowHeight
    if($script:Servers.Count -eq 0){
        $empty=New-Object System.Windows.Controls.TextBlock;$script:EmptyText=$empty;$empty.Text=Get-T 'NoServers';$empty.Foreground=Get-Brush '#D8DCE5';$empty.FontSize=15;$empty.Margin='7,18,7,7';[void]$script:ServerPanel.Children.Add($empty);return
    }
    for($i=0;$i -lt $script:Servers.Count;$i++){
        $s=$script:Servers[$i];$iconKey='Auto';if($s.PSObject.Properties['Icon']){$iconKey=[string]$s.Icon};$btn=New-Object System.Windows.Controls.Button;$btn.Content=New-ServerTileContent -Name ([string]$s.Name) -Address ([string]$s.Address) -Icon $iconKey;$btn.Tag=$i;$btn.Width=232;$btn.Height=104;$btn.Margin='7';$btn.Style=$script:ServerButtonStyle;$btn.AllowDrop=$true
        $hex='';if($s.PSObject.Properties['Color']){$hex=[string]$s.Color};if([string]::IsNullOrWhiteSpace($hex)){$hex=[string]$script:Settings.DefaultButtonColor};$btn.Background=Get-Brush $hex;$btn.BorderBrush=Get-Brush (Get-ServerAccentColor -Name ([string]$s.Name) -Address ([string]$s.Address) -Icon $iconKey);$btn.BorderThickness='2'

        $btn.Add_PreviewMouseLeftButtonDown({param($sender,$e)$script:DragStartPoint=$e.GetPosition($script:Window)})
        $btn.Add_PreviewMouseMove({param($sender,$e) Start-ServerDrag $sender $e})
        $btn.Add_DragOver({param($sender,$e)if($e.Data.GetDataPresent('HypeTekServerIndex')){$e.Effects=[System.Windows.DragDropEffects]::Move;$e.Handled=$true}})
        $btn.Add_Drop({
            param($sender,$e)
            if($e.Data.GetDataPresent('HypeTekServerIndex')){
                $from=[int]$e.Data.GetData('HypeTekServerIndex')
                $to=[int]$sender.Tag
                $e.Effects=[System.Windows.DragDropEffects]::Move;$e.Handled=$true
                Move-ServerItem -FromIndex $from -ToIndex $to
            }
        })
        $btn.Add_Click({
            param($sender,$e)
            # DoDragDrop kann je nach Windows-/DPI-Konfiguration noch einen Click
            # nachliefern. Direkt nach einem Drag darf deshalb keine URL starten.
            if(((Get-Date)-$script:LastDragEnd).TotalMilliseconds -lt 450){return}
            Open-ServerAddress ([string]$script:Servers[[int]$sender.Tag].Address)
        })

        $menu=New-Object System.Windows.Controls.ContextMenu
        $edit=New-Object System.Windows.Controls.MenuItem;$edit.Header=Get-T 'Edit';$edit.Tag=$i;$edit.Add_Click({param($sender,$e) Show-ServerDialog -Index ([int]$sender.Tag)})
        $delete=New-Object System.Windows.Controls.MenuItem;$delete.Header=Get-T 'Delete';$delete.Tag=$i;$delete.Add_Click({param($sender,$e)$idx=[int]$sender.Tag;$r=[System.Windows.MessageBox]::Show((Get-T 'DeleteConfirm'),(Get-T 'Delete'),'YesNo','Question');if($r -eq 'Yes'){$new=@();for($j=0;$j -lt $script:Servers.Count;$j++){if($j -ne $idx){$new+=$script:Servers[$j]}};$script:Servers=$new;Save-Servers;Refresh-ServerButtons}})
        [void]$menu.Items.Add($edit);[void]$menu.Items.Add($delete);$btn.ContextMenu=$menu;[void]$script:ServerPanel.Children.Add($btn)
    }
}

function Run-Launcher {
    Load-Data
    if(Test-Path -LiteralPath $script:ErrorFile){Remove-Item -LiteralPath $script:ErrorFile -Force -ErrorAction SilentlyContinue}

    [xml]$xaml=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="HypeTek Bookmarker" Width="1060" Height="359" MinWidth="860" MinHeight="340" WindowStartupLocation="CenterScreen" Background="#17191E" Foreground="White" FontFamily="Segoe UI" ResizeMode="CanResizeWithGrip">
  <Window.Resources>
    <Style x:Key="ServerButtonStyle" TargetType="Button">
      <Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="15"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/><Setter Property="BorderThickness" Value="2"/><Setter Property="BorderBrush" Value="#00D9FF"/><Setter Property="Padding" Value="12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Card" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="12" SnapsToDevicePixels="True">
              <Grid><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10"/></Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Card" Property="Opacity" Value="0.88"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="Card" Property="Opacity" Value="0.72"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="ActionButtonStyle" TargetType="Button">
      <Setter Property="Foreground" Value="White"/><Setter Property="FontSize" Value="14"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/><Setter Property="BorderBrush" Value="#6AFFFFFF"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Padding" Value="13,7"/>
      <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border x:Name="B" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="B" Property="Opacity" Value="0.86"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
    </Style>
  </Window.Resources>
  <Grid Background="#17191E">
    <Image x:Name="BgImage" Stretch="UniformToFill"/>
    <Border x:Name="DimOverlay" Background="#73000000"/>
    <Grid Margin="28,20,28,20">
      <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
      <Grid Grid.Row="0">
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel Orientation="Vertical">
          <Image x:Name="HeaderLogo" Height="88" Stretch="Uniform" HorizontalAlignment="Left" Margin="0,0,0,2"/>
          <TextBlock x:Name="TitleText" FontSize="25" FontWeight="SemiBold" Foreground="#EAF8FF" Visibility="Collapsed"/>
          <TextBlock x:Name="SubtitleText" FontSize="13" Foreground="#E5E8EE" Margin="1,2,0,0" Visibility="Collapsed"/>
        </StackPanel>
        <Button x:Name="GearButton" Grid.Column="1" Content="⚙" Width="48" Height="42" FontSize="21" FontFamily="Segoe UI Symbol" Padding="0" Background="#AA20242C" Style="{StaticResource ActionButtonStyle}" Margin="12,0,0,0"/>
      </Grid>
      <Grid Grid.Row="1" Margin="0,16,0,8">
        <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        <Button x:Name="AddButton" MinWidth="190" Height="42" Padding="16,7" Background="#E6008DF3" Style="{StaticResource ActionButtonStyle}"/>
        <TextBlock x:Name="HintText" Grid.Column="1" VerticalAlignment="Center" Foreground="#D9DEE8" FontSize="12.5" Margin="18,0,0,0" TextWrapping="Wrap"/>
      </Grid>
      <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Background="Transparent" Margin="-7,4,-7,0">
        <WrapPanel x:Name="ServerPanel" Background="Transparent"/>
      </ScrollViewer>
    </Grid>
  </Grid>
</Window>
"@
    $reader=New-Object System.Xml.XmlNodeReader $xaml
    $window=[System.Windows.Markup.XamlReader]::Load($reader);$script:Window=$window
    $script:BackgroundImageControl=$window.FindName('BgImage');$script:DimOverlay=$window.FindName('DimOverlay');$script:HeaderLogo=$window.FindName('HeaderLogo');$script:TitleText=$window.FindName('TitleText');$script:SubtitleText=$window.FindName('SubtitleText');$script:AddButton=$window.FindName('AddButton');$script:GearButton=$window.FindName('GearButton');$script:HintText=$window.FindName('HintText');$script:ServerPanel=$window.FindName('ServerPanel');$script:ServerButtonStyle=$window.Resources['ServerButtonStyle']
    $script:ServerPanel.AllowDrop=$true
    $script:ServerPanel.Add_DragOver({param($sender,$e)if($e.Data.GetDataPresent('HypeTekServerIndex')){$e.Effects=[System.Windows.DragDropEffects]::Move}})
    $script:ServerPanel.Add_Drop({param($sender,$e)if(-not $e.Handled -and $e.Data.GetDataPresent('HypeTekServerIndex')){$from=[int]$e.Data.GetData('HypeTekServerIndex');Move-ServerItem -FromIndex $from -ToIndex ($script:Servers.Count-1);$e.Handled=$true}})
    $script:AddButton.Add_Click({Show-ServerDialog});$script:GearButton.Add_Click({Show-SettingsDialog})
    Apply-Language;Apply-HeaderLogo;Apply-HintVisibility;Apply-Background;Refresh-ServerButtons
    [void]$window.ShowDialog()
}

try { Run-Launcher; exit 0 }
catch { Write-LauncherError $_; try{[System.Windows.MessageBox]::Show("$($_.Exception.Message)`r`n`r`nDetails: $script:ErrorFile",'HypeTek Bookmarker','OK','Error')|Out-Null}catch{}; exit 1 }
