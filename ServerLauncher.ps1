# HypeTek Bookmarker V3.7.2
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
        InvalidName='Введите название кнопки.'; BrowseImage='Выберите фоновое изображения'; OpenError='Не удалось открыть адрес.'; AppSettings='Настройки Bookmarker';
        NewServer='Новая запись'; EditServer='Изменить запись'; Error='Ошибка';
        Hint='Drag & Drop: изменить порядок  •  Правый клик: изменить или удалить'; BackgroundNone='Фоновое изображение не выбрано';
        BackgroundMode='Масштаб изображения'; ModeCover='Заполнитц2'; ModeFit='Вписать'; ModeStretch='Растянуть';
        BackgroundDim='Затемнение фона'; Percent='%'; DefaultWallpaper='Стандартные обои HypeTek'; ResetDesign='Стандартный дизайн'; ResetDesignHint='Сбрасывает только цвета, обои и оформление – записи не изменяются.';
        ShowHint='Показывать подсказку Drag & Drop / правый клик