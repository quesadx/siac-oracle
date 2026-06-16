#!/bin/bash
# ============================================================
# SIAC — Startup unificado
# Corre despues de "DATABASE IS READY TO USE!", BD abierta.
# Idempotente: si el schema ya existe, solo recompila paquete.
# ============================================================
set -e

SCRIPT_DIR="/opt/siac"
LOG="/tmp/siac-startup.log"
SYS_CONN="sys/AdminPass2026#@FREEPDB1 as sysdba"
APP_CONN="mvargas/SiacPass2026#@FREEPDB1"

echo "============================================" | tee -a "$LOG"
echo "SIAC — Startup $(date)"                     | tee -a "$LOG"
echo "============================================" | tee -a "$LOG"

# ------------------------------------------------------------------
# Fase 0: Esperar a que FREEPDB1 este registrado en el listener
# ------------------------------------------------------------------
for i in $(seq 1 30); do
    if echo "SELECT 1 FROM DUAL;" | sqlplus -S "$SYS_CONN" > /dev/null 2>&1; then
        echo "  -> FREEPDB1 accesible." | tee -a "$LOG"
        break
    fi
    [ "$i" -eq 30 ] && { echo "  ERROR: FREEPDB1 no accesible tras 30 intentos." | tee -a "$LOG"; exit 1; }
    sleep 3
done

# ------------------------------------------------------------------
# Fase 1: Crear tablespace + usuario (SYSDBA, idempotente)
# ------------------------------------------------------------------
echo "[1/3] Configurando tablespace y usuario..." | tee -a "$LOG"
sqlplus -S "$SYS_CONN" <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO cnt FROM dba_tablespaces WHERE tablespace_name='UNA';
    IF cnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLESPACE UNA DATAFILE ''/opt/oracle/oradata/FREE/FREEPDB1/una01.dbf'' SIZE 200M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED';
        DBMS_OUTPUT.PUT_LINE('Tablespace UNA creado.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Tablespace UNA ya existe.');
    END IF;
END;
/

DECLARE
    cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO cnt FROM dba_users WHERE username='MVARGAS';
    IF cnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER MVARGAS IDENTIFIED BY "SiacPass2026#" DEFAULT TABLESPACE UNA TEMPORARY TABLESPACE TEMP QUOTA UNLIMITED ON UNA';
        EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE, UNLIMITED TABLESPACE TO MVARGAS';
        EXECUTE IMMEDIATE 'GRANT EXP_FULL_DATABASE, IMP_FULL_DATABASE, DATAPUMP_EXP_FULL_DATABASE, DATAPUMP_IMP_FULL_DATABASE TO MVARGAS';
        DBMS_OUTPUT.PUT_LINE('Usuario MVARGAS creado.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Usuario MVARGAS ya existe.');
    END IF;
END;
/

CREATE OR REPLACE DIRECTORY dpump_dir AS '/opt/oracle/admin/FREE/dpdump';
GRANT READ, WRITE ON DIRECTORY dpump_dir TO MVARGAS;

EXIT;
SQL
echo "  -> OK." | tee -a "$LOG"

# ------------------------------------------------------------------
# Fase 2: Verificar si el schema ya fue aplicado
# ------------------------------------------------------------------
ALREADY=$(echo "SELECT COUNT(*) FROM user_tables WHERE table_name='SIAC_REGION';" | sqlplus -S "$APP_CONN" 2>/dev/null | tail -1 | tr -d ' ')

if [ "$ALREADY" = "1" ]; then
    echo "[2/3] Schema SIAC ya existe. Omitiendo DDL." | tee -a "$LOG"
    echo "[3/3] Recompilando paquete..." | tee -a "$LOG"
    echo "@$SCRIPT_DIR/PckAtencionComunitaria.pks" | sqlplus -S "$APP_CONN" 2>&1 | tee -a "$LOG"
    echo "@$SCRIPT_DIR/PckAtencionComunitaria.pkb" | sqlplus -S "$APP_CONN" 2>&1 | tee -a "$LOG"
    echo "============================================" | tee -a "$LOG"
    exit 0
fi

# ------------------------------------------------------------------
# Fase 3: Aplicar DDL completo
# ------------------------------------------------------------------
echo "[2/3] Ejecutando siac-db.ddl..." | tee -a "$LOG"
sqlplus -S "$APP_CONN" <<SQL
    WHENEVER SQLERROR EXIT SQL.SQLCODE;
    @$SCRIPT_DIR/siac-db.ddl
    EXIT;
SQL
echo "  -> DDL completado." | tee -a "$LOG"

# ------------------------------------------------------------------
# Fase 4: Crear paquete
# ------------------------------------------------------------------
echo "[3/3] Creando PckAtencionComunitaria..." | tee -a "$LOG"
sqlplus -S "$APP_CONN" <<SQL
    WHENEVER SQLERROR EXIT SQL.SQLCODE;
    @$SCRIPT_DIR/PckAtencionComunitaria.pks
    EXIT;
SQL
sqlplus -S "$APP_CONN" <<SQL
    WHENEVER SQLERROR EXIT SQL.SQLCODE;
    @$SCRIPT_DIR/PckAtencionComunitaria.pkb
    EXIT;
SQL
echo "  -> Paquete compilado." | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "============================================" | tee -a "$LOG"
echo "SIAC — Schema MVARGAS inicializado con exito." | tee -a "$LOG"
echo "============================================" | tee -a "$LOG"
