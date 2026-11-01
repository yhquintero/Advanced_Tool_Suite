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
