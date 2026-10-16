#uso:
#cd C:\SAT_DACHSER\labels
#.\get-label-from-uri.ps1 -Uri "https://api-gateway.dachser.com/rest/v2/transportorders/YOUR_ORDER_ID/send?label-format=P" -ApiKey "YOUR_APIKEY"
#-------------------------------------------
# ADVERTENCIAS DE SEGURIDAD Y FUNCIONAMIENTO
# ------------------------------------------
#
# 1. Este script realiza una peticion POST a la URI recibida
#    mediante el parametro -Uri, incluyendo la API Key.
#    IMPORTANTE: Utilizar exclusivamente URLs verificadas
#    del dominio api-gateway.dachser.com para evitar exponer
#    las credenciales a servidores no autorizados.
#
# 2. El endpoint /transportorders/{id}/send puede modificar
#    el estado de una orden o provocar su transmision.
#    No debe considerarse una simple operacion de descarga.
#    Verificar su comportamiento antes de utilizarlo con
#    ordenes reales o en otros entornos.
#
# 3. Ante errores de comunicacion, comprobar el estado de
#    la orden en Dachser antes de repetir la peticion,
#    para evitar posibles transmisiones duplicadas.
#
# 4. Pendiente de evaluar el endpoint /labels como alternativa
#    para recuperar etiquetas de ordenes existentes.
#
#------------------------------------------------

param(
    [Parameter(Mandatory = $true)]
    [string]$Uri,

    [Parameter(Mandatory = $true)]
    [string]$ApiKey
)

# Carpeta desde donde se ejecuta el script

$OutDir = Join-Path $PSScriptRoot "generadas"
# Crear directorio si no existe
if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -ErrorAction Stop | Out-Null
}



Write-Host "Ejecutando desde: $OutDir"
Write-Host "Llamando a URI:"
Write-Host $Uri

try {
    $response = Invoke-RestMethod `
        -Method POST `
        -Uri $Uri `
        -Headers @{
            "X-API-Key" = $ApiKey
            "Accept"    = "application/json"
        } `
        -ErrorAction Stop
}
catch {
    Write-Host "ERROR al consultar la API de Dachser." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Comprueba el estado de la orden antes de repetir la operacion." -ForegroundColor Yellow
    return
}

# Extraer ID de la URL (último número)
if ($Uri -match '/transportorders/(\d+)/') {
    $TransportOrderId = $Matches[1]
} else {
    $TransportOrderId = "desconocido"
}

# Guardar JSON respuesta
$response | ConvertTo-Json -Depth 20 | Out-File "$OutDir\label_response_$TransportOrderId.json"

# Decodificar etiqueta
# -----
# Control de errores al generar PDF
# -----

if ($response.label) {
    try {
        $pdfPath = Join-Path $OutDir "etiqueta_$TransportOrderId.pdf"

        $bytes = [Convert]::FromBase64String($response.label)

        [IO.File]::WriteAllBytes($pdfPath, $bytes)

        Write-Host "Etiqueta generada: $pdfPath" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR al generar la etiqueta PDF." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return
    }
}
else {
    Write-Host "No se encontro el campo 'label' en la respuesta." -ForegroundColor Yellow
}