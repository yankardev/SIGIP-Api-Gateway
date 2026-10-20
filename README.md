# api-gateway

Punto único de entrada (Spring Cloud Gateway).

## Funcionalidad

- Rutas `lb://<servicio>`: resuelve las instancias en Eureka y reparte la carga (round robin).
- `StripPrefix=1`: `/sales-service/api/v1/pedidos` llega a sales como `/api/v1/pedidos`.
- CORS configurable con `CORS_ORIGINS` (por defecto `http://localhost:4200`).
- `/actuator/gateway/routes` muestra las rutas activas.

Variables: `EUREKA_URL`, `CORS_ORIGINS`; en la nube `AUTH_URL`, `CATALOG_URL`, ... (una por servicio).

## Ejecución

Puerto `8090`.

```bash
mvn -pl backend/api-gateway -am spring-boot:run
```
