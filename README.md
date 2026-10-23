# SIGIP API Gateway

Punto único de entrada de SIGIP mediante Spring Cloud Gateway.

## Funcionalidad

- Rutas `lb://<servicio>` resueltas mediante Eureka y Spring Cloud LoadBalancer.
- `StripPrefix=1`: `/sales-service/api/v1/pedidos` llega a Sales como `/api/v1/pedidos`.
- CORS configurable con `CORS_ORIGINS` (por defecto `http://localhost:4200`).
- Actuator expone health, métricas, Prometheus y rutas del Gateway.

Variables principales: `EUREKA_URL` y `CORS_ORIGINS`.

## Ejecución local

Puerto: `9002`.

```powershell
mvn spring-boot:run
```

Con Eureka en `http://localhost:9001`, las rutas del Gateway quedan bajo:

- `/auth-service/**`
- `/catalog-service/**`
- `/sales-service/**`
- `/design-service/**`
- `/production-service/**`
- `/inventory-service/**`
- `/notification-service/**`
- `/report-service/**`

## Despliegue completo de los repositorios independientes

`docker-compose.full.yml` construye y levanta MySQL, RabbitMQ, Eureka, los microservicios, Gateway, Angular, Prometheus y Grafana usando las carpetas hermanas `SIGIP-*`.

Para la demo empresarial, `scripts/aplicar-datos-demo.ps1` aplica de forma idempotente el catálogo visual, las opciones de personalización de precios y los clientes de prueba sobre el contenedor MySQL existente.

Consulta [DEPLOYMENT.md](DEPLOYMENT.md) para los comandos y las evidencias de despliegue/observabilidad.
