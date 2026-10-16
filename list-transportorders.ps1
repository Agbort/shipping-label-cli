#list-transportorders.ps1
#uso: .\list-transportorders.ps1 -ApiKey "CLAVE" -DateFrom "2026-03-27"
# opcion 2: #uso: .\list-transportorders.ps1 -ApiKey "CLAVE" -DateFrom "2026-03-27" -DateTo   "2026-03-31"


param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,

    [Parameter(Mandatory = $true)]
    [string]$DateFrom,   # formato: YYYY-MM-DD

    [Parameter(Mandatory = $false)]
    [string]$DateTo  # formato: YYYY-MM-DD

)

# Si no se pasa DateTo, usamos DateFrom
if ([string]::IsNullOrWhiteSpace($DateTo)) {
    $DateTo = $DateFrom
}

#$uri = "https://api-gateway.dachser.com/rest/v2/transportorders?date-from=$Date&date-to=$Date"
$uri = "https://api-gateway.dachser.com/rest/v2/transportorders?date-from=$DateFrom&date-to=$DateTo"

Write-Host "Consultando transportorders para la fecha $DateFrom - $DateTo ..." -ForegroundColor Cyan

$response = Invoke-RestMethod `
    -Method GET `
    -Uri $uri `
    -Headers @{
        "accept"    = "application/json"
        "X-API-Key" = $ApiKey
    }

if (-not $response -or $response.Count -eq 0) {
    Write-Host "No se han encontrado ordenes para esa fecha." -ForegroundColor Yellow
    return
}

Write-Host "Ordenes encontradas:" -ForegroundColor Green

# Mostrar resumen numerado
$i = 1
$response | ForEach-Object {


 # Reference (puede haber varias, cogemos la primera)
    $refCode  = $null
    $refValue = $null

    if ($_.references -and $_.references.Count -gt 0) {
        $refCode  = $_.references[0].code
        $refValue = $_.references[0].value
    }

    # Weight
    $weightText = $null
    if ($_.weight) {
        $weightText = "$($_.weight.weight) $($_.weight.unit)"
    }

 # Cita previa (service AT)
    $citaPrevia = 'No'

if ($_.services) {
    if ($_.services | Where-Object { $_.code -eq 'AT' }) {
        $citaPrevia = 'Sí'
    }
}

    [PSCustomObject]@{
        Num  = $i++
        ID   = $_.id
        Date = $_.transportDate
	RefCode  = $refCode
        RefValue = $refValue
	CitaPrevia = $citaPrevia
        Weight = $weightText
	
    }
} | Format-Table -AutoSize

# Elegir ID
Write-Host "Elige el NUM de la orden para descargar la etiqueta." -ForegroundColor Yellow
$choice = Read-Host "0 para salir"

# Salir sin descargar ninguna etiqueta
if ($choice -eq "0") {
    Write-Host "Saliendo sin descargar etiqueta." -ForegroundColor Yellow
    return
}
# Validar numero seleccionado
$num = 0

if (-not [int]::TryParse($choice, [ref]$num) -or
    $num -lt 1 -or
    $num -gt @($response).Count) {

    Write-Host "Seleccion invalida." -ForegroundColor Red
    return
}

$selected = @($response)[$num - 1]

$selectedId = $selected.id

Write-Host "Seleccionado transportOrderId: $selectedId" -ForegroundColor Cyan

# Llamar al script de descarga de etiqueta
$labelScript = Join-Path $PSScriptRoot "get-label-from-uri.ps1"
$transportOrderUri = "https://api-gateway.dachser.com/rest/v2/transportorders/$selectedId/send?label-format=P"

& $labelScript -Uri $TransportOrderUri -ApiKey $ApiKey