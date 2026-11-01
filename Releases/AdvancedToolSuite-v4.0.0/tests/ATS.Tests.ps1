#requires -Version 5.1
# Pester 5.7.1: exactamente 43 casos sin abrir WPF ni ejecutar herramientas administrativas.
BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
    $source = Get-Content (Join-Path $root 'Tool\AdvancedToolSuite.ps1') -Raw
    $build = Get-Content (Join-Path $root 'packaging\Build-Release.ps1') -Raw
    $sign = Get-Content (Join-Path $root 'packaging\Sign-Release.ps1') -Raw
    $install = Get-Content (Join-Path $root 'install.ps1') -Raw
    $uninstall = Get-Content (Join-Path $root 'uninstall.ps1') -Raw
    $tokens = $null; $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput($source,[ref]$tokens,[ref]$parseErrors)
    $assignment = $ast.Find({ param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$script:Tools' },$true)
    # Solo expresion de catalogo y funciones puras revisadas del repositorio.
    $tools = @(& ([ScriptBlock]::Create($assignment.Right.Extent.Text)))
    $common = Get-Content (Join-Path $root 'packaging\Deployment.Common.ps1') -Raw
    $commonAst = [Management.Automation.Language.Parser]::ParseInput($common,[ref]$tokens,[ref]$parseErrors)
    $functions = @($ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] },$true)) + @($commonAst.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] },$true))
    foreach ($name in @('Test-ReadOnlyTool','Get-RegistrySpec','Write-RotatingLog','Get-ATSPayloadNames','Read-ATSReceipt','Assert-ATSPlainDirectory','Get-ATSLaunch')) {
        $definition = $functions | Where-Object Name -eq $name | Select-Object -First 1
        . ([ScriptBlock]::Create($definition.Extent.Text))
    }
    [xml]$manifest = Get-Content (Join-Path $root 'packaging\manifest.xml') -Raw
    $ns = [Xml.XmlNamespaceManager]::new($manifest.NameTable)
    $ns.AddNamespace('a','urn:schemas-microsoft-com:asm.v3')
    $ns.AddNamespace('c','urn:schemas-microsoft-com:compatibility.v1')
    $ns.AddNamespace('d','http://schemas.microsoft.com/SMI/2016/WindowsSettings')
    $metadata = Get-Content (Join-Path $root 'VERSION.json') -Raw | ConvertFrom-Json
}

Describe 'ATS: catalogo e interfaz (01-15)' {
    It '01 - Todos los scripts pasan el parser nativo' {
        foreach ($file in Get-ChildItem $root -Filter '*.ps1' -Recurse | Where-Object FullName -NotMatch '[\\/]artifacts[\\/]') {
            $t = $null; $e = $null
            [void][Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$t,[ref]$e)
            @($e).Count | Should -Be 0 -Because $file.Name
        }
    }
    It '02 - El catalogo tiene 42 herramientas' { $tools.Count | Should -Be 42 }
    It '03 - Los IDs son unicos y consecutivos' { ($tools.Id | Sort-Object) -join ',' | Should -Be ((1..42) -join ',') }
    It '04 - La version de la aplicacion coincide con VERSION.json' { $source | Should -Match ([regex]::Escape("`$script:Version = '$($metadata.version)'")) }
    It '05 - Los indicadores de riesgo y UAC son booleanos' {
        foreach ($tool in $tools) { $tool.Admin | Should -BeOfType ([bool]); $tool.Risk | Should -BeOfType ([bool]) }
    }
    It '06 - Todas las categorias pertenecen a la lista conocida' {
        foreach ($tool in $tools) { $tool.Category | Should -BeIn @('Sistema','Mantenimiento','Red','Personalizacion','Energia','Seguridad') }
    }
    It '07 - Los nombres de las herramientas no se repiten' { @($tools.Name | Select-Object -Unique).Count | Should -Be 42 }
    It '08 - La plantilla conserva contornos redondeados' { $source | Should -Match 'CornerRadius="16"' }
    It '09 - Los dos bloques XAML son XML bien formado' {
        $blocks = [regex]::Matches($source,'(?s)\[xml\]\$(?:xaml|preferencesXaml) = @\x27\r?\n(.*?)\r?\n\x27@')
        $blocks.Count | Should -Be 2
        foreach ($block in $blocks) { { [xml]$block.Groups[1].Value } | Should -Not -Throw }
    }
    It '10 - Hay 42 SVG con el mismo path que el icono embebido' {
        $embedded = $source.Split(@('$script:IconPaths = @{'),[StringSplitOptions]::None)[1]
        $paths = [regex]::Matches($embedded,"(?m)^\s+(\d+)='([^']+)'\r?$")
        $paths.Count | Should -Be 42
        foreach ($path in $paths) {
            $file = Join-Path $root ('Assets\Icons\{0:00}.svg' -f [int]$path.Groups[1].Value)
            [xml]$svg = Get-Content $file -Raw
            $svg.svg.path.d | Should -BeExactly $path.Groups[2].Value
        }
    }
    It '11 - Estan las cuatro paletas seleccionables' {
        foreach ($theme in @('Neon azul','Purpura cyberpunk','Verde Matrix','Rojo gaming')) { $source | Should -Match ([regex]::Escape("'$theme'=@(")) }
    }
    It '12 - La busqueda no distingue mayusculas' { $source | Should -Match 'CurrentCultureIgnoreCase' }
    It '13 - Favoritos no es un boton anidado en otro boton' {
        $source | Should -Match '\$wrapper.Children.Add\(\$star\)'
        $source | Should -Not -Match '\$top.Children.Add\(\$star\)'
    }
    It '14 - El modo compacto tiene anchura de 410 px' { $source | Should -Match '\$script:Window.Width = 410' }
    It '15 - La animacion respeta la configuracion de accesibilidad' { $source | Should -Match 'SystemParameters\]::ClientAreaAnimation' }
}

Describe 'ATS: seguridad y almacenamiento (16-29)' {
    It '16 - Solo lectura permite los ocho diagnosticos definidos' {
        foreach ($id in @(1,11,14,19,27,28,29,30)) { Test-ReadOnlyTool $id | Should -BeTrue }
    }
    It '17 - Solo lectura bloquea todas las demas herramientas' {
        foreach ($id in (1..42 | Where-Object { $_ -notin @(1,11,14,19,27,28,29,30) })) { Test-ReadOnlyTool $id | Should -BeFalse }
    }
    It '18 - El despacho verifica la politica antes del switch' {
        $dispatch = $source.Substring($source.IndexOf('function Invoke-Tool('))
        $dispatch.IndexOf('Assert-ToolAllowed $Tool') | Should -BeLessThan $dispatch.IndexOf('switch ($Tool.Id)')
    }
    It '19 - Los ajustes de Registro se limitan a HKCU' {
        foreach ($id in @(10,17,18,25,26)) { (Get-RegistrySpec $id).Path | Should -BeLike 'HKCU:\*' }
    }
    It '20 - Se rechaza un ID de Registro desconocido' { { Get-RegistrySpec 999 } | Should -Throw }
    It '21 - Deshacer obtiene la ruta de la lista blanca, no del archivo' {
        $source | Should -Match 'Get-RegistrySpec \(\[int\]\$snapshot.Id\)'
        $source | Should -Not -Match '\$snapshot.Path(?!Existed)'
    }
    It '22 - Deshacer detecta cambios ajenos de tipo y valor' {
        $source | Should -Match '\$kindChanged -or'
        $source | Should -Match '\$current -cne \$spec.Value'
    }
    It '23 - La lista de archivos instalables no contiene rutas' {
        foreach ($name in Get-ATSPayloadNames) { [IO.Path]::GetFileName($name) | Should -BeExactly $name; $name | Should -Not -Match '[\\/]' }
    }
    It '24 - Un recibo con traversal no se admite' {
        $folder = Join-Path $TestDrive 'traversal'; New-Item $folder -ItemType Directory | Out-Null
        @{ProductId='AdvancedToolSuite.Nexus'; EntryPoint='AdvancedToolSuite.ps1'; Files=@(@{Name='../fuera.txt'; Hash=('A'*64)})} | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $folder 'installed-files.json')
        { Read-ATSReceipt $folder } | Should -Throw
    }
    It '25 - Se detecta un archivo instalado modificado' {
        $folder = Join-Path $TestDrive 'modified'; New-Item $folder -ItemType Directory | Out-Null
        $file = Join-Path $folder 'AdvancedToolSuite.ps1'; Set-Content $file 'original'
        $hash = (Get-FileHash $file -Algorithm SHA256).Hash
        @{ProductId='AdvancedToolSuite.Nexus'; EntryPoint='AdvancedToolSuite.ps1'; Files=@(@{Name='AdvancedToolSuite.ps1'; Hash=$hash})} | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $folder 'installed-files.json')
        Set-Content $file 'cambiado'
        { Read-ATSReceipt $folder } | Should -Throw '*modificado*'
    }
    It '26 - No se desinstala sin un recibo' {
        $folder = Join-Path $TestDrive 'missing'; New-Item $folder -ItemType Directory | Out-Null
        { Read-ATSReceipt $folder } | Should -Throw '*recibo*'
    }
    It '27 - Se admite una cadena de directorios normales' { { Assert-ATSPlainDirectory $TestDrive } | Should -Not -Throw }
    It '28 - Un log mayor de 5 MiB se rota sin perder el nuevo evento' {
        $file = Join-Path $TestDrive 'rotation.log'; [IO.File]::WriteAllText($file,('x'*5242881))
        Write-RotatingLog $file 'evento nuevo'
        Test-Path "$file.1" | Should -BeTrue
        Get-Content $file -Raw | Should -Match 'evento nuevo'
    }
    It '29 - La retencion no crea mas de cinco copias' {
        $file = Join-Path $TestDrive 'retention.log'
        for ($i=0; $i -lt 7; $i++) { [IO.File]::WriteAllText($file,('x'*5242881)); Write-RotatingLog $file 'evento' }
        Test-Path "$file.5" | Should -BeTrue
        Test-Path "$file.6" | Should -BeFalse
    }
}

Describe 'ATS: construccion y entrega (30-43)' {
    It '30 - El manifiesto mantiene asInvoker y no UIAccess' {
        $level = $manifest.SelectSingleNode('//a:requestedExecutionLevel',$ns)
        $level.level | Should -BeExactly 'asInvoker'; $level.uiAccess | Should -BeExactly 'false'
    }
    It '31 - Se declara compatibilidad con Windows 10 y 11' { $manifest.SelectSingleNode('//c:supportedOS',$ns).Id | Should -Be '{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}' }
    It '32 - El manifiesto declara PerMonitorV2' { $manifest.SelectSingleNode('//d:dpiAwareness',$ns).InnerText | Should -Match 'PerMonitorV2' }
    It '33 - El EXE se modifica antes de firmarlo' { $build.IndexOf('& mt.exe') | Should -BeLessThan $build.IndexOf("'Sign-Release.ps1'") }
    It '34 - Se exige clave privada y EKU de firma de codigo' { $sign | Should -Match 'HasPrivateKey'; $sign | Should -Match '1\.3\.6\.1\.5\.5\.7\.3\.3' }
    It '35 - Se verifica sello de tiempo y firma despues de firmar' { $sign | Should -Match 'TimeStamperCertificate'; $sign | Should -Match 'Get-AuthenticodeSignature' }
    It '36 - Authenticode usa SHA256 y servidor HTTPS' { $sign | Should -Match '-HashAlgorithm SHA256'; $sign | Should -Match "Scheme -ne 'https'" }
    It '37 - Instalacion soporta WhatIf y no omite politicas' { $install | Should -Match 'SupportsShouldProcess'; $install | Should -Not -Match 'ExecutionPolicy.*Bypass' }
    It '38 - Desinstalacion pide confirmacion y no tiene borrado de datos' { $uninstall | Should -Match "ConfirmImpact='High'"; $uninstall | Should -Not -Match '\[switch\]\$Purge' }
    It '39 - El lanzador PS1 entrecomilla las rutas con espacios' {
        $folder = Join-Path $TestDrive 'con espacios'
        $launch = Get-ATSLaunch $folder 'AdvancedToolSuite.ps1'
        $launch.Arguments | Should -BeExactly ('-NoProfile -STA -File "{0}"' -f (Join-Path $folder 'AdvancedToolSuite.ps1'))
    }
    It '40 - El lanzador EXE no agrega comandos de PowerShell' { (Get-ATSLaunch $TestDrive 'AdvancedToolSuite.exe').Arguments | Should -BeExactly '' }
    It '41 - Las tareas se ejecutan con principal limitado e interactivo' { $source | Should -Match '-LogonType Interactive -RunLevel Limited' }
    It '42 - Restauracion exige un punto nuevo antes de continuar' { $source | Should -Match '\$after.Count -eq 0'; $source | Should -Match '\$pending.Process.ExitCode -eq 0' }
    It '43 - La entrega contiene manual, build, licencia e itinerario v4' {
        foreach ($file in @('MANUAL.md','BUILD.md','LICENSE','CHANGELOG.md','docs\ROADMAP-v4.0.0.md')) { Test-Path (Join-Path $root $file) | Should -BeTrue }
    }
}
