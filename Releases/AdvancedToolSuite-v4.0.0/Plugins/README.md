# Plugins v4 · fase inicial declarativa

**Implementado en código; validación interactiva Windows pendiente.** Esta fase no es un host de código externo ni un sandbox. Son manifiestos JSON que dan nombre y descripción a un único diagnóstico integrado.

## Diagnósticos permitidos

| toolId | Acción |
| --- | --- |
| 1 | Información del sistema |
| 14 | Diagnóstico de memoria |
| 19 | Salud reportada de discos |
| 27 | Configuración IP |
| 28 | Ping a google.com |
| 30 | Exportar inventario local |

No admite parámetros libres, rutas a scripts, comandos, DLL, EXE, workflows ni acciones de escritura del sistema. Exportar inventario y consultar red pueden generar archivos locales o tráfico; no significa ausencia de efectos operativos.

## Flujo de uso

1. Abre **Plugins v4** en el panel.
2. Pulsa **Importar JSON** y elige un ejemplo de `Plugins/Examples`.
3. Revisa ID, nombre, versión, diagnóstico y descripción; confirma la importación **inactiva**.
4. Selecciona el plugin y pulsa **Activar** para aprobar su SHA256 actual.
5. **Ejecutar** pasa por el mismo despacho y restricciones del diagnóstico integrado.
6. **Desactivar** retira la aprobación; **Retirar** elimina solo ese manifiesto local.

Nada se ejecuta al importar, activar, abrir el panel o reiniciar Windows. No hay descargas automáticas. No se permiten cambios del almacén/aprobaciones en modo solo lectura; ejecutar un diagnóstico ya aprobado continúa permitido.

## Ejemplo

```json
{
  "schemaVersion": 1,
  "id": "ats-memory",
  "name": "Diagnostico de memoria",
  "version": "1.0.0",
  "description": "Consulta memoria sin cerrar aplicaciones.",
  "toolId": 14
}
```

El ID solo admite minúsculas, números y guiones; 3–48 caracteres, comenzando por una letra. Nombre hasta 80 y descripción hasta 320 caracteres, sin controles. Versión numérica en tres partes. Tamaño máximo de archivo: 16 KiB. Los campos son exactamente los del ejemplo; se rechazan otros como `command`, `scriptPath` o `arguments`. El esquema de referencia es `plugin.schema.json`.

## Almacén y aprobación

Los plugins importados están en `%LOCALAPPDATA%\AdvancedToolSuite\Plugins\<id>.json`. No se ejecuta código desde esa carpeta. Se rechazan enlaces y nombres de archivo que no coincidan con el ID.

`preferencias.json` conserva `EnabledPlugins` como `id:SHA256`. Si cambia el archivo, deja de estar aprobado. Antes de ejecutar se relee y comprueba la huella. No se sobrescriben IDs existentes al importar: retira y revisa la nueva versión explícitamente.

Los eventos `PLUGIN_IMPORTED`, `PLUGIN_STATE`, `PLUGIN_REJECTED`, `PLUGIN_REQUEST` y `PLUGIN_ERROR` usan la auditoría existente. Rechazar un archivo no lo elimina automáticamente.

## Límites

- Datos de un manifiesto no acreditan autor ni firma. El hash es una aprobación local de contenido, no autenticación de editor.
- Un usuario con acceso al perfil puede modificar preferencias; no es una barrera de privilegios.
- No hay actualización automática, dependencias de plugins, aislamiento de procesos ni autorización empresarial.
- Una modificación concurrente se detecta cuando se vuelve a leer la huella; no se promete una transacción frente a código malicioso de la misma cuenta.
- Los diagnósticos se ejecutan en consolas/ventanas externas y mantienen sus limitaciones documentadas.

`Plugin.Core.ps1` contiene funciones reutilizables y está embebido en el PS1 principal para mantenerlo autónomo. Tras editarlo, sincroniza el bloque `ATS_PLUGIN_CORE` del principal; las pruebas detectan diferencias. El autoextraíble debe regenerarse después de cualquier cambio.

El host de plugins externos con capacidades y aislamiento sigue en `docs/ROADMAP-v4.0.0.md`, no se considera terminado por esta fase.
