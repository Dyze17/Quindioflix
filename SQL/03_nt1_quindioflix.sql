
-- =========================================================
-- QUINDIOFLIX - ENTREGA 1
-- Script 03: Nucleo 1 - Consultas avanzadas y almacenamiento
-- =========================================================

SET SERVEROUTPUT ON;
SET DEFINE ON;
SET PAGESIZE 100;
SET LINESIZE 200;

PROMPT =====================================================
PROMPT 1. CONSULTAS PARAMETRIZADAS
PROMPT =====================================================

PROMPT -----------------------------------------------------
PROMPT Consulta 1: Top 10 de contenido mas reproducido por ciudad
PROMPT -----------------------------------------------------

COLUMN titulo FORMAT A35
COLUMN total_reproducciones FORMAT 99990
COLUMN ranking FORMAT 999

SELECT *
FROM (
    SELECT
        c.titulo,
        COUNT(*) AS total_reproducciones,
        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking
    FROM reproducciones r
    JOIN perfiles p   ON p.id_perfil = r.id_perfil
    JOIN usuarios u   ON u.id_usuario = p.id_usuario
    JOIN contenido c  ON c.id_contenido = r.id_contenido
    WHERE UPPER(u.ciudad) = UPPER('&&P_CIUDAD')
    GROUP BY c.titulo
    ORDER BY total_reproducciones DESC, c.titulo
)
WHERE ROWNUM <= 10;

UNDEFINE P_CIUDAD;

PROMPT -----------------------------------------------------
PROMPT Consulta 2: Ingresos por plan en un mes y ano determinados
PROMPT -----------------------------------------------------

DEFINE P_MES = &MES;
DEFINE P_ANIO = &ANIO;

COLUMN nombre_plan FORMAT A15
COLUMN ingresos FORMAT 99999990.99

SELECT
    pl.nombre_plan,
    COUNT(*) AS pagos_registrados,
    SUM(pg.monto_pagado) AS ingresos
FROM pagos pg
JOIN planes pl ON pl.id_plan = pg.id_plan
WHERE EXTRACT(MONTH FROM pg.fecha_pago) = &P_MES
  AND EXTRACT(YEAR  FROM pg.fecha_pago) = &P_ANIO
  AND pg.estado_pago = 'EXITOSO'
GROUP BY pl.nombre_plan
ORDER BY ingresos DESC;

UNDEFINE P_MES;
UNDEFINE P_ANIO;

PROMPT -----------------------------------------------------
PROMPT Consulta 3: Calificacion promedio por categoria para un genero
PROMPT -----------------------------------------------------

COLUMN nombre_categoria FORMAT A15
COLUMN promedio_estrellas FORMAT 990.99

SELECT
    cat.nombre_categoria,
    ROUND(AVG(cal.estrellas), 2) AS promedio_estrellas,
    COUNT(*) AS total_calificaciones
FROM calificaciones cal
JOIN contenido c          ON c.id_contenido = cal.id_contenido
JOIN categorias cat       ON cat.id_categoria = c.id_categoria
JOIN contenido_genero cg  ON cg.id_contenido = c.id_contenido
JOIN generos g            ON g.id_genero = cg.id_genero
WHERE UPPER(g.nombre_genero) = UPPER('&P_GENERO')
GROUP BY cat.nombre_categoria
ORDER BY promedio_estrellas DESC, cat.nombre_categoria;

PROMPT =====================================================
PROMPT 2. PIVOT (2)
PROMPT =====================================================

PROMPT -----------------------------------------------------
PROMPT PIVOT 1: Usuarios activos por ciudad y plan
PROMPT -----------------------------------------------------

SELECT *
FROM (
    SELECT
        u.ciudad,
        pl.nombre_plan
    FROM usuarios u
    JOIN planes pl ON pl.id_plan = u.id_plan_actual
    WHERE u.estado_cuenta = 'ACTIVO'
)
PIVOT (
    COUNT(nombre_plan)
    FOR nombre_plan IN (
        'BASICO' AS BASICO,
        'ESTANDAR' AS ESTANDAR,
        'PREMIUM' AS PREMIUM
    )
)
ORDER BY ciudad;

PROMPT -----------------------------------------------------
PROMPT PIVOT 2: Reproducciones por categoria y dispositivo
PROMPT -----------------------------------------------------

SELECT *
FROM (
    SELECT
        cat.nombre_categoria,
        r.dispositivo
    FROM reproducciones r
    JOIN contenido c    ON c.id_contenido = r.id_contenido
    JOIN categorias cat ON cat.id_categoria = c.id_categoria
)
PIVOT (
    COUNT(dispositivo)
    FOR dispositivo IN (
        'CELULAR' AS CELULAR,
        'TABLET' AS TABLET,
        'TV' AS TV,
        'COMPUTADOR' AS COMPUTADOR
    )
)
ORDER BY nombre_categoria;

PROMPT =====================================================
PROMPT 3. UNPIVOT (2)
PROMPT =====================================================

PROMPT -----------------------------------------------------
PROMPT UNPIVOT 1: Convertir ciudad-plan de columnas a filas
PROMPT -----------------------------------------------------

SELECT
    ciudad,
    plan,
    total_activos
FROM (
    SELECT
        ciudad,
        NVL(BASICO, 0)   AS basico,
        NVL(ESTANDAR, 0) AS estandar,
        NVL(PREMIUM, 0)  AS premium
    FROM (
        SELECT
            u.ciudad,
            pl.nombre_plan
        FROM usuarios u
        JOIN planes pl ON pl.id_plan = u.id_plan_actual
        WHERE u.estado_cuenta = 'ACTIVO'
    )
    PIVOT (
        COUNT(nombre_plan)
        FOR nombre_plan IN (
            'BASICO' AS BASICO,
            'ESTANDAR' AS ESTANDAR,
            'PREMIUM' AS PREMIUM
        )
    )
)
UNPIVOT (
    total_activos FOR plan IN (
        basico   AS 'BASICO',
        estandar AS 'ESTANDAR',
        premium  AS 'PREMIUM'
    )
)
ORDER BY ciudad, plan;

PROMPT -----------------------------------------------------
PROMPT UNPIVOT 2: Convertir reproducciones por dispositivo de columnas a filas
PROMPT -----------------------------------------------------

SELECT
    nombre_categoria,
    dispositivo,
    total_reproducciones
FROM (
    SELECT
        nombre_categoria,
        NVL(CELULAR, 0)     AS celular,
        NVL(TABLET, 0)      AS tablet,
        NVL(TV, 0)          AS tv,
        NVL(COMPUTADOR, 0)  AS computador
    FROM (
        SELECT
            cat.nombre_categoria,
            r.dispositivo
        FROM reproducciones r
        JOIN contenido c    ON c.id_contenido = r.id_contenido
        JOIN categorias cat ON cat.id_categoria = c.id_categoria
    )
    PIVOT (
        COUNT(dispositivo)
        FOR dispositivo IN (
            'CELULAR' AS CELULAR,
            'TABLET' AS TABLET,
            'TV' AS TV,
            'COMPUTADOR' AS COMPUTADOR
        )
    )
)
UNPIVOT (
    total_reproducciones FOR dispositivo IN (
        celular    AS 'CELULAR',
        tablet     AS 'TABLET',
        tv         AS 'TV',
        computador AS 'COMPUTADOR'
    )
)
ORDER BY nombre_categoria, dispositivo;

PROMPT =====================================================
PROMPT 4. FUNCIONES AVANZADAS DEL GROUP BY
PROMPT =====================================================

PROMPT -----------------------------------------------------
PROMPT ROLLUP: Ingresos por ciudad y plan con subtotales
PROMPT -----------------------------------------------------

SELECT
    u.ciudad,
    pl.nombre_plan,
    SUM(pg.monto_pagado) AS ingresos
FROM pagos pg
JOIN usuarios u ON u.id_usuario = pg.id_usuario
JOIN planes pl  ON pl.id_plan   = pg.id_plan
WHERE pg.estado_pago = 'EXITOSO'
GROUP BY ROLLUP (u.ciudad, pl.nombre_plan)
ORDER BY u.ciudad, pl.nombre_plan;

PROMPT -----------------------------------------------------
PROMPT CUBE: Reproducciones por categoria y dispositivo
PROMPT -----------------------------------------------------

SELECT
    cat.nombre_categoria,
    r.dispositivo,
    COUNT(*) AS total_reproducciones
FROM reproducciones r
JOIN contenido c    ON c.id_contenido = r.id_contenido
JOIN categorias cat ON cat.id_categoria = c.id_categoria
GROUP BY CUBE (cat.nombre_categoria, r.dispositivo)
ORDER BY cat.nombre_categoria, r.dispositivo;

PROMPT -----------------------------------------------------
PROMPT GROUPING: Etiquetar subtotales y total general
PROMPT -----------------------------------------------------

SELECT
    CASE
        WHEN GROUPING(u.ciudad) = 1 THEN 'TOTAL GENERAL'
        ELSE u.ciudad
    END AS ciudad,
    CASE
        WHEN GROUPING(pl.nombre_plan) = 1 AND GROUPING(u.ciudad) = 0 THEN 'SUBTOTAL CIUDAD'
        WHEN GROUPING(pl.nombre_plan) = 1 AND GROUPING(u.ciudad) = 1 THEN 'TODOS LOS PLANES'
        ELSE pl.nombre_plan
    END AS plan,
    SUM(pg.monto_pagado) AS ingresos
FROM pagos pg
JOIN usuarios u ON u.id_usuario = pg.id_usuario
JOIN planes pl  ON pl.id_plan   = pg.id_plan
WHERE pg.estado_pago = 'EXITOSO'
GROUP BY ROLLUP (u.ciudad, pl.nombre_plan)
ORDER BY GROUPING(u.ciudad), u.ciudad, GROUPING(pl.nombre_plan), pl.nombre_plan;

PROMPT -----------------------------------------------------
PROMPT GROUPING SETS: Totales por categoria y por ciudad, sin cruce
PROMPT -----------------------------------------------------

SELECT
    CASE
        WHEN GROUPING(cat.nombre_categoria) = 0 THEN 'CATEGORIA'
        ELSE 'CIUDAD'
    END AS tipo_dimension,
    COALESCE(cat.nombre_categoria, u.ciudad) AS valor_dimension,
    COUNT(*) AS total_reproducciones
FROM reproducciones r
JOIN perfiles p     ON p.id_perfil = r.id_perfil
JOIN usuarios u     ON u.id_usuario = p.id_usuario
JOIN contenido c    ON c.id_contenido = r.id_contenido
JOIN categorias cat ON cat.id_categoria = c.id_categoria
GROUP BY GROUPING SETS (
    (cat.nombre_categoria),
    (u.ciudad)
)
ORDER BY tipo_dimension, valor_dimension;

PROMPT =====================================================
PROMPT 5. VISTAS MATERIALIZADAS (2)
PROMPT =====================================================

BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_popularidad_contenido';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW mv_ingresos_mensuales';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

PROMPT -----------------------------------------------------
PROMPT MV 1: Popularidad por contenido
PROMPT -----------------------------------------------------

CREATE MATERIALIZED VIEW mv_popularidad_contenido
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    c.id_contenido,
    c.titulo,
    cat.nombre_categoria,
    COUNT(r.id_reproduccion) AS total_reproducciones,
    SUM(CASE WHEN r.porcentaje_avance >= 90 THEN 1 ELSE 0 END) AS reproducciones_completas,
    ROUND(AVG(cal.estrellas), 2) AS promedio_calificacion
FROM contenido c
JOIN categorias cat ON cat.id_categoria = c.id_categoria
LEFT JOIN reproducciones r ON r.id_contenido = c.id_contenido
LEFT JOIN calificaciones cal ON cal.id_contenido = c.id_contenido
GROUP BY c.id_contenido, c.titulo, cat.nombre_categoria;

SELECT * FROM mv_popularidad_contenido
ORDER BY reproducciones_completas DESC, promedio_calificacion DESC, titulo;

PROMPT -----------------------------------------------------
PROMPT MV 2: Ingresos mensuales por ciudad y plan
PROMPT -----------------------------------------------------

CREATE MATERIALIZED VIEW mv_ingresos_mensuales
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    TRUNC(pg.fecha_pago, 'MM') AS periodo_mes,
    u.ciudad,
    pl.nombre_plan,
    COUNT(*) AS pagos_exitosos,
    SUM(pg.monto_pagado) AS total_ingresos
FROM pagos pg
JOIN usuarios u ON u.id_usuario = pg.id_usuario
JOIN planes pl  ON pl.id_plan   = pg.id_plan
WHERE pg.estado_pago = 'EXITOSO'
GROUP BY TRUNC(pg.fecha_pago, 'MM'), u.ciudad, pl.nombre_plan;

SELECT * FROM mv_ingresos_mensuales
ORDER BY periodo_mes, ciudad, nombre_plan;

PROMPT =====================================================
PROMPT 6. FRAGMENTACION DE REPRODUCCIONES POR RANGO DE FECHAS
PROMPT =====================================================

SELECT
    table_name,
    partition_name,
    tablespace_name
FROM user_tab_partitions
WHERE table_name = 'REPRODUCCIONES'
ORDER BY partition_position;

PROMPT =====================================================
PROMPT FIN DEL SCRIPT NT1
PROMPT =====================================================
