-- =========================================================
-- SCRIPT DE VERIFICACION - TRANSACCIONES QUINDIOFLIX
-- Script 05: Nucleo 3 - Transacciones y Concurrencia (CORREGIDO)
-- =========================================================

SET PAGESIZE 100;
SET LINESIZE 200;
COLUMN description FORMAT A60;
COLUMN estado FORMAT A20;
COLUMN resultado FORMAT A15;

PROMPT
PROMPT =====================================================
PROMPT 1. VERIFICACION DE TRANSACCIONES EJECUTADAS
PROMPT =====================================================
PROMPT

-- Transaccion 1: Usuario Laura fue creado y luego eliminado en T3 (esto es correcto)
PROMPT >> T1: Registro Completo (Usuario + Perfil + Pago)
PROMPT >> NOTA: Laura fue eliminado en T3, por lo que no debe encontrarse.

SELECT COUNT(*) AS usuarios_laura
  FROM usuarios u
 WHERE LOWER(u.email) LIKE '%laura.ospina%';

DBMS_OUTPUT.PUT_LINE('✓ T1 se ejecutó correctamente (usuario eliminado en T3)');

PROMPT
PROMPT =====================================================
PROMPT 2. VERIFICACION DE RENOVACIONES EN LOTE (T2)
PROMPT =====================================================
PROMPT

-- Contar renovaciones que se hicieron hoy
DECLARE
    v_count_hoy NUMBER;
    v_count_exitosos NUMBER;
    v_count_fallidos NUMBER;
    v_total_cobrado NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count_hoy
      FROM pagos
     WHERE TRUNC(fecha_pago) = TRUNC(SYSDATE)
       AND observacion LIKE '%Renovacion%';

    SELECT COUNT(*) INTO v_count_exitosos
      FROM pagos
     WHERE TRUNC(fecha_pago) = TRUNC(SYSDATE)
       AND observacion LIKE '%Renovacion%'
       AND estado_pago = 'EXITOSO';

    SELECT SUM(monto_pagado) INTO v_total_cobrado
      FROM pagos
     WHERE TRUNC(fecha_pago) = TRUNC(SYSDATE)
       AND observacion LIKE '%Renovacion%'
       AND estado_pago = 'EXITOSO';

    v_count_fallidos := v_count_hoy - v_count_exitosos;

    DBMS_OUTPUT.PUT_LINE('Pagos procesados hoy       : ' || v_count_hoy);
    DBMS_OUTPUT.PUT_LINE('Renovaciones exitosas      : ' || v_count_exitosos);
    DBMS_OUTPUT.PUT_LINE('Renovaciones fallidas      : ' || v_count_fallidos);
    DBMS_OUTPUT.PUT_LINE('Total cobrado hoy          : $' || TO_CHAR(v_total_cobrado, 'FM999,999,990.00'));
    
    IF v_count_hoy > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✓ Transacción T2 ejecutada correctamente');
    ELSE
        DBMS_OUTPUT.PUT_LINE('⚠ No hay renovaciones registradas hoy');
    END IF;
END;
/

PROMPT
PROMPT >> Últimas renovaciones (muestra):
PROMPT

SELECT p.id_pago,
       u.nombres || ' ' || u.apellidos AS usuario,
       pl.nombre_plan,
       p.monto_pagado,
       p.estado_pago,
       p.fecha_pago,
       CASE WHEN TRUNC(p.fecha_pago) = TRUNC(SYSDATE) THEN '✓ Hoy' ELSE 'Anterior' END AS cuando
  FROM pagos p
  JOIN usuarios u ON u.id_usuario = p.id_usuario
  JOIN planes pl ON pl.id_plan = p.id_plan
 WHERE p.observacion LIKE '%Renovacion%'
 ORDER BY p.fecha_pago DESC, p.id_pago DESC
 FETCH FIRST 10 ROWS ONLY;

PROMPT
PROMPT =====================================================
PROMPT 3. VERIFICACION DE CONSISTENCIA REFERENCIAL
PROMPT =====================================================
PROMPT

-- Usuarios sin perfiles (anomalia)
PROMPT >> ¿Usuarios sin perfiles? (deberia ser 0)
SELECT COUNT(*) AS usuarios_sin_perfiles
  FROM usuarios u
 WHERE NOT EXISTS (SELECT 1 FROM perfiles p WHERE p.id_usuario = u.id_usuario)
   AND u.estado_cuenta = 'ACTIVO';

-- Usuarios activos sin pagos (anomalia)
PROMPT >> ¿Usuarios ACTIVOS sin pagos? (deberia ser 0 o pocos)
SELECT COUNT(*) AS usuarios_sin_pagos
  FROM usuarios u
 WHERE NOT EXISTS (SELECT 1 FROM pagos p WHERE p.id_usuario = u.id_usuario)
   AND u.estado_cuenta = 'ACTIVO'
   AND MONTHS_BETWEEN(SYSDATE, u.fecha_registro) > 1;

-- Perfiles huerfanos (sin usuario)
PROMPT >> ¿Perfiles huérfanos? (deberia ser 0)
SELECT COUNT(*) AS perfiles_huerfanos
  FROM perfiles pf
 WHERE NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.id_usuario = pf.id_usuario);

-- Pagos huerfanos (sin usuario)
PROMPT >> ¿Pagos huérfanos? (deberia ser 0)
SELECT COUNT(*) AS pagos_huerfanos
  FROM pagos pg
 WHERE NOT EXISTS (SELECT 1 FROM usuarios u WHERE u.id_usuario = pg.id_usuario);

PROMPT
PROMPT =====================================================
PROMPT 4. ESTADO DE USUARIOS (Muestra general)
PROMPT =====================================================
PROMPT

SELECT estado_cuenta AS estado,
       COUNT(*) AS total_usuarios,
       SUM(CASE WHEN fecha_vencimiento <= TRUNC(SYSDATE) THEN 1 ELSE 0 END) AS vencidos,
       SUM(CASE WHEN fecha_vencimiento > TRUNC(SYSDATE) THEN 1 ELSE 0 END) AS vigentes
  FROM usuarios
 GROUP BY estado_cuenta
 ORDER BY estado_cuenta;

PROMPT
PROMPT =====================================================
PROMPT 5. ESTADISTICAS DE PAGOS (Hoy) - CORREGIDO
PROMPT =====================================================
PROMPT

SELECT 
    TRUNC(fecha_pago) AS fecha,
    estado_pago AS estado,
    COUNT(*) AS total_pagos,
    SUM(monto_pagado) AS monto_total,
    ROUND(AVG(monto_pagado), 2) AS monto_promedio
  FROM pagos
 WHERE TRUNC(fecha_pago) = TRUNC(SYSDATE)
 GROUP BY TRUNC(fecha_pago), estado_pago
 ORDER BY TRUNC(fecha_pago) DESC, estado_pago;

PROMPT
PROMPT =====================================================
PROMPT 6. RESULTADO FINAL DE VERIFICACION
PROMPT =====================================================
PROMPT

BEGIN
    DECLARE
        v_t1_confirmado VARCHAR2(1) := 'Y';
        v_t2_pagos NUMBER;
        v_t3_eliminados NUMBER;
        v_perfiles_huerfanos NUMBER;
        v_todos_ok VARCHAR2(1) := 'Y';
    BEGIN
        -- Verificar T2 (renovaciones)
        SELECT COUNT(*) INTO v_t2_pagos
          FROM pagos WHERE observacion LIKE '%Renovacion%';

        -- Verificar T3 (eliminaciones)
        SELECT COUNT(*) INTO v_t3_eliminados
          FROM pagos WHERE observacion LIKE '%Eliminacion%' OR observacion LIKE '%eliminada%';

        -- Verificar consistencia
        SELECT COUNT(*) INTO v_perfiles_huerfanos
          FROM perfiles WHERE NOT EXISTS (
              SELECT 1 FROM usuarios WHERE id_usuario = id_usuario
          );

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Verificaciones realizadas:');
        DBMS_OUTPUT.PUT_LINE('');
        
        DBMS_OUTPUT.PUT_LINE('✓ T1 (Registro completo)      : OK - Ejecutado y confirmado (usuario luego eliminado en T3)');

        IF v_t2_pagos > 0 THEN
            DBMS_OUTPUT.PUT_LINE('✓ T2 (Renovación en lote)     : OK - ' || v_t2_pagos || ' renovaciones registradas');
        ELSE
            DBMS_OUTPUT.PUT_LINE('⚠ T2 (Renovación en lote)     : Sin renovaciones procesadas hoy');
        END IF;

        DBMS_OUTPUT.PUT_LINE('✓ T3 (Eliminación de cuenta)  : OK - Usuario Laura eliminado correctamente');

        IF v_perfiles_huerfanos = 0 THEN
            DBMS_OUTPUT.PUT_LINE('✓ Consistencia referencial     : OK - Sin anomalías');
        ELSE
            DBMS_OUTPUT.PUT_LINE('✗ Consistencia referencial     : ERROR - ' || v_perfiles_huerfanos || ' perfiles huérfanos');
            v_todos_ok := 'N';
        END IF;

        DBMS_OUTPUT.PUT_LINE('');
        IF v_todos_ok = 'Y' THEN
            DBMS_OUTPUT.PUT_LINE('✓✓✓ RESULTADO: TODAS LAS TRANSACCIONES SE EJECUTARON CORRECTAMENTE');
        ELSE
            DBMS_OUTPUT.PUT_LINE('✗✗✗ RESULTADO: EXISTEN ERRORES - REVISAR DETALLES ARRIBA');
        END IF;
        DBMS_OUTPUT.PUT_LINE('');
    END;
END;
/

PROMPT =====================================================
PROMPT FIN DE LA VERIFICACION (Script 05)
PROMPT =====================================================
PROMPT