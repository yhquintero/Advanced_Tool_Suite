# Matriz de validación Windows · 3.0.0

**Estado inicial: todas las pruebas de esta página pendientes.** Marca resultados reales, no inferidos de la inspección de código. Usa VM con instantánea y datos ficticios; no conviertas discos ni pruebes reinicios en producción.

## Entorno

Registrar por ejecución: fecha, versión de la suite/hash, edición y compilación de Windows, versión PowerShell/.NET, arquitectura, usuario estándar/administrador, resolución/DPI, antivirus y estado de Protección del sistema.

Mínimo: Windows 10 x64 y Windows 11 x64; Windows PowerShell 5.1, .NET Framework 4.8; cuenta estándar y administrador con UAC. Incluir rutas con espacios y tildes.

## Comprobaciones automatizadas sin acciones del sistema

```powershell
.\tests\Validar-PowerShell.ps1
.\tests\Probar-Contratos.ps1
powershell.exe -NoProfile -STA -File .\Tool\AdvancedToolSuite.ps1 -SmokeTest
```

- [ ] Parser oficial: todos los PS1 sin errores y catálogo con 42 IDs únicos.
- [ ] Contratos: lista blanca solo lectura, especificaciones de Registro y rotación de cinco copias.
- [ ] Smoke test: ambas ventanas, 42 tarjetas/iconos, cuatro temas, tamaño compacto/completo y búsqueda vacía.
- [ ] CI Linux/Windows aprobado; conservar enlaces y resultados en la revisión de versión.

## Visual e interacción (1–8)

- [ ] Entrada fade/slide visible en navegación y tarjetas, sin saltos molestos.
- [ ] Movimiento desactivado desde Ajustes y desde Windows: sin animaciones.
- [ ] Los 42 iconos se ven correctamente; comparar SVG con la tarjeta.
- [ ] Cambiar los cuatro temas varias veces sin errores de brushes congelados.
- [ ] Compacto: categoría accesible, botones utilizables, Ajustes permite salir del modo.
- [ ] DPI 100 %, 150 % y 200 %; redimensionar a mínimos, maximizar y desplazar tarjetas.
- [ ] Tab/Mayús+Tab/Entrar/Espacio; foco visible y favoritos no ejecutan la herramienta.
- [ ] Filtro combinado de nombre, categoría y favoritos; texto sin coincidencias.
- [ ] Favoritos/tema/preferencias persisten al reiniciar; JSON corrupto usa valores predeterminados.
- [ ] Exportación del log, cancelación del diálogo y destino sin permiso; verificar rotaciones.

## Herramientas, tareas y diagnóstico (9–11)

- [ ] Abrir herramientas inocuas: Bloc de notas, audio, información, Panel de control.
- [ ] Preflight: ejecutable o componente no disponible muestra error comprensible.
- [ ] Unidad inexistente, ruta en vez de letra y cancelación: no ejecutan comando.
- [ ] Tipo y espacio comprobados en HDD, SSD, USB y volumen virtual; no inventar tipo desconocido.
- [ ] Conversión rechaza NTFS y exige dos confirmaciones en FAT32. Prueba real solo sobre VHD desechable y copia previa.
- [ ] Ping: IPv4, IPv6 y dominio válidos; rechazar `-t`, comillas, punto y coma y comandos concatenados.
- [ ] Inventario generado en Documentos redirigidos y revisado por datos sensibles.
- [ ] Tarea de informe: fecha inválida/pasada/cancelación no crean tareas.
- [ ] Crear tarea futura: nombre ATS-Informe-*, principal Interactive/Limited y sin credenciales.
- [ ] Comprobar informe al ejecutarse; eliminar tarea desde Programador y verificar retirada.
- [ ] CPU/RAM/disco se actualizan sin congelar interfaz; caída de CIM informa indisponibilidad.
- [ ] Abrir/cerrar panel repetidamente y sesión prolongada: comprobar procesos, memoria y runspaces.

## Registro, auditoría y seguridad (12–16)

- [ ] Ocultos, modo claro/oscuro y menú clásico/moderno: guardar valor y tipo antes, cambiar y deshacer; comparar exactitud.
- [ ] Ajuste originalmente ausente: deshacer no deja una sobrescritura funcional inesperada.
- [ ] Un cambio posterior externo en el mismo valor impide deshacer.
- [ ] Opción de menú moderno no elimina valores ni subclaves ajenos.
- [ ] Log con fecha/hora; audit con UTC, sesión, versión, usuario, ID y estado correcto.
- [ ] `DISPATCHED` no aparece como finalización; consola fallida se registra con salida de error tras cerrarla.
- [ ] C:\REPORTE escribible y no escribible: advertencia y copia local; sin cambios de ACL ni elevación automática.
- [ ] Rotación con archivos grandes; archivo ocupado, disco lleno y segunda instancia; documentar pérdidas o conflictos.
- [ ] Solo lectura: intentar cada tarjeta y atajo (programar, deshacer, restaurar, integración) y confirmar bloqueo.
- [ ] Configurar clave, confirmación distinta, cancelación, clave incorrecta, correcta y cambio/retiro.
- [ ] Cinco fallos bloquean cinco minutos, persiste tras reiniciar; nunca aparece clave en logs.
- [ ] DPAPI corrupto o de otro usuario: se rechaza la autorización; no se acepta por error.
- [ ] Punto manual con Protección del sistema habilitada: nuevo SequenceNumber confirmado.
- [ ] Punto automático: cancelar UAC, protección deshabilitada y límite 24 h bloquean el cambio.
- [ ] Tras punto exitoso: se aplica solo la acción confirmada; cambiar a solo lectura mientras espera debe bloquearla.
- [ ] No hay reinicio automático tras Winsock; firewall solo cambia tras confirmar y UAC.
- [ ] Apagar/reiniciar: cancelar no afecta el equipo; aceptar solo en VM después de guardar trabajo.

## Distribución e integración (17–20)

- [ ] Portable desde carpeta nueva: solo el PS1 basta para abrirse; no se buscan SVG/XAML externos.
- [ ] Construir portable; verificar SHA256.json con Get-FileHash.
- [ ] Construir EXE con versión documentada de ps2exe; icono, STA y panel sin consola principal.
- [ ] EXE: consolas secundarias y UAC correctos, métricas, preferencias y menú contextual apuntan al EXE real.
- [ ] Construir MSI con WiX 3.x sin errores ni supresión indiscriminada de ICE.
- [ ] Instalar por usuario sin admin; ubicación y acceso a Inicio correctos.
- [ ] Actualización a versión mayor de producto, prohibición de downgrade y desinstalación limpia de archivos instalados.
- [ ] .NET insuficiente o Windows incompatible: mensaje claro, sin instalación parcial.
- [ ] Firma/SmartScreen/Defender: comprobar en VM limpia; no desactivar protecciones para ocultar alertas.
- [ ] Menú contextual: instalar, clic derecho del fondo de carpeta, Mostrar más opciones en Windows 11, abrir y retirar.
- [ ] Mover portable invalida la entrada anterior; reinstalar corrige ruta. Retirar antes de desinstalar MSI.
- [ ] Se conservan preferencias/logs/informes deliberadamente y se documenta cómo eliminarlos por usuario.

## Registro de resultados

| Prueba | Entorno | Resultado real | Evidencia / incidencia | Responsable / fecha |
| --- | --- | --- | --- | --- |
| Pendiente | — | No ejecutada | — | — |

No anotar contraseñas, licencias, direcciones públicas ni números de serie reales en este documento versionado.

## Ampliación 3.0.1: distribución, firma y Pester

- [ ] `tests\Run-Pester.ps1`: 43/43, ningún omitido, NUnit XML conservado.
- [ ] `install.ps1 -WhatIf`: ningún archivo, clave o acceso directo modificado.
- [ ] Instalación por usuario desde Portable y Exe; probar Inicio y Aplicaciones instaladas.
- [ ] Paquete corrupto/incompleto, SHA incorrecto, salida no vacía y recibo desconocido: rechazo sin borrar datos.
- [ ] Actualización válida, downgrade bloqueado, archivo modificado y archivo ajeno: resultados y mensajes correctos.
- [ ] Junction/symlink en destino o padre: rechazo; acceso directo cambiado: no sobrescribirlo.
- [ ] Fallo de registro o acceso directo durante instalación: intento de rollback y backup recuperable.
- [ ] Desinstalación: confirmación/cancelación, WhatIf, solo archivos propios, datos/tareas conservados.
- [ ] Archivo bloqueado y fallo de retirada parcial: registrar resultado y procedimiento de recuperación.
- [ ] Manifiesto extraído del EXE final: asInvoker, uiAccess=false, DPI y versión coherentes.
- [ ] Firma con certificado autorizado: SHA256, sello presente y estado Valid.
- [ ] Certificado sin clave/EKU, expirado, cadena no confiable o sello fallido: construcción no se presenta como exitosa.
- [ ] Tras modificar un archivo firmado, firma/hashes rechazan el cambio.
- [ ] MSI bloquea la instalación registrada por scripts; scripts rechazan formato Msi.
- [ ] Manual/BUILD/licencia presentes en distribución e instalación MSI; revisión de derechos antes de publicar.
