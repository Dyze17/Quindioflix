-- =========================================================
-- QUINDIOFLIX - ENTREGA 3
-- Script 06: Nucleo 4 - Indices
--   4.1 Creacion y administracion de indices (minimo 4)
--   4.2 Analisis de rendimiento con EXPLAIN PLAN
-- =========================================================

SET SERVEROUTPUT ON SIZE 1000000;
SET LINESIZE 200;
SET PAGESIZE 100;

-- Columna para el plan de ejecucion
COLUMN PLAN_TABLE_OUTPUT FORMAT A180;

PROMPT =====================================================
PROMPT LIMPIEZA PREVIA DE INDICES
PROMPT =====================================================

BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_rep_perfil_fecha';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_usr_email_lower';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_cont_categoria_anio';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP INDEX idx_pagos_usuario_estado';   EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT =====================================================
PROMPT 4.2 ANALISIS DE RENDIMIENTO - ANTES DE LOS INDICES
PROMPT =====================================================

-- -------------------------------------------------------
-- CONSULTA DE REFERENCIA (la misma se ejecutara despues
-- de crear los indices para comparar el plan de ejecucion)
--
-- Consulta: Historial completo de reproducciones de un
-- perfil ordenado por fecha, con titulo y dispositivo.
-- Es la consulta mas frecuente en el sistema (historial
-- de "Seguir viendo" de un usuario).
-- -------------------------------------------------------

PROMPT ----------------------------------------------------------
PROMPT EXPLAIN PLAN ANTES - Historial de reproducciones perfil 1
PROMPT ----------------------------------------------------------

EXPLAIN PLAN
SET STATEMENT_ID = 'ANTES_IDX'
FOR
    SELECT
        r.id_reproduccion,
        c.titulo,
        r.fecha_hora_inicio,
        r.dispositivo,
        r.porcentaje_avance
    FROM reproducciones r
    JOIN contenido c ON c.id_contenido = r.id_contenido
    WHERE r.id_perfil = 1
    ORDER BY r.fecha_hora_inicio DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    table_name  => 'PLAN_TABLE',
    statement_id => 'ANTES_IDX',
    format       => 'ALL'
));

-- -------------------------------------------------------
-- CONSULTA DE REFERENCIA 2: Login por email (case-insensitive)
-- Tambien se medira antes/despues del indice funcional.
-- -------------------------------------------------------

PROMPT ----------------------------------------------------------
PROMPT EXPLAIN PLAN ANTES - Busqueda de usuario por email
PROMPT ----------------------------------------------------------

EXPLAIN PLAN
SET STATEMENT_ID = 'ANTES_EMAIL'
FOR
    SELECT id_usuario, nombres, apellidos, estado_cuenta
      FROM usuarios
     WHERE LOWER(email) = LOWER('usuario5@correo.com');

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    table_name   => 'PLAN_TABLE',
    statement_id => 'ANTES_EMAIL',
    format       => 'ALL'
));

PROMPT =====================================================
PROMPT 4.1 CREACION DE INDICES
PROMPT =====================================================

-- -------------------------------------------------------
-- INDICE 1: REPRODUCCIONES(id_perfil, fecha_hora_inicio)
-- -------------------------------------------------------
-- JUSTIFICACION:
--   La consulta de historial de reproduccion de un perfil
--   (pantalla "Seguir viendo") filtra por id_perfil y
--   ordena por fecha_hora_inicio DESC.
--   Sin indice, Oracle hace FULL TABLE SCAN sobre
--   REPRODUCCIONES (200+ filas, creciendo diariamente).
--   El indice compuesto permite:
--     1) Localizar las filas del perfil por id_perfil (primer prefijo).
--     2) Devolver las filas ya ordenadas por fecha_hora_inicio
--        (evita un ORDER BY costoso con SORT).
--   Al ser la tabla particionada por rango de fechas,
--   el optimizador ademas hace PARTITION PRUNING para
--   limitar la busqueda a la particion correcta.
--   Selectividad alta: cada perfil tiene pocas filas
--   respecto al total de la tabla.
-- -------------------------------------------------------

CREATE INDEX idx_rep_perfil_fecha
    ON reproducciones (id_perfil, fecha_hora_inicio DESC)
    LOCAL;   -- LOCAL: un segmento de indice por cada particion de la tabla

-- -------------------------------------------------------
-- INDICE 2: USUARIOS - indice funcional LOWER(email)
-- -------------------------------------------------------
-- JUSTIFICACION:
--   El proceso de login normaliza el email con LOWER()
--   para hacer la comparacion case-insensitive.
--   La tabla ya tiene un UNIQUE INDEX sobre email (creado
--   por la constraint uq_usuarios_email), pero ese indice
--   NO se usa cuando la clausula WHERE aplica LOWER():
--     WHERE LOWER(email) = LOWER('x@y.com')
--   Un indice funcional sobre LOWER(email) permite al
--   optimizador hacer INDEX UNIQUE SCAN (costo ~1) en
--   lugar de FULL TABLE SCAN (costo proporcional a N).
--   Critico para la escalabilidad: con 30 usuarios el
--   FTS es rapido, pero con miles de usuarios la diferencia
--   es de ordenes de magnitud.
-- -------------------------------------------------------

CREATE UNIQUE INDEX idx_usr_email_lower
    ON usuarios (LOWER(email));


-- -------------------------------------------------------
-- INDICE 3: CONTENIDO(id_categoria, anio_lanzamiento)
-- -------------------------------------------------------
-- JUSTIFICACION:
--   Las busquedas del catalogo siempre filtran por
--   categoria (PELICULA, SERIE, etc.) y frecuentemente
--   agregan un rango de anios ("peliculas desde 2020").
--   El indice compuesto sirve como:
--     - Indice de prefijo para consultas solo por categoria.
--     - Indice completo para consultas por categoria + anio.
--   Evita FULL SCAN sobre CONTENIDO en las consultas de
--   navegacion del catalogo, que son las mas frecuentes
--   de toda la plataforma.
--   La cardinalidad del primer campo (5 categorias) es baja,
--   pero combinada con anio_lanzamiento la selectividad
--   del indice compuesto es alta y eficiente.
-- -------------------------------------------------------

CREATE INDEX idx_cont_categoria_anio
    ON contenido (id_categoria, anio_lanzamiento);


-- -------------------------------------------------------
-- INDICE 4 (adicional): PAGOS(id_usuario, estado_pago)
-- -------------------------------------------------------
-- JUSTIFICACION:
--   Dos consultas criticas del sistema acceden a PAGOS
--   filtrando por id_usuario + estado_pago:
--     a) sp_cambiar_plan: verifica si el usuario tiene
--        pagos EXITOSOS antes de procesar el cambio.
--     b) El trigger trg_pago_activa_cuenta: consulta
--        pagos EXITOSOS del usuario para actualizar fechas.
--     c) Los reportes financieros (MV mv_ingresos_mensuales)
--        filtran WHERE estado_pago = 'EXITOSO' sin fijar
--        usuario, usando solo el segundo campo del indice
--        (skip-scan posible en Oracle).
--   Sin el indice, cada consulta hace FTS sobre 80+ pagos.
--   El indice convierte esas operaciones en INDEX RANGE SCAN
--   con un subconjunto muy pequeno de bloques leidos.
-- -------------------------------------------------------

CREATE INDEX idx_pagos_usuario_estado
    ON pagos (id_usuario, estado_pago);


PROMPT =====================================================
PROMPT VERIFICACION DE INDICES CREADOS
PROMPT =====================================================

COLUMN index_name  FORMAT A30
COLUMN table_name  FORMAT A20
COLUMN index_type  FORMAT A15
COLUMN uniqueness  FORMAT A10
COLUMN status      FORMAT A10
COLUMN partitioned FORMAT A12

SELECT
    index_name,
    table_name,
    index_type,
    uniqueness,
    status,
    partitioned
FROM user_indexes
WHERE index_name IN (
    'IDX_REP_PERFIL_FECHA',
    'IDX_USR_EMAIL_LOWER',
    'IDX_CONT_CATEGORIA_ANIO',
    'IDX_PAGOS_USUARIO_ESTADO'
)
ORDER BY table_name, index_name;

-- Columnas de cada indice
COLUMN column_name  FORMAT A30
COLUMN column_position FORMAT 999
COLUMN descend FORMAT A5

SELECT
    index_name,
    column_position,
    column_name,
    descend
FROM user_ind_columns
WHERE index_name IN (
    'IDX_REP_PERFIL_FECHA',
    'IDX_USR_EMAIL_LOWER',
    'IDX_CONT_CATEGORIA_ANIO',
    'IDX_PAGOS_USUARIO_ESTADO'
)
ORDER BY index_name, column_position;

PROMPT =====================================================
PROMPT 4.2 ANALISIS DE RENDIMIENTO - DESPUES DE LOS INDICES
PROMPT =====================================================

-- -------------------------------------------------------
-- EXPLICACION DE LA COMPARACION:
--   ANTES -> El optimizador no tenia los indices.
--            Esperamos ver: TABLE ACCESS FULL.
--   DESPUES -> Con los indices creados.
--              Esperamos ver: INDEX RANGE SCAN (o UNIQUE SCAN).
--   La metrica clave es el campo "Cost" en el plan.
--   Un menor costo = menos bloques leidos = mejor rendimiento.
-- -------------------------------------------------------

PROMPT ----------------------------------------------------------
PROMPT EXPLAIN PLAN DESPUES - Historial de reproducciones perfil 1
PROMPT (Debe mostrar INDEX RANGE SCAN en idx_rep_perfil_fecha)
PROMPT ----------------------------------------------------------

EXPLAIN PLAN
SET STATEMENT_ID = 'DESPUES_IDX'
FOR
    SELECT
        r.id_reproduccion,
        c.titulo,
        r.fecha_hora_inicio,
        r.dispositivo,
        r.porcentaje_avance
    FROM reproducciones r
    JOIN contenido c ON c.id_contenido = r.id_contenido
    WHERE r.id_perfil = 1
    ORDER BY r.fecha_hora_inicio DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    table_name   => 'PLAN_TABLE',
    statement_id => 'DESPUES_IDX',
    format       => 'ALL'
));

PROMPT ----------------------------------------------------------
PROMPT EXPLAIN PLAN DESPUES - Busqueda de usuario por email
PROMPT (Debe mostrar INDEX UNIQUE SCAN en idx_usr_email_lower)
PROMPT ----------------------------------------------------------

EXPLAIN PLAN
SET STATEMENT_ID = 'DESPUES_EMAIL'
FOR
    SELECT id_usuario, nombres, apellidos, estado_cuenta
      FROM usuarios
     WHERE LOWER(email) = LOWER('usuario5@correo.com');

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    table_name   => 'PLAN_TABLE',
    statement_id => 'DESPUES_EMAIL',
    format       => 'ALL'
));

PROMPT ----------------------------------------------------------
PROMPT EXPLAIN PLAN - Busqueda catalogo por categoria y anio
PROMPT (Debe mostrar INDEX RANGE SCAN en idx_cont_categoria_anio)
PROMPT ----------------------------------------------------------

EXPLAIN PLAN
SET STATEMENT_ID = 'DESPUES_CAT'
FOR
    SELECT id_contenido, titulo, anio_lanzamiento, clasificacion_edad
      FROM contenido
     WHERE id_categoria      = 1
       AND anio_lanzamiento >= 2020
     ORDER BY anio_lanzamiento DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    table_name   => 'PLAN_TABLE',
    statement_id => 'DESPUES_CAT',
    format       => 'ALL'
));

PROMPT ----------------------------------------------------------
PROMPT EXPLAIN PLAN - Pagos exitosos de un usuario
PROMPT (Debe mostrar INDEX RANGE SCAN en idx_pagos_usuario_estado)
PROMPT ----------------------------------------------------------

EXPLAIN PLAN
SET STATEMENT_ID = 'DESPUES_PAG'
FOR
    SELECT id_pago, fecha_pago, monto_pagado, metodo_pago
      FROM pagos
     WHERE id_usuario  = 5
       AND estado_pago = 'EXITOSO'
     ORDER BY fecha_pago DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(
    table_name   => 'PLAN_TABLE',
    statement_id => 'DESPUES_PAG',
    format       => 'ALL'
));

PROMPT =====================================================
PROMPT RESUMEN COMPARATIVO DE RENDIMIENTO
PROMPT =====================================================

-- Tabla comparativa de los planes ANTES vs DESPUES para el informe
SELECT
    s.statement_id                                      AS escenario,
    o.operation || ' ' || NVL(o.options,'')            AS operacion,
    o.object_name                                       AS objeto,
    o.cost                                              AS costo,
    o.cardinality                                       AS cardinalidad
FROM plan_table o
JOIN (
    SELECT DISTINCT statement_id FROM plan_table
     WHERE statement_id IN ('ANTES_IDX','DESPUES_IDX','ANTES_EMAIL','DESPUES_EMAIL')
) s ON s.statement_id = o.statement_id
WHERE o.operation IN ('TABLE ACCESS','INDEX')
ORDER BY o.statement_id, o.id;

PROMPT =====================================================
PROMPT ESTADISTICAS DE LOS INDICES
PROMPT =====================================================

-- Actualizar estadisticas para que el optimizador los use correctamente
BEGIN
    DBMS_STATS.GATHER_INDEX_STATS(
        ownname    => USER,
        indname    => 'IDX_REP_PERFIL_FECHA'
    );
    DBMS_STATS.GATHER_INDEX_STATS(
        ownname    => USER,
        indname    => 'IDX_USR_EMAIL_LOWER'
    );
    DBMS_STATS.GATHER_INDEX_STATS(
        ownname    => USER,
        indname    => 'IDX_CONT_CATEGORIA_ANIO'
    );
    DBMS_STATS.GATHER_INDEX_STATS(
        ownname    => USER,
        indname    => 'IDX_PAGOS_USUARIO_ESTADO'
    );
    DBMS_OUTPUT.PUT_LINE('Estadisticas de indices actualizadas correctamente.');
END;
/

-- Ver estadisticas actualizadas
COLUMN index_name        FORMAT A28
COLUMN blevel            FORMAT 999
COLUMN leaf_blocks       FORMAT 9999
COLUMN distinct_keys     FORMAT 9999999
COLUMN clustering_factor FORMAT 9999999
COLUMN num_rows          FORMAT 9999999
COLUMN last_analyzed     FORMAT A20

SELECT
    index_name,
    blevel,
    leaf_blocks,
    distinct_keys,
    clustering_factor,
    num_rows,
    TO_CHAR(last_analyzed,'DD/MM/YYYY HH24:MI') AS last_analyzed
FROM user_indexes
WHERE index_name IN (
    'IDX_REP_PERFIL_FECHA',
    'IDX_USR_EMAIL_LOWER',
    'IDX_CONT_CATEGORIA_ANIO',
    'IDX_PAGOS_USUARIO_ESTADO'
)
ORDER BY index_name;

PROMPT =====================================================
PROMPT FIN DEL SCRIPT NT4 - INDICES
PROMPT =====================================================
