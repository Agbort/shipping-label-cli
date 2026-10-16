# DACHSER Shipping Label CLI

Herramienta PowerShell para consultar expediciones, recuperar etiquetas PDF, transmitir pedidos JSON y eliminar órdenes mediante la API REST de DACHSER.

Proyecto independiente, no oficial.

## Requisitos

- Windows con PowerShell 5.1 o superior.
- API Key válida de DACHSER.
- Acceso a `api-gateway.dachser.com`.

## Configuración

Copiar `DACHSER_EXAMPLE.ini` como `DACHSER.ini` e introducir la API Key:

```ini
[DACHSER]
ApiKey=YOUR_API_KEY
```

El archivo `DACHSER.ini` está excluido de Git por seguridad.

## Ejecución

```powershell
.\DACHSER.ps1
```

## Opciones del menú

**1. Descargar etiqueta existente**

Consulta órdenes por intervalo de fechas, permite seleccionar una y recupera su etiqueta PDF. Los archivos se guardan en `generadas/`.

**2. Generar etiqueta desde JSON**

Selecciona un fichero `request_*.json`, lo transmite a DACHSER y genera su etiqueta. Si finaliza correctamente, mueve el JSON a `JSON_ENVIADOS/`.

**3. Eliminar orden**

Solicita introducir manualmente el ID de la expedición y confirmar su eliminación. Requiere permisos en la API.

**0. Salir**

## Archivos principales

| Archivo | Función |
|---|---|
| `DACHSER.ps1` | Menú principal y configuración |
| `list-transportorders.ps1` | Consulta de expediciones |
| `get-label-from-uri.ps1` | Recuperación de etiquetas |
| `get-labelv2.ps1` | Transmisión de pedidos JSON |
| `delete-order.ps1` | Eliminación de órdenes |
| `DACHSER_EXAMPLE.ini` | Ejemplo de configuración |

## Advertencias

- `/transportorders/labelled` puede crear nuevas órdenes. No utilizar para reimprimir etiquetas existentes.
- `/transportorders/{id}/send` puede modificar el estado de una expedición.
- DELETE es una operación destructiva. Verificar siempre el ID y el estado de la orden.
- Ante errores de comunicación, comprobar el estado en DACHSER antes de repetir una petición.
- No publicar credenciales, JSON de pedidos ni etiquetas reales.

---

*Herramienta independiente de soporte para integraciones con DACHSER. No afiliada ni respaldada oficialmente por DACHSER.*
