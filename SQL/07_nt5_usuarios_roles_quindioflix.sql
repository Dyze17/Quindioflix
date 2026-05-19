-- =========================================================
-- QUINDIOFLIX - ENTREGA 3
-- Script 07: Nucleo 5 - Administracion de Acceso a BD
--   5.1 Esquema de usuarios y roles (minimo 3 roles)
--   5.2 Implementacion: usuarios, GRANT, PROFILE,
--       demostracion de restricciones
--
-- IMPORTANTE: Este script debe ejecutarse como DBA
--   (sistema / SYS AS SYSDBA o con privilegios de DBA)
--   ya que crea usuarios, roles y perfiles Oracle.
--
-- Sustituye &SCHEMA_OWNER por el esquema donde estan
--   las tablas de QuindioFlix (por defecto: QUINDIOFLIX).
-- =========================================================

SET SERVEROUTPUT ON SIZE 1000000;
SET LINESIZE 200;
SET PAGESIZE 100;
SET DEFINE ON;

PROMPT =====================================================
PROMPT LIMPIEZA PREVIA (ejecutar con privilegios DBA)
PROMPT =====================================================

-- Eliminar usuarios Oracle si existen
BEGIN EXECUTE IMMEDIATE 'DROP USER qf_admin    CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP USER qf_analista CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP USER qf_soporte  CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP USER qf_contenido CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Eliminar roles Oracle si existen
BEGIN EXECUTE IMMEDIATE 'DROP ROLE rol_admin';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE rol_analista'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE rol_soporte';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP ROLE rol_contenido'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Eliminar perfiles Oracle si existen (excepto DEFAULT)
BEGIN EXECUTE IMMEDIATE 'DROP PROFILE perfil_estandar CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROFILE perfil_restringido CASCADE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT =====================================================
PROMPT 5.1 CREACION DE ROLES ORACLE
PROMPT =====================================================

-- -------------------------------------------------------
-- ROL_ADMIN
--   Administrador de la plataforma.
--   Privilegios: CRUD en todas las tablas,
--   crear/eliminar usuarios, ejecutar todos los SPs.
-- -------------------------------------------------------
CREATE ROLE rol_admin;

-- -------------------------------------------------------
-- ROL_ANALISTA
--   Analista de datos / gerencia.
--   Privilegios: SELECT en todas las tablas,
--   ejecutar SPs de reportes, acceso a vistas materializadas.
-- -------------------------------------------------------
CREATE ROLE rol_analista;

-- -------------------------------------------------------
-- ROL_SOPORTE
--   Soporte al cliente.
--   Privilegios: SELECT en USUARIOS, PERFILES, PAGOS.
--   INSERT/UPDATE en PAGOS. Ejecutar SP_CAMBIAR_PLAN.
-- -------------------------------------------------------
CREATE ROLE rol_soporte;

-- -------------------------------------------------------
-- ROL_CONTENIDO
--   Gestor de catalogo.
--   Privilegios: CRUD en CONTENIDO, TEMPORADAS, EPISODIOS,
--   GENEROS. SELECT en REPRODUCCIONES y CALIFICACIONES.
-- -------------------------------------------------------
CREATE ROLE rol_contenido;

PROMPT =====================================================
PROMPT 5.1 ASIGNACION DE PRIVILEGIOS A LOS ROLES
PROMPT =====================================================

-- ==========================================================
-- ROL_ADMIN - CRUD completo en todas las tablas de negocio
-- ==========================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON planes             TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON departamentos      TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON empleados          TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON usuarios           TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON roles_app          TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON usuario_rol_app    TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON perfiles           TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON categorias         TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON generos            TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON contenido          TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON contenido_genero   TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON temporadas         TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON episodios          TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON contenido_relacionado TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON pagos              TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON reproducciones     TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON calificaciones     TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON favoritos          TO rol_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON reportes_contenido TO rol_admin;

-- Acceso a vistas materializadas
GRANT SELECT ON mv_popularidad_contenido TO rol_admin;
GRANT SELECT ON mv_ingresos_mensuales    TO rol_admin;

-- Ejecutar todos los procedimientos y funciones
GRANT EXECUTE ON sp_registrar_usuario    TO rol_admin;
GRANT EXECUTE ON sp_cambiar_plan         TO rol_admin;
GRANT EXECUTE ON sp_reporte_consumo      TO rol_admin;
GRANT EXECUTE ON cur_usuarios_morosos    TO rol_admin;
GRANT EXECUTE ON cur_popularidad_contenido TO rol_admin;
GRANT EXECUTE ON fn_calcular_monto       TO rol_admin;
GRANT EXECUTE ON fn_contenido_recomendado TO rol_admin;

-- Privilegio de sistema para crear/eliminar usuarios (necesita ser DBA o tener el privilegio)
-- (Se otorga directamente al usuario qf_admin, no al rol, ya que son system privileges)

-- ==========================================================
-- ROL_ANALISTA - Solo lectura + reportes
-- ==========================================================
GRANT SELECT ON planes             TO rol_analista;
GRANT SELECT ON departamentos      TO rol_analista;
GRANT SELECT ON empleados          TO rol_analista;
GRANT SELECT ON usuarios           TO rol_analista;
GRANT SELECT ON roles_app          TO rol_analista;
GRANT SELECT ON usuario_rol_app    TO rol_analista;
GRANT SELECT ON perfiles           TO rol_analista;
GRANT SELECT ON categorias         TO rol_analista;
GRANT SELECT ON generos            TO rol_analista;
GRANT SELECT ON contenido          TO rol_analista;
GRANT SELECT ON contenido_genero   TO rol_analista;
GRANT SELECT ON temporadas         TO rol_analista;
GRANT SELECT ON episodios          TO rol_analista;
GRANT SELECT ON contenido_relacionado TO rol_analista;
GRANT SELECT ON pagos              TO rol_analista;
GRANT SELECT ON reproducciones     TO rol_analista;
GRANT SELECT ON calificaciones     TO rol_analista;
GRANT SELECT ON favoritos          TO rol_analista;
GRANT SELECT ON reportes_contenido TO rol_analista;

-- Vistas materializadas (base de reportes ejecutivos)
GRANT SELECT ON mv_popularidad_contenido TO rol_analista;
GRANT SELECT ON mv_ingresos_mensuales    TO rol_analista;

-- Procedimientos de reportes
GRANT EXECUTE ON sp_reporte_consumo       TO rol_analista;
GRANT EXECUTE ON cur_usuarios_morosos     TO rol_analista;
GRANT EXECUTE ON cur_popularidad_contenido TO rol_analista;
GRANT EXECUTE ON fn_calcular_monto        TO rol_analista;
GRANT EXECUTE ON fn_contenido_recomendado TO rol_analista;

-- ==========================================================
-- ROL_SOPORTE - Lectura de cuenta + gestion de pagos
-- ==========================================================
GRANT SELECT         ON usuarios  TO rol_soporte;
GRANT SELECT         ON perfiles  TO rol_soporte;
GRANT SELECT, INSERT, UPDATE ON pagos     TO rol_soporte;
GRANT SELECT         ON planes    TO rol_soporte;
GRANT SELECT         ON reportes_contenido TO rol_soporte;

-- Solo puede ejecutar sp_cambiar_plan
GRANT EXECUTE ON sp_cambiar_plan  TO rol_soporte;

-- ==========================================================
-- ROL_CONTENIDO - CRUD del catalogo + lectura de consumo
-- ==========================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON contenido           TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON contenido_genero    TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON temporadas          TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON episodios           TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON generos             TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON categorias          TO rol_contenido;
GRANT SELECT, INSERT, UPDATE, DELETE ON contenido_relacionado TO rol_contenido;

-- Lectura de estadisticas para decision editorial
GRANT SELECT ON reproducciones     TO rol_contenido;
GRANT SELECT ON calificaciones     TO rol_contenido;
GRANT SELECT ON mv_popularidad_contenido TO rol_contenido;

PROMPT =====================================================
PROMPT 5.1 CREACION DE PERFILES ORACLE (PROFILE)
PROMPT =====================================================

-- -------------------------------------------------------
-- PERFIL ESTANDAR: para usuarios internos de confianza
--   (admin, analista, gestor de contenido)
--   Limita sesiones concurrentes, tiempo de inactividad
--   y intentos de login fallidos.
-- -------------------------------------------------------
CREATE PROFILE perfil_estandar LIMIT
    SESSIONS_PER_USER        3        -- Max 3 sesiones concurrentes por usuario
    CPU_PER_SESSION           UNLIMITED
    CPU_PER_CALL              UNLIMITED
    CONNECT_TIME              480      -- Max 8 horas por sesion (minutos)
    IDLE_TIME                 30       -- Desconectar si esta 30 min inactivo
    FAILED_LOGIN_ATTEMPTS     5        -- Bloquear cuenta tras 5 intentos fallidos
    PASSWORD_LOCK_TIME        1/24     -- Bloqueo de 1 hora (fraccion de dia)
    PASSWORD_LIFE_TIME        90       -- Contrasena vence cada 90 dias
    PASSWORD_REUSE_TIME       365      -- No reutilizar contrasena por 1 anio
    PASSWORD_REUSE_MAX        5        -- No reutilizar las ultimas 5 contrasenas
    PASSWORD_GRACE_TIME       7;       -- 7 dias de gracia antes de forzar cambio

-- -------------------------------------------------------
-- PERFIL RESTRINGIDO: para soporte (acceso mas limitado)
-- -------------------------------------------------------
CREATE PROFILE perfil_restringido LIMIT
    SESSIONS_PER_USER        1        -- Solo 1 sesion concurrente
    CPU_PER_SESSION           UNLIMITED
    CPU_PER_CALL              60000   -- Max 1 minuto de CPU por llamada
    CONNECT_TIME              240     -- Max 4 horas por sesion
    IDLE_TIME                 15      -- Desconectar tras 15 min inactivo
    FAILED_LOGIN_ATTEMPTS     3       -- Bloquear tras 3 intentos fallidos
    PASSWORD_LOCK_TIME        1/12    -- Bloqueo de 2 horas
    PASSWORD_LIFE_TIME        60      -- Contrasena vence cada 60 dias
    PASSWORD_REUSE_TIME       180
    PASSWORD_REUSE_MAX        3
    PASSWORD_GRACE_TIME       3;

PROMPT =====================================================
PROMPT 5.2 CREACION DE USUARIOS ORACLE
PROMPT =====================================================

-- -------------------------------------------------------
-- USUARIO: qf_admin (ROL_ADMIN + perfil_estandar)
-- -------------------------------------------------------
CREATE USER qf_admin
    IDENTIFIED BY "QuindioFlix#Admin2025"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE perfil_estandar
    ACCOUNT UNLOCK;

-- Privilegios de sistema para administracion
GRANT CREATE SESSION  TO qf_admin;
GRANT CREATE USER     TO qf_admin;
GRANT DROP USER       TO qf_admin;
GRANT ALTER USER      TO qf_admin;
GRANT CREATE SYNONYM  TO qf_admin;

-- Asignar el rol de aplicacion
GRANT rol_admin TO qf_admin;

-- Otorgar el rol activo por defecto al conectarse
ALTER USER qf_admin DEFAULT ROLE rol_admin;

-- -------------------------------------------------------
-- USUARIO: qf_analista (ROL_ANALISTA + perfil_estandar)
-- -------------------------------------------------------
CREATE USER qf_analista
    IDENTIFIED BY "QuindioFlix#Analista2025"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE perfil_estandar
    ACCOUNT UNLOCK;

GRANT CREATE SESSION  TO qf_analista;
GRANT rol_analista    TO qf_analista;
ALTER USER qf_analista DEFAULT ROLE rol_analista;

-- -------------------------------------------------------
-- USUARIO: qf_soporte (ROL_SOPORTE + perfil_restringido)
-- -------------------------------------------------------
CREATE USER qf_soporte
    IDENTIFIED BY "QuindioFlix#Soporte2025"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE perfil_restringido
    ACCOUNT UNLOCK;

GRANT CREATE SESSION  TO qf_soporte;
GRANT rol_soporte     TO qf_soporte;
ALTER USER qf_soporte DEFAULT ROLE rol_soporte;

-- -------------------------------------------------------
-- USUARIO: qf_contenido (ROL_CONTENIDO + perfil_estandar)
-- -------------------------------------------------------
CREATE USER qf_contenido
    IDENTIFIED BY "QuindioFlix#Contenido2025"
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    PROFILE perfil_estandar
    ACCOUNT UNLOCK;

GRANT CREATE SESSION  TO qf_contenido;
GRANT rol_contenido   TO qf_contenido;
ALTER USER qf_contenido DEFAULT ROLE rol_contenido;

PROMPT =====================================================
PROMPT VERIFICACION - USUARIOS, ROLES Y PERFILES
PROMPT =====================================================

COLUMN username    FORMAT A20
COLUMN profile     FORMAT A22
COLUMN account_status FORMAT A20
COLUMN default_tablespace FORMAT A12

SELECT username, profile, account_status, default_tablespace
  FROM dba_users
 WHERE username IN ('QF_ADMIN','QF_ANALISTA','QF_SOPORTE','QF_CONTENIDO')
 ORDER BY username;

-- Verificar asignacion de roles a usuarios
COLUMN grantee FORMAT A20
COLUMN granted_role FORMAT A20
COLUMN admin_option FORMAT A12
COLUMN default_role FORMAT A12

SELECT grantee, granted_role, admin_option, default_role
  FROM dba_role_privs
 WHERE grantee IN ('QF_ADMIN','QF_ANALISTA','QF_SOPORTE','QF_CONTENIDO')
 ORDER BY grantee;

-- Verificar privilegios de objeto por rol
COLUMN grantee   FORMAT A20
COLUMN owner     FORMAT A15
COLUMN table_name FORMAT A30
COLUMN privilege FORMAT A15

SELECT grantee, owner, table_name, privilege
  FROM dba_tab_privs
 WHERE grantee IN ('ROL_ADMIN','ROL_ANALISTA','ROL_SOPORTE','ROL_CONTENIDO')
 ORDER BY grantee, table_name, privilege;

-- Verificar perfiles creados
COLUMN profile   FORMAT A25
COLUMN resource_name FORMAT A30
COLUMN limit     FORMAT A20

SELECT profile, resource_name, limit
  FROM dba_profiles
 WHERE profile IN ('PERFIL_ESTANDAR','PERFIL_RESTRINGIDO')
   AND resource_name IN (
       'SESSIONS_PER_USER','IDLE_TIME','CONNECT_TIME',
       'FAILED_LOGIN_ATTEMPTS','PASSWORD_LIFE_TIME'
   )
 ORDER BY profile, resource_name;

PROMPT =====================================================
PROMPT 5.2 DEMOSTRACION DE RESTRICCIONES DE ACCESO
PROMPT =====================================================

-- -------------------------------------------------------
-- DEMOSTRACION 1: qf_soporte intenta hacer DELETE en USUARIOS
--   Resultado esperado: ORA-01031 insufficient privileges
-- -------------------------------------------------------

PROMPT ---------------------------------------------------
PROMPT DEMO 1: Soporte intenta DELETE en USUARIOS (debe fallar)
PROMPT ---------------------------------------------------

BEGIN
    -- Simular la verificacion de privilegios del rol ROL_SOPORTE
    -- sobre la tabla USUARIOS (DELETE no fue otorgado)
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
          FROM dba_tab_privs
         WHERE grantee   = 'ROL_SOPORTE'
           AND table_name = 'USUARIOS'
           AND privilege  = 'DELETE';

        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE(
                'VERIFICADO: ROL_SOPORTE NO tiene privilegio DELETE en USUARIOS.'
            );
            DBMS_OUTPUT.PUT_LINE(
                '=> Si qf_soporte ejecuta: DELETE FROM usuarios WHERE ..'
            );
            DBMS_OUTPUT.PUT_LINE(
                '   Oracle devuelve: ORA-01031: insufficient privileges'
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE('ADVERTENCIA: El rol tiene DELETE en USUARIOS (revisar GRANTs).');
        END IF;
    END;
END;
/

-- -------------------------------------------------------
-- DEMOSTRACION 2: qf_analista intenta INSERT en PAGOS
--   Resultado esperado: ORA-01031
-- -------------------------------------------------------

PROMPT ---------------------------------------------------
PROMPT DEMO 2: Analista intenta INSERT en PAGOS (debe fallar)
PROMPT ---------------------------------------------------

BEGIN
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
          FROM dba_tab_privs
         WHERE grantee    = 'ROL_ANALISTA'
           AND table_name = 'PAGOS'
           AND privilege  = 'INSERT';

        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE(
                'VERIFICADO: ROL_ANALISTA NO tiene privilegio INSERT en PAGOS.'
            );
            DBMS_OUTPUT.PUT_LINE(
                '=> Si qf_analista ejecuta un INSERT en PAGOS:'
            );
            DBMS_OUTPUT.PUT_LINE(
                '   Oracle devuelve: ORA-01031: insufficient privileges'
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE('ADVERTENCIA: El rol tiene INSERT en PAGOS (revisar GRANTs).');
        END IF;
    END;
END;
/

-- -------------------------------------------------------
-- DEMOSTRACION 3: qf_contenido intenta SELECT en PAGOS
--   Resultado esperado: ORA-00942 table or view does not exist
-- -------------------------------------------------------

PROMPT ---------------------------------------------------
PROMPT DEMO 3: Contenido intenta SELECT en PAGOS (debe fallar)
PROMPT ---------------------------------------------------

BEGIN
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
          FROM dba_tab_privs
         WHERE grantee    = 'ROL_CONTENIDO'
           AND table_name = 'PAGOS'
           AND privilege  = 'SELECT';

        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE(
                'VERIFICADO: ROL_CONTENIDO NO tiene acceso a PAGOS.'
            );
            DBMS_OUTPUT.PUT_LINE(
                '=> Si qf_contenido ejecuta: SELECT * FROM pagos'
            );
            DBMS_OUTPUT.PUT_LINE(
                '   Oracle devuelve: ORA-00942: table or view does not exist'
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE('ADVERTENCIA: El rol tiene SELECT en PAGOS (revisar GRANTs).');
        END IF;
    END;
END;
/

-- -------------------------------------------------------
-- DEMOSTRACION 4: qf_soporte ejecuta SP_CAMBIAR_PLAN
--   Resultado esperado: EXITOSO (tiene el privilegio EXECUTE)
-- -------------------------------------------------------

PROMPT ---------------------------------------------------
PROMPT DEMO 4: Soporte ejecuta SP_CAMBIAR_PLAN (debe funcionar)
PROMPT ---------------------------------------------------

BEGIN
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
          FROM dba_tab_privs
         WHERE grantee    = 'ROL_SOPORTE'
           AND table_name = 'SP_CAMBIAR_PLAN'
           AND privilege  = 'EXECUTE';

        IF v_count > 0 THEN
            DBMS_OUTPUT.PUT_LINE(
                'VERIFICADO: ROL_SOPORTE TIENE privilegio EXECUTE en SP_CAMBIAR_PLAN.'
            );
            DBMS_OUTPUT.PUT_LINE(
                '=> qf_soporte puede ejecutar:'
            );
            DBMS_OUTPUT.PUT_LINE(
                '   EXEC sp_cambiar_plan(p_id_usuario=>1, p_nuevo_id_plan=>2);'
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE('ADVERTENCIA: El rol no tiene EXECUTE en SP_CAMBIAR_PLAN.');
        END IF;
    END;
END;
/

-- -------------------------------------------------------
-- DEMOSTRACION 5: Verificar que el PERFIL limita sesiones
-- -------------------------------------------------------

PROMPT ---------------------------------------------------
PROMPT DEMO 5: Restricciones del PROFILE para qf_soporte
PROMPT ---------------------------------------------------

SELECT
    dp.profile,
    dp.resource_name,
    dp.limit
  FROM dba_profiles dp
 WHERE dp.profile = 'PERFIL_RESTRINGIDO'
   AND dp.resource_name IN (
       'SESSIONS_PER_USER',
       'IDLE_TIME',
       'CONNECT_TIME',
       'FAILED_LOGIN_ATTEMPTS',
       'PASSWORD_LOCK_TIME'
   )
 ORDER BY dp.resource_name;

-- Verificar que qf_soporte usa el perfil restringido
SELECT username, profile, account_status
  FROM dba_users
 WHERE username = 'QF_SOPORTE';

PROMPT =====================================================
PROMPT RESUMEN FINAL DE PRIVILEGIOS POR ROL
PROMPT =====================================================

-- Resumen de cuantos privilegios de objeto tiene cada rol
SELECT
    grantee                  AS rol,
    COUNT(DISTINCT table_name) AS tablas_con_acceso,
    COUNT(*)                   AS total_privilegios,
    SUM(CASE WHEN privilege = 'SELECT' THEN 1 ELSE 0 END) AS select_count,
    SUM(CASE WHEN privilege = 'INSERT' THEN 1 ELSE 0 END) AS insert_count,
    SUM(CASE WHEN privilege = 'UPDATE' THEN 1 ELSE 0 END) AS update_count,
    SUM(CASE WHEN privilege = 'DELETE' THEN 1 ELSE 0 END) AS delete_count,
    SUM(CASE WHEN privilege = 'EXECUTE' THEN 1 ELSE 0 END) AS execute_count
  FROM dba_tab_privs
 WHERE grantee IN ('ROL_ADMIN','ROL_ANALISTA','ROL_SOPORTE','ROL_CONTENIDO')
 GROUP BY grantee
 ORDER BY total_privilegios DESC;

PROMPT =====================================================
PROMPT FIN DEL SCRIPT NT5 - ADMINISTRACION DE ACCESO
PROMPT =====================================================
