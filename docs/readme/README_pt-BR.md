# NEXUS · Advanced Tool Suite

## Diagnostique. Organize. Decida.

Painel local para Windows com **42 ferramentas em 6 categorias**, desenvolvido em PowerShell e WPF. Pesquisa, favoritos, quatro temas, inventários, registros de atividade e plugins declarativos de diagnóstico.

[Español](../../README.md) · [English](README_en.md) · **Português**

**Este é um resumo da documentação, não uma interface em português.** O aplicativo Windows está em espanhol. A versão 4.0.0 está em desenvolvimento, sem certificação para produção.

## Requisitos

Windows 10/11 x64 de desktop, Windows PowerShell 5.1 e .NET Framework 4.8. Abra o painel como usuário padrão; autorize UAC somente para ações que compreenda. PowerShell 7 não é o runtime WPF suportado.

## Começar a partir do código

Na raiz do repositório, abra o painel local:

```powershell
powershell.exe -NoProfile -STA -File .\Tool\AdvancedToolSuite.ps1
```

Para instalar para o seu usuário:

```powershell
.\install.ps1 -WhatIf
.\install.ps1
```

O instalador prepara um novo pacote Portable sem assinatura, valida e instala localmente. Depois, use **Iniciar → Advanced Tool Suite**, não o instalador. Comece com **Ajustes → Solo lectura** (Configurações → Somente leitura) e diagnósticos básicos do sistema e IP.

## Entenda os limites

O site é documentação, não administração remota nem PWA. A suíte não é antivírus. Somente leitura e senha local não substituem os controles de segurança do Windows. Desfazer é limitado: faça backup antes de alterar. Logs e inventários podem conter dados pessoais ou de rede. Hashes verificam integridade, não a identidade do autor. Plugins não executam scripts arbitrários de terceiros.

## Documentação e licença

Referências completas em espanhol: [manual](../../MANUAL.md), [primeiro uso](../../LEEME-PRIMERO.md), [compilação](../../BUILD.md), [segurança](../../SECURITY.md), [histórico](../../CHANGELOG.md), [roadmap](../ROADMAP-v4.0.0.md).

[Código do site](../../site/index.html); não se afirma publicação ativa no Pages. [Licença MIT](../../LICENSE), sem garantia. Consulte os avisos de terceiros antes de redistribuir.
