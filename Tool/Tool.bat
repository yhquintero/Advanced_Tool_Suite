@echo off
setlocal EnableExtensions
title Herramientas de Trabajo para Windows - Advanced Edition
color 0A

:: ============================================================
:: AUTO-ELEVACION: solicita privilegios de Administrador (UAC)
:: ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo =====================================================================================
    echo Solicitando privilegios de Administrador...
    echo Acepte la ventana de UAC para continuar.
    echo =====================================================================================
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ============================================================
:: Ya somos Administrador. Menu principal.
:: ============================================================
:MENU
cls
echo  ===================================================================================================================
echo             Herramientas Administrativas de Windows 
echo  ===================================================================================================================
echo.
echo  [ 1] Informacion del Sistema            [ 2] Administrador de Tareas          [ 3] Administrador de Dispositivos
echo  [ 4] Administrador de Servicios         [ 5] Administrador de Redes           [ 6] Simbolo del Sistema (CMD)
echo  [ 7] Panel de Control                   [ 8] Editor de Registro               [ 9] Administrador de Audio
echo  [10] Mostrar Atributos Ocultos          [11] Chequeo de Unidades (chkdsk)     [12] Convertir FAT32 a NTFS
echo  [13] Limpiar Temporales                 [14] Optimizar RAM                    [15] Optimizar CPUir FAT32 a NTFS
echo  [16] Carpeta Modo Dios                  [17] Menu Windows 10 Clasico          [18] Menu Windows 11
echo  [19] Estado del Disco Duro              [20] Reparar Conexion de Red          [21] Configuracion de REDES
echo  [22] Apagar Equipo                      [23] Reiniciar Equipo                 [24] Reiniciar Explorador
echo  [25] Enable Dark Mode                   [26] Disable Dark Mode                [27] Mostrar Configuracion RED
echo  [28] Ping www.google.com Test           [29] Consultar una Direccion IP       [30] Archivo Reporte
echo  [31] Configurar Fehca y Hora            [32] Administrador de Discos          [33] Activar Firewall
echo  [34] Desactivar Firewall                [35] Abrir Windows Defender           [36] Abrir Bloc de Notas 
echo  [37] Configuración Regional Sistema    [38] Ver Aplicaciones de Windows      [39] Activacion de Windows
echo  [40] Revisar con Windows Defender       [41] Tareas Programadas de Windows
echo.
echo.
echo  [Q] Salir
echo  [0] Actualizar Ventana
echo  ===================================================================================================================
set "choice="
set /p "choice=Seleccione una opcion [1-40/Q/0]: "

if not defined choice goto MENU
if /i "%choice%"=="1"  goto opt1
if /i "%choice%"=="2"  goto opt2
if /i "%choice%"=="3"  goto opt3
if /i "%choice%"=="4"  goto opt4
if /i "%choice%"=="5"  goto opt5
if /i "%choice%"=="6"  goto opt6
if /i "%choice%"=="7"  goto opt7
if /i "%choice%"=="8"  goto opt8
if /i "%choice%"=="9"  goto opt9
if /i "%choice%"=="10" goto opt10
if /i "%choice%"=="11" goto opt11
if /i "%choice%"=="12" goto opt12
if /i "%choice%"=="13" goto opt13
if /i "%choice%"=="14" goto opt14
if /i "%choice%"=="15" goto opt15
if /i "%choice%"=="16" goto opt16
if /i "%choice%"=="17" goto opt17
if /i "%choice%"=="18" goto opt18
if /i "%choice%"=="19" goto opt19
if /i "%choice%"=="20" goto opt20
if /i "%choice%"=="21" goto opt21
if /i "%choice%"=="22" goto opt22
if /i "%choice%"=="23" goto opt23
if /i "%choice%"=="24" goto opt24
if /i "%choice%"=="25" goto opt25
if /i "%choice%"=="26" goto opt26
if /i "%choice%"=="27" goto opt27
if /i "%choice%"=="28" goto opt28
if /i "%choice%"=="29" goto opt29
if /i "%choice%"=="30" goto opt30
if /i "%choice%"=="31" goto opt31
if /i "%choice%"=="32" goto opt32
if /i "%choice%"=="33" goto opt33
if /i "%choice%"=="34" goto opt34
if /i "%choice%"=="35" goto opt35
if /i "%choice%"=="36" goto opt36
if /i "%choice%"=="37" goto opt37
if /i "%choice%"=="38" goto opt38
if /i "%choice%"=="39" goto opt39
if /i "%choice%"=="40" goto opt40
if /i "%choice%"=="41" goto opt41
if /i "%choice%"=="Q"  goto SALIR
if /i "%choice%"=="q"  goto SALIR
if /i "%choice%"=="0"  goto MENU

goto MENU

:opt1
    cls
    echo =========================================================
    echo Obteniendo informacion del Sistema...
    echo =========================================================
    systeminfo
    echo =========================================================
    if not exist "C:\REPORTE" mkdir "C:\REPORTE"
    systeminfo > "C:\REPORTE\ReporteSistema.txt"
    echo Informacion del Sistema guardada en C:\REPORTE\ReporteSistema.txt
    start "" "C:\REPORTE\ReporteSistema.txt"
    pause
    goto MENU

:opt2
    cls
    start "" taskmgr
    goto MENU

:opt3
    cls
    start "" devmgmt.msc
    goto MENU

:opt4
    cls
    start "" services.msc
    goto MENU

:opt5
    cls
    start "" ncpa.cpl
    goto MENU

:opt6
    cls
    start "" powershell -NoProfile -Command "Start-Process cmd -Verb RunAs"
    goto MENU

:opt7
    cls
    start "" control
    goto MENU

:opt8
    cls
    start "" regedit
    goto MENU

:opt9
    cls
    start "" mmsys.cpl
    goto MENU

:opt10
    cls
    set "drive_letter="
    set /p "drive_letter=Ingrese la letra de la unidad (ej. C): "
    if not defined drive_letter goto MENU
    attrib -h -r -s /s /d %drive_letter%:\*.*
    echo Funcion completada: MOSTRAR archivos y carpetas ocultas de la unidad %drive_letter%:
    pause
    goto MENU

:opt11
    cls
    echo ADVERTENCIA: chkdsk con /f /r /v puede tardar mucho tiempo.
    echo No interrumpa el proceso.
    echo.
    set "drive_letter="
    set /p "drive_letter=Ingrese la letra de la unidad (ej. C): "
    if not defined drive_letter goto MENU
    chkdsk %drive_letter%: /f /r /v
    echo Funcion completada: REPARACION de archivos y carpetas de la unidad %drive_letter%:
    pause
    goto MENU

:opt12
    cls
    set "drive_letter="
    set /p "drive_letter=Ingrese la letra de la unidad (ej. D): "
    if not defined drive_letter goto MENU
    convert %drive_letter%: /fs:ntfs
    echo Funcion completada: CONVERSION de la unidad %drive_letter%: de FAT32 a NTFS.
    pause
    goto MENU

:opt13
    cls
    echo Limpiando %TEMP%, C:\Windows\Temp y C:\Windows\Prefetch...
    del /q /f /s "%temp%\*" >nul 2>&1
    del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
    del /q /f /s "C:\Windows\Prefetch\*" >nul 2>&1
    echo Ejecutando limpieza rapida de la unidad C: (puede tardar)...
    cleanmgr /d c: /verylowdisk
    echo Limpieza realizada correctamente.
    pause
    goto MENU

:opt14
    cls
    echo Optimizando RAM...
    taskkill /f /fi "STATUS eq NOT RESPONDING" >nul 2>&1
    powershell -NoProfile -Command "[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()"
    echo Funcion completada: Optimizacion de la RAM.
    pause
    goto MENU

:opt15
    cls
    echo Optimizando CPU al maximo rendimiento...
    powercfg -setactive SCHEME_MAX
    echo Funcion completada: Optimizacion del CPU.
    pause
    goto MENU

:opt16
    cls
    mkdir "%userprofile%\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" 2>nul
    echo Funcion completada: Carpeta "Modo Dios" creada en el Escritorio.
    ::pause
    goto MENU

:opt17
    cls
    reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul
    echo Funcion completada: Menu clasico de Windows 10 activado. Reinicie para aplicar.
    pause
    goto MENU

:opt18
    cls
    reg.exe delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
    echo Funcion completada: Menu de Windows 11 restaurado. Reinicie para aplicar.
    pause
    goto MENU

:opt19
    cls
    echo Chequeando estado de los discos HDD, SSD, M.2...
    wmic diskdrive get model,status 2>nul
    if %errorlevel% neq 0 (
        echo wmic no disponible. Usando PowerShell como alternativa...
        powershell -NoProfile -Command "Get-PhysicalDisk | Select-Object FriendlyName,MediaType,HealthStatus"
    )
    pause
    goto MENU

:opt20
    cls
    echo Restableciendo el catalogo Winsock...
    netsh winsock reset
    echo.
    echo Reinicie el equipo para completar el restablecimiento.
    pause
    goto MENU

:opt21
    cls
    echo Abriendo configuracion de REDES...
    start "" ms-settings:network
    ::pause
    goto MENU

:opt22
    cls
    echo Apagando equipo...
    shutdown /s /t 0
    ::pause
    exit /b

:opt23
    cls
    echo Reiniciando equipo...
    shutdown /r /t 0
    ::pause
    exit /b

:opt24
    cls
    echo Reiniciando Explorador de Windows...
    taskkill /f /im explorer.exe >nul 2>&1
    timeout /t 0 /nobreak >nul
    start "" explorer.exe
    ::echo [%date% %time%] Explorer reiniciado >> "%LOG_FILE%"
    echo Explorador reiniciado correctamente.
    pause
    exit /b

:opt25
    cls
    reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d 0 /f
    echo Funcion completada: Modo Oscuro Activado.
    pause
    goto MENU

:opt26
    cls
    reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d 1 /f
    echo Funcion completada: Modo Oscuro Activado.
    pause
    goto MENU

:opt27
    cls
    echo Mostrar configuracion de REDES...
    ipconfig /all
    pause
    goto MENU

:opt28
    cls
    echo Haciendo Ping de Prueba a Google.com...
    ping google.com
    pause
    goto MENU

:opt29
    cls
    set "direccionIP"
    echo Ingrese la direccion IP a consultar
    set /p "direccionIP=(ej. 192.168.1.1): "
    echo Haciendo Ping de Prueba a la IP a consultar: %direccionIP%...
    ping %direccionIP%
    pause
    goto MENU

:opt30
    cls
    echo Creando Archivo de Reporte de Inventario en C:\REPORTE
    CD C:\
    MD REPORTE
    CD REPORTE
    echo === Archivo de Reporte de Inventario ===  [%date% %time%]  > ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo === Nombre del Equipo === >> ReporteInventario.txt
    wmic COMPUTERSYSTEM get Caption, Domain, UserName >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo === Version del Sistema Operativo === >> ReporteInventario.txt
    wmic OS get Caption,CSDVersion,OSArchitecture,Version >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo === Informe de Discos Duros === >> ReporteInventario.txt
    wmic Diskdrive Get Description, Model, SerialNumber, DeviceID, Size >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo === Informe de Particiones Logicas === >> ReporteInventario.txt
    wmic LOGICALDISK get VolumeName, DeviceID, Size, FreeSpace >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo === Informe de MotherBoard === >> ReporteInventario.txt
    wmic baseboard get product, manufacturer, version, serialnumber >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo === Informe de MicroProcesador === >> ReporteInventario.txt
    wmic cpu get name, Manufacturer, serialnumber >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo === Informe de Memoria RAM === >> ReporteInventario.txt
    wmic MemoryChip get BankLabel, Capacity, MemoryType, TypeDetail, Speed, Manufacturer, SerialNumber >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo === Informe de RED === >> ReporteInventario.txt
    wmic NICCONFIG get Caption, IPAddress, IPSubnet, DefaultIPGateway, DNSServerSearchOrder, MACAddress, DNSDomain,DNSDomainSuffixSearchOrder >> ReporteInventario.txt
    echo ================================================================ >> ReporteInventario.txt
    echo. >> ReporteInventario.txt
    pause
    goto MENU

:opt31
    cls
    echo Abriendo configuracion de Tiempo y Hora...
    start "" timedate.cpl
    ::pause
    goto MENU

:opt32
    cls
    echo Abriendo configuracion de Discos Duros...
    start "" diskmgmt.msc
    ::pause
    goto MENU

:opt33
    cls
    echo Activar Firewall de Windows...
    start "" netsh.exe advfirewall set allprofiles state on
    echo Activado Firewall de Windows...
    pause
    goto MENU

:opt34
    cls
    echo Desactivar Firewall de Windows...
    start "" netsh.exe advfirewall set allprofiles state off
    echo Desactivado Firewall de Windows...
    pause
    goto MENU

:opt35
    cls
    echo Abrir Windows Defender...
    start "" explorer.exe windowsdefender:
    ::pause
    goto MENU


:opt36
    cls
    echo Abrir Bloc de Notas...
    start "" notepad
    ::pause
    goto MENU

:opt37
    cls
    ::echo Abrir Bloc de Notas...
    start "" control.exe intl.cpl,,2
    ::pause
    goto MENU

:opt38
    cls
    ::echo Abrir Aplicaciones de Windows...
    start "" shell:appsfolder
    ::pause
    goto MENU

:opt39
    cls
    ::echo Ver Activacion de Windows...
    start "" slmgr.vbs -xpr
    ::pause
    goto MENU

:opt40
    cls
    ::echo Revisar con Windows Defender...
    start "" mrt
    ::pause
    goto MENU
	
:opt41
    cls
    ::echo tareas Programadas de Windows...
    start "" taskschd.msc
    ::pause
    goto MENU

:SALIR
    cls
    echo [%date% %time%] === FIN DE SESION === >> "%LOG_FILE%"
    echo Gracias por usar las Herramientas Administrativas de Windows ...
    echo Creado por:...
    echo ..................................................
    echo ......   Ing. Yoesdany Hernández Quintero   ......
    echo ......   Ing. Yosvany Hernández Quintero    ......
    echo ..................................................
    timeout /t 3 /nobreak >nul
    endlocal
    exit /b 0