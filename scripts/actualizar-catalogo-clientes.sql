-- ============================================================================
-- SIGIP - ACTUALIZACION DE DEMO 2026
-- Ejecutar con MySQL 8.x despues de levantar al menos catalog-service y
-- sales-service una vez. Es idempotente: puede ejecutarse mas de una vez.
--
-- Incluye:
--   1) columnas para imagen y productos personalizables
--   2) tabla de opciones por servicio
--   3) catalogo con servicios fijos/personalizables e imagenes
--   4) opciones de precio para Packaging, Gigantografia, Stickers y Polos
--   5) 15 clientes ficticios con formatos peruanos validos para demo
-- ============================================================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS sigip_catalog CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE IF NOT EXISTS sigip_sales CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- ----------------------------------------------------------------------------
-- 1. Ajuste de esquema del catalogo (compatible con una base anterior)
-- ----------------------------------------------------------------------------
SET @sql = (
    SELECT IF(COUNT(*) = 0,
        'ALTER TABLE sigip_catalog.servicio_impresion ADD COLUMN personalizable BIT(1) NOT NULL DEFAULT b''0''',
        'SELECT 1')
    FROM information_schema.columns
    WHERE table_schema = 'sigip_catalog' AND table_name = 'servicio_impresion' AND column_name = 'personalizable'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = (
    SELECT IF(COUNT(*) = 0,
        'ALTER TABLE sigip_catalog.servicio_impresion ADD COLUMN imagen_url VARCHAR(300) NULL',
        'SELECT 1')
    FROM information_schema.columns
    WHERE table_schema = 'sigip_catalog' AND table_name = 'servicio_impresion' AND column_name = 'imagen_url'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS sigip_catalog.servicio_opcion (
    idopcion INT NOT NULL AUTO_INCREMENT,
    idservicio INT NOT NULL,
    grupo VARCHAR(80) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    incremento DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    orden INT NOT NULL DEFAULT 0,
    activo BIT(1) NOT NULL DEFAULT b'1',
    PRIMARY KEY (idopcion),
    INDEX idx_servicio_opcion_servicio (idservicio),
    CONSTRAINT fk_servicio_opcion_servicio
      FOREIGN KEY (idservicio) REFERENCES sigip_catalog.servicio_impresion (idservicio)
      ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- El detalle del calculo queda guardado en el pedido.
SET @sql = (
    SELECT IF(COUNT(*) = 0,
        'ALTER TABLE sigip_sales.pedidos ADD COLUMN detalle_precio VARCHAR(1000) NULL',
        'SELECT 1')
    FROM information_schema.columns
    WHERE table_schema = 'sigip_sales' AND table_name = 'pedidos' AND column_name = 'detalle_precio'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- 2. Categorias
-- ----------------------------------------------------------------------------
INSERT INTO sigip_catalog.categoria (nombre, descripcion, activo) VALUES
('Impresión digital', 'Trabajos de pequeño formato en papel y adhesivos', b'1'),
('Gran formato', 'Banners, gigantografías y viniles', b'1'),
('Trabajos especiales', 'Empaques y productos configurables', b'1'),
('Merchandising', 'Productos promocionales personalizados', b'1')
ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion), activo = b'1';

-- ----------------------------------------------------------------------------
-- 3. Servicios. Se actualiza lo existente por nombre y se inserta lo faltante.
-- ----------------------------------------------------------------------------
UPDATE sigip_catalog.servicio_impresion s
JOIN sigip_catalog.categoria c ON c.nombre = 'Impresión digital'
SET s.descripcion='Papel couché 115 g, full color', s.precio_base=95.00,
    s.requiere_cotizacion=b'0', s.personalizable=b'0', s.imagen_url='/assets/servicios/volantes.svg',
    s.activo=b'1', s.idcategoria=c.idcategoria
WHERE s.nombre='Volantes A5 (millar)';
INSERT INTO sigip_catalog.servicio_impresion
(nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Volantes A5 (millar)', 'Papel couché 115 g, full color', 95.00, b'0', b'0', '/assets/servicios/volantes.svg', b'1', c.idcategoria
FROM sigip_catalog.categoria c
WHERE c.nombre='Impresión digital'
  AND NOT EXISTS (SELECT 1 FROM sigip_catalog.servicio_impresion s WHERE s.nombre='Volantes A5 (millar)');

UPDATE sigip_catalog.servicio_impresion s
JOIN sigip_catalog.categoria c ON c.nombre = 'Impresión digital'
SET s.descripcion='Cartulina 300 g, plastificado mate', s.precio_base=60.00,
    s.requiere_cotizacion=b'0', s.personalizable=b'0', s.imagen_url='/assets/servicios/tarjetas.svg',
    s.activo=b'1', s.idcategoria=c.idcategoria
WHERE s.nombre='Tarjetas personales (millar)';
INSERT INTO sigip_catalog.servicio_impresion
(nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Tarjetas personales (millar)', 'Cartulina 300 g, plastificado mate', 60.00, b'0', b'0', '/assets/servicios/tarjetas.svg', b'1', c.idcategoria
FROM sigip_catalog.categoria c
WHERE c.nombre='Impresión digital'
  AND NOT EXISTS (SELECT 1 FROM sigip_catalog.servicio_impresion s WHERE s.nombre='Tarjetas personales (millar)');

UPDATE sigip_catalog.servicio_impresion s
JOIN sigip_catalog.categoria c ON c.nombre = 'Impresión digital'
SET s.descripcion='Vinil adhesivo con corte', s.precio_base=45.00,
    s.requiere_cotizacion=b'0', s.personalizable=b'1', s.imagen_url='/assets/servicios/stickers.svg',
    s.activo=b'1', s.idcategoria=c.idcategoria
WHERE s.nombre='Stickers troquelados (ciento)';
INSERT INTO sigip_catalog.servicio_impresion
(nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Stickers troquelados (ciento)', 'Vinil adhesivo con corte', 45.00, b'0', b'1', '/assets/servicios/stickers.svg', b'1', c.idcategoria
FROM sigip_catalog.categoria c
WHERE c.nombre='Impresión digital'
  AND NOT EXISTS (SELECT 1 FROM sigip_catalog.servicio_impresion s WHERE s.nombre='Stickers troquelados (ciento)');

UPDATE sigip_catalog.servicio_impresion s
JOIN sigip_catalog.categoria c ON c.nombre = 'Gran formato'
SET s.descripcion='Lona 13 oz con ojales', s.precio_base=70.00,
    s.requiere_cotizacion=b'0', s.personalizable=b'0', s.imagen_url='/assets/servicios/banner.svg',
    s.activo=b'1', s.idcategoria=c.idcategoria
WHERE s.nombre='Banner 1 x 2 m';
INSERT INTO sigip_catalog.servicio_impresion
(nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Banner 1 x 2 m', 'Lona 13 oz con ojales', 70.00, b'0', b'0', '/assets/servicios/banner.svg', b'1', c.idcategoria
FROM sigip_catalog.categoria c
WHERE c.nombre='Gran formato'
  AND NOT EXISTS (SELECT 1 FROM sigip_catalog.servicio_impresion s WHERE s.nombre='Banner 1 x 2 m');

UPDATE sigip_catalog.servicio_impresion s
JOIN sigip_catalog.categoria c ON c.nombre = 'Gran formato'
SET s.descripcion='Impresión de gran formato por metro cuadrado', s.precio_base=28.00,
    s.requiere_cotizacion=b'0', s.personalizable=b'1', s.imagen_url='/assets/servicios/gigantografia.svg',
    s.activo=b'1', s.idcategoria=c.idcategoria
WHERE s.nombre='Gigantografía m2';
INSERT INTO sigip_catalog.servicio_impresion
(nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Gigantografía m2', 'Impresión de gran formato por metro cuadrado', 28.00, b'0', b'1', '/assets/servicios/gigantografia.svg', b'1', c.idcategoria
FROM sigip_catalog.categoria c
WHERE c.nombre='Gran formato'
  AND NOT EXISTS (SELECT 1 FROM sigip_catalog.servicio_impresion s WHERE s.nombre='Gigantografía m2');

UPDATE sigip_catalog.servicio_impresion s
JOIN sigip_catalog.categoria c ON c.nombre = 'Trabajos especiales'
SET s.descripcion='Cajas y empaques a medida por unidad', s.precio_base=4.50,
    s.requiere_cotizacion=b'0', s.personalizable=b'1', s.imagen_url='/assets/servicios/packaging.svg',
    s.activo=b'1', s.idcategoria=c.idcategoria
WHERE s.nombre='Packaging personalizado';
INSERT INTO sigip_catalog.servicio_impresion
(nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Packaging personalizado', 'Cajas y empaques a medida por unidad', 4.50, b'0', b'1', '/assets/servicios/packaging.svg', b'1', c.idcategoria
FROM sigip_catalog.categoria c
WHERE c.nombre='Trabajos especiales'
  AND NOT EXISTS (SELECT 1 FROM sigip_catalog.servicio_impresion s WHERE s.nombre='Packaging personalizado');

UPDATE sigip_catalog.servicio_impresion s
JOIN sigip_catalog.categoria c ON c.nombre = 'Merchandising'
SET s.descripcion='Polo de algodón con impresión DTF', s.precio_base=25.00,
    s.requiere_cotizacion=b'0', s.personalizable=b'1', s.imagen_url='/assets/servicios/polos.svg',
    s.activo=b'1', s.idcategoria=c.idcategoria
WHERE s.nombre='Polos personalizados';
INSERT INTO sigip_catalog.servicio_impresion
(nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Polos personalizados', 'Polo de algodón con impresión DTF', 25.00, b'0', b'1', '/assets/servicios/polos.svg', b'1', c.idcategoria
FROM sigip_catalog.categoria c
WHERE c.nombre='Merchandising'
  AND NOT EXISTS (SELECT 1 FROM sigip_catalog.servicio_impresion s WHERE s.nombre='Polos personalizados');

UPDATE sigip_catalog.servicio_impresion s
JOIN sigip_catalog.categoria c ON c.nombre = 'Merchandising'
SET s.descripcion='Taza cerámica sublimada', s.precio_base=18.00,
    s.requiere_cotizacion=b'0', s.personalizable=b'0', s.imagen_url='/assets/servicios/tazas.svg',
    s.activo=b'1', s.idcategoria=c.idcategoria
WHERE s.nombre='Tazas personalizadas';
INSERT INTO sigip_catalog.servicio_impresion
(nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Tazas personalizadas', 'Taza cerámica sublimada', 18.00, b'0', b'0', '/assets/servicios/tazas.svg', b'1', c.idcategoria
FROM sigip_catalog.categoria c
WHERE c.nombre='Merchandising'
  AND NOT EXISTS (SELECT 1 FROM sigip_catalog.servicio_impresion s WHERE s.nombre='Tazas personalizadas');

-- ----------------------------------------------------------------------------
-- 4. Opciones de personalizacion. Para estos cuatro servicios se reconstruyen
--    las opciones demo para garantizar precios consistentes.
-- ----------------------------------------------------------------------------
DELETE o FROM sigip_catalog.servicio_opcion o
JOIN sigip_catalog.servicio_impresion s ON s.idservicio=o.idservicio
WHERE s.nombre IN ('Gigantografía m2','Packaging personalizado','Stickers troquelados (ciento)','Polos personalizados');

-- Gigantografia
INSERT INTO sigip_catalog.servicio_opcion (idservicio, grupo, nombre, incremento, orden, activo)
SELECT s.idservicio, x.grupo, x.nombre, x.incremento, x.orden, b'1'
FROM sigip_catalog.servicio_impresion s
JOIN (
    SELECT 'Material' grupo, 'Lona frontlit' nombre, 0.00 incremento, 1 orden UNION ALL
    SELECT 'Material', 'Lona blackout', 8.00, 2 UNION ALL
    SELECT 'Material', 'Vinil adhesivo', 15.00, 3 UNION ALL
    SELECT 'Acabado', 'Sin acabado adicional', 0.00, 1 UNION ALL
    SELECT 'Acabado', 'Ojales reforzados', 4.00, 2 UNION ALL
    SELECT 'Acabado', 'Bastidor', 20.00, 3
) x
WHERE s.nombre='Gigantografía m2';

-- Packaging
INSERT INTO sigip_catalog.servicio_opcion (idservicio, grupo, nombre, incremento, orden, activo)
SELECT s.idservicio, x.grupo, x.nombre, x.incremento, x.orden, b'1'
FROM sigip_catalog.servicio_impresion s
JOIN (
    SELECT 'Tamaño' grupo, 'Pequeño' nombre, 0.00 incremento, 1 orden UNION ALL
    SELECT 'Tamaño', 'Mediano', 0.80, 2 UNION ALL
    SELECT 'Tamaño', 'Grande', 1.80, 3 UNION ALL
    SELECT 'Material', 'Cartulina SBS', 0.00, 1 UNION ALL
    SELECT 'Material', 'Kraft', 1.00, 2 UNION ALL
    SELECT 'Material', 'Microcorrugado', 1.50, 3 UNION ALL
    SELECT 'Acabado', 'Sin laminado', 0.00, 1 UNION ALL
    SELECT 'Acabado', 'Laminado mate', 0.90, 2 UNION ALL
    SELECT 'Acabado', 'Barniz UV', 1.20, 3
) x
WHERE s.nombre='Packaging personalizado';

-- Stickers
INSERT INTO sigip_catalog.servicio_opcion (idservicio, grupo, nombre, incremento, orden, activo)
SELECT s.idservicio, x.grupo, x.nombre, x.incremento, x.orden, b'1'
FROM sigip_catalog.servicio_impresion s
JOIN (
    SELECT 'Material' grupo, 'Vinil blanco' nombre, 0.00 incremento, 1 orden UNION ALL
    SELECT 'Material', 'Vinil transparente', 8.00, 2 UNION ALL
    SELECT 'Material', 'Vinil reflectivo', 15.00, 3 UNION ALL
    SELECT 'Corte', 'Corte estándar', 0.00, 1 UNION ALL
    SELECT 'Corte', 'Troquelado especial', 10.00, 2 UNION ALL
    SELECT 'Laminado', 'Sin laminado', 0.00, 1 UNION ALL
    SELECT 'Laminado', 'Laminado mate', 6.00, 2 UNION ALL
    SELECT 'Laminado', 'Laminado brillante', 6.00, 3
) x
WHERE s.nombre='Stickers troquelados (ciento)';

-- Polos
INSERT INTO sigip_catalog.servicio_opcion (idservicio, grupo, nombre, incremento, orden, activo)
SELECT s.idservicio, x.grupo, x.nombre, x.incremento, x.orden, b'1'
FROM sigip_catalog.servicio_impresion s
JOIN (
    SELECT 'Talla' grupo, 'S' nombre, 0.00 incremento, 1 orden UNION ALL
    SELECT 'Talla', 'M', 0.00, 2 UNION ALL
    SELECT 'Talla', 'L', 1.50, 3 UNION ALL
    SELECT 'Talla', 'XL', 2.50, 4 UNION ALL
    SELECT 'Color', 'Blanco', 0.00, 1 UNION ALL
    SELECT 'Color', 'Negro', 1.50, 2 UNION ALL
    SELECT 'Color', 'Azul marino', 1.50, 3 UNION ALL
    SELECT 'Impresión', 'Pecho', 0.00, 1 UNION ALL
    SELECT 'Impresión', 'Pecho + espalda', 8.00, 2
) x
WHERE s.nombre='Polos personalizados';

-- ----------------------------------------------------------------------------
-- 5. Clientes de demostracion.
--    Todos son FICTICIOS. Los RUC tienen 11 digitos y digito verificador valido;
--    los DNI tienen formato numerico de 8 digitos. Correos example.com/.demo.
-- ----------------------------------------------------------------------------
INSERT INTO sigip_sales.clientes
(tipo_documento, numero_documento, razon_social, contacto, telefono, email, direccion, activo, fecha_registro, fecha_actualizacion)
VALUES
('RUC','20481234566','Comercial Norte SAC','Andrea Torres','944562311','ventas@comercialnorte.demo','Av. América Norte 1420, Trujillo',b'1',NOW(),NULL),
('RUC','20547891237','Distribuidora El Pacífico EIRL','Luis Mendoza','961447852','pedidos@elpacifico.demo','Jr. Pizarro 845, Trujillo',b'1',NOW(),NULL),
('RUC','20614578905','Inversiones Santa Isabel SAC','María Paredes','987561204','compras@santaisabel.demo','Av. Larco 780, Víctor Larco',b'1',NOW(),NULL),
('RUC','20596325875','Corporación Gráfica del Norte SAC','Jorge Reyes','972884115','contacto@graficanorte.demo','Av. Nicolás de Piérola 1180, Trujillo',b'1',NOW(),NULL),
('RUC','20625874131','Agroexportadora Moche SAC','Rosa Vásquez','955214783','logistica@agromoche.demo','Carretera Industrial Km 3.5, Moche',b'1',NOW(),NULL),
('RUC','20456987126','Tecnología y Oficina Perú SAC','Miguel Salazar','966741225','operaciones@toficina.demo','Urb. California Mz. F Lt. 12, Trujillo',b'1',NOW(),NULL),
('RUC','20687412355','Restaurante Sabor Norteño SAC','Paola Chávez','978332110','administracion@sabornorteno.demo','Av. España 520, Trujillo',b'1',NOW(),NULL),
('RUC','20574123691','Clínica San Gabriel EIRL','Diana Cabrera','949885671','marketing@csangabriel.demo','Jr. Bolívar 1122, Trujillo',b'1',NOW(),NULL),
('RUC','20633214582','Eventos y Publicidad Impacto SAC','Fernando León','981236547','ventas@impactosac.demo','Av. Fátima 1325, Víctor Larco',b'1',NOW(),NULL),
('DNI','45871236','Carlos Ríos Calderón','Carlos Ríos','987654321','carlos.rios@example.com','Urb. San Andrés, Trujillo',b'1',NOW(),NULL),
('DNI','74125896','María Fernanda Castillo Ruiz','María Castillo','955332781','maria.castillo@example.com','Urb. Primavera, Trujillo',b'1',NOW(),NULL),
('DNI','60321478','José Luis Gamarra Soto','José Gamarra','964220517','jose.gamarra@example.com','Florencia de Mora, Trujillo',b'1',NOW(),NULL),
('DNI','71589632','Rocío Alexandra Peña Vega','Rocío Peña','979114320','rocio.pena@example.com','Urb. Monserrate, Trujillo',b'1',NOW(),NULL),
('DNI','48231597','Diego Armando Rojas Silva','Diego Rojas','951778430','diego.rojas@example.com','Jr. Junín 680, Trujillo',b'1',NOW(),NULL),
('DNI','73698514','Valeria Soto Ramírez','Valeria Soto','943112870','valeria.soto@example.com','La Esperanza, Trujillo',b'1',NOW(),NULL)
ON DUPLICATE KEY UPDATE
    razon_social=VALUES(razon_social),
    contacto=VALUES(contacto),
    telefono=VALUES(telefono),
    email=VALUES(email),
    direccion=VALUES(direccion),
    activo=b'1',
    fecha_actualizacion=NOW();

-- ----------------------------------------------------------------------------
-- 6. Comprobacion rapida
-- ----------------------------------------------------------------------------
SELECT 'CLIENTES_ACTIVOS' AS dato, COUNT(*) AS cantidad FROM sigip_sales.clientes WHERE activo=b'1';
SELECT 'SERVICIOS_ACTIVOS' AS dato, COUNT(*) AS cantidad FROM sigip_catalog.servicio_impresion WHERE activo=b'1';
SELECT 'SERVICIOS_PERSONALIZABLES' AS dato, COUNT(*) AS cantidad FROM sigip_catalog.servicio_impresion WHERE activo=b'1' AND personalizable=b'1';
SELECT 'OPCIONES_PRECIO' AS dato, COUNT(*) AS cantidad FROM sigip_catalog.servicio_opcion WHERE activo=b'1';
