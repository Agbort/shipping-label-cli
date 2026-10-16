#delete-order.ps1
#.\delete-order.ps1 -TransportOrderId ID_ORDEN -BearerToken "EL_TOKEN_AQUI"
# ============================================================
# DELETE ORDER - DACHSER API
# ============================================================
#
# Herramienta experimental para eliminar ordenes.
#
# Requiere permisos de eliminacion en la API.
# No forma parte del menu principal DACHSER.ps1.
#
# ATENCION: Operacion destructiva.
#
# ============================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$TransportOrderId,

    [Parameter(Mandatory = $true)]
    [string]$BearerToken
)

# URL DELETE
$deleteUrl = "https://api-gateway.dachser.com/rest/v2/transportorders/$TransportOrderId"

Write-Host "Eliminando orden $TransportOrderId ..."

try {
    Invoke-RestMethod `
        -Method DELETE `
        -Uri $deleteUrl `
        -Headers @{
            "Authorization" = "Bearer $BearerToken"
            "Accept"        = "application/json"
        }

    Write-Host "Orden $TransportOrderId eliminada correctamente."
}
catch {
    Write-Host "ERROR eliminando la orden $TransportOrderId"
    Write-Host $_.Exception.Message
}
