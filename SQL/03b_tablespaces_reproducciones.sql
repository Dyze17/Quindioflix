-- ============================================================
-- INSTRUCCIONES PARA EL USUARIO:
--   Antes de ejecutar este script, ajusta DATA_DIR al directorio
--   de datos de tu instalación Oracle. Ejemplos comunes:
--
--   Windows (Oracle XE 21c):
--     DEFINE DATA_DIR = 'C:\app\<tu_usuario>\product\21c\oradata\XE\<tu_pdb>'
--
--   Linux / macOS:
--     DEFINE DATA_DIR = '/opt/oracle/oradata/XE/<tu_pdb>'
--
--   Puedes consultar el directorio actual ejecutando:
--     SELECT name FROM v$datafile WHERE rownum = 1;
-- ============================================================

-- OPCIÓN A: Define manualmente tu directorio (descomenta y edita)
-- DEFINE DATA_DIR = 'C:\app\<tu_usuario>\product\21c\oradata\XE\<tu_pdb>'

-- OPCIÓN B: Oracle determina automáticamente el directorio por defecto (recomendado)
--   Oracle usará OMF (Oracle Managed Files) si DB_CREATE_FILE_DEST está configurado.
--   Ejecuta primero:
--     ALTER SYSTEM SET DB_CREATE_FILE_DEST='/opt/oracle/oradata' SCOPE=BOTH;

CREATE TABLESPACE ts_repro_2024
DATAFILE SIZE 50M
AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

CREATE TABLESPACE ts_repro_2025
DATAFILE SIZE 50M
AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

CREATE TABLESPACE ts_repro_max
DATAFILE SIZE 50M
AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

ALTER TABLE reproducciones MOVE PARTITION p_repro_2024 TABLESPACE ts_repro_2024 UPDATE INDEXES;
ALTER TABLE reproducciones MOVE PARTITION p_repro_2025 TABLESPACE ts_repro_2025 UPDATE INDEXES;
ALTER TABLE reproducciones MOVE PARTITION p_repro_max  TABLESPACE ts_repro_max  UPDATE INDEXES;