# -------------------------------
# get-labelv2.ps1
#
# Uso interactivo:
# .\get-labelv2.ps1 -ApiKey "YOUR_APIKEY"
#
# Uso directo:
# .\get-labelv2.ps1 -ApiKey "YOUR_APIKEY" -JsonPath "request_123456.json"
#
# Este script transmite un JSON a Dachser y puede crear una nueva orden de transporte.
# Para recuperar una etiqueta de una orden ya registrada, utilizar list-transportorders.ps1.
#
# Busca JSON, permite seleccionar uno, lo transmite a Dachser
# y lo mueve a JSON_ENVIADOS si se genera la etiqueta.
#
# ADVERTENCIAS:
#
# - El endpoint POST /transportorders/labelled puede crear una nueva orden de transporte.
# - No utilizar para recuperar etiquetas ya transmitidas.
# - Ante errores de comunicacion, comprobar el estado de la orden antes de repetir la peticion.
# ============================================================

param(
    [Parameter(Mandatory = $false)]
    [string]$JsonPath,

    [Parameter(Mandatory = $true)]
    [string]$ApiKey
)

# ============================================================
# CAMBIO 1 - DIRECTORIOS
# ============================================================

# Carpeta desde la que se ejecuta PowerShell
# $WorkDir = (Get-Location).Path
# Directorio donde esta ubicado DACHSER.ps1 y los demas scripts
$WorkDir = $PSScriptRoot

# Carpeta para los JSON transmitidos
$EnviadosDir = Join-Path $WorkDir "JSON_ENVIADOS"

# Endpoint Dachser
$labelUrl = "https://api-gateway.dachser.com/rest/v2/transportorders/labelled"

# ============================================================
# CAMBIO 2 - SELECCION DEL JSON
# ============================================================

if ([string]::IsNullOrWhiteSpace($JsonPath)) {

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       ENVIO DE PEDIDOS A DACHSER" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Buscando ficheros JSON en $WorkDir ..."

    $archivos = @(
	Get-ChildItem -LiteralPath $WorkDir -Filter "request_*.json" -File |
        Where-Object {
            $_.Name -notlike "label_response_*" -and
            $_.Name -notlike "send_response_*" -and
            $_.Name -notlike "response_*"
        } |
        Sort-Object Name
    )

    if ($archivos.Count -eq 0) {
        Write-Host "No se encontraron JSON pendientes." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "JSON disponibles:" -ForegroundColor Green
    Write-Host ""

    for ($i = 0; $i -lt $archivos.Count; $i++) {
        Write-Host "$($i + 1) - $($archivos[$i].Name)"
    }

    Write-Host "0 - Salir"
    Write-Host ""

    $choice = Read-Host "Selecciona el NUM del JSON a transmitir"

    if ($choice -eq "0") {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }

    $numSeleccionado = 0

    if (-not [int]::TryParse($choice, [ref]$numSeleccionado) -or
        $numSeleccionado -lt 1 -or
        $numSeleccionado -gt $archivos.Count) {

        Write-Host "Seleccion invalida." -ForegroundColor Red
        return
    }

    $JsonPath = $archivos[$numSeleccionado - 1].FullName
}
elseif (-not [System.IO.Path]::IsPathRooted($JsonPath)) {
    $JsonPath = Join-Path $WorkDir $JsonPath
}

if (-not (Test-Path -LiteralPath $JsonPath -PathType Leaf)) {
    Write-Host "ERROR: No existe el fichero $JsonPath" -ForegroundColor Red
    return
}

$archivoSeleccionado = Get-Item -LiteralPath $JsonPath
$JsonPath = $archivoSeleccionado.FullName

# Comprobar si ya existe en enviados
$DestinoJson = Join-Path $EnviadosDir $archivoSeleccionado.Name

if (Test-Path -LiteralPath $DestinoJson) {
    Write-Host "ERROR: Ya existe un fichero con ese nombre en enviados." -ForegroundColor Red
    Write-Host "No se ha transmitido el pedido." -ForegroundColor Yellow
    return
}

# ============================================================
# CAMBIO 3 - LEER Y VALIDAR JSON
# ============================================================

try {
    $jsonBody = Get-Content -Raw -LiteralPath $JsonPath -ErrorAction Stop
    $jsonObj = $jsonBody | ConvertFrom-Json -ErrorAction Stop

    $PedidoId = [string]$jsonObj.references[0].value

    if ([string]::IsNullOrWhiteSpace($PedidoId)) {
        throw "El JSON no contiene references[0].value"
    }
}
catch {
    Write-Host "ERROR leyendo el JSON: $($_.Exception.Message)" -ForegroundColor Red
    return
}

Write-Host ""
Write-Host "Fichero: $($archivoSeleccionado.Name)" -ForegroundColor Cyan
Write-Host "Pedido:  $PedidoId" -ForegroundColor Cyan
Write-Host ""

$confirmacion = Read-Host "Confirmas la transmision a Dachser? (S/N)"

if ($confirmacion -ne "S") {
    Write-Host "Operacion cancelada." -ForegroundColor Yellow
    return
}

# ============================================================
# CAMBIO 4 - TRANSMISION A DACHSER
# ============================================================

Write-Host ""
Write-Host "Transmitiendo pedido $PedidoId a Dachser..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod `
        -Method POST `
        -Uri $labelUrl `
        -Headers @{
            "X-API-Key"   = $ApiKey
            "Accept"      = "application/json"
            "Content-Type" = "application/json"
        } `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($jsonBody)) `
        -ErrorAction Stop
}
catch {
    Write-Host "ERROR durante la transmision a Dachser." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "El JSON permanece en su carpeta original." -ForegroundColor Yellow
    Write-Host "Comprueba el estado en Dachser antes de reintentar."
    return
}

# ============================================================
# CAMBIO 5 - GUARDAR RESPUESTA Y ETIQUETA
# ============================================================

try {
    # Guardar respuesta recibida
    $responsePath = Join-Path $WorkDir "label_response_$PedidoId.json"

    $response |
        ConvertTo-Json -Depth 20 |
        Out-File -LiteralPath $responsePath -Encoding UTF8 -ErrorAction Stop

    if (-not $response.label) {
        throw "Dachser ha respondido pero no se ha recibido el campo label."
    }

    # Decodificar PDF
    $bytes = [Convert]::FromBase64String($response.label)

    $pdfPath = Join-Path $WorkDir "etiqueta_$PedidoId.pdf"

    [System.IO.File]::WriteAllBytes($pdfPath, $bytes)

    Write-Host "Etiqueta generada: $pdfPath" -ForegroundColor Green
}
catch {
    Write-Host "ERROR procesando la respuesta de Dachser." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "El JSON NO se ha movido." -ForegroundColor Yellow
    Write-Host "ATENCION: La transmision puede haberse completado."
    Write-Host "Consulta Dachser antes de volver a transmitir."
    return
}

# ============================================================
# CAMBIO 6 - MOVER JSON A ENVIADOS
# ============================================================

try {
    if (-not (Test-Path -LiteralPath $EnviadosDir)) {
        New-Item -ItemType Directory -Path $EnviadosDir -ErrorAction Stop |
            Out-Null
    }

    Move-Item `
        -LiteralPath $JsonPath `
        -Destination $DestinoJson `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  TRANSMISION FINALIZADA CORRECTAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Pedido: $PedidoId"
    Write-Host "JSON movido a: $DestinoJson"
    Write-Host "PDF generado: $pdfPath"
}
catch {
    Write-Host "ERROR al mover el JSON a enviados." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "El pedido ya se ha transmitido a Dachser." -ForegroundColor Yellow
    Write-Host "NO repitas la transmision sin comprobarlo."
}

# FIN CAMBIOS
