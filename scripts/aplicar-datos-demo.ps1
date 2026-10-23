$ErrorActionPreference = 'Stop'

$gatewayRoot = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $gatewayRoot '.env'
$sqlPath = Join-Path $gatewayRoot 'database\actualizacion-personalizacion-demo.sql'

if (-not (Test-Path $envPath)) {
    throw "No existe .env. Ejecuta primero .\scripts\prepare-env.ps1"
}
if (-not (Test-Path $sqlPath)) {
    throw "No se encontró el script SQL: $sqlPath"
}

$mysqlPassword = $null
Get-Content $envPath | ForEach-Object {
    if ($_ -match '^MYSQL_ROOT_PASSWORD=(.*)$') {
        $mysqlPassword = $Matches[1].Trim()
    }
}
if ([string]::IsNullOrWhiteSpace($mysqlPassword)) {
    throw 'MYSQL_ROOT_PASSWORD no está definido en .env'
}

$running = docker inspect -f '{{.State.Running}}' sigip-mysql 2>$null
if ($LASTEXITCODE -ne 0 -or $running -ne 'true') {
    throw 'El contenedor sigip-mysql no está ejecutándose. Levanta primero SIGIP con docker compose.'
}

Write-Host 'Aplicando actualización de catálogo, personalización y clientes demo...' -ForegroundColor Cyan
$sql = Get-Content -Raw -Encoding UTF8 $sqlPath
$sql | docker exec -i sigip-mysql mysql --default-character-set=utf8mb4 -uroot "-p$mysqlPassword"
if ($LASTEXITCODE -ne 0) {
    throw 'MySQL devolvió un error al aplicar el script.'
}

Write-Host ''
Write-Host 'Base de datos actualizada correctamente.' -ForegroundColor Green
Write-Host 'Comprobando datos...' -ForegroundColor Cyan

docker exec sigip-mysql mysql -uroot "-p$mysqlPassword" -N -e "SELECT CONCAT('Servicios activos: ',COUNT(*)) FROM sigip_catalog.servicio_impresion WHERE activo=1; SELECT CONCAT('Opciones de personalización: ',COUNT(*)) FROM sigip_catalog.servicio_opcion WHERE activo=1; SELECT CONCAT('Clientes activos: ',COUNT(*)) FROM sigip_sales.clientes WHERE activo=1;"
