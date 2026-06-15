#!/bin/bash
# ============================================================
# SIAC — Ejecuta DDL y paquete como MVARGAS
# Corre tras 01-create-user.sql, dentro del contenedor
# ============================================================
set -e

CONN="mvargas/SiacPass2026#@XEPDB1"
SCRIPT_DIR="/opt/siac"
LOG="/tmp/siac-init.log"

echo "============================================" | tee -a "$LOG"
echo "SIAC — Inicializando schema MVARGAS"        | tee -a "$LOG"
echo "Fecha: $(date)"                                | tee -a "$LOG"
echo "============================================" | tee -a "$LOG"

# 1. Estructura de la base de datos (tablas, secuencias, etc.)
echo "" | tee -a "$LOG"
echo "[1/3] Ejecutando siac-db.ddl..." | tee -a "$LOG"
sqlplus -S "$CONN" <<SQL
    WHENEVER SQLERROR EXIT SQL.SQLCODE;
    @$SCRIPT_DIR/siac-db.ddl
    EXIT;
SQL
echo "  -> DDL completado exitosamente." | tee -a "$LOG"

# 2. Especificacion del paquete
echo "" | tee -a "$LOG"
echo "[2/3] Creando especificacion del paquete..." | tee -a "$LOG"
sqlplus -S "$CONN" <<SQL
    WHENEVER SQLERROR EXIT SQL.SQLCODE;
    @$SCRIPT_DIR/PckAtencionComunitaria.pks
    EXIT;
SQL
echo "  -> Package spec creado." | tee -a "$LOG"

# 3. Cuerpo del paquete
echo "" | tee -a "$LOG"
echo "[3/3] Compilando cuerpo del paquete..." | tee -a "$LOG"
sqlplus -S "$CONN" <<SQL
    WHENEVER SQLERROR EXIT SQL.SQLCODE;
    @$SCRIPT_DIR/PckAtencionComunitaria.pkb
    EXIT;
SQL
echo "  -> Package body compilado." | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "============================================" | tee -a "$LOG"
echo "SIAC — Schema MVARGAS inicializado con exito" | tee -a "$LOG"
echo "============================================" | tee -a "$LOG"
