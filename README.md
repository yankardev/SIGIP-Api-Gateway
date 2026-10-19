# SIGIP API Gateway

Puerta de entrada HTTP para los microservicios del Sistema Integral de Gestión de Impresión y Pedidos (SIGIP).

## Requisitos
- JDK 21
- IntelliJ IDEA con soporte Maven
- SIGIP Discovery Server disponible en http://localhost:8761

## Puerto
- API Gateway: http://localhost:8090

## Rutas configuradas
- `/api/auth/**` → Auth Service
- `/api/catalogo/**` → Catalog Service
- `/api/pedidos/**` y `/api/pagos/**` → Sales Service
- `/api/disenos/**` → Design Service
- `/api/produccion/**` → Production Service
- `/api/inventario/**` → Inventory Service
- `/api/notificaciones/**` → Notification Service
- `/api/reportes/**` → Report Service

Las rutas usan descubrimiento de servicios mediante Eureka. Cada microservicio debe registrarse en Eureka con el nombre correspondiente y exponer los paths indicados.

## Ejecución
Abrir `pom.xml` en IntelliJ, cargar el proyecto Maven y ejecutar `ApiGatewayApplication`.
