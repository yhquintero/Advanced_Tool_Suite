#requires -Version 5.1
<#
.SYNOPSIS
Panel de herramientas administrativas para Windows 10/11.
.DESCRIPTION
Interfaz WPF. No requiere modulos externos. Solicita UAC solo cuando hace falta.
Use -ValidateOnly para comprobar el catalogo sin abrir ventanas ni ejecutar acciones.
#>
[CmdletBinding()]
param([switch]$ValidateOnly, [switch]$SmokeTest)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Catalogo declarativo: las acciones se resuelven por ID, nunca como codigo de entrada.
$script:Tools = @(
    @{Id=1; Name='Informacion del sistema'; Category='Sistema'; Description='Version de Windows, hardware y configuracion.'; Admin=$false; Risk=$false}
    @{Id=2; Name='Administrador de tareas'; Category='Sistema'; Description='Procesos, consumo de CPU y memoria.'; Admin=$false; Risk=$false}
    @{Id=3; Name='Administrador de dispositivos'; Category='Sistema'; Description='Hardware y controladores del equipo.'; Admin=$false; Risk=$false}
    @{Id=4; Name='Servicios de Windows'; Category='Sistema'; Description='Consulta y administra servicios.'; Admin=$true; Risk=$false}
    @{Id=5; Name='Adaptadores de red'; Category='Red'; Description='Conexiones Ethernet, Wi-Fi y adaptadores.'; Admin=$false; Risk=$false}
    @{Id=6; Name='Terminal administrativa'; Category='Sistema'; Description='Abre CMD con privilegios elevados.'; Admin=$true; Risk=$false}
    @{Id=7; Name='Panel de control'; Category='Sistema'; Description='Todas las opciones clasicas de Windows.'; Admin=$false; Risk=$false}
    @{Id=8; Name='Editor del Registro'; Category='Sistema'; Description='Configuracion avanzada. Exporta antes de modificar.'; Admin=$true; Risk=$true}
    @{Id=9; Name='Dispositivos de audio'; Category='Sistema'; Description='Reproduccion, grabacion y sonidos.'; Admin=$false; Risk=$false}
    @{Id=10; Name='Ver archivos ocultos'; Category='Personalizacion'; Description='Activa su visualizacion sin alterar archivos del disco.'; Admin=$false; Risk=$false}
    @{Id=11; Name='Comprobar unidad'; Category='Mantenimiento'; Description='CHKDSK en modo lectura; no programa reparaciones.'; Admin=$true; Risk=$false}
    @{Id=12; Name='Convertir FAT32 a NTFS'; Category='Mantenimiento'; Description='Conversion no reversible desde esta herramienta. Haz una copia.'; Admin=$true; Risk=$true}
    @{Id=13; Name='Liberar espacio'; Category='Mantenimiento'; Description='Abre el limpiador oficial; tu eliges que borrar.'; Admin=$false; Risk=$false}
    @{Id=14; Name='Diagnostico de memoria'; Category='Mantenimiento'; Description='Consulta consumo real; no cierra procesos ni promete liberar RAM.'; Admin=$false; Risk=$false}
    @{Id=15; Name='Planes de energia'; Category='Mantenimiento'; Description='Elige rendimiento o ahorro sin cambios automaticos.'; Admin=$false; Risk=$false}
    @{Id=16; Name='Todas las tareas'; Category='Sistema'; Description='Abre la vista avanzada del Panel de control.'; Admin=$false; Risk=$false}
    @{Id=17; Name='Menu contextual clasico'; Category='Personalizacion'; Description='Windows 11: requiere reiniciar el Explorador o la sesion.'; Admin=$false; Risk=$true}
    @{Id=18; Name='Restaurar menu moderno'; Category='Personalizacion'; Description='Deshace el ajuste del menu clasico en Windows 11.'; Admin=$false; Risk=$true}
    @{Id=19; Name='Salud de los discos'; Category='Mantenimiento'; Description='Estado reportado por Windows; no sustituye un diagnostico fisico.'; Admin=$false; Risk=$false}
    @{Id=20; Name='Restablecer Winsock'; Category='Red'; Description='Restablece el catalogo de red; requiere reinicio posterior.'; Admin=$true; Risk=$true}
    @{Id=21; Name='Configuracion de red'; Category='Red'; Description='Abre la configuracion de conexiones de Windows.'; Admin=$false; Risk=$false}
    @{Id=22; Name='Apagar equipo'; Category='Energia'; Description='Apagado inmediato tras confirmar. Guarda tu trabajo.'; Admin=$false; Risk=$true}
    @{Id=23; Name='Reiniciar equipo'; Category='Energia'; Description='Reinicio inmediato tras confirmar. Guarda tu trabajo.'; Admin=$false; Risk=$true}
    @{Id=24; Name='Reiniciar Explorador'; Category='Sistema'; Description='Cierra ventanas del Explorador y recarga la barra de tareas.'; Admin=$false; Risk=$true}
    @{Id=25; Name='Modo oscuro'; Category='Personalizacion'; Description='Activa el tema oscuro de las aplicaciones de Windows.'; Admin=$false; Risk=$false}
    @{Id=26; Name='Modo claro'; Category='Personalizacion'; Description='Restaura el tema claro de las aplicaciones de Windows.'; Admin=$false; Risk=$false}
    @{Id=27; Name='Configuracion IP'; Category='Red'; Description='Muestra direcciones, DNS y puertas de enlace.'; Admin=$false; Risk=$false}
    @{Id=28; Name='Prueba de conectividad'; Category='Red'; Description='Envia cuatro solicitudes a google.com.'; Admin=$false; Risk=$false}
    @{Id=29; Name='Consultar IP o dominio'; Category='Red'; Description='Prueba un destino validado con cuatro solicitudes.'; Admin=$false; Risk=$false}
    @{Id=30; Name='Exportar inventario'; Category='Sistema'; Description='Genera un informe local de hardware y red en Documentos.'; Admin=$false; Risk=$false}
    @{Id=31; Name='Fecha y hora'; Category='Sistema'; Description='Reloj, zona horaria y sincronizacion.'; Admin=$false; Risk=$false}
    @{Id=32; Name='Administrador de discos'; Category='Mantenimiento'; Description='Particiones y volumenes. Modifica con precaucion.'; Admin=$true; Risk=$false}
    @{Id=33; Name='Activar firewall'; Category='Seguridad'; Description='Activa la proteccion en todos los perfiles.'; Admin=$true; Risk=$true}
    @{Id=34; Name='Desactivar firewall'; Category='Seguridad'; Description='Desprotege todos los perfiles. No recomendado.'; Admin=$true; Risk=$true}
    @{Id=35; Name='Seguridad de Windows'; Category='Seguridad'; Description='Centro de proteccion y estado del antivirus.'; Admin=$false; Risk=$false}
    @{Id=36; Name='Bloc de notas'; Category='Sistema'; Description='Editor de texto de Windows.'; Admin=$false; Risk=$false}
    @{Id=37; Name='Configuracion regional'; Category='Personalizacion'; Description='Formatos, idioma y opciones regionales.'; Admin=$false; Risk=$false}
    @{Id=38; Name='Aplicaciones instaladas'; Category='Sistema'; Description='Abre la carpeta de aplicaciones de Windows.'; Admin=$false; Risk=$false}
    @{Id=39; Name='Activacion de Windows'; Category='Sistema'; Description='Consulta el estado de licencia en Configuracion.'; Admin=$false; Risk=$false}
    @{Id=40; Name='Analisis rapido Defender'; Category='Seguridad'; Description='Solicita un analisis rapido con Microsoft Defender.'; Admin=$true; Risk=$false}
    @{Id=41; Name='Programador de tareas'; Category='Sistema'; Description='Consulta y administra tareas programadas.'; Admin=$true; Risk=$false}
    @{Id=42; Name='Cancelar apagado o reinicio'; Category='Energia'; Description='Cancela una cuenta atras pendiente programada desde Windows.'; Admin=$false; Risk=$false}
)

if ($ValidateOnly) {
    if ($script:Tools.Count -ne 42 -or @($script:Tools.Id | Select-Object -Unique).Count -ne 42) {
        throw 'El catalogo contiene IDs duplicados o faltantes.'
    }
    'Catalogo valido: 42 herramientas.'
    return
}
if ($env:OS -ne 'Windows_NT') { throw 'Esta interfaz WPF requiere Windows 10 u 11.' }
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    $exe = Join-Path $PSHOME 'powershell.exe'
    if (-not (Test-Path $exe)) { $exe = Join-Path $PSHOME 'pwsh.exe' }
    Start-Process $exe -ArgumentList "-NoProfile -STA -File `"$PSCommandPath`""
    return
}
Add-Type -AssemblyName @('PresentationFramework', 'PresentationCore', 'WindowsBase', 'Microsoft.VisualBasic', 'System.Security')
$script:DataPath = Join-Path $env:LOCALAPPDATA 'AdvancedToolSuite'
if ($SmokeTest) { $script:DataPath = Join-Path ([IO.Path]::GetTempPath()) ('ATS-Smoke-' + [guid]::NewGuid().ToString('N')) }
New-Item $script:DataPath -ItemType Directory -Force | Out-Null
$script:LogPath = Join-Path $script:DataPath 'actividad.log'
$script:Version = '4.0.0'
$script:SourcePath = $PSCommandPath
$script:ExecutablePath = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$script:SessionId = [guid]::NewGuid().ToString()
$script:SettingsPath = Join-Path $script:DataPath 'preferencias.json'
$script:Settings = @{ Theme='Neon azul'; Compact=$false; Motion=$true; ReadOnly=$false; Restore=$false; Favorites=@(); EnabledPlugins=@() }
try {
    if (Test-Path $script:SettingsPath) {
        $saved = Get-Content $script:SettingsPath -Raw | ConvertFrom-Json
        foreach ($key in @('Compact','Motion','ReadOnly','Restore')) {
            if ($saved.PSObject.Properties.Name -contains $key -and $saved.$key -is [bool]) { $script:Settings[$key] = $saved.$key }
        }
        if ($saved.PSObject.Properties.Name -contains 'Theme' -and $saved.Theme -is [string]) { $script:Settings.Theme = $saved.Theme }
        if ($saved.PSObject.Properties.Name -contains 'EnabledPlugins') {
            $script:Settings.EnabledPlugins = @($saved.EnabledPlugins | Where-Object { $_ -is [string] -and $_ -cmatch '^[a-z][a-z0-9-]{2,47}:[A-F0-9]{64}$' } | Select-Object -Unique)
        }
        if ($saved.PSObject.Properties.Name -contains 'Favorites') {
            $script:Settings.Favorites = @($saved.Favorites | Where-Object { $_ -is [int] -or $_ -is [long] } | Where-Object { $_ -ge 1 -and $_ -le 42 } | Select-Object -Unique)
        }
    }
} catch { Write-Warning 'Preferencias ilegibles; se usaran valores predeterminados.' }
$script:FavoritesOnly = $false
$script:AuditWarned = $false
$script:RestorePending = $null
$script:UndoPath = Join-Path $script:DataPath 'registro-undo.clixml'
$script:GuardPath = Join-Path $script:DataPath 'proteccion.dpapi'
$script:CurrentActionId = 0
$script:Timers = [Collections.Generic.List[object]]::new()
$script:MetricsJob = $null
$script:MetricsHandle = $null


[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Advanced Tool Suite 4.0.0 | Centro de control"
 Width="1220" Height="820" MinWidth="960" MinHeight="650" WindowStartupLocation="CenterScreen"
 Background="{DynamicResource MainBackground}" Foreground="#E7EEFF" FontFamily="Segoe UI" FontSize="13">
 <Window.Resources>
  <SolidColorBrush x:Key="Accent" Color="#38E8ED"/>
  <SolidColorBrush x:Key="Secondary" Color="#B69AFF"/>
  <LinearGradientBrush x:Key="MainBackground" StartPoint="0,0" EndPoint="1,1">
   <GradientStop Color="#090E1B" Offset="0"/>
   <GradientStop x:Name="AmbientStop" Color="#17213B" Offset="0.65"/>
   <GradientStop Color="#090E1B" Offset="1"/>
  </LinearGradientBrush>
  <Style TargetType="Button">
   <Setter Property="Background" Value="#19253D"/><Setter Property="Foreground" Value="#E7EEFF"/>
   <Setter Property="BorderBrush" Value="#314565"/><Setter Property="BorderThickness" Value="1"/>
   <Setter Property="Padding" Value="16,11"/><Setter Property="Margin" Value="0,0,8,8"/>
   <Setter Property="Cursor" Value="Hand"/><Setter Property="HorizontalContentAlignment" Value="Left"/>
   <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
    <Border x:Name="Surface" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
     BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="16" Padding="{TemplateBinding Padding}">
     <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
    </Border>
    <ControlTemplate.Triggers>
     <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Surface" Property="Background" Value="#25395A"/><Setter TargetName="Surface" Property="BorderBrush" Value="{DynamicResource Accent}"/></Trigger>
     <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Surface" Property="BorderBrush" Value="{DynamicResource Secondary}"/></Trigger>
     <Trigger Property="IsPressed" Value="True"><Setter TargetName="Surface" Property="Background" Value="#36527A"/></Trigger>
     <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Surface" Property="Opacity" Value="0.4"/></Trigger>
    </ControlTemplate.Triggers>
   </ControlTemplate></Setter.Value></Setter>
  </Style>
  <Style TargetType="TextBox">
   <Setter Property="Background" Value="#111C30"/><Setter Property="Foreground" Value="#E7EEFF"/>
   <Setter Property="CaretBrush" Value="{DynamicResource Accent}"/><Setter Property="BorderBrush" Value="#314565"/>
   <Setter Property="Padding" Value="12"/><Setter Property="VerticalContentAlignment" Value="Center"/>
  </Style>
  <Style x:Key="Panel" TargetType="Border">
   <Setter Property="Background" Value="#111A2C"/><Setter Property="BorderBrush" Value="#23314B"/>
   <Setter Property="BorderThickness" Value="1"/><Setter Property="CornerRadius" Value="20"/><Setter Property="Padding" Value="18"/>
  </Style>
 </Window.Resources>
 <Grid x:Name="RootGrid" Margin="22">
  <Grid.ColumnDefinitions><ColumnDefinition x:Name="SidebarColumn" Width="218"/><ColumnDefinition x:Name="GutterColumn" Width="22"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
  <Border x:Name="Sidebar" Style="{StaticResource Panel}" Padding="16">
   <DockPanel>
    <StackPanel DockPanel.Dock="Top" Margin="0,5,0,24">
     <TextBlock Text="ATS / NEXUS" Foreground="{DynamicResource Accent}" FontSize="23" FontWeight="Bold"/>
     <TextBlock Text="ADVANCED TOOL SUITE" Foreground="#9CAECC" FontSize="10" Margin="0,6,0,0"/>
     <Border Height="2" Background="#8B5CF6" Margin="0,22,0,0"/>
    </StackPanel>
    <StackPanel DockPanel.Dock="Bottom">
     <TextBlock Text="CONTROL LOCAL" Foreground="{DynamicResource Accent}" FontSize="10"/>
     <TextBlock Text="Sin telemetria de la suite" Foreground="#9CAECC" Margin="0,6,0,10"/>
     <TextBlock Text="UAC solo cuando es necesario" Foreground="#9CAECC" TextWrapping="Wrap" FontSize="11"/>
     <TextBlock Text="v4.0.0 / Windows 10 + 11" Foreground="#687E9F" Margin="0,16,0,0" FontSize="11"/>
    </StackPanel>
    <StackPanel x:Name="Navigation"/>
   </DockPanel>
  </Border>
  <Grid Grid.Column="2">
   <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="140"/></Grid.RowDefinitions>
   <Grid Margin="0,0,0,20">
    <StackPanel><TextBlock x:Name="MainHeading" Text="Centro de control" FontSize="24" FontWeight="SemiBold"/>
     <TextBlock x:Name="Subtitle" Text="Herramientas locales y seguras." Foreground="#9CAECC" Margin="0,6,0,0"/></StackPanel>
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
     <Button x:Name="Refresh" Content="↻" Margin="0,0,6,0" ToolTip="Actualizar" AutomationProperties.Name="Actualizar"/>
     <Button x:Name="Options" Content="Ajustes" Margin="0" ToolTip="Temas, seguridad, modo compacto y registros"/>
    </StackPanel>
   </Grid>
   <UniformGrid Grid.Row="1" Columns="3" Margin="0,0,0,18">
    <Border Style="{StaticResource Panel}" Margin="0,0,10,0"><StackPanel><TextBlock Text="EQUIPO" Foreground="#9CAECC" FontSize="10"/><TextBlock x:Name="Machine" FontSize="18" Foreground="{DynamicResource Accent}" Margin="0,7,0,0" TextTrimming="CharacterEllipsis"/></StackPanel></Border>
    <Border Style="{StaticResource Panel}" Margin="0,0,10,0"><StackPanel><TextBlock Text="SESION" Foreground="#9CAECC" FontSize="10"/><TextBlock x:Name="Session" FontSize="18" Foreground="{DynamicResource Secondary}" Margin="0,7,0,0"/></StackPanel></Border>
    <Border Style="{StaticResource Panel}"><StackPanel><TextBlock Text="ESTADO / CADA 3 s" Foreground="#9CAECC" FontSize="10"/><TextBlock x:Name="Metrics" Text="Consultando…" FontSize="12" TextWrapping="Wrap" Foreground="{DynamicResource Accent}" Margin="0,7,0,0"/></StackPanel></Border>
   </UniformGrid>
   <Grid Grid.Row="2" Margin="0,0,0,14">
    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
    <StackPanel><TextBlock Text="Buscar herramienta" Foreground="#9CAECC" Margin="0,0,0,6"/>
     <TextBox x:Name="Search" ToolTip="Filtra por nombre, descripcion o categoria" AutomationProperties.Name="Buscar herramienta"/>
     <ComboBox x:Name="CategoryPicker" Margin="0,8,0,0" AutomationProperties.Name="Categoria de herramientas"/>
     <WrapPanel Margin="0,8,0,0">
      <Button x:Name="OnlyFavorites" Content="☆ Favoritos" Padding="10,6"/>
      <Button x:Name="Undo" Content="Deshacer registro" Padding="10,6"/>
      <Button x:Name="Schedule" Content="Programar" Padding="10,6"/>
      <Button x:Name="Plugins" Content="Plugins v4" Padding="10,6"/>
      <Button x:Name="ExportLog" Content="Exportar log" Padding="10,6"/>
     </WrapPanel></StackPanel>
    <TextBlock x:Name="Count" Grid.Column="1" Foreground="{DynamicResource Accent}" VerticalAlignment="Bottom" Margin="18,0,0,12"/>
   </Grid>
   <ScrollViewer Grid.Row="3" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
    <StackPanel><WrapPanel x:Name="Cards"/><TextBlock x:Name="Empty" Text="No hay coincidencias. Prueba otra busqueda o categoria." Foreground="#9CAECC" Margin="10,24" Visibility="Collapsed"/></StackPanel>
   </ScrollViewer>
   <Border Grid.Row="4" Style="{StaticResource Panel}" Margin="0,12,0,0" Padding="14,10">
    <DockPanel><Grid DockPanel.Dock="Top" Margin="0,0,0,6">
     <TextBlock Text="ACTIVIDAD DE LA SESION" Foreground="{DynamicResource Secondary}" FontSize="10" VerticalAlignment="Center"/>
     <Button x:Name="OpenLog" Content="Abrir registro" HorizontalAlignment="Right" Padding="10,4" Margin="0" FontSize="11"/>
    </Grid><TextBox x:Name="Activity" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" BorderThickness="0" Background="Transparent" Padding="0" FontFamily="Consolas" FontSize="11"/></DockPanel>
   </Border>
  </Grid>
 </Grid>
</Window>
'@
$script:Window = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($xaml))
foreach ($name in @('Navigation','Refresh','Machine','Session','Search','Count','Cards','Empty','Activity','OpenLog','Options','Metrics','OnlyFavorites','Undo','Schedule','ExportLog','Plugins','Sidebar','SidebarColumn','GutterColumn','MainHeading','Subtitle','CategoryPicker')) {
    Set-Variable -Name $name -Value $script:Window.FindName($name) -Scope Script
}
$script:Category = 'Todas'

function Write-Activity([string]$Message, [string]$Status = 'INFO', [int]$ActionId = -1) {
    if ($ActionId -lt 0) { $ActionId = $script:CurrentActionId }
    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Status, $Message
    if ($script:Activity.Text.Length -gt 64000) { $script:Activity.Clear() }
    $script:Activity.AppendText("$line`r`n")
    $script:Activity.ScrollToEnd()
    $event = [ordered]@{ utc=[DateTime]::UtcNow.ToString('o'); version=$script:Version; session=$script:SessionId; user=[Security.Principal.WindowsIdentity]::GetCurrent().Name; machine=$env:COMPUTERNAME; action=$ActionId; status=$Status; message=$Message }
    try {
        Write-RotatingLog $script:LogPath $line
        Write-RotatingLog (Join-Path $script:DataPath 'audit.jsonl') ($event | ConvertTo-Json -Compress)
    } catch { $script:Activity.AppendText("Fallo de escritura del registro local: $($_.Exception.Message)`r`n") }
    try {
        # No se cambia la ACL ni se solicita elevacion para escribir auditoria.
        if (-not (Test-Path 'C:\REPORTE')) { New-Item 'C:\REPORTE' -ItemType Directory -ErrorAction Stop | Out-Null }
        Write-RotatingLog 'C:\REPORTE\audit.log' ($event | ConvertTo-Json -Compress)
    } catch {
        if (-not $script:AuditWarned) {
            $script:AuditWarned = $true
            $script:Activity.AppendText("Auditoria C:\REPORTE no disponible; se conserva la copia local. No es un registro inmutable.`r`n")
        }
    }
}

function Start-ConsoleTask([string]$Code, [bool]$Admin = $false) {
    # Proceso separado: operaciones largas nunca bloquean el hilo de WPF.
    # La consola muestra el resultado real; iniciar no significa haber completado.
    $wrapped = @"
`$ErrorActionPreference = 'Stop'
`$taskExit = 0
`$global:LASTEXITCODE = 0
try {
$Code
if (`$LASTEXITCODE -ne 0) { throw ('El comando devolvio el codigo ' + `$LASTEXITCODE) }
Write-Host 'Operacion completada. Revisa el resultado anterior.' -ForegroundColor Cyan
} catch { `$taskExit = 1; Write-Host (`$_ | Out-String) -ForegroundColor Red }
[void](Read-Host 'Pulsa Entrar para cerrar')
exit `$taskExit
"@
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($wrapped))
    $parameters = @{ FilePath="$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"; ArgumentList="-NoProfile -EncodedCommand $encoded"; ErrorAction='Stop'; PassThru=$true; WorkingDirectory="$env:SystemRoot\System32" }
    if ($Admin) { $parameters.Verb = 'RunAs' }
    $process = Start-Process @parameters
    $timer = [Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Tag = @{Process=$process; Id=$script:CurrentActionId}
    $timer.Add_Tick({
        param($sender,$eventArgs)
        $task = $sender.Tag
        if (-not $task.Process.HasExited) { return }
        $sender.Stop()
        [void]$script:Timers.Remove($sender)
        $sender.Tag = $null
        $code = $task.Process.ExitCode
        $status = if ($code -eq 0) { 'PROCESS_EXIT_OK' } else { 'PROCESS_EXIT_ERROR' }
        Write-Activity "Consola finalizada con codigo $code. Si se cerro de forma externa, verifica el resultado manualmente." $status $task.Id
        $task.Process.Dispose()
    })
    $script:Timers.Add($timer); $timer.Start()
}

function Open-Program([string]$File, [string]$Arguments = '', [bool]$Admin = $false) {
    if ($File -notmatch '^(ms-settings:|windowsdefender:)') {
        $base = if ($File -in @('explorer.exe','regedit.exe')) { $env:SystemRoot } else { "$env:SystemRoot\System32" }
        $File = Join-Path $base $File
        if (-not (Test-Path -LiteralPath $File -PathType Leaf)) { throw "No se encuentra la herramienta: $File" }
    }
    $parameters = @{FilePath=$File; ErrorAction='Stop'; WorkingDirectory="$env:SystemRoot\System32"}
    if ($Arguments) { $parameters.ArgumentList = $Arguments }
    if ($Admin) { $parameters.Verb = 'RunAs' }
    Start-Process @parameters | Out-Null
}

function Read-Drive {
    $inputValue = [Microsoft.VisualBasic.Interaction]::InputBox('Letra de una unidad local (ejemplo: D). No incluyas rutas.', 'Seleccionar unidad', 'D')
    if ([string]::IsNullOrWhiteSpace($inputValue)) { return $null }
    if ($inputValue -notmatch '^[a-zA-Z]:?$') { throw 'Introduce solo una letra de unidad, por ejemplo D.' }
    $drive = $inputValue.Substring(0,1).ToUpperInvariant()
    if (-not (Test-Path -LiteralPath "${drive}:\" -PathType Container)) { throw 'La unidad no existe o no esta disponible.' }
    return $drive
}

function Invoke-Tool($Tool, [switch]$Prepared) {
    try {
        $script:CurrentActionId = $Tool.Id
        Assert-ToolAllowed $Tool
        if (-not $Prepared) { Write-Activity "Solicitud: $($Tool.Name)" 'REQUEST' }
        if (-not $Prepared -and $Tool.Risk) {
            $warning = "{0}`n`n{1}`n`nEsta accion puede modificar el sistema. Guarda tu trabajo. ¿Quieres continuar?" -f $Tool.Name, $Tool.Description
            if ([Windows.MessageBox]::Show($script:Window, $warning, 'Confirmar accion', 'YesNo', 'Warning', 'No') -ne 'Yes') {
                Write-Activity "Cancelado: $($Tool.Name)" 'CANCELLED'; return
            }
        }
        if (-not $Prepared) {
            if ($Tool.Risk) { Assert-Guard }
            if ($script:Settings.Restore -and $Tool.Id -in @(10,12,17,18,20,25,26,33,34)) {
                Start-RestoreWorkflow $Tool
                return
            }
        }
        switch ($Tool.Id) {
            1 { Open-Program 'msinfo32.exe' }
            2 { Open-Program 'taskmgr.exe' }
            3 { Open-Program 'mmc.exe' 'devmgmt.msc' }
            4 { Open-Program 'mmc.exe' 'services.msc' $true }
            5 { Open-Program 'control.exe' 'ncpa.cpl' }
            6 { Open-Program 'cmd.exe' '' $true }
            7 { Open-Program 'control.exe' }
            8 { Open-Program 'regedit.exe' '' $true }
            9 { Open-Program 'control.exe' 'mmsys.cpl' }
            10 { Set-RegistryTool 10; Open-Program 'explorer.exe' }
            11 {
                $drive = Read-Drive; if (-not $drive) { return }
                Show-VolumePreflight $drive
                Start-ConsoleTask "& chkdsk.exe '${drive}:'; if (`$LASTEXITCODE -ne 0) { Write-Warning ('CHKDSK devolvio el codigo ' + `$LASTEXITCODE) }" $true
            }
            12 {
                $drive = Read-Drive; if (-not $drive) { return }
                $volume = Get-Volume -DriveLetter $drive
                Show-VolumePreflight $drive
                if ($volume.FileSystem -ne 'FAT32') { throw 'Esta herramienta solo convierte volumenes FAT32.' }
                $answer = [Microsoft.VisualBasic.Interaction]::InputBox("Haz una copia de seguridad. Escribe ${drive}: para confirmar la conversion a NTFS.", 'Confirmacion de volumen', '')
                if ($answer -cne "${drive}:") { Write-Activity 'Conversion cancelada.'; return }
                Start-ConsoleTask "& convert.exe '${drive}:' /fs:ntfs; if (`$LASTEXITCODE -ne 0) { throw ('Conversion no completada. Codigo: ' + `$LASTEXITCODE) }" $true
            }
            13 { Open-Program 'cleanmgr.exe' }
            14 { Start-ConsoleTask 'Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize,FreePhysicalMemory | Format-List; Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 ProcessName,Id,@{N="RAM_MB";E={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize' }
            15 { Open-Program 'control.exe' 'powercfg.cpl' }
            16 { Open-Program 'explorer.exe' 'shell:::{ED7BA470-8E54-465E-825C-99712043E01C}' }
            17 { Set-RegistryTool 17 }
            18 { Set-RegistryTool 18 }
            19 { Start-ConsoleTask 'Get-PhysicalDisk | Select-Object FriendlyName,MediaType,HealthStatus,OperationalStatus,Size | Format-Table -AutoSize' }
            20 { Start-ConsoleTask '& netsh.exe winsock reset; if ($LASTEXITCODE -ne 0) { throw "No se pudo restablecer Winsock." }; Write-Host "Reinicia el equipo para completar el cambio."' $true }
            21 { Open-Program 'ms-settings:network' }
            22 { Open-Program 'shutdown.exe' '/s /t 0' }
            23 { Open-Program 'shutdown.exe' '/r /t 0' }
            24 { Start-ConsoleTask 'Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq (Get-Process -Id $PID).SessionId | Stop-Process -Force; Start-Sleep -Seconds 2; Start-Process explorer.exe' }
            { $_ -in 25,26 } { Set-RegistryTool $Tool.Id }
            27 { Start-ConsoleTask '& ipconfig.exe /all' }
            28 { Start-ConsoleTask '& ping.exe -n 4 google.com' }
            29 {
                $target = [Microsoft.VisualBasic.Interaction]::InputBox('Introduce una direccion IPv4, IPv6 o un nombre de dominio.', 'Prueba de conectividad', '1.1.1.1')
                if ([string]::IsNullOrWhiteSpace($target)) { return }
                # Lista estricta: impide opciones de ping e inyeccion en el proceso hijo.
                if ($target.Length -gt 253 -or $target -notmatch '^[a-zA-Z0-9][a-zA-Z0-9.:-]*$' -or [Uri]::CheckHostName($target) -eq [UriHostNameType]::Unknown) { throw 'IP o dominio no valido.' }
                Start-ConsoleTask "& ping.exe -n 4 '$target'"
            }
            30 { Start-ConsoleTask @'
$folder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'AdvancedToolSuite\Reportes'
New-Item $folder -ItemType Directory -Force | Out-Null
$file = Join-Path $folder ('Inventario-{0}.txt' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
"INVENTARIO LOCAL / $(Get-Date -Format 's')" | Out-File $file -Encoding utf8
foreach ($class in @('Win32_ComputerSystem','Win32_OperatingSystem','Win32_DiskDrive','Win32_LogicalDisk','Win32_BaseBoard','Win32_Processor','Win32_PhysicalMemory','Win32_NetworkAdapterConfiguration')) {
    "`r`n=== $class ===" | Out-File $file -Append -Encoding utf8
    Get-CimInstance -ClassName $class | Format-List * | Out-File $file -Append -Encoding utf8 -Width 200
}
Write-Host "Informe guardado en: $file"
Start-Process notepad.exe -ArgumentList ('"' + $file + '"')
'@ }
            31 { Open-Program 'control.exe' 'timedate.cpl' }
            32 { Open-Program 'mmc.exe' 'diskmgmt.msc' $true }
            33 { Start-ConsoleTask 'Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True; Get-NetFirewallProfile | Select-Object Name,Enabled | Format-Table' $true }
            34 { Start-ConsoleTask 'Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False; Get-NetFirewallProfile | Select-Object Name,Enabled | Format-Table' $true }
            35 { Open-Program 'windowsdefender:' }
            36 { Open-Program 'notepad.exe' }
            37 { Open-Program 'control.exe' 'intl.cpl' }
            38 { Open-Program 'explorer.exe' 'shell:appsfolder' }
            39 { Open-Program 'ms-settings:activation' }
            40 { Start-ConsoleTask 'Start-MpScan -ScanType QuickScan; Get-MpComputerStatus | Select-Object AntivirusEnabled,QuickScanStartTime,QuickScanEndTime | Format-List' $true }
            41 { Show-Scheduler }
            42 { Start-ConsoleTask '& shutdown.exe /a; if ($LASTEXITCODE -ne 0) { throw "No se pudo cancelar. Es posible que no haya un apagado pendiente." }' }
            default { throw 'Herramienta no implementada.' }
        }
        Write-Activity "Accion enviada: $($Tool.Name). Comprueba el resultado en la ventana abierta o en Windows." 'DISPATCHED'
    } catch {
        Write-Activity "ERROR / $($Tool.Name): $($_.Exception.Message)" 'ERROR'
        [void][Windows.MessageBox]::Show($script:Window, $_.Exception.Message, 'No se pudo ejecutar la accion', 'OK', 'Error')
    }
}

function Update-Cards {
    $script:Cards.Children.Clear()
    $query = $script:Search.Text.Trim()
    $filtered = @($script:Tools | Where-Object {
        (-not $script:FavoritesOnly -or $_.Id -in @($script:Settings.Favorites)) -and
        ($script:Category -eq 'Todas' -or $_.Category -eq $script:Category) -and
        (-not $query -or (($_.Name + ' ' + $_.Description + ' ' + $_.Category).IndexOf($query, [StringComparison]::CurrentCultureIgnoreCase) -ge 0))
    })
    foreach ($tool in $filtered) {
        $button = [Windows.Controls.Button]::new()
        $button.Width = if ($script:Settings.Compact) { 290 } else { 248 }; $button.MinHeight = 152; $button.Padding = [Windows.Thickness]::new(16)
        $button.Tag = $tool
        $button.ToolTip = $tool.Description
        $button.IsEnabled = -not $script:Settings.ReadOnly -or (Test-ReadOnlyTool $tool.Id)
        $panel = [Windows.Controls.StackPanel]::new()
        $top = [Windows.Controls.DockPanel]::new()
        $star = [Windows.Controls.Button]::new()
        $star.Content = if ($tool.Id -in @($script:Settings.Favorites)) { '★' } else { '☆' }
        $star.Tag = $tool.Id; $star.Padding = [Windows.Thickness]::new(6,0,6,0)
        $star.ToolTip = 'Marcar o quitar favorito'
        $star.Add_Click({
            param($sender, $eventArgs)
            $id = [int]$sender.Tag
            if ($id -in @($script:Settings.Favorites)) { $script:Settings.Favorites = @($script:Settings.Favorites | Where-Object { $_ -ne $id }) }
            else { $script:Settings.Favorites = @($script:Settings.Favorites) + $id }
            Save-Preferences; Update-Cards
            $eventArgs.Handled = $true
        })

        $icon = New-ToolIcon $tool.Id
        [void]$top.Children.Add($icon)
        [void]$panel.Children.Add($top)
        $badge = [Windows.Controls.TextBlock]::new()
        $badge.Text = $tool.Category.ToUpperInvariant() + $(if ($tool.Admin) { ' / UAC' } else { '' })
        $badge.FontSize = 10; $badge.Foreground = $script:Window.Resources['Accent']
        $title = [Windows.Controls.TextBlock]::new()
        $title.Text = $tool.Name; $title.FontSize = 16; $title.FontWeight = 'SemiBold'
        $title.TextWrapping = 'Wrap'; $title.Margin = [Windows.Thickness]::new(0,9,0,7)
        $description = [Windows.Controls.TextBlock]::new()
        $description.Text = $tool.Description; $description.TextWrapping = 'Wrap'; $description.FontSize = 12
        $description.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString('#9CAECC')
        if ($tool.Risk) { $badge.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString('#FFBE7A'); $badge.Text += ' / PRECAUCION' }
        [void]$panel.Children.Add($badge); [void]$panel.Children.Add($title); [void]$panel.Children.Add($description)
        $button.Content = $panel
        Add-EntranceAnimation $button
        $button.Add_Click({ param($sender, $eventArgs) Invoke-Tool $sender.Tag })
        $wrapper = [Windows.Controls.Grid]::new()
        $star.HorizontalAlignment = 'Right'; $star.VerticalAlignment = 'Top'
        $star.Margin = [Windows.Thickness]::new(0,8,16,0)
        [void]$wrapper.Children.Add($button); [void]$wrapper.Children.Add($star)
        [void]$script:Cards.Children.Add($wrapper)
    }
    $script:Count.Text = '{0} herramientas' -f $filtered.Count
    $script:Empty.Visibility = if ($filtered.Count -eq 0) { 'Visible' } else { 'Collapsed' }
}

# REGION NEXUS_V3_EXTENSIONS
function Write-RotatingLog([string]$Path, [string]$Text) {
    # Un escritor por sesion; varias instancias reintentan si el archivo esta ocupado.
    for ($attempt = 0; $attempt -lt 3; $attempt++) {
        try {
            if ((Test-Path -LiteralPath $Path) -and (Get-Item -LiteralPath $Path).Length -gt 5242880) {
                if (Test-Path "$Path.5") { Remove-Item "$Path.5" -Force }
                for ($n = 4; $n -ge 1; $n--) {
                    if (Test-Path "$Path.$n") { Move-Item "$Path.$n" "$Path.$($n+1)" -Force }
                }
                Move-Item $Path "$Path.1" -Force
            }
            Add-Content -LiteralPath $Path -Value $Text -Encoding UTF8 -ErrorAction Stop
            return
        } catch {
            if ($attempt -eq 2) { throw }
            Start-Sleep -Milliseconds 25
        }
    }
}

function Save-Preferences {
    try {
        $temporary = "$script:SettingsPath.$PID.tmp"
        $script:Settings | ConvertTo-Json -Depth 4 | Set-Content $temporary -Encoding UTF8
        Move-Item $temporary $script:SettingsPath -Force
    } catch { Write-Warning "No se pudieron guardar las preferencias: $($_.Exception.Message)" }
}

function Apply-Theme {
    $palette = @{
        'Neon azul'=@('#38E8ED','#B69AFF','#17213B')
        'Purpura cyberpunk'=@('#D48AFF','#FF70CC','#2D1740')
        'Verde Matrix'=@('#66FF99','#C2FF70','#102D22')
        'Rojo gaming'=@('#FF727F','#FFBF69','#331625')
    }
    if (-not $palette.ContainsKey([string]$script:Settings.Theme)) { $script:Settings.Theme = 'Neon azul' }
    $colors = $palette[$script:Settings.Theme]
    $script:Window.Resources['Accent'] = [Windows.Media.SolidColorBrush]::new([Windows.Media.ColorConverter]::ConvertFromString($colors[0]))
    $script:Window.Resources['Secondary'] = [Windows.Media.SolidColorBrush]::new([Windows.Media.ColorConverter]::ConvertFromString($colors[1]))
    $gradient = $script:Window.Resources['MainBackground'].CloneCurrentValue()
    $script:Window.Resources['MainBackground'] = $gradient
    $gradient.GradientStops[1].Color = [Windows.Media.ColorConverter]::ConvertFromString($colors[2])
    $gradient.GradientStops[1].BeginAnimation([Windows.Media.GradientStop]::OffsetProperty, $null)
    if ($script:Settings.Motion -and [Windows.SystemParameters]::ClientAreaAnimation) {
        $animation = [Windows.Media.Animation.DoubleAnimation]::new(0.25, 0.85, [Windows.Duration]::new([TimeSpan]::FromSeconds(12)))
        $animation.AutoReverse = $true; $animation.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever
        $gradient.GradientStops[1].BeginAnimation([Windows.Media.GradientStop]::OffsetProperty, $animation)
    }
}

function Add-EntranceAnimation($Control) {
    if (-not $script:Settings.Motion -or -not [Windows.SystemParameters]::ClientAreaAnimation) { return }
    $Control.RenderTransform = [Windows.Media.TranslateTransform]::new(0,0)
    $Control.Add_Loaded({
        param($sender, $eventArgs)
        if (-not $script:Settings.Motion) { return }
        $duration = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(220))
        $fade = [Windows.Media.Animation.DoubleAnimation]::new(0,1,$duration)
        $slide = [Windows.Media.Animation.DoubleAnimation]::new(12,0,$duration)
        $sender.BeginAnimation([Windows.UIElement]::OpacityProperty, $fade)
        $sender.RenderTransform.BeginAnimation([Windows.Media.TranslateTransform]::YProperty, $slide)
    })
}

function Set-CompactMode {
    if ($script:Settings.Compact) {
        $script:MainHeading.FontSize = 14
        $script:Subtitle.Visibility = 'Collapsed'
        $script:Window.MinWidth = 380
        $script:Sidebar.Visibility = 'Collapsed'
        $script:SidebarColumn.Width = [Windows.GridLength]::new(0)
        $script:GutterColumn.Width = [Windows.GridLength]::new(0)
        $script:Window.Width = 410
    } else {
        $script:MainHeading.FontSize = 24
        $script:Subtitle.Visibility = 'Visible'
        $script:Window.MinWidth = 960
        $script:Sidebar.Visibility = 'Visible'
        $script:SidebarColumn.Width = [Windows.GridLength]::new(218)
        $script:GutterColumn.Width = [Windows.GridLength]::new(22)
        $script:Window.Width = 1220
    }
    Update-Cards
}

# Lista conservadora: no abre consolas administrativas ni paneles que permitan editar.
function Test-ReadOnlyTool([int]$Id) { return $Id -in @(1,11,14,19,27,28,29,30) }
function Assert-ToolAllowed($Tool) {
    if ($script:Settings.ReadOnly -and -not (Test-ReadOnlyTool $Tool.Id)) { throw 'Modo solo lectura: esta herramienta esta bloqueada.' }
    if ($null -ne $script:RestorePending) { throw 'Espera a que termine el punto de restauracion pendiente.' }
    $required = @{11='chkdsk.exe';12='convert.exe';19='Get-PhysicalDisk';20='netsh.exe';27='ipconfig.exe';28='ping.exe';29='ping.exe';33='Set-NetFirewallProfile';34='Set-NetFirewallProfile';40='Start-MpScan'}
    if ($required.ContainsKey([int]$Tool.Id) -and -not (Get-Command $required[[int]$Tool.Id] -ErrorAction SilentlyContinue)) {
        throw "No esta disponible: $($required[[int]$Tool.Id]). Comprueba los componentes de Windows."
    }
}

function Show-VolumePreflight([string]$Drive) {
    $volume = Get-Volume -DriveLetter $Drive -ErrorAction Stop
    $media = 'No disponible'
    try {
        $disk = Get-Partition -DriveLetter $Drive | Get-Disk
        $media = ($disk | Select-Object -ExpandProperty Model) -join ', '
        # MediaType puede ser Unspecified; no se infiere SSD por velocidad ni por nombre.
        $serial = [string]$disk.SerialNumber
        $physical = @()
        if (-not [string]::IsNullOrWhiteSpace($serial)) {
            $physical = @(Get-PhysicalDisk | Where-Object { -not [string]::IsNullOrWhiteSpace($_.SerialNumber) -and $_.SerialNumber.Trim() -eq $serial.Trim() })
        }
        if ($physical.Count -eq 1) { $media += ' / ' + $physical[0].MediaType }
    } catch { $media = 'Tipo no determinado (RAID, virtual o permisos insuficientes)' }
    $text = "Unidad ${Drive}: / $($volume.FileSystem)`nEspacio libre: $([math]::Round($volume.SizeRemaining/1073741824,2)) GB`nDispositivo: $media`n`nNo se ejecuta desfragmentacion. Un informe de salud no garantiza ausencia de fallos."
    if ($volume.SizeRemaining -lt 1073741824) { $text += "`nADVERTENCIA: menos de 1 GB disponible." }
    Write-Activity $text 'PREFLIGHT'
    if ([Windows.MessageBox]::Show($script:Window, $text, 'Verificacion previa de unidad', 'OKCancel', 'Information') -ne 'OK') { throw 'Operacion cancelada en la verificacion previa.' }
}

function Start-Metrics {
    $timer = [Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromSeconds(3)
    $timer.Add_Tick({
        try {
            if ($null -ne $script:MetricsJob) {
                if (-not $script:MetricsHandle.IsCompleted) { return }
                $result = @($script:MetricsJob.EndInvoke($script:MetricsHandle))
                $hasErrors = $script:MetricsJob.HadErrors
                $script:MetricsJob.Dispose(); $script:MetricsJob = $null
                if ($hasErrors -or $result.Count -eq 0) { $script:Metrics.Text = 'Metricas no disponibles' }
                else { $script:Metrics.Text = [string]$result[-1] }
            }
            $script:MetricsJob = [PowerShell]::Create()
            [void]$script:MetricsJob.AddScript({
                $ErrorActionPreference = 'Stop'
                $os = Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 5
                $cpu = @(Get-CimInstance Win32_Processor -OperationTimeoutSec 5 | Select-Object -ExpandProperty LoadPercentage | Where-Object { $null -ne $_ })
                $load = if ($cpu.Count) { [math]::Round(($cpu | Measure-Object -Average).Average) } else { 'N/D' }
                $ram = [math]::Round(100 * (1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize))
                $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'" -OperationTimeoutSec 5
                'CPU {0}% / RAM {1}% / Disco {2} GB libres' -f $load,$ram,[math]::Round($disk.FreeSpace/1073741824,1)
            })
            $script:MetricsHandle = $script:MetricsJob.BeginInvoke()
        } catch {
            $script:Metrics.Text = 'Metricas no disponibles'
            if ($null -ne $script:MetricsJob) { $script:MetricsJob.Dispose(); $script:MetricsJob = $null }
        }
    })
    $script:Timers.Add($timer); $timer.Start()
}

function Get-RegistrySpec([int]$Id) {
    switch ($Id) {
        10 { return @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='Hidden'; Value=1; Kind='DWord'} }
        17 { return @{Path='HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'; Name=''; Value=''; Kind='String'} }
        18 { return @{Path='HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'; Name=''; Value=$null; Kind='String'} }
        25 { return @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name='AppsUseLightTheme'; Value=0; Kind='DWord'} }
        26 { return @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name='AppsUseLightTheme'; Value=1; Kind='DWord'} }
        default { throw 'Cambio de registro no admitido.' }
    }
}

function Save-RegistryUndo([int]$Id) {
    $spec = Get-RegistrySpec $Id
    $exists = $false; $value = $null; $kind = $spec.Kind
    if (Test-Path $spec.Path) {
        $key = Get-Item $spec.Path
        $exists = $key.GetValueNames() -contains $spec.Name
        if ($exists) { $value = $key.GetValue($spec.Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames); $kind = [string]$key.GetValueKind($spec.Name) }
    }
    # Solo un nivel. No se serializan claves enteras ni credenciales.
    @{Id=$Id; PathExisted=(Test-Path $spec.Path); Exists=$exists; Value=$value; Kind=$kind; Utc=[DateTime]::UtcNow} | Export-Clixml $script:UndoPath -Encoding UTF8
}

function Set-RegistryTool([int]$Id) {
    $spec = Get-RegistrySpec $Id
    if ($Id -eq 18 -and (Test-Path $spec.Path)) {
        $existing = Get-Item $spec.Path
        if (@($existing.GetValueNames() | Where-Object { $_ -ne '' }).Count -gt 0 -or $existing.SubKeyCount -gt 0) {
            throw 'La clave contiene otros ajustes. No se eliminara; revisala manualmente.'
        }
    }
    Save-RegistryUndo $Id
    if ($Id -eq 18) {
        if (Test-Path $spec.Path) { Remove-Item $spec.Path }
    } else {
        if (-not (Test-Path $spec.Path)) { New-Item $spec.Path -Force | Out-Null }
        (Get-Item $spec.Path).SetValue($spec.Name,$spec.Value,([Enum]::Parse([Microsoft.Win32.RegistryValueKind],$spec.Kind)))
    }
    Write-Activity 'Ajuste interno aplicado y valor anterior guardado. Puede requerir reiniciar el Explorador o cerrar sesion.' 'REGISTRY_OK'
}

function Invoke-RegistryUndo([switch]$Prepared) {
    $script:CurrentActionId = 0
    try {
        if ($script:Settings.ReadOnly) { throw 'Deshacer esta bloqueado en modo solo lectura.' }
        if ($null -ne $script:RestorePending) { throw 'Espera a que termine el punto de restauracion pendiente.' }
        if (-not (Test-Path $script:UndoPath)) { throw 'No hay un ajuste de registro guardado para deshacer.' }
        if (-not $Prepared -and [Windows.MessageBox]::Show($script:Window, '¿Restaurar el valor anterior del ultimo ajuste de registro? No revierte operaciones externas.', 'Deshacer registro', 'YesNo', 'Warning', 'No') -ne 'Yes') { return }
        if (-not $Prepared) {
            Assert-Guard
            if ($script:Settings.Restore) { Start-RestoreWorkflow @{Id=-1; Name='Deshacer registro'}; return }
        }
        $snapshot = Import-Clixml $script:UndoPath
        # Nunca se acepta una ruta desde el archivo persistido: solo un ID de la lista blanca.
        $spec = Get-RegistrySpec ([int]$snapshot.Id)
        # No sobrescribir un cambio ajeno posterior al ajuste guardado.
        $current = if (Test-Path $spec.Path) { (Get-Item $spec.Path).GetValue($spec.Name,$null) } else { $null }
        $kindChanged = $false
        if ($snapshot.Id -ne 18 -and (Test-Path $spec.Path)) {
            $currentKey = Get-Item $spec.Path
            if ($currentKey.GetValueNames() -contains $spec.Name) { $kindChanged = [string]$currentKey.GetValueKind($spec.Name) -ne $spec.Kind }
        }
        if ($kindChanged -or ($snapshot.Id -eq 18 -and (Test-Path $spec.Path)) -or ($snapshot.Id -ne 18 -and $current -cne $spec.Value)) {
            throw 'El ajuste cambio desde la ultima operacion. Deshacer se cancela para no sobrescribir cambios externos.'
        }
        if ($snapshot.Exists) {
            if ([string]$snapshot.Kind -notin @('DWord','String','ExpandString','QWord','MultiString','Binary')) { throw 'Tipo de registro no permitido.' }
            if (-not (Test-Path $spec.Path)) { New-Item $spec.Path -Force | Out-Null }
            $key = Get-Item $spec.Path
            $key.SetValue($spec.Name, $snapshot.Value, ([Enum]::Parse([Microsoft.Win32.RegistryValueKind], [string]$snapshot.Kind)))
        } elseif (Test-Path $spec.Path) {
            $key = Get-Item $spec.Path
            $key.DeleteValue($spec.Name, $false)
            if (-not $snapshot.PathExisted -and $key.ValueCount -eq 0 -and $key.SubKeyCount -eq 0) { Remove-Item $spec.Path }
        }
        Remove-Item $script:UndoPath
        Write-Activity 'Valor anterior restaurado. Puede requerir reiniciar el Explorador o la sesion.' 'UNDO_OK'
    } catch { Write-Activity $_.Exception.Message 'UNDO_ERROR' }
}

function Read-Secret([string]$Title) {
    $dialog = [Windows.Window]::new()
    $dialog.Resources.MergedDictionaries.Add($script:Window.Resources)
    $dialog.Background = [Windows.Media.BrushConverter]::new().ConvertFromString('#111A2C')
    $dialog.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString('#E7EEFF')
    $dialog.Title = $Title; $dialog.Owner = $script:Window; $dialog.Width = 400; $dialog.SizeToContent = 'Height'
    $dialog.WindowStartupLocation = 'CenterOwner'; $dialog.ResizeMode = 'NoResize'
    $panel = [Windows.Controls.StackPanel]::new(); $panel.Margin = [Windows.Thickness]::new(20)
    $label = [Windows.Controls.TextBlock]::new(); $label.Text = 'Proteccion local contra cambios accidentales (no sustituye UAC).'; $label.TextWrapping = 'Wrap'
    $box = [Windows.Controls.PasswordBox]::new(); $box.Margin = [Windows.Thickness]::new(0,14,0,14); $box.MaxLength = 128
    $ok = [Windows.Controls.Button]::new(); $ok.Content = 'Aceptar'; $ok.IsDefault = $true
    $ok.Add_Click({ $this.Tag.DialogResult = $true }); $ok.Tag = $dialog
    [void]$panel.Children.Add($label); [void]$panel.Children.Add($box); [void]$panel.Children.Add($ok)
    $dialog.Content = $panel
    if ($dialog.ShowDialog() -eq $true) { return $box.SecurePassword }
    return $null
}

function Get-PasswordHash([Security.SecureString]$Secret, [byte[]]$Salt) {
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret)
    try {
        $text = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
        $derive = [Security.Cryptography.Rfc2898DeriveBytes]::new($text, $Salt, 310000, [Security.Cryptography.HashAlgorithmName]::SHA256)
        try { return [Convert]::ToBase64String($derive.GetBytes(32)) } finally { $derive.Dispose(); $text = $null }
    } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
}

function Read-GuardRecord {
    $bytes = [IO.File]::ReadAllBytes($script:GuardPath)
    $plain = [Security.Cryptography.ProtectedData]::Unprotect($bytes,$null,[Security.Cryptography.DataProtectionScope]::CurrentUser)
    return [Text.Encoding]::UTF8.GetString($plain) | ConvertFrom-Json
}
function Save-GuardRecord($Record) {
    $plain = [Text.Encoding]::UTF8.GetBytes(($Record | ConvertTo-Json -Compress))
    $bytes = [Security.Cryptography.ProtectedData]::Protect($plain,$null,[Security.Cryptography.DataProtectionScope]::CurrentUser)
    [IO.File]::WriteAllBytes($script:GuardPath,$bytes)
}
function Set-Guard {
    try {
        if ($script:Settings.ReadOnly) { throw 'No se cambia la proteccion en modo solo lectura.' }
        if (Test-Path $script:GuardPath) { Assert-Guard }
        $first = Read-Secret 'Nueva clave (minimo 10 caracteres)'; if ($null -eq $first) { return }
        try {
            if ($first.Length -lt 10) { throw 'Usa al menos 10 caracteres.' }
            $second = Read-Secret 'Repite la nueva clave'; if ($null -eq $second) { return }
            try {
                $salt = [byte[]]::new(32); $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
                try { $rng.GetBytes($salt) } finally { $rng.Dispose() }
                $hash = Get-PasswordHash $first $salt
                if ($hash -cne (Get-PasswordHash $second $salt)) { throw 'Las claves no coinciden.' }
                Save-GuardRecord @{Salt=[Convert]::ToBase64String($salt); Hash=$hash; Failures=0; LockedUntil=''}
                Write-Activity 'Proteccion local configurada (DPAPI por usuario).' 'GUARD_SET'
            } finally { $second.Dispose() }
        } finally { $first.Dispose() }
    } catch { Write-Activity $_.Exception.Message 'GUARD_ERROR' }
}
function Assert-Guard {
    if (-not (Test-Path $script:GuardPath)) { return }
    $record = Read-GuardRecord
    if ($record.LockedUntil -and [DateTime]::Parse($record.LockedUntil).ToUniversalTime() -gt [DateTime]::UtcNow) { throw 'Proteccion bloqueada temporalmente. Espera 5 minutos.' }
    $secret = Read-Secret 'Autoriza la accion critica'
    if ($null -eq $secret) { throw 'Autorizacion cancelada.' }
    try { $hash = Get-PasswordHash $secret ([Convert]::FromBase64String($record.Salt)) } finally { $secret.Dispose() }
    # Comparacion de longitud fija, sin guardar contrasenas en texto claro.
    $left = [Convert]::FromBase64String($hash); $right = [Convert]::FromBase64String($record.Hash)
    $difference = $left.Length -bxor $right.Length
    for ($i=0; $i -lt [Math]::Min($left.Length,$right.Length); $i++) { $difference = $difference -bor ($left[$i] -bxor $right[$i]) }
    if ($difference -ne 0) {
        $record.Failures++
        if ($record.Failures -ge 5) { $record.LockedUntil = [DateTime]::UtcNow.AddMinutes(5).ToString('o'); $record.Failures = 0 }
        Save-GuardRecord $record
        throw 'Clave incorrecta.'
    }
    $record.Failures = 0; $record.LockedUntil = ''; Save-GuardRecord $record
}

function Start-RestoreWorkflow($Tool = $null) {
    if ($script:Settings.ReadOnly) { throw 'La restauracion esta bloqueada en modo solo lectura.' }
    if ($null -ne $script:RestorePending) { throw 'Ya hay una restauracion pendiente.' }
    # Verificacion antes/despues: Checkpoint-Computer puede advertir sin crear por la cuota de 24 h.
    $code = @'
$ErrorActionPreference = 'Stop'
try {
    $before = @(Get-ComputerRestorePoint | Select-Object -ExpandProperty SequenceNumber)
    Checkpoint-Computer -Description 'Advanced Tool Suite - previo a cambios' -RestorePointType MODIFY_SETTINGS -WarningAction Stop
    $after = @(Get-ComputerRestorePoint | Where-Object { $_.SequenceNumber -notin $before })
    if ($after.Count -eq 0) { throw 'No se ha verificado un punto nuevo.' }
    exit 0
} catch { Write-Host $_ -ForegroundColor Red; Start-Sleep -Seconds 8; exit 1 }
'@
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
    $process = Start-Process "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-NoProfile -EncodedCommand $encoded" -Verb RunAs -PassThru
    $script:RestorePending = @{Process=$process; Tool=$Tool}
    Write-Activity 'Creando punto de restauracion. Si falla, NO se ejecutara el cambio.' 'RESTORE_START'
    $timer = [Windows.Threading.DispatcherTimer]::new(); $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Add_Tick({
        param($sender,$eventArgs)
        if ($null -eq $script:RestorePending -or -not $script:RestorePending.Process.HasExited) { return }
        $pending = $script:RestorePending; $script:RestorePending = $null; $sender.Stop(); [void]$script:Timers.Remove($sender)
        if ($pending.Process.ExitCode -eq 0) {
            Write-Activity 'Nuevo punto de restauracion verificado.' 'RESTORE_OK'
            if ($null -ne $pending.Tool) {
                if ($pending.Tool.Id -eq -1) { Invoke-RegistryUndo -Prepared }
                else { Invoke-Tool $pending.Tool -Prepared }
            }
        } else { Write-Activity 'No se creo el punto. Accion bloqueada; comprueba Proteccion del sistema y limite de frecuencia de Windows.' 'RESTORE_ERROR' }
        $pending.Process.Dispose()
    })
    $script:Timers.Add($timer); $timer.Start()
}

function Export-Activity {
    try {
        $dialog = [Microsoft.Win32.SaveFileDialog]::new()
        $dialog.Filter = 'Registro de texto (*.log)|*.log'; $dialog.FileName = 'ATS-historial.log'
        if ($dialog.ShowDialog($script:Window)) {
            $parts = @()
            for ($n=5; $n -ge 1; $n--) { if (Test-Path "$script:LogPath.$n") { $parts += Get-Content "$script:LogPath.$n" } }
            if (Test-Path $script:LogPath) { $parts += Get-Content $script:LogPath }
            $parts | Set-Content -LiteralPath $dialog.FileName -Encoding UTF8
            Write-Activity 'Historial exportado. Revisalo antes de compartirlo.' 'EXPORT_OK'
        }
    } catch { Write-Activity $_.Exception.Message 'EXPORT_ERROR' }
}

function Show-Scheduler {
    $script:CurrentActionId = 0
    try {
        if ($script:Settings.ReadOnly) { throw 'Programar tareas esta bloqueado en modo solo lectura.' }
        if (-not (Get-Command Register-ScheduledTask -ErrorAction SilentlyContinue)) { throw 'El Programador de tareas no esta disponible.' }
        Assert-Guard
        $value = [Microsoft.VisualBasic.Interaction]::InputBox('Programa una captura de sistema unica (sesion iniciada). Fecha local: yyyy-MM-dd HH:mm. Los informes van a Documentos\AdvancedToolSuite\Programados.', 'Programar informe del sistema', (Get-Date).AddHours(1).ToString('yyyy-MM-dd HH:mm'))
        if (-not $value) { return }
        $when = [DateTime]::MinValue
        if (-not [DateTime]::TryParseExact($value,'yyyy-MM-dd HH:mm',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$when) -or $when -le (Get-Date)) { throw 'Introduce una fecha futura con el formato indicado.' }
        if ([Windows.MessageBox]::Show($script:Window, "¿Crear una tarea de informe para $value? Solo se ejecuta con tu sesion iniciada. Puedes eliminarla en el Programador de tareas (ATS-Informe-*).", 'Confirmar tarea', 'YesNo', 'Question', 'No') -ne 'Yes') { return }
        $code = @'
$ErrorActionPreference = 'Stop'
$folder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'AdvancedToolSuite\Programados'
New-Item $folder -ItemType Directory -Force | Out-Null
$file = Join-Path $folder ('Sistema-{0}.txt' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,LastBootUpTime,FreePhysicalMemory,TotalVisibleMemorySize | Format-List | Out-File $file -Encoding UTF8
'@
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($code))
        $action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -NonInteractive -EncodedCommand $encoded"
        $trigger = New-ScheduledTaskTrigger -Once -At $when
        $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
        $name = 'ATS-Informe-' + [guid]::NewGuid().ToString('N').Substring(0,12)
        Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Informe de sistema ATS; sin credenciales guardadas.' | Out-Null
        Write-Activity "Tarea creada: $name / $value. No se guarda ninguna contrasena de Windows." 'TASK_REGISTERED'
    } catch { Write-Activity $_.Exception.Message 'TASK_ERROR' }
}

function Set-ExplorerIntegration([bool]$Install) {
    $script:CurrentActionId = 0
    if ($script:Settings.ReadOnly) { throw 'Integracion bloqueada en modo solo lectura.' }
    Assert-Guard
    $root = 'HKCU:\Software\Classes\Directory\Background\shell\AdvancedToolSuite'
    if (-not $Install) {
        if (Test-Path $root) { Remove-Item $root -Recurse -Force }
        Write-Activity 'Menu contextual de ATS retirado para este usuario.' 'CONTEXT_REMOVE'
        return
    }
    # Un EXE empaquetado no tiene PSCommandPath util: se usa su ruta real.
    if ([IO.Path]::GetExtension($script:ExecutablePath) -eq '.exe' -and [IO.Path]::GetFileName($script:ExecutablePath) -notin @('powershell.exe','pwsh.exe')) {
        $command = '"' + $script:ExecutablePath + '"'
    } else {
        if (-not $script:SourcePath -or -not (Test-Path -LiteralPath $script:SourcePath)) { throw 'No se ha podido localizar el archivo portable.' }
        $command = '"' + "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" + '" -NoProfile -STA -File "' + $script:SourcePath + '"'
    }
    if ([Windows.MessageBox]::Show($script:Window, 'Se agregara Advanced Tool Suite al clic derecho del fondo de las carpetas. Si mueves el programa deberas reinstalar esta opcion. ¿Continuar?', 'Integrar en Explorador', 'YesNo', 'Question', 'No') -ne 'Yes') { return }
    New-Item "$root\command" -Force | Out-Null
    Set-Item $root -Value 'Advanced Tool Suite'
    Set-Item "$root\command" -Value $command
    Write-Activity 'Menu contextual de ATS instalado. En Windows 11 puede estar en Mostrar mas opciones.' 'CONTEXT_INSTALL'
}

function Show-Preferences {
    $script:CurrentActionId = 0
    [xml]$preferencesXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="ATS / Preferencias y seguridad" Width="580" Height="710" MinHeight="500" WindowStartupLocation="CenterOwner" Background="#111A2C" Foreground="#E7EEFF" FontFamily="Segoe UI">
 <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="24">
  <TextBlock Text="Personaliza tu centro de control" FontSize="22" Margin="0,0,0,18"/>
  <TextBlock Text="Tema visual"/><ComboBox x:Name="Theme" Margin="0,6,0,12"/>
  <CheckBox x:Name="Compact" Foreground="#E7EEFF" Content="Modo compacto (barra lateral)" Margin="0,6"/>
  <CheckBox x:Name="Motion" Foreground="#E7EEFF" Content="Animaciones y gradiente ambiental" Margin="0,6"/>
  <CheckBox x:Name="ReadOnly" Foreground="#E7EEFF" Content="Solo lectura (lista conservadora de diagnosticos)" Margin="0,6"/>
  <CheckBox x:Name="Restore" Foreground="#E7EEFF" Content="Exigir punto de restauracion antes de cambios compatibles" Margin="0,6"/>
  <TextBlock Text="No sustituye permisos Windows. Deshacer solo cubre el ultimo ajuste interno de registro. Los puntos requieren Proteccion del sistema y pueden estar limitados a uno cada 24 h." TextWrapping="Wrap" Foreground="#9CAECC" Margin="0,12"/>
  <Button x:Name="Apply" Content="Aplicar preferencias" Margin="0,5" Padding="10"/>
  <Button x:Name="Guard" Content="Configurar / cambiar clave local" Margin="0,5" Padding="10"/>
  <Button x:Name="ClearGuard" Content="Retirar clave local (requiere clave actual)" Margin="0,5" Padding="10"/>
  <Button x:Name="RestoreNow" Content="Crear punto de restauracion ahora" Margin="0,5" Padding="10"/>
  <Button x:Name="ContextInstall" Content="Instalar menu contextual del Explorador" Margin="0,5" Padding="10"/>
  <Button x:Name="ContextRemove" Content="Retirar menu contextual del Explorador" Margin="0,5" Padding="10"/>
  <Button x:Name="Logs" Content="Abrir carpeta de registros y preferencias" Margin="0,5" Padding="10"/>
  <TextBlock Text="ATS 4.0.0 · Historial de versiones: CHANGELOG.md junto al proyecto. Auditoria local y C:\REPORTE\audit.log si es accesible." TextWrapping="Wrap" Foreground="#9CAECC" Margin="0,12"/>
 </StackPanel></ScrollViewer>
</Window>
'@
    $dialog = [Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($preferencesXaml))
    $dialog.Owner = $script:Window
    $dialog.Resources.MergedDictionaries.Add($script:Window.Resources)
    foreach ($theme in @('Neon azul','Purpura cyberpunk','Verde Matrix','Rojo gaming')) { [void]$dialog.FindName('Theme').Items.Add($theme) }
    $dialog.FindName('Theme').SelectedItem = $script:Settings.Theme
    foreach ($key in @('Compact','Motion','ReadOnly','Restore')) { $dialog.FindName($key).IsChecked = [bool]$script:Settings[$key] }
    $dialog.FindName('Apply').Tag = $dialog
    $dialog.FindName('Apply').Add_Click({
        $owner = $this.Tag
        try {
            if ($script:Settings.ReadOnly -and -not $owner.FindName('ReadOnly').IsChecked) { Assert-Guard }
            $script:Settings.Theme = [string]$owner.FindName('Theme').SelectedItem
            foreach ($key in @('Compact','Motion','ReadOnly','Restore')) { $script:Settings[$key] = [bool]$owner.FindName($key).IsChecked }
            Save-Preferences; Apply-Theme; Set-CompactMode
            Write-Activity 'Preferencias aplicadas.' 'SETTINGS'
        } catch { Write-Activity $_.Exception.Message 'SETTINGS_ERROR' }
    })
    $dialog.FindName('Guard').Add_Click({ Set-Guard })
    $dialog.FindName('ClearGuard').Add_Click({
        try {
            if ($script:Settings.ReadOnly) { throw 'Desactiva solo lectura antes de cambiar la proteccion.' }
            Assert-Guard
            if (Test-Path $script:GuardPath) { Remove-Item $script:GuardPath }
            Write-Activity 'Proteccion local retirada.' 'GUARD_REMOVE'
        } catch { Write-Activity $_.Exception.Message 'GUARD_ERROR' }
    })
    $dialog.FindName('RestoreNow').Add_Click({ try { Assert-Guard; Start-RestoreWorkflow } catch { Write-Activity $_.Exception.Message 'RESTORE_ERROR' } })
    $dialog.FindName('ContextInstall').Add_Click({ try { Set-ExplorerIntegration $true } catch { Write-Activity $_.Exception.Message 'CONTEXT_ERROR' } })
    $dialog.FindName('ContextRemove').Add_Click({ try { Set-ExplorerIntegration $false } catch { Write-Activity $_.Exception.Message 'CONTEXT_ERROR' } })
    $dialog.FindName('Logs').Add_Click({ try { Open-Program 'explorer.exe' ('"' + $script:DataPath + '"') } catch { Write-Activity $_.Exception.Message 'ERROR' } })
    [void]$dialog.ShowDialog()
}

$script:IconPaths = @{
    1='M3 3H21V17H3Z M8 21H16 M12 17V21'
    2='M3 20V4 M3 20H22 M7 16V12 M12 16V7 M17 16V10'
    3='M6 4H18V20H6Z M9 2V4 M15 2V4 M9 20V22 M15 20V22 M2 8H6 M18 8H22 M2 16H6 M18 16H22'
    4='M12 4L15 8H20V16H15L12 20L9 16H4V8H9Z M9 10H15V14H9Z'
    5='M3 3H9V9H3Z M15 3H21V9H15Z M9 6H15 M6 9V17H18V9 M9 17H15V22H9Z'
    6='M3 4H21V20H3Z M6 8L10 12L6 16 M12 16H18'
    7='M3 3H10V10H3Z M14 3H21V10H14Z M3 14H10V21H3Z M14 14H21V21H14Z'
    8='M4 3H10V9H4Z M14 15H20V21H14Z M14 3H20V9H14Z M7 9V18H14 M10 6H14'
    9='M3 9H7L12 4V20L7 15H3Z M16 8Q22 12 16 16'
    10='M2 12Q12 1 22 12Q12 23 2 12Z M9 12A3 3 0 1 0 15 12A3 3 0 1 0 9 12'
    11='M3 5H21V18H3Z M6 14H9 M13 11L16 14L20 8'
    12='M3 4H10V10H3Z M14 14H21V21H14Z M10 7H20L17 4 M20 7L17 10 M14 18H4L7 21'
    13='M6 7H18L17 21H7Z M4 7H20 M9 3H15V7 M10 10V18 M14 10V18'
    14='M3 7H21V17H3Z M6 10V14 M10 10V14 M14 10V14 M18 10V14 M6 17V21 M12 17V21 M18 17V21'
    15='M13 2L5 13H11L10 22L20 9H13Z'
    16='M3 6H10L12 8H21V20H3Z M6 12H18 M6 16H14'
    17='M5 4H19V20H5Z M8 8H16 M8 12H16 M8 16H13'
    18='M3 3H11V11H3Z M13 3H21V11H13Z M3 13H11V21H3Z M13 13H21V21H13Z M11 3L13 21'
    19='M3 5H21V19H3Z M6 15H9 M13 11L16 14L20 8 M6 8H10'
    20='M4 10A8 8 0 1 1 4 16 M4 10V4 M4 10H10 M9 13L12 16L17 10'
    21='M2 8Q12 0 22 8 M5 12Q12 6 19 12 M8 16Q12 12 16 16 M11 20H13'
    22='M12 2V12 M6 5A9 9 0 1 0 18 5'
    23='M19 9A8 8 0 1 0 20 16 M19 9V3 M19 9H13'
    24='M4 5H12L14 7H21V20H4Z M8 12A5 5 0 1 1 9 18 M8 12V16H12'
    25='M17 3A9 9 0 1 0 21 16A9 9 0 0 1 17 3Z'
    26='M12 7A5 5 0 1 0 12 17A5 5 0 1 0 12 7 M12 1V4 M12 20V23 M1 12H4 M20 12H23 M4 4L6 6 M18 18L20 20 M4 20L6 18 M18 6L20 4'
    27='M3 4H21V20H3Z M6 8H10 M6 12H18 M6 16H14'
    28='M2 12H6L9 4L14 20L17 12H22'
    29='M10 3A7 7 0 1 0 10 17A7 7 0 1 0 10 3 M15 15L22 22'
    30='M5 2H15L20 7V22H5Z M15 2V7H20 M8 11H17 M8 15H17 M8 19H14'
    31='M12 3A9 9 0 1 0 12 21A9 9 0 1 0 12 3 M12 7V12L16 14'
    32='M3 4H21V20H3Z M3 12H21 M8 12V20 M13 12V20 M18 12V20'
    33='M12 2L21 6V13L12 22L3 13V6Z M7 12L11 16L17 8'
    34='M12 2L21 6V13L12 22L3 13V6Z M8 8L16 16 M16 8L8 16'
    35='M12 2L21 6V13L12 22L3 13V6Z M12 6V18 M7 10H17'
    36='M5 2H19V22H5Z M8 6H16 M8 10H16 M8 14H16 M8 18H13'
    37='M3 3H21V21H3Z M12 3V21 M3 12H21 M5 5L19 19 M19 5L5 19'
    38='M3 3H9V9H3Z M15 3H21V9H15Z M3 15H9V21H3Z M15 15H21V21H15Z M10 12H14'
    39='M4 9H20V22H4Z M7 9V6A5 5 0 0 1 17 6V9 M12 13V18'
    40='M12 2L21 6V13L12 22L3 13V6Z M8 10A4 4 0 1 0 16 10A4 4 0 1 0 8 10 M15 14L18 17'
    41='M3 4H21V22H3Z M3 9H21 M7 1V6 M17 1V6 M7 13H10 M14 13H17 M7 17H10'
    42='M12 3A9 9 0 1 0 12 21A9 9 0 1 0 12 3 M8 8L16 16 M16 8L8 16'
}

function New-ToolIcon([int]$Id) {
    $path = [Windows.Shapes.Path]::new()
    $path.Data = [Windows.Media.Geometry]::Parse($script:IconPaths[$Id])
    $path.Stroke = $script:Window.Resources['Accent']; $path.StrokeThickness = 1.6
    $path.StrokeLineJoin = 'Round'; $path.StrokeStartLineCap = 'Round'; $path.StrokeEndLineCap = 'Round'
    $path.Width = 26; $path.Height = 26; $path.Stretch = 'Uniform'
    $path.HorizontalAlignment = 'Left'; $path.Margin = [Windows.Thickness]::new(0,0,0,7)
    return $path
}


# ENDREGION

# REGION ATS_PLUGIN_CORE
# ATS v4 / plugins declarativos de diagnostico. No ejecuta archivos PS1, DLL ni comandos de plugins.
function ConvertFrom-ATSPlugin([string]$Json) {
    if ([string]::IsNullOrWhiteSpace($Json) -or $Json.Length -gt 16384) { throw 'Manifiesto vacio o mayor de 16 KiB.' }
    $item = ConvertFrom-Json -InputObject $Json -ErrorAction Stop
    if ($null -eq $item -or $item -is [array] -or $item -is [string]) { throw 'El manifiesto debe ser un objeto JSON.' }
    $fields = @('schemaVersion','id','name','version','description','toolId')
    $actual = @($item.PSObject.Properties.Name)
    if ($actual.Count -ne $fields.Count -or @($actual | Where-Object { $fields -cnotcontains $_ }).Count) { throw 'Campos ausentes o no permitidos. No se admite codigo ni comandos libres.' }
    if (($item.schemaVersion -isnot [int] -and $item.schemaVersion -isnot [long]) -or $item.schemaVersion -ne 1) { throw 'Version de esquema no compatible.' }
    if ($item.id -isnot [string] -or $item.id -cnotmatch '^[a-z][a-z0-9-]{2,47}$') { throw 'ID de plugin no valido: usa minusculas, numeros y guiones, de 3 a 48 caracteres.' }
    if ($item.version -isnot [string] -or $item.version -notmatch '^\d{1,4}\.\d{1,4}\.\d{1,4}$') { throw 'Version del plugin no valida.' }
    foreach ($field in @('name','description')) {
        $limit = if ($field -eq 'name') { 80 } else { 320 }
        if ($item.$field -isnot [string] -or [string]::IsNullOrWhiteSpace($item.$field) -or $item.$field.Length -gt $limit -or $item.$field -match '[\x00-\x1f\x7f]') { throw "Texto no valido: $field" }
    }
    if (($item.toolId -isnot [int] -and $item.toolId -isnot [long]) -or $item.toolId -notin @(1,14,19,27,28,30)) { throw 'El plugin solo puede seleccionar un diagnostico permitido (1,14,19,27,28,30).' }
    return $item
}

function Get-ATSPluginStore {
    return Join-Path $script:DataPath 'Plugins'
}

function Assert-ATSPluginStore {
    $folder = Get-ATSPluginStore
    $current = [IO.Path]::GetFullPath($folder)
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $attributes = (Get-Item -LiteralPath $current -Force).Attributes
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'No se permiten enlaces en el almacen de plugins.' }
            if (($attributes -band [IO.FileAttributes]::Directory) -eq 0) { throw 'El almacen de plugins requiere una carpeta normal.' }
        }
        $current = [IO.Path]::GetDirectoryName($current)
    }
}

function Get-ATSPlugins {
    Assert-ATSPluginStore
    $folder = Get-ATSPluginStore
    if (-not (Test-Path -LiteralPath $folder)) { return }
    foreach ($file in Get-ChildItem -LiteralPath $folder -Filter '*.json' -File | Sort-Object Name) {
        try {
            if ($file.Length -gt 16384 -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Archivo de plugin enlazado o demasiado grande.' }
            $plugin = ConvertFrom-ATSPlugin (Get-Content -LiteralPath $file.FullName -Raw)
            if ($file.BaseName -cne $plugin.id) { throw 'El ID no coincide con su nombre de archivo.' }
            $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
            $enabled = ($plugin.id + ':' + $hash) -in @($script:Settings.EnabledPlugins)
            [pscustomobject]@{Descriptor=$plugin; Hash=$hash; Enabled=$enabled; Path=$file.FullName}
        } catch { Write-Activity ('Plugin rechazado: ' + $file.Name + ' / ' + $_.Exception.Message) 'PLUGIN_REJECTED' 0 }
    }
}

function Update-ATSPluginList($List) {
    $List.Items.Clear()
    try {
        foreach ($record in @(Get-ATSPlugins)) {
            $entry = [Windows.Controls.ListBoxItem]::new()
            $state = if ($record.Enabled) { 'ACTIVO' } else { 'INACTIVO / requiere aprobacion' }
            $entry.Content = '{0} / {1} / diagnostico {2} / {3}' -f $record.Descriptor.name,$record.Descriptor.version,$record.Descriptor.toolId,$state
            $entry.Tag = $record; [void]$List.Items.Add($entry)
        }
    } catch { Write-Activity $_.Exception.Message 'PLUGIN_ERROR' 0 }
}

function Invoke-ATSPlugin($Record) {
    # Relee y compara huella en el momento de ejecutar; no confia en el objeto de la UI.
    $fresh = @(Get-ATSPlugins | Where-Object { $_.Descriptor.id -ceq $Record.Descriptor.id -and $_.Hash -ceq $Record.Hash -and $_.Enabled })
    if ($fresh.Count -ne 1) { throw 'Plugin inactivo o modificado desde su aprobacion. Vuelve a revisarlo.' }
    $tool = @($script:Tools | Where-Object Id -eq $fresh[0].Descriptor.toolId)
    if ($tool.Count -ne 1) { throw 'Diagnostico no disponible.' }
    Write-Activity ('Plugin solicitado: ' + $fresh[0].Descriptor.id + ' / SHA256 ' + $fresh[0].Hash) 'PLUGIN_REQUEST' 0
    Invoke-Tool $tool[0]
}

function Show-PluginManager {
    $dialog = [Windows.Window]::new()
    $dialog.Title = 'ATS v4 / Plugins de diagnostico'; $dialog.Width = 720; $dialog.Height = 480
    $dialog.MinWidth = 480; $dialog.MinHeight = 350; $dialog.Owner = $script:Window; $dialog.WindowStartupLocation = 'CenterOwner'
    $dialog.Resources.MergedDictionaries.Add($script:Window.Resources)
    $dialog.Background = [Windows.Media.BrushConverter]::new().ConvertFromString('#111A2C')
    $dialog.Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString('#E7EEFF')
    $panel = [Windows.Controls.DockPanel]::new(); $panel.Margin = [Windows.Thickness]::new(20)
    $notice = [Windows.Controls.TextBlock]::new()
    $notice.Text = 'Plugins declarativos v1: solo diagnosticos integrados. Importar no activa ni ejecuta. No se admiten scripts externos. Revisa cada manifiesto: sus datos no acreditan autor/editor.'
    $notice.TextWrapping = 'Wrap'; $notice.Margin = [Windows.Thickness]::new(0,0,0,16)
    [Windows.Controls.DockPanel]::SetDock($notice,'Top'); [void]$panel.Children.Add($notice)
    $buttons = [Windows.Controls.WrapPanel]::new()
    [Windows.Controls.DockPanel]::SetDock($buttons,'Bottom'); [void]$panel.Children.Add($buttons)
    $list = [Windows.Controls.ListBox]::new(); $list.Background = $dialog.Background; $list.Foreground = $dialog.Foreground
    [void]$panel.Children.Add($list)
    foreach ($label in @('Importar JSON','Activar','Desactivar','Ejecutar','Retirar','Actualizar')) {
        $button = [Windows.Controls.Button]::new(); $button.Content = $label
        $button.Tag = @{List=$list; Operation=$label; Dialog=$dialog}
        [void]$buttons.Children.Add($button)
        $button.Add_Click({
            param($sender,$eventArgs)
            $context = $sender.Tag
            try {
                $operation = $context.Operation
                if ($operation -eq 'Actualizar') { Update-ATSPluginList $context.List; return }
                $record = if ($null -ne $context.List.SelectedItem) { $context.List.SelectedItem.Tag } else { $null }
                if ($operation -eq 'Ejecutar') {
                    if ($null -eq $record) { throw 'Selecciona un plugin.' }
                    Invoke-ATSPlugin $record; return
                }
                if ($script:Settings.ReadOnly) { throw 'No se modifica el almacen ni la aprobacion en modo solo lectura.' }
                Assert-Guard
                Assert-ATSPluginStore
                $folder = Get-ATSPluginStore
                if ($operation -eq 'Importar JSON') {
                    $picker = [Microsoft.Win32.OpenFileDialog]::new(); $picker.Filter = 'Manifiesto JSON (*.json)|*.json'
                    if (-not $picker.ShowDialog($context.Dialog)) { return }
                    if ((Get-Item -LiteralPath $picker.FileName).Length -gt 16384) { throw 'El manifiesto supera 16 KiB.' }
                    $plugin = ConvertFrom-ATSPlugin (Get-Content -LiteralPath $picker.FileName -Raw)
                    $path = Join-Path $folder ($plugin.id + '.json')
                    if (Test-Path -LiteralPath $path) { throw 'Ya existe este ID. Retiralo antes de importar una nueva version.' }
                    $message = 'ID: {0}`nNombre: {1}`nVersion: {2}`nDiagnostico: {3}`nDescripcion: {4}' -f $plugin.id,$plugin.name,$plugin.version,$plugin.toolId,$plugin.description
                    if ([Windows.MessageBox]::Show($context.Dialog,$message.Replace('`n',"`n") + "`n`n¿Importar INACTIVO?",'Revisar plugin','YesNo','Question','No') -ne 'Yes') { return }
                    New-Item $folder -ItemType Directory -Force | Out-Null
                    # CreateNew no sobrescribe, incluso si otro proceso crea el archivo tras comprobarlo.
                    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($plugin | ConvertTo-Json))
                    $stream = [IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
                    try { $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
                    Write-Activity ('Plugin importado inactivo: ' + $plugin.id) 'PLUGIN_IMPORTED' 0
                } else {
                    if ($null -eq $record) { throw 'Selecciona un plugin.' }
                    $current = @(Get-ATSPlugins | Where-Object { $_.Descriptor.id -ceq $record.Descriptor.id -and $_.Hash -ceq $record.Hash })
                    if ($current.Count -ne 1) { throw 'El manifiesto cambio. Actualiza la lista antes de continuar.' }
                    $id = $current[0].Descriptor.id
                    $remaining = @($script:Settings.EnabledPlugins | Where-Object { -not $_.StartsWith($id + ':',[StringComparison]::Ordinal) })
                    switch ($operation) {
                        'Activar' {
                            if ([Windows.MessageBox]::Show($context.Dialog,('¿Aprobar ' + $id + ' para diagnostico ' + $current[0].Descriptor.toolId + '? Esta aprobacion solo vale para su SHA256 actual.'),'Activar plugin','YesNo','Question','No') -ne 'Yes') { return }
                            $script:Settings.EnabledPlugins = $remaining + ($id + ':' + $current[0].Hash)
                        }
                        'Desactivar' { $script:Settings.EnabledPlugins = $remaining }
                        'Retirar' {
                            if ([Windows.MessageBox]::Show($context.Dialog,('¿Retirar el manifiesto ' + $id + '?'),'Retirar plugin','YesNo','Warning','No') -ne 'Yes') { return }
                            Remove-Item -LiteralPath $current[0].Path
                            $script:Settings.EnabledPlugins = $remaining
                        }
                        default { throw 'Operacion de plugin desconocida.' }
                    }
                    Save-Preferences
                    Write-Activity ('Plugin ' + $id + ' / ' + $operation) 'PLUGIN_STATE' 0
                }
                Update-ATSPluginList $context.List
            } catch {
                Write-Activity $_.Exception.Message 'PLUGIN_ERROR' 0
                [void][Windows.MessageBox]::Show($context.Dialog,$_.Exception.Message,'Plugins','OK','Warning')
            }
        })
    }
    $dialog.Content = $panel
    Update-ATSPluginList $list
    [void]$dialog.ShowDialog()
}

# ENDREGION ATS_PLUGIN_CORE

foreach ($category in @('Todas','Sistema','Mantenimiento','Red','Seguridad','Personalizacion','Energia')) {
    $button = [Windows.Controls.Button]::new()
    [void]$script:CategoryPicker.Items.Add($category)
    $button.Content = $category; $button.Tag = $category
    Add-EntranceAnimation $button
    $button.Margin = [Windows.Thickness]::new(0,0,0,8)
    $button.Add_Click({
        param($sender, $eventArgs)
        $script:Category = [string]$sender.Tag
        $script:CategoryPicker.SelectedItem = $script:Category
        foreach ($item in $script:Navigation.Children) {
            $item.Background = [Windows.Media.BrushConverter]::new().ConvertFromString('#19253D')
        }
        $sender.Background = [Windows.Media.BrushConverter]::new().ConvertFromString('#334269')
        Update-Cards
        Write-Activity ('Categoria: ' + $script:Category)
    })
    [void]$script:Navigation.Children.Add($button)
}
$script:Navigation.Children[0].Background = [Windows.Media.BrushConverter]::new().ConvertFromString('#334269')
function Update-Summary {
    $script:Machine.Text = $env:COMPUTERNAME
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $script:Session.Text = if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 'Administrador' } else { 'Usuario estandar' }
    $identity.Dispose()
}
$script:CategoryPicker.SelectedItem = 'Todas'
$script:CategoryPicker.Add_SelectionChanged({ $script:Category = [string]$script:CategoryPicker.SelectedItem; Update-Cards })
$script:Plugins.Add_Click({ Show-PluginManager })
$script:Options.Add_Click({ Show-Preferences })
$script:OnlyFavorites.Add_Click({ $script:FavoritesOnly = -not $script:FavoritesOnly; $script:OnlyFavorites.Content = if ($script:FavoritesOnly) { '★ Solo favoritos' } else { '☆ Favoritos' }; Update-Cards })
$script:Undo.Add_Click({ Invoke-RegistryUndo })
$script:Schedule.Add_Click({ Show-Scheduler })
$script:ExportLog.Add_Click({ Export-Activity })
$script:Window.Add_Closed({
    foreach ($timer in $script:Timers) {
        $timer.Stop()
        if ($timer.Tag -is [System.Collections.IDictionary] -and $timer.Tag.Contains('Process')) { $timer.Tag.Process.Dispose() }
    }
    if ($null -ne $script:RestorePending) { $script:RestorePending.Process.Dispose(); $script:RestorePending = $null }
    if ($null -ne $script:MetricsJob) { $script:MetricsJob.Stop(); $script:MetricsJob.Dispose() }
    Save-Preferences
    Write-Activity 'Cierre de la sesion.' 'SESSION_END'
})
$script:Search.Add_TextChanged({ Update-Cards })
$script:Refresh.Add_Click({ Update-Summary; Update-Cards; Write-Activity 'Panel actualizado.' })
$script:OpenLog.Add_Click({ try { Open-Program 'notepad.exe' ('"' + $script:LogPath + '"') } catch { Write-Activity $_.Exception.Message } })
if ($SmokeTest) {
    try {
        foreach ($theme in @('Neon azul','Purpura cyberpunk','Verde Matrix','Rojo gaming')) { $script:Settings.Theme = $theme; Apply-Theme }
        $script:Settings.Motion = $false; Apply-Theme
        $script:Settings.Compact = $true; Set-CompactMode
        $script:Settings.Compact = $false; Set-CompactMode
        Update-Summary; Update-Cards
        if ($script:Cards.Children.Count -ne 42) { throw 'Fallo al crear las 42 tarjetas.' }
        $script:Settings.ReadOnly = $true; Update-Cards
        $script:Search.Text = 'sin_coincidencias_ATS'
        if ($script:Cards.Children.Count -ne 0) { throw 'El filtro no funciona.' }
        $script:Search.Text = ''
        $script:Window.Measure([Windows.Size]::new(1220,820))
        $script:Window.Arrange([Windows.Rect]::new(0,0,1220,820))
        # La segunda ventana se valida aparte, sin abrirla ni tocar el registro.
        $source = Get-Content -LiteralPath $PSCommandPath -Raw
        $pattern = '(?s)\[xml\]\$preferencesXaml = @\x27\r?\n(.*?)\r?\n\x27@'
        $match = [regex]::Match($source, $pattern)
        if (-not $match.Success) { throw 'No se encontro el XAML de preferencias.' }
        [xml]$prefs = $match.Groups[1].Value
        [void][Windows.Markup.XamlReader]::Load([Xml.XmlNodeReader]::new($prefs))
        Write-Output 'Smoke test WPF correcto: temas, iconos, compacto, filtros y dos ventanas.'
    } finally {
        foreach ($timer in $script:Timers) { $timer.Stop() }
        Remove-Item -LiteralPath $script:DataPath -Recurse -Force
    }
    return
}
$releasePath = Join-Path $script:DataPath 'versiones.log'
try {
    $releaseLine = '4.0.0 | 2026-11-01 | Animaciones, SVG, 4 temas, compacto, gradiente, favoritos, exportacion, tareas, preflight, metricas, deshacer, auditoria, solo lectura, DPAPI, restauracion, recetas EXE/MSI, portable y menu contextual. Entrega 4.0.0: manifiesto, firma Authenticode opcional, instaladores por usuario, 43 casos Pester, manuales y roadmap v4. Inicio v4.0.0: plugins declarativos de diagnostico y bootstrap autoextraible del proyecto completo.'
    if (-not (Test-Path $releasePath) -or -not (Select-String -LiteralPath $releasePath -SimpleMatch '4.0.0 |' -Quiet)) { Add-Content $releasePath $releaseLine -Encoding UTF8 }
} catch { Write-Activity 'No se pudo guardar el historial de versiones.' 'LOG_ERROR' }
Apply-Theme
Set-CompactMode
Start-Metrics
Update-Summary
Update-Cards
Write-Activity 'Panel 4.0.0 iniciado. Las acciones UAC solicitan permisos por separado.' 'SESSION_START'
[void]$script:Window.ShowDialog()
