@echo off
setlocal
title Advanced Tool Suite - Inicio
powershell.exe -NoProfile -STA -File "%~dp0AdvancedToolSuite.ps1"
if errorlevel 1 (
    echo.
    echo No se pudo abrir el panel. Revisa el error anterior y las instrucciones del README.
    pause
)
endlocal
