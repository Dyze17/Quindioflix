-- =========================================================
-- QUINDIOFLIX - Script 00b: Creación del usuario del esquema
--   Este script crea el usuario principal que poseerá todas
--   las tablas, vistas y objetos PL/SQL del proyecto.
--
-- IMPORTANTE: Debe ejecutarse como DBA (SYS AS SYSDBA)
--   DESPUÉS del script 00 y ANTES del script 01.
--
-- Cómo conectar como DBA en Oracle XE:
--   SQL*Plus:      sqlplus sys/tu_password_sys@localhost:1521/XEPDB1 AS SYSDBA
--   SQL Developer: usuario=sys, rol=SYSDBA, servicio=XEPDB1
--
-- Una vez creado el usuario, conéctate con él para los
-- scripts 01 al 06.
-- =========================================================

SET SERVEROUTPUT ON SIZE 1000000;
SET LINESIZE 200;

PROMPT =====================================================
PROMPT CONFIGURACIÓN INICIAL — USUARIO DEL ESQUEMA
PROMPT =====================================================

-- -------------------------------------------------------
-- PASO 1: Verificar en qué contenedor/PDB estamos.
--   Si aparece CDB$ROOT, debes cambiar a la PDB antes
--   de continuar con el comando:
--     ALTER SESSION SET CONTAINER = XEPDB1;
-- -------------------------------------------------------
PROMPT => Contenedor actual:
SHOW CON_NAME;

PROMPT =====================================================
PROMPT CONFIGURACIÓN DEL USUARIO DEL ESQUEMA
PROMPT =====================================================

-- -------------------------------------------------------
-- NOTA PARA EL USUARIO:
--   Cambia 'QUINDIOFLIX_USER' por el nombre de usuario
--   que quieras usar (debe coincidir con DB_USER en tu .env).
--   Cambia 'mi_password_seguro' por una contraseña propia.
--
--   Ejemplo mínimo sin cambios: usa usuario=QUINDIOFLIX_USER
--   y en backend/.env pon:  DB_USER=QUINDIOFLIX_USER
-- -------------------------------------------------------

DECLARE
    v_exists NUMBER;
    v_username VARCHAR2(30) := 'QUINDIOFLIX_USER'; -- <-- cambia si lo deseas
    v_password VARCHAR2(50) := 'QuindioFlix2025#'; -- <-- cambia por tu contraseña
BEGIN
    -- Eliminar usuario anterior si ya existía (limpieza)
    SELECT COUNT(*) INTO v_exists
      FROM dba_users
     WHERE username = UPPER(v_username);

    IF v_exists > 0 THEN
        DBMS_OUTPUT.PUT_LINE('=> Usuario ' || v_username || ' ya existe. Omitiendo creación.');
        DBMS_OUTPUT.PUT_LINE('   Si quieres recrearlo, ejecuta primero:');
        DBMS_OUTPUT.PUT_LINE('   DROP USER ' || v_username || ' CASCADE;');
    ELSE
        -- Crear el usuario del esquema
        EXECUTE IMMEDIATE
            'CREATE USER ' || v_username ||
            ' IDENTIFIED BY "' || v_password || '"' ||
            ' DEFAULT TABLESPACE USERS' ||
            ' TEMPORARY TABLESPACE TEMP' ||
            ' QUOTA UNLIMITED ON USERS';

        DBMS_OUTPUT.PUT_LINE('=> Usuario ' || v_username || ' creado exitosamente.');

        -- Privilegios mínimos para que la API y los scripts funcionen
        EXECUTE IMMEDIATE 'GRANT CREATE SESSION     TO ' || v_username;
        EXECUTE IMMEDIATE 'GRANT CREATE TABLE       TO ' || v_username;
        EXECUTE IMMEDIATE 'GRANT CREATE VIEW        TO ' || v_username;
        EXECUTE IMMEDIATE 'GRANT CREATE SEQUENCE    TO ' || v_username;
        EXECUTE IMMEDIATE 'GRANT CREATE PROCEDURE   TO ' || v_username;
        EXECUTE IMMEDIATE 'GRANT CREATE TRIGGER     TO ' || v_username;
        EXECUTE IMMEDIATE 'GRANT CREATE TYPE        TO ' || v_username;
        EXECUTE IMMEDIATE 'GRANT CREATE MATERIALIZED VIEW TO ' || v_username;
        -- Necesario para los tablespaces del script 03b
        EXECUTE IMMEDIATE 'GRANT CREATE TABLESPACE  TO ' || v_username;
        EXECUTE IMMEDIATE 'GRANT ALTER TABLESPACE   TO ' || v_username;
        -- Necesario para los índices y DBMS_STATS del script 06
        EXECUTE IMMEDIATE 'GRANT ANALYZE ANY        TO ' || v_username;
        -- Necesario para SELECT FOR UPDATE / manejo de transacciones del script 05
        EXECUTE IMMEDIATE 'GRANT SELECT ANY DICTIONARY TO ' || v_username;

        DBMS_OUTPUT.PUT_LINE('=> Privilegios otorgados correctamente.');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('=====================================================');
        DBMS_OUTPUT.PUT_LINE('PRÓXIMO PASO:');
        DBMS_OUTPUT.PUT_LINE('  Actualiza backend/.env con estas credenciales:');
        DBMS_OUTPUT.PUT_LINE('    DB_USER=' || v_username);
        DBMS_OUTPUT.PUT_LINE('    DB_PASSWORD=<la contraseña que elegiste>');
        DBMS_OUTPUT.PUT_LINE('    DB_DSN=localhost:1521/XEPDB1');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  Luego conéctate con ese usuario y ejecuta:');
        DBMS_OUTPUT.PUT_LINE('    @SQL/01_create_tables_quindioflix.sql');
        DBMS_OUTPUT.PUT_LINE('=====================================================');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR al crear el usuario: ' || SQLERRM);
        RAISE;
END;
/

PROMPT =====================================================
PROMPT VERIFICACIÓN — USUARIOS EN ESTA PDB
PROMPT =====================================================

COLUMN username            FORMAT A25
COLUMN account_status      FORMAT A20
COLUMN default_tablespace  FORMAT A15

SELECT username, account_status, default_tablespace
  FROM dba_users
 WHERE username = 'QUINDIOFLIX_USER' -- ajusta si cambiaste el nombre
 ORDER BY username;

PROMPT =====================================================
PROMPT FIN DEL SCRIPT 00b
PROMPT =====================================================
