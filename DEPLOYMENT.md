# Despliegue integrado de SIGIP

Este repositorio contiene el archivo de orquestación para levantar los repositorios independientes de SIGIP como un solo sistema. Los repositorios deben estar como carpetas hermanas dentro de la misma carpeta `SIGIP`.

## Requisitos

- Docker Desktop con Docker Compose moderno.
- Los 12 repositorios clonados como carpetas hermanas.
- Usar la rama `main` en los 12 repositorios.

## Preparación

Desde `SIGIP-Api-Gateway`:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
```

Para una demo real cambia las contraseñas y el secreto JWT del archivo `.env` antes de levantar el stack.

Actualiza los 12 repositorios desde la carpeta que los contiene:

```powershell
cd ..
Get-ChildItem -Directory -Filter "SIGIP-*" | ForEach-Object {
    git -C $_.FullName switch main
    if ($LASTEXITCODE -ne 0) { throw "No se pudo cambiar a main: $($_.Name)" }
    git -C $_.FullName pull --ff-only
    if ($LASTEXITCODE -ne 0) { throw "No se pudo actualizar: $($_.Name)" }
}
cd SIGIP-Api-Gateway
```

Si ya tienes `.env`, conserva tus valores; no lo sobrescribas al actualizar.

## Construir y levantar

```powershell
docker compose -f docker-compose.full.yml config --quiet
docker compose -f docker-compose.full.yml build
docker compose -f docker-compose.full.yml up -d --wait --wait-timeout 600
```

La primera compilación demora porque cada imagen backend instala `SIGIP-Common` en su etapa Maven y ejecuta la compilación y todas las pruebas de su microservicio. Cada servicio espera la salud de sus dependencias antes de arrancar. Los siguientes builds reutilizan la caché de Maven/BuildKit.

## Verificación

```powershell
docker compose -f docker-compose.full.yml ps
```

La validación automática comprueba la salud de los diez procesos Java, las ocho rutas a través de nginx/Gateway, el inicio de sesión y los permisos, y las consultas de Reportes a Ventas e Inventario. Con Python 3 instalado:

```powershell
python scripts/smoke-test.py
```

Usa `SIGIP_ADMIN_USERNAME` y `SIGIP_ADMIN_PASSWORD` de `.env` (o del entorno). No imprime contraseñas ni tokens. En GitHub Actions se ejecuta además `--write-test-data`: crea registros temporales, comprueba GET/POST/PUT/DELETE y verifica que un pedido genere su notificación mediante RabbitMQ; después elimina los registros de prueba. Ese modo está pensado para el stack desechable de CI.

Endpoints principales:

- Frontend: http://localhost:4200
- Eureka: http://localhost:9001
- API Gateway: http://localhost:9002
- RabbitMQ Management: http://localhost:15672
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000

Los microservicios se exponen también en 9003-9010 para diagnóstico, aunque el frontend debe consumirlos a través del Gateway.

En Prometheus abre `Status > Target health`; los targets SIGIP deben aparecer `UP`. En Grafana agrega Prometheus con URL `http://prometheus:9090` y crea un panel con métricas como `http_server_requests_seconds_count` y `jvm_memory_used_bytes`.

## Flujo mínimo para evidencias de la rúbrica

1. Iniciar sesión usando el REST de Auth y comprobar que el password almacenado está en BCrypt, no en texto plano.
2. Desde Angular demostrar GET, POST, PUT y DELETE contra datos persistidos.
3. Demostrar la separación Cliente/Admin y que un cliente solo accede a sus propios pedidos.
4. Mostrar Eureka con los servicios registrados.
5. Crear/cambiar un pedido y mostrar el evento publicado por Sales y consumido por Notification mediante RabbitMQ.
6. Mostrar `/actuator/health`, Prometheus y Grafana para evidencia de observabilidad.
7. Guardar capturas de las pruebas y del funcionamiento para los anexos del informe y el demo reel.

## Apagar

```powershell
docker compose -f docker-compose.full.yml down
```

Para eliminar también las bases y datos locales:

```powershell
docker compose -f docker-compose.full.yml down -v
```

> `down -v` borra los volúmenes de MySQL y Grafana. Úsalo solo cuando quieras reiniciar todos los datos de la demo.
