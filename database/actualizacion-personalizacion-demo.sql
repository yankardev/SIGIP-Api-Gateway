-- =============================================================
-- SIGIP - ACTUALIZACION DEMO: catalogo visual + personalizacion
-- Ejecutar con los servicios detenidos o ya levantados una vez.
-- Compatible con MySQL 8.x. Idempotente: puede ejecutarse mas de una vez.
-- =============================================================

CREATE DATABASE IF NOT EXISTS sigip_catalog CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE IF NOT EXISTS sigip_sales CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- -------------------------------------------------------------
-- 1. ESTRUCTURA CATALOGO
-- -------------------------------------------------------------
USE sigip_catalog;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA='sigip_catalog' AND TABLE_NAME='servicio_impresion' AND COLUMN_NAME='personalizable') = 0,
  'ALTER TABLE servicio_impresion ADD COLUMN personalizable BIT NOT NULL DEFAULT 0',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA='sigip_catalog' AND TABLE_NAME='servicio_impresion' AND COLUMN_NAME='imagen_url') = 0,
  'ALTER TABLE servicio_impresion ADD COLUMN imagen_url VARCHAR(300) NULL',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

CREATE TABLE IF NOT EXISTS servicio_opcion (
  idopcion INT NOT NULL AUTO_INCREMENT,
  idservicio INT NOT NULL,
  grupo VARCHAR(80) NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  incremento DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  orden INT NOT NULL DEFAULT 0,
  activo BIT NOT NULL DEFAULT 1,
  PRIMARY KEY (idopcion),
  KEY idx_opcion_servicio (idservicio),
  CONSTRAINT fk_opcion_servicio FOREIGN KEY (idservicio)
    REFERENCES servicio_impresion(idservicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Categorias
INSERT IGNORE INTO categoria (nombre, descripcion, activo) VALUES
('Impresión digital','Trabajos de pequeño formato en papel y adhesivos',1),
('Gran formato','Banners, gigantografías y viniles',1),
('Trabajos especiales','Empaques y productos configurables',1),
('Merchandising','Productos promocionales personalizados',1);

-- Servicios: insertar si no existen
INSERT INTO servicio_impresion (nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Volantes A5 (millar)','Papel couché 115 g, full color',95.00,0,0,'/assets/servicios/volantes.svg',1,idcategoria
FROM categoria WHERE nombre='Impresión digital'
AND NOT EXISTS (SELECT 1 FROM servicio_impresion WHERE nombre='Volantes A5 (millar)');

INSERT INTO servicio_impresion (nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Tarjetas personales (millar)','Cartulina 300 g, plastificado mate',60.00,0,0,'/assets/servicios/tarjetas.svg',1,idcategoria
FROM categoria WHERE nombre='Impresión digital'
AND NOT EXISTS (SELECT 1 FROM servicio_impresion WHERE nombre='Tarjetas personales (millar)');

INSERT INTO servicio_impresion (nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Stickers troquelados (ciento)','Vinil adhesivo con corte',45.00,0,1,'/assets/servicios/stickers.svg',1,idcategoria
FROM categoria WHERE nombre='Impresión digital'
AND NOT EXISTS (SELECT 1 FROM servicio_impresion WHERE nombre='Stickers troquelados (ciento)');

INSERT INTO servicio_impresion (nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Banner 1 x 2 m','Lona 13 oz con ojales',70.00,0,0,'/assets/servicios/banner.svg',1,idcategoria
FROM categoria WHERE nombre='Gran formato'
AND NOT EXISTS (SELECT 1 FROM servicio_impresion WHERE nombre='Banner 1 x 2 m');

INSERT INTO servicio_impresion (nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Gigantografía m2','Impresión de gran formato por metro cuadrado',28.00,0,1,'/assets/servicios/gigantografia.svg',1,idcategoria
FROM categoria WHERE nombre='Gran formato'
AND NOT EXISTS (SELECT 1 FROM servicio_impresion WHERE nombre='Gigantografía m2');

INSERT INTO servicio_impresion (nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Packaging personalizado','Cajas y empaques a medida por unidad',4.50,0,1,'/assets/servicios/packaging.svg',1,idcategoria
FROM categoria WHERE nombre='Trabajos especiales'
AND NOT EXISTS (SELECT 1 FROM servicio_impresion WHERE nombre='Packaging personalizado');

INSERT INTO servicio_impresion (nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Polos personalizados','Polo de algodón con impresión DTF',25.00,0,1,'/assets/servicios/polos.svg',1,idcategoria
FROM categoria WHERE nombre='Merchandising'
AND NOT EXISTS (SELECT 1 FROM servicio_impresion WHERE nombre='Polos personalizados');

INSERT INTO servicio_impresion (nombre, descripcion, precio_base, requiere_cotizacion, personalizable, imagen_url, activo, idcategoria)
SELECT 'Tazas personalizadas','Taza cerámica sublimada',18.00,0,0,'/assets/servicios/tazas.svg',1,idcategoria
FROM categoria WHERE nombre='Merchandising'
AND NOT EXISTS (SELECT 1 FROM servicio_impresion WHERE nombre='Tazas personalizadas');

-- Normalizar servicios conocidos de una base existente
UPDATE servicio_impresion SET precio_base=95.00, requiere_cotizacion=0, personalizable=0, imagen_url='/assets/servicios/volantes.svg', activo=1 WHERE nombre='Volantes A5 (millar)';
UPDATE servicio_impresion SET precio_base=60.00, requiere_cotizacion=0, personalizable=0, imagen_url='/assets/servicios/tarjetas.svg', activo=1 WHERE nombre='Tarjetas personales (millar)';
UPDATE servicio_impresion SET precio_base=45.00, requiere_cotizacion=0, personalizable=1, imagen_url='/assets/servicios/stickers.svg', activo=1 WHERE nombre='Stickers troquelados (ciento)';
UPDATE servicio_impresion SET precio_base=70.00, requiere_cotizacion=0, personalizable=0, imagen_url='/assets/servicios/banner.svg', activo=1 WHERE nombre='Banner 1 x 2 m';
UPDATE servicio_impresion SET precio_base=28.00, requiere_cotizacion=0, personalizable=1, imagen_url='/assets/servicios/gigantografia.svg', activo=1 WHERE nombre='Gigantografía m2';
UPDATE servicio_impresion SET precio_base=4.50, requiere_cotizacion=0, personalizable=1, imagen_url='/assets/servicios/packaging.svg', activo=1 WHERE nombre='Packaging personalizado';
UPDATE servicio_impresion SET precio_base=25.00, requiere_cotizacion=0, personalizable=1, imagen_url='/assets/servicios/polos.svg', activo=1 WHERE nombre='Polos personalizados';
UPDATE servicio_impresion SET precio_base=18.00, requiere_cotizacion=0, personalizable=0, imagen_url='/assets/servicios/tazas.svg', activo=1 WHERE nombre='Tazas personalizadas';

-- Procedimiento temporal para insertar opciones sin duplicar
DROP PROCEDURE IF EXISTS agregar_opcion_demo;
DELIMITER $$
CREATE PROCEDURE agregar_opcion_demo(
  IN p_servicio VARCHAR(150), IN p_grupo VARCHAR(80), IN p_nombre VARCHAR(120),
  IN p_incremento DECIMAL(12,2), IN p_orden INT
)
BEGIN
  DECLARE v_id INT;
  SELECT idservicio INTO v_id FROM servicio_impresion WHERE nombre=p_servicio ORDER BY idservicio LIMIT 1;
  IF v_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM servicio_opcion WHERE idservicio=v_id AND grupo=p_grupo AND nombre=p_nombre
  ) THEN
    INSERT INTO servicio_opcion(idservicio,grupo,nombre,incremento,orden,activo)
    VALUES(v_id,p_grupo,p_nombre,p_incremento,p_orden,1);
  END IF;
END$$
DELIMITER ;

CALL agregar_opcion_demo('Gigantografía m2','Material','Lona frontlit',0.00,1);
CALL agregar_opcion_demo('Gigantografía m2','Material','Lona blackout',8.00,2);
CALL agregar_opcion_demo('Gigantografía m2','Material','Vinil adhesivo',15.00,3);
CALL agregar_opcion_demo('Gigantografía m2','Acabado','Sin acabado adicional',0.00,1);
CALL agregar_opcion_demo('Gigantografía m2','Acabado','Ojales reforzados',4.00,2);
CALL agregar_opcion_demo('Gigantografía m2','Acabado','Bastidor',20.00,3);

CALL agregar_opcion_demo('Packaging personalizado','Tamaño','Pequeño',0.00,1);
CALL agregar_opcion_demo('Packaging personalizado','Tamaño','Mediano',0.80,2);
CALL agregar_opcion_demo('Packaging personalizado','Tamaño','Grande',1.80,3);
CALL agregar_opcion_demo('Packaging personalizado','Material','Cartulina SBS',0.00,1);
CALL agregar_opcion_demo('Packaging personalizado','Material','Kraft',1.00,2);
CALL agregar_opcion_demo('Packaging personalizado','Material','Microcorrugado',1.50,3);
CALL agregar_opcion_demo('Packaging personalizado','Acabado','Sin laminado',0.00,1);
CALL agregar_opcion_demo('Packaging personalizado','Acabado','Laminado mate',0.90,2);
CALL agregar_opcion_demo('Packaging personalizado','Acabado','Barniz UV',1.20,3);

CALL agregar_opcion_demo('Stickers troquelados (ciento)','Material','Vinil blanco',0.00,1);
CALL agregar_opcion_demo('Stickers troquelados (ciento)','Material','Vinil transparente',8.00,2);
CALL agregar_opcion_demo('Stickers troquelados (ciento)','Material','Vinil reflectivo',15.00,3);
CALL agregar_opcion_demo('Stickers troquelados (ciento)','Corte','Corte estándar',0.00,1);
CALL agregar_opcion_demo('Stickers troquelados (ciento)','Corte','Troquelado especial',10.00,2);
CALL agregar_opcion_demo('Stickers troquelados (ciento)','Laminado','Sin laminado',0.00,1);
CALL agregar_opcion_demo('Stickers troquelados (ciento)','Laminado','Laminado mate',6.00,2);
CALL agregar_opcion_demo('Stickers troquelados (ciento)','Laminado','Laminado brillante',6.00,3);

CALL agregar_opcion_demo('Polos personalizados','Talla','S',0.00,1);
CALL agregar_opcion_demo('Polos personalizados','Talla','M',0.00,2);
CALL agregar_opcion_demo('Polos personalizados','Talla','L',1.50,3);
CALL agregar_opcion_demo('Polos personalizados','Talla','XL',2.50,4);
CALL agregar_opcion_demo('Polos personalizados','Color','Blanco',0.00,1);
CALL agregar_opcion_demo('Polos personalizados','Color','Negro',1.50,2);
CALL agregar_opcion_demo('Polos personalizados','Color','Azul marino',1.50,3);
CALL agregar_opcion_demo('Polos personalizados','Impresión','Pecho',0.00,1);
CALL agregar_opcion_demo('Polos personalizados','Impresión','Pecho + espalda',8.00,2);
DROP PROCEDURE IF EXISTS agregar_opcion_demo;

-- -------------------------------------------------------------
-- 2. ESTRUCTURA Y DATOS DE VENTAS
-- -------------------------------------------------------------
USE sigip_sales;

SET @sql = IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA='sigip_sales' AND TABLE_NAME='pedidos' AND COLUMN_NAME='detalle_precio') = 0,
  'ALTER TABLE pedidos ADD COLUMN detalle_precio VARCHAR(1000) NULL',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 15 clientes de demostración. Los nombres son ficticios y los datos tienen formato peruano válido.
INSERT INTO clientes
(tipo_documento, numero_documento, razon_social, contacto, telefono, email, direccion, activo, fecha_registro)
VALUES
('RUC','20481234566','Comercial Norte SAC','Andrea Torres','944562311','ventas@comercialnorte.demo','Av. América Norte 1420, Trujillo',1,NOW()),
('RUC','20547891237','Distribuidora El Pacífico EIRL','Luis Mendoza','961447852','pedidos@elpacifico.demo','Jr. Pizarro 845, Trujillo',1,NOW()),
('RUC','20614578905','Inversiones Santa Isabel SAC','María Paredes','987561204','compras@santaisabel.demo','Av. Larco 780, Víctor Larco',1,NOW()),
('RUC','20596325875','Corporación Gráfica del Norte SAC','Jorge Reyes','972884115','contacto@graficanorte.demo','Av. Nicolás de Piérola 1180, Trujillo',1,NOW()),
('RUC','20625874131','Agroexportadora Moche SAC','Rosa Vásquez','955214783','logistica@agromoche.demo','Carretera Industrial Km 3.5, Moche',1,NOW()),
('RUC','20456987126','Tecnología y Oficina Perú SAC','Miguel Salazar','966741225','operaciones@toficina.demo','Urb. California Mz. F Lt. 12, Trujillo',1,NOW()),
('RUC','20687412355','Restaurante Sabor Norteño SAC','Paola Chávez','978332110','administracion@sabornorteno.demo','Av. España 520, Trujillo',1,NOW()),
('RUC','20574123691','Clínica San Gabriel EIRL','Diana Cabrera','949885671','marketing@csangabriel.demo','Jr. Bolívar 1122, Trujillo',1,NOW()),
('RUC','20633214582','Eventos y Publicidad Impacto SAC','Fernando León','981236547','ventas@impactosac.demo','Av. Fátima 1325, Víctor Larco',1,NOW()),
('DNI','45871236','Carlos Ríos Calderón','Carlos Ríos','987654321','carlos.rios@example.com','Urb. San Andrés, Trujillo',1,NOW()),
('DNI','74125896','María Fernanda Castillo Ruiz','María Castillo','955332781','maria.castillo@example.com','Urb. Primavera, Trujillo',1,NOW()),
('DNI','60321478','José Luis Gamarra Soto','José Gamarra','964220517','jose.gamarra@example.com','Florencia de Mora, Trujillo',1,NOW()),
('DNI','71589632','Rocío Alexandra Peña Vega','Rocío Peña','979114320','rocio.pena@example.com','Urb. Monserrate, Trujillo',1,NOW()),
('DNI','48231597','Diego Armando Rojas Silva','Diego Rojas','951778430','diego.rojas@example.com','Jr. Junín 680, Trujillo',1,NOW()),
('DNI','73698514','Valeria Soto Ramírez','Valeria Soto','943112870','valeria.soto@example.com','La Esperanza, Trujillo',1,NOW())
ON DUPLICATE KEY UPDATE
razon_social=VALUES(razon_social), contacto=VALUES(contacto), telefono=VALUES(telefono),
email=VALUES(email), direccion=VALUES(direccion), activo=1;

-- Verificación rápida
SELECT 'SERVICIOS' AS bloque, COUNT(*) AS cantidad FROM sigip_catalog.servicio_impresion WHERE activo=1;
SELECT 'OPCIONES_PERSONALIZACION' AS bloque, COUNT(*) AS cantidad FROM sigip_catalog.servicio_opcion WHERE activo=1;
SELECT 'CLIENTES_DEMO' AS bloque, COUNT(*) AS cantidad FROM sigip_sales.clientes WHERE activo=1;
