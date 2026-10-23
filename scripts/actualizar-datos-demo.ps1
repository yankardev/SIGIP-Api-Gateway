$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$envPath = Join-Path $root '.env'
$sqlPath = Join-Path $PSScriptRoot 'actualizar-catalogo-clientes.sql'

if (-not (Test-Path $envPath)) {
    throw 'No existe .env. Ejecuta primero .\scripts\prepare-env.ps1'
}
if (-not (Test-Path $sqlPath)) {
    throw "No se encontro el SQL: $sqlPath"
}

$envText = [System.IO.File]::ReadAllText($envPath)
$match = [regex]::Match($envText, '(?m)^MYSQL_ROOT_PASSWORD=(.+)$')
if (-not $match.Success) {
    throw 'MYSQL_ROOT_PASSWORD no esta definido en .env'
}
$password = $match.Groups[1].Value.Trim().Trim('"').Trim("'")

$mysqlRunning = docker ps --filter "name=^/sigip-mysql$" --filter "status=running" --format "{{.Names}}"
if ($mysqlRunning -ne 'sigip-mysql') {
    throw 'El contenedor sigip-mysql no esta ejecutandose. Levanta SIGIP antes de cargar los datos.'
}

Write-Host 'Aplicando actualizacion de catalogo, personalizaciones y clientes demo...' -ForegroundColor Cyan
$sql = [System.IO.File]::ReadAllText($sqlPath)
$sql | docker exec -i -e "MYSQL_PWD=$password" sigip-mysql mysql --default-character-set=utf8mb4 -uroot

if ($LASTEXITCODE -ne 0) {
    throw "MySQL devolvio codigo $LASTEXITCODE"
}

Write-Host 'Datos demo actualizados correctamente.' -ForegroundColor Green
Write-Host 'Puedes abrir SIGIP en http://localhost:4200' -ForegroundColor Green
