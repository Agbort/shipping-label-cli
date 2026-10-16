#delete-order.ps1
# Uso: .\delete-order.ps1 -TransportOrderId "ID_ORDEN" -ApiKey "YOUR_APIKEY"
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
# Autenticacion X-API-Key verificada mediante una eliminacion real.
# La operacion requiere permisos y un estado de orden que permita DELETE.
# Tras eliminar, comprobar que la orden desaparece de la consulta.
# ============================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$TransportOrderId,

    [Parameter(Mandatory = $true)]
    [string]$ApiKey

    # Autenticacion anterior (pendiente de comprobar):
    # [Parameter(Mandatory = $true)]
    # [string]$BearerToken
)

# URL DELETE
$deleteUrl = "https://api-gateway.dachser.com/rest/v2/transportorders/$TransportOrderId"

Write-Host "" 
Write-Host "ATENCION: Se va a eliminar la orden $TransportOrderId" -ForegroundColor Yellow
$confirmacion = Read-Host "Confirmar eliminacion? (S/N)"

if ($confirmacion -ne "S") {
    Write-Host "Operacion cancelada." -ForegroundColor Yellow
 return
}

Write-Host "Eliminando orden $TransportOrderId ..."

try {
   Invoke-RestMethod `
        -Method DELETE `
        -Uri $deleteUrl `
        -Headers @{
            "X-API-Key" = $ApiKey
            "Accept"    = "application/json"
            # Autenticacion anterior (no utilizar junto a X-API-Key sin verificar):
            # "Authorization" = "Bearer $BearerToken"
        } `
        -ErrorAction Stop

    Write-Host "Orden $TransportOrderId eliminada correctamente." -ForegroundColor Green
}

catch {
    Write-Host "ERROR eliminando la orden $TransportOrderId"
    Write-Host $_.Exception.Message
}
