
# DACHSER.ps1
# Programa principal de gestion de etiquetas Dachser

# ============================================================
# CONFIGURACION
# ============================================================

#$ApiKey = "XXXX"
# ============================================================
# CONFIGURACION - LECTURA API KEY DESDE DACHSER.ini
# ============================================================

$IniPath = Join-Path $PSScriptRoot "DACHSER.ini"

if (-not (Test-Path -LiteralPath $IniPath -PathType Leaf)) {
    Write-Host "ERROR: No se encuentra DACHSER.ini" -ForegroundColor Red
    return
}

# Leer seccion [DACHSER] y parametro ApiKey
$ApiKey = $null
$EnSeccion = $false

foreach ($linea in Get-Content -LiteralPath $IniPath) {

    $linea = $linea.Trim()

    # Ignorar lineas vacias y comentarios
    if ($linea -eq "" -or $linea.StartsWith(";") -or $linea.StartsWith("#")) {
        continue
    }

    # Detectar secciones
    if ($linea -match '^\[(.+)\]$') {
        $EnSeccion = ($Matches[1] -eq "DACHSER")
        continue
    }

    # Leer ApiKey dentro de [DACHSER]
    if ($EnSeccion -and $linea -match '^ApiKey\s*=\s*(.*)$') {
        $ApiKey = $Matches[1].Trim()
        break
    }
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "ERROR: No se ha encontrado ApiKey en DACHSER.ini" -ForegroundColor Red
    return
}

# FIN CONFIGURACION



#$ScriptPath = Join-Path $PSScriptRoot "list-transportorders.ps1"
$ListScript = Join-Path $PSScriptRoot "list-transportorders.ps1"
$GetLabelScript = Join-Path $PSScriptRoot "get-labelv2.ps1"
# ============================================================
# MENU PRINCIPAL
# ============================================================

do {

    Clear-Host

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       GESTION ETIQUETAS DACHSER" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Descargar etiqueta existente"
    Write-Host "  2. Generar etiqueta desde JSON"
    Write-Host ""
    Write-Host "  0. Salir"
    Write-Host ""

    $opcion = Read-Host "Selecciona una opcion"

    switch ($opcion) {

        # ====================================================
        # OPCION 1 - DESCARGAR ETIQUETA EXISTENTE
        # ====================================================

        "1" {

            Write-Host ""
            Write-Host "DESCARGAR ETIQUETA EXISTENTE" -ForegroundColor Cyan
            Write-Host ""

            $diasInput = Read-Host "Cuantos dias de historico quieres consultar? [7]"

            if ([string]::IsNullOrWhiteSpace($diasInput)) {
                $dias = 7
            }
            else {
                $dias = 0

                if (-not [int]::TryParse($diasInput, [ref]$dias) -or $dias -lt 0) {
                    Write-Host "Numero de dias no valido." -ForegroundColor Red
                    break
                }
            }

            $DateTo = (Get-Date).ToString("yyyy-MM-dd")
            $DateFrom = (Get-Date).AddDays(-$dias).ToString("yyyy-MM-dd")

            Write-Host ""
            Write-Host "Consultando desde $DateFrom hasta $DateTo" -ForegroundColor Yellow
            Write-Host ""

            if (Test-Path -LiteralPath $ListScript -PathType Leaf) {

                & $ListScript `
                    -ApiKey $ApiKey `
                    -DateFrom $DateFrom `
                    -DateTo $DateTo

            }
            else {
                Write-Host "ERROR: No se encuentra list-transportorders.ps1" -ForegroundColor Red
            }
        }

        # ====================================================
        # OPCION 2 - GENERAR ETIQUETA DESDE JSON
        # ====================================================

        "2" {

            Write-Host ""
            Write-Host "GENERAR ETIQUETA DESDE JSON" -ForegroundColor Cyan
            Write-Host ""

            if (Test-Path -LiteralPath $GetLabelScript -PathType Leaf) {

                & $GetLabelScript -ApiKey $ApiKey
		
            }
            else {
                Write-Host "ERROR: No se encuentra get-label2.ps1" -ForegroundColor Red
            }
        }

        # ====================================================
        # OPCION 0 - SALIR
        # ====================================================

        "0" {
            Write-Host ""
            Write-Host "Saliendo del programa..." -ForegroundColor Yellow
        }

        default {
            Write-Host "Opcion no valida." -ForegroundColor Red
        }
    }

    if ($opcion -ne "0") {
        Write-Host ""
        Read-Host "Pulsa INTRO para volver al menu principal"
    }

} while ($opcion -ne "0")