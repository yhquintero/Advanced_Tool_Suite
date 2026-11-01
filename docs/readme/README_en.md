# NEXUS · Advanced Tool Suite

## Diagnose. Organize. Decide.

A local Windows control panel with **42 tools in 6 categories**, built with PowerShell and WPF. Search, favorites, four themes, inventories, activity logs and declarative diagnostic plugins.

[Español](../../README.md) · **English** · [Português](README_pt-BR.md)

**This is a documentation summary, not an English UI.** The Windows application is currently in Spanish. Version 4.0.0 is in development, not certified for production.

## Requirements

Windows 10/11 x64 desktop, Windows PowerShell 5.1 and .NET Framework 4.8. Open the panel as a standard user; authorize individual UAC prompts only when needed. PowerShell 7 is not the supported WPF runtime.

## Start from source

From the repository root, open the local panel:

```powershell
powershell.exe -NoProfile -STA -File .\Tool\AdvancedToolSuite.ps1
```

To install for your user instead:

```powershell
.\install.ps1 -WhatIf
.\install.ps1
```

The installer builds a fresh unsigned Portable package, validates it, and installs locally. After installation, use **Start → Advanced Tool Suite**, not the installer. Begin with **Ajustes → Solo lectura** (Settings → Read-only) and basic system/IP diagnostics.

## Know the limits

The website is documentation, not a remote administration service or PWA. The suite is not an antivirus. Read-only mode and the local password are not Windows security boundaries. Undo is limited; back up important files before changes. Logs and inventories may contain personal or network data. Hashes check integrity, not publisher identity. Plugins do not run arbitrary third-party scripts.

## Documentation and license

Full reference documents remain in Spanish: [manual](../../MANUAL.md), [first run](../../LEEME-PRIMERO.md), [build](../../BUILD.md), [security policy](../../SECURITY.md), [history](../../CHANGELOG.md), [roadmap](../ROADMAP-v4.0.0.md).

[Website source](../../site/index.html); Pages publication is not claimed as active. [MIT license](../../LICENSE), without warranty. Check third-party notices before redistribution.
