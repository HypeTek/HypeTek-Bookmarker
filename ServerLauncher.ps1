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
        BackgroundDim='Hintergrund abdunkeln'; Percent='%'; DefaultWallpaper='HypeTek Standard-Wallpaper'; ResetDesign='Standarddesign'; ResetDesignHint='Setzt nur Farben, Wallpaper und Darstellung zurück – Server bleiben unverändert.';
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
        Hint='Drag & drop: reorder servers  •  Right-click: edit or delete'; BackgroundNone='No background image selected';
        BackgroundMode='Image scaling'; ModeCover='Fill'; ModeFit='Fit'; ModeStretch='Stretch';
        BackgroundDim='Darken background'; Percent='%'; DefaultWallpaper='HypeTek default wallpaper'; ResetDesign='Default design'; ResetDesignHint='Resets only colors, wallpaper and appearance – server entries stay unchanged.';
        ShowHint='Show drag & drop / right-click help text'; ColorChoose='Choose color'; AddressExample='e.g. 192.168.1.10 or https://server.local:8443'; Icon='Icon'; IconAuto='Automatic'; IconServer='Server'; IconPC='PC'; IconLaptop='Laptop'; IconWebsite='Website'; IconNAS='NAS'; IconRouter='Router'; IconRaspberry='Raspberry Pi'; IconVM='VM / Virtualization'; IconGeneric='Generic'
    }
    ru = @{
        Title='HypeTek Bookmarker'; Subtitle='Серверы, NAS и веб-интерфейсы в один клик'; Add='Добавить запись';
        Settings='Настройки'; Name='Название'; Address='Адрес'; Color='Цвет кнопки';
        Default='По умолчанию'; Save='Сохранить'; Cancel='Отмена'; Edit='Изменить'; Delete='Удалить';
        DeleteConfirm='Удалить эту запись?'; Language='Язык'; DefaultColor='Цвет кнопок по умолчанию';
        Background='Фоновое изображение'; Choose='Выбрать'; Remove='Удалить'; Apply='Применить';
        NoServers='Записей пока нет.'; InvalidAddress='Введите адрес.';
        InvalidName='Введите название кнопки.'; BrowseImage='Выберите фоновое изображе��="26dex $to
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
