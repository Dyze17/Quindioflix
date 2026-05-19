-- =========================================================
-- SCRIPT DE VERIFICACION - OBJETOS PL/SQL CREADOS
-- Quindioflix - Nucleo 2 (NT2)
-- =========================================================

SET PAGESIZE 100;
SET LINESIZE 200;
COLUMN object_name FORMAT A35;
COLUMN object_type FORMAT A15;
COLUMN status FORMAT A10;

PROMPT
PROMPT =====================================================
PROMPT 1. ESTADO GENERAL DE OBJETOS PL/SQL
PROMPT =====================================================
PROMPT

SELECT object_name, 
       object_type, 
       status,
       CASE WHEN status = 'VALID' THEN '✓ OK' ELSE '✗ ERROR' END AS verificacion
  FROM user_objects
 WHERE object_type IN ('PROCEDURE','FUNCTION','TRIGGER')
   AND object_name IN (
       'CUR_USUARIOS_MOROSOS',
       'CUR_POPULARIDAD_CONTENIDO',
       'SP_REGISTRAR_USUARIO',
       'SP_CAMBIAR_PLAN',
       'SP_REPORTE_CONSUMO',
       'FN_CALCULAR_MONTO',
       'FN_CONTENIDO_RECOMENDADO',
       'TRG_REP_CUENTA_ACTIVA',
       'TRG_PERF_MAX_PLAN',
       'TRG_CALIF_AVANCE_MIN',
       'TRG_PAGO_ACTIVA_CUENTA'
   )
ORDER BY object_type DESC, object_name;

PROMPT
PROMPT =====================================================
PROMPT 2. RESUMEN POR TIPO DE OBJETO
PROMPT =====================================================
PROMPT

SELECT object_type, 
       COUNT(*) AS total,
       SUM(CASE WHEN status = 'VALID' THEN 1 ELSE 0 END) AS validos,
       SUM(CASE WHEN status = 'INVALID' THEN 1 ELSE 0 END) AS invalidos
  FROM user_objects
 WHERE object_type IN ('PROCEDURE','FUNCTION','TRIGGER')
   AND object_name IN (
       'CUR_USUARIOS_MOROSOS',
       'CUR_POPULARIDAD_CONTENIDO',
       'SP_REGISTRAR_USUARIO',
       'SP_CAMBIAR_PLAN',
       'SP_REPORTE_CONSUMO',
       'FN_CALCULAR_MONTO',
       'FN_CONTENIDO_RECOMENDADO',
       'TRG_REP_CUENTA_ACTIVA',
       'TRG_PERF_MAX_PLAN',
       'TRG_CALIF_AVANCE_MIN',
       'TRG_PAGO_ACTIVA_CUENTA'
   )
 GROUP BY object_type
ORDER BY object_type DESC;

PROMPT
PROMPT =====================================================
PROMPT 3. ERRORES DE COMPILACION (si existen)
PROMPT =====================================================
PROMPT

SELECT name, type, line, position, text
  FROM user_errors
 WHERE name IN (
       'CUR_USUARIOS_MOROSOS',
       'CUR_POPULARIDAD_CONTENIDO',
       'SP_REGISTRAR_USUARIO',
       'SP_CAMBIAR_PLAN',
       'SP_REPORTE_CONSUMO',
       'FN_CALCULAR_MONTO',
       'FN_CONTENIDO_RECOMENDADO',
       'TRG_REP_CUENTA_ACTIVA',
       'TRG_PERF_MAX_PLAN',
       'TRG_CALIF_AVANCE_MIN',
       'TRG_PAGO_ACTIVA_CUENTA'
   )
 ORDER BY name, line;

PROMPT
PROMPT =====================================================
PROMPT 4. PROCEDIMIENTOS CREADOS
PROMPT =====================================================
PROMPT

SELECT object_name, 
       status,
       created,
       last_ddl_time
  FROM user_objects
 WHERE object_type = 'PROCEDURE'
   AND object_name IN (
       'CUR_USUARIOS_MOROSOS',
       'CUR_POPULARIDAD_CONTENIDO',
       'SP_REGISTRAR_USUARIO',
       'SP_CAMBIAR_PLAN',
       'SP_REPORTE_CONSUMO'
   )
ORDER BY object_name;

PROMPT
PROMPT =====================================================
PROMPT 5. FUNCIONES CREADAS
PROMPT =====================================================
PROMPT

SELECT object_name, 
       status,
       created,
       last_ddl_time
  FROM user_objects
 WHERE object_type = 'FUNCTION'
   AND object_name IN (
       'FN_CALCULAR_MONTO',
       'FN_CONTENIDO_RECOMENDADO'
   )
ORDER BY object_name;

PROMPT
PROMPT =====================================================
PROMPT 6. TRIGGERS CREADOS
PROMPT =====================================================
PROMPT

SELECT object_name, 
       status,
       created,
       last_ddl_time
  FROM user_objects
 WHERE object_type = 'TRIGGER'
   AND object_name IN (
       'TRG_REP_CUENTA_ACTIVA',
       'TRG_PERF_MAX_PLAN',
       'TRG_CALIF_AVANCE_MIN',
       'TRG_PAGO_ACTIVA_CUENTA'
   )
ORDER BY object_name;

PROMPT
PROMPT =====================================================
PROMPT 7. ESTADISTICAS FINALES
PROMPT =====================================================
PROMPT

BEGIN
    DECLARE
        v_total NUMBER;
        v_validos NUMBER;
        v_invalidos NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total
          FROM user_objects
         WHERE object_type IN ('PROCEDURE','FUNCTION','TRIGGER')
           AND object_name IN (
               'CUR_USUARIOS_MOROSOS',
               'CUR_POPULARIDAD_CONTENIDO',
               'SP_REGISTRAR_USUARIO',
               'SP_CAMBIAR_PLAN',
               'SP_REPORTE_CONSUMO',
               'FN_CALCULAR_MONTO',
               'FN_CONTENIDO_RECOMENDADO',
               'TRG_REP_CUENTA_ACTIVA',
               'TRG_PERF_MAX_PLAN',
               'TRG_CALIF_AVANCE_MIN',
               'TRG_PAGO_ACTIVA_CUENTA'
           );

        SELECT COUNT(*) INTO v_validos
          FROM user_objects
         WHERE object_type IN ('PROCEDURE','FUNCTION','TRIGGER')
           AND status = 'VALID'
           AND object_name IN (
               'CUR_USUARIOS_MOROSOS',
               'CUR_POPULARIDAD_CONTENIDO',
               'SP_REGISTRAR_USUARIO',
               'SP_CAMBIAR_PLAN',
               'SP_REPORTE_CONSUMO',
               'FN_CALCULAR_MONTO',
               'FN_CONTENIDO_RECOMENDADO',
               'TRG_REP_CUENTA_ACTIVA',
               'TRG_PERF_MAX_PLAN',
               'TRG_CALIF_AVANCE_MIN',
               'TRG_PAGO_ACTIVA_CUENTA'
           );

        v_invalidos := v_total - v_validos;

        DBMS_OUTPUT.PUT_LINE('Total de objetos esperados: ' || v_total);
        DBMS_OUTPUT.PUT_LINE('Objetos VALIDOS          : ' || v_validos);
        DBMS_OUTPUT.PUT_LINE('Objetos INVALIDOS        : ' || v_invalidos);
        
        IF v_invalidos = 0 THEN
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('✓ RESULTADO: TODO SE CREO CORRECTAMENTE');
        ELSE
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('✗ RESULTADO: EXISTEN ERRORES DE COMPILACION');
            DBMS_OUTPUT.PUT_LINE('  Revisa la seccion 3 (Errores de compilacion)');
        END IF;
    END;
END;
/

PROMPT
PROMPT =====================================================
PROMPT FIN DE LA VERIFICACION
PROMPT =====================================================
PROMPT