-- ============================================================
-- SIAC — Inicializacion Docker (corre como SYSDBA una sola vez)
-- Crea: tablespace UNA, usuario MVARGAS, privilegios
-- ============================================================

WHENEVER SQLERROR CONTINUE;

-- 1. Tablespace UNA
CREATE TABLESPACE UNA
  DATAFILE '/opt/oracle/oradata/XE/una01.dbf'
  SIZE 200M
  AUTOEXTEND ON NEXT 50M
  MAXSIZE UNLIMITED
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;

-- 2. Usuario (primera letra nombre + primer apellido -> MVARGAS)
--    Si ya fue creado por APP_USER, solo se ajustan privilegios
BEGIN
    EXECUTE IMMEDIATE 'ALTER USER MVARGAS DEFAULT TABLESPACE UNA QUOTA UNLIMITED ON UNA';
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- el usuario ya tiene lo necesario
END;
/

-- 3. Privilegios completos para desarrollo
GRANT CONNECT, RESOURCE          TO MVARGAS;
GRANT CREATE VIEW                TO MVARGAS;
GRANT CREATE SEQUENCE            TO MVARGAS;
GRANT CREATE PROCEDURE           TO MVARGAS;
GRANT CREATE TRIGGER             TO MVARGAS;
GRANT CREATE TYPE                TO MVARGAS;
GRANT UNLIMITED TABLESPACE       TO MVARGAS;

-- Privilegios de exportacion/importacion
GRANT EXP_FULL_DATABASE          TO MVARGAS;
GRANT IMP_FULL_DATABASE          TO MVARGAS;
GRANT DATAPUMP_EXP_FULL_DATABASE TO MVARGAS;
GRANT DATAPUMP_IMP_FULL_DATABASE TO MVARGAS;

-- 4. Crear directorio para Data Pump (backups)
CREATE OR REPLACE DIRECTORY dpump_dir AS '/opt/oracle/admin/XE/dpdump';
GRANT READ, WRITE ON DIRECTORY dpump_dir TO MVARGAS;

-- 5. Confirmacion
PROMPT ============================================
PROMPT Tablespace UNA y usuario MVARGAS listos.
PROMPT ============================================

EXIT;
