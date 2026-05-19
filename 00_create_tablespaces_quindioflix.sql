-- =========================================================
-- QUINDIOFLIX - Script 00: Creación de Tablespaces USERS y TEMP
--   Este script crea los tablespaces por defecto USERS y TEMP 
--   si no existen en la base de datos o en la PDB.
--
-- IMPORTANTE: Este script debe ejecutarse como DBA
--   (SYS AS SYSDBA o con privilegios de administrador)
--   y de forma previa a todos los demás scripts del proyecto.
-- =========================================================

SET SERVEROUTPUT ON SIZE 1000000;
SET LINESIZE 200;

PROMPT =====================================================
PROMPT INICIANDO VERIFICACIÓN DE TABLESPACES (QUINDIOFLIX)
PROMPT =====================================================

DECLARE
    v_exists NUMBER;
BEGIN
    -- 1. Verificar y crear el tablespace permanente USERS
    SELECT COUNT(*) INTO v_exists 
      FROM dba_tablespaces 
     WHERE tablespace_name = 'USERS';
     
    IF v_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=> Creando tablespace USERS (permanente)...');
        -- Usando Oracle Managed Files (OMF) para máxima portabilidad (sin rutas absolutas)
        EXECUTE IMMEDIATE 'CREATE TABLESPACE USERS DATAFILE SIZE 100M AUTOEXTEND ON NEXT 10M MAXSIZE 10G';
        DBMS_OUTPUT.PUT_LINE('=> Tablespace USERS creado exitosamente.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('=> El tablespace USERS ya existe en esta instancia/PDB. No se requiere acción.');
    END IF;

    -- 2. Verificar y crear el tablespace temporal TEMP
    SELECT COUNT(*) INTO v_exists 
      FROM dba_tablespaces 
     WHERE tablespace_name = 'TEMP';
     
    IF v_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('=> Creando tablespace TEMP (temporal)...');
        -- Usando Oracle Managed Files (OMF) para máxima portabilidad
        EXECUTE IMMEDIATE 'CREATE TEMPORARY TABLESPACE TEMP TEMPFILE SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE 2G';
        DBMS_OUTPUT.PUT_LINE('=> Tablespace temporal TEMP creado exitosamente.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('=> El tablespace temporal TEMP ya existe en esta instancia/PDB. No se requiere acción.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠️ ERROR: No se pudieron gestionar los tablespaces: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Sugerencia: Habilita Oracle Managed Files (OMF) antes de correr el script:');
        DBMS_OUTPUT.PUT_LINE('  ALTER SYSTEM SET DB_CREATE_FILE_DEST=''/tu/ruta/oradata'' SCOPE=BOTH;');
        RAISE;
END;
/

PROMPT =====================================================
PROMPT PROCESO DE TABLESPACES 00 COMPLETADO CON ÉXITO
PROMPT =====================================================
