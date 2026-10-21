# Despliegue integrado de SIGIP

Este repositorio contiene el archivo de orquestación para levantar los repositorios independientes de SIGIP como un solo sistema. Los repositorios deben estar como carpetas hermanas dentro de la misma carpeta `SIGIP`.

## Requisitos

- Docker Desktop con Docker Compose moderno.
- Los 12 repositorios clonados como carpetas hermanas.
- En `SIGIP-Frontend`, usar la rama `feature/frontend-sigip-integracion-local` mientras el PR de integración no haya sido fusionado.

## Preparación

Desde `SIGIP-Api-Gateway`:

```powershell
Copy-Item .env.example .env
```

Para una demo real cambia las contraseñas y el secreto JWT del archivo `.env` antes de levantar el stack.

Actualiza el frontend de integración:

```powershell
cd ..\SIGIP-Frontend
git fetch origin
git switch feature/frontend-sigip-integracion-local
git pull
cd ..\SIGIP-Api-Gateway
```

Actualiza también los demás repositorios antes del build.

## Construir y levantar

```powershell
docker compose -f docker-compose.full.yml config
docker compose -f docker-compose.full.yml build
docker compose -f docker-compose.full.yml up -d
```

La primera compilación demora porque cada imagen backend instala `SIGIP-Common` en su etapa Maven y compila su microservicio. Los siguientes builds reutilizan la caché de Maven/BuildKit.

## Verificación

```powershell
docker compose -f docker-compose.full.yml ps
```

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
