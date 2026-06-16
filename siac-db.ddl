-- ============================================================
-- AVANCE 2: MODELO RELACIONAL NORMALIZADO (3FN estricta)
-- Sistema de Información para Atención Comunitaria (SIAC) [ Pasé el script por Prettier SQL]
-- ============================================================
-- 0. CONFIGURACIÓN INICIAL (ejecutar como SYSDBA)
-- ============================================================
/*
CREATE TABLESPACE UNA
  DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/una01.dbf'
  SIZE 200M AUTOEXTEND ON NEXT 50M MAXSIZE UNLIMITED
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;

CREATE USER MVARGAS IDENTIFIED BY "SiacPass2026#"
  DEFAULT TABLESPACE UNA
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON UNA;

GRANT CONNECT, RESOURCE                TO MVARGAS;
GRANT CREATE VIEW                      TO MVARGAS;
GRANT CREATE SEQUENCE                  TO MVARGAS;
GRANT CREATE PROCEDURE                 TO MVARGAS;
GRANT CREATE TRIGGER                   TO MVARGAS;
GRANT CREATE TYPE                      TO MVARGAS;
GRANT EXP_FULL_DATABASE                TO MVARGAS;
GRANT IMP_FULL_DATABASE                TO MVARGAS;
GRANT DATAPUMP_EXP_FULL_DATABASE       TO MVARGAS;
GRANT DATAPUMP_IMP_FULL_DATABASE       TO MVARGAS;
*/
-- ============================================================
-- A partir de aquí, ejecutar conectado como el usuario creado
-- ============================================================
-- ============================================================
-- 1. LIMPIEZA (DROP en orden inverso por dependencias)
-- ============================================================
BEGIN
    FOR v IN (SELECT view_name FROM user_views
              WHERE view_name LIKE 'SIAC\_%' ESCAPE '\') LOOP
        EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
    END LOOP;
END;
/

BEGIN
    FOR t IN (SELECT table_name FROM user_tables
              WHERE table_name LIKE 'SIAC\_%' ESCAPE '\'
              ORDER BY table_name) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;
END;
/

BEGIN
    FOR s IN (SELECT sequence_name FROM user_sequences
              WHERE sequence_name LIKE 'SIAC\_SEQ\_%' ESCAPE '\') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- ============================================================
-- 2. SECUENCIAS (16 secuencias)
-- ============================================================
CREATE SEQUENCE siac_seq_region         START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_distrito       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_comunidad      START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_vivienda       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_familia        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_persona        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_tipo_contacto  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_contacto       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_tipo_control   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_control_salud  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_enfermedad     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_persona_enf    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_programa       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_beneficiario   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_rol            START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE siac_seq_usuario        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ============================================================
-- 3. MÓDULO GESTIÓN GEOGRÁFICA
-- ============================================================
-- 3.1 SIAC_REGION (tabla 1/16)
CREATE TABLE siac_region (
    id_region      NUMBER       CONSTRAINT pk_siac_region PRIMARY KEY,
    nombre         VARCHAR2(100) CONSTRAINT nn_region_nombre NOT NULL,
    descripcion    VARCHAR2(500),
    estado         VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_region_estado NOT NULL
                   CONSTRAINT ck_region_estado CHECK (estado IN ('A','I')),
    fecha_registro DATE DEFAULT SYSDATE
) TABLESPACE una;

COMMENT ON TABLE  siac_region IS 'Regiones geográficas del sistema SIAC';
COMMENT ON COLUMN siac_region.id_region IS 'Identificador único de la región';
COMMENT ON COLUMN siac_region.nombre    IS 'Nombre de la región';
COMMENT ON COLUMN siac_region.estado    IS 'Estado: A=Activo / I=Inactivo';

-- 3.2 SIAC_DISTRITO (tabla 2/16)
CREATE TABLE siac_distrito (
    id_distrito    NUMBER        CONSTRAINT pk_siac_distrito PRIMARY KEY,
    nombre         VARCHAR2(100) CONSTRAINT nn_distrito_nombre NOT NULL,
    descripcion    VARCHAR2(500),
    id_region      NUMBER        CONSTRAINT nn_distrito_region NOT NULL,
    estado         VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_distrito_estado NOT NULL
                   CONSTRAINT ck_distrito_estado CHECK (estado IN ('A','I')),
    fecha_registro DATE DEFAULT SYSDATE,
    CONSTRAINT fk_distrito_region FOREIGN KEY (id_region)
        REFERENCES siac_region (id_region)
) TABLESPACE una;

COMMENT ON TABLE  siac_distrito IS 'Distritos dentro de cada región';
COMMENT ON COLUMN siac_distrito.id_region IS 'FK → SIAC_REGION';
COMMENT ON COLUMN siac_distrito.estado    IS 'Estado: A=Activo / I=Inactivo';

-- 3.3 SIAC_COMUNIDAD (tabla 3/16)
CREATE TABLE siac_comunidad (
    id_comunidad   NUMBER        CONSTRAINT pk_siac_comunidad PRIMARY KEY,
    nombre         VARCHAR2(100) CONSTRAINT nn_comunidad_nombre NOT NULL,
    descripcion    VARCHAR2(500),
    id_distrito    NUMBER        CONSTRAINT nn_comunidad_dist NOT NULL,
    estado         VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_comunidad_estado NOT NULL
                   CONSTRAINT ck_comunidad_estado CHECK (estado IN ('A','I')),
    fecha_registro DATE DEFAULT SYSDATE,
    CONSTRAINT fk_comunidad_distrito FOREIGN KEY (id_distrito)
        REFERENCES siac_distrito (id_distrito)
) TABLESPACE una;

COMMENT ON TABLE  siac_comunidad IS 'Comunidades dentro de cada distrito';
COMMENT ON COLUMN siac_comunidad.id_distrito IS 'FK → SIAC_DISTRITO';
COMMENT ON COLUMN siac_comunidad.estado      IS 'Estado: A=Activo / I=Inactivo';

-- ============================================================
-- 4. MÓDULO VIVIENDAS
-- ============================================================
-- 4.1 SIAC_VIVIENDA (tabla 4/16)
CREATE TABLE siac_vivienda (
    id_vivienda           NUMBER        CONSTRAINT pk_siac_vivienda PRIMARY KEY,
    direccion_exacta      VARCHAR2(400) CONSTRAINT nn_vivienda_dir NOT NULL,
    id_comunidad          NUMBER        CONSTRAINT nn_vivienda_com NOT NULL,
    condicion_general     VARCHAR2(1) DEFAULT 'R' CONSTRAINT nn_vivienda_cond NOT NULL
                          CONSTRAINT ck_vivienda_cond CHECK (condicion_general IN ('B','R','M')),
    tipo_vivienda         VARCHAR2(1)   CONSTRAINT ck_vivienda_tipo
                          CHECK (tipo_vivienda IN ('P','A','R','O')),
    material_paredes      VARCHAR2(50),
    material_techo        VARCHAR2(50),
    acceso_agua           VARCHAR2(1) DEFAULT 'N' CONSTRAINT ck_vivienda_agua
                          CHECK (acceso_agua IN ('S','N')),
    acceso_electricidad   VARCHAR2(1) DEFAULT 'N' CONSTRAINT ck_vivienda_elec
                          CHECK (acceso_electricidad IN ('S','N')),
    acceso_alcantarillado VARCHAR2(1) DEFAULT 'N' CONSTRAINT ck_vivienda_alcan
                          CHECK (acceso_alcantarillado IN ('S','N')),
    acceso_internet       VARCHAR2(1) DEFAULT 'N' CONSTRAINT ck_vivienda_inet
                          CHECK (acceso_internet IN ('S','N')),
    estado_sanitario      VARCHAR2(1) DEFAULT 'A' CONSTRAINT ck_vivienda_sanit
                          CHECK (estado_sanitario IN ('A','I','R')),
    observaciones         VARCHAR2(1000),
    fecha_registro        DATE DEFAULT SYSDATE,
    CONSTRAINT fk_vivienda_comunidad FOREIGN KEY (id_comunidad)
        REFERENCES siac_comunidad (id_comunidad)
) TABLESPACE una;

COMMENT ON TABLE  siac_vivienda IS 'Viviendas registradas por comunidad';
COMMENT ON COLUMN siac_vivienda.condicion_general IS 'B=Buena / R=Regular / M=Mala';
COMMENT ON COLUMN siac_vivienda.tipo_vivienda     IS 'P=Propia / A=Alquilada / R=Prestada / O=Otro';
COMMENT ON COLUMN siac_vivienda.acceso_agua       IS 'S=Sí tiene / N=No tiene';
COMMENT ON COLUMN siac_vivienda.estado_sanitario  IS 'A=Adecuado / I=Inadecuado / R=En revisión';

-- ============================================================
-- 5. MÓDULO PERSONAS (creada ANTES de FAMILIA por FK del jefe)
-- ============================================================
-- 5.1 SIAC_PERSONA (tabla 5/16)
CREATE TABLE siac_persona (
    id_persona       NUMBER        CONSTRAINT pk_siac_persona PRIMARY KEY,
    cedula           VARCHAR2(30)  CONSTRAINT nn_persona_ced NOT NULL,
    nombre           VARCHAR2(100) CONSTRAINT nn_persona_nom NOT NULL,
    primer_apellido  VARCHAR2(100) CONSTRAINT nn_persona_ap1 NOT NULL,
    segundo_apellido VARCHAR2(100),
    fecha_nacimiento DATE          CONSTRAINT nn_persona_fnac NOT NULL,
    genero           VARCHAR2(1)   CONSTRAINT nn_persona_gen NOT NULL
                   CONSTRAINT ck_persona_genero CHECK (genero IN ('M','F','O')),
    estado_civil     VARCHAR2(1)   CONSTRAINT ck_persona_ecivil
                   CHECK (estado_civil IN ('S','C','D','V','U')),
    nivel_educativo  VARCHAR2(1)   CONSTRAINT ck_persona_educ
                   CHECK (nivel_educativo IN ('N','P','S','T','U','G')),
    ocupacion        VARCHAR2(150),
    relacion_familia VARCHAR2(1)   CONSTRAINT ck_persona_rel
                   CHECK (relacion_familia IN ('J','C','H','P','M','A','R','O')),
    estado           VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_persona_estado NOT NULL
                   CONSTRAINT ck_persona_estado CHECK (estado IN ('A','I','F')),
    fecha_registro   DATE DEFAULT SYSDATE,
    CONSTRAINT uq_persona_cedula UNIQUE (cedula)
) TABLESPACE una;

COMMENT ON TABLE  siac_persona IS 'Personas registradas en el sistema SIAC';
COMMENT ON COLUMN siac_persona.cedula          IS 'Identificación única (VARCHAR2(30))';
COMMENT ON COLUMN siac_persona.genero          IS 'M=Masculino / F=Femenino / O=Otro';
COMMENT ON COLUMN siac_persona.estado_civil    IS 'S=Soltero / C=Casado / D=Divorciado / V=Viudo / U=Unión libre';
COMMENT ON COLUMN siac_persona.nivel_educativo IS 'N=Ninguno / P=Primaria / S=Secundaria / T=Técnico / U=Universitario / G=Posgrado';
COMMENT ON COLUMN siac_persona.relacion_familia IS 'J=Jefe / C=Cónyuge / H=Hijo / P=Padre / M=Madre / A=Abuelo / R=Hermano / O=Otro';
COMMENT ON COLUMN siac_persona.estado          IS 'A=Activo / I=Inactivo / F=Fallecido';

-- ============================================================
-- 6. MÓDULO FAMILIAS  ★★★ NORMALIZADO ★★★
--    Se eliminó id_comunidad (transitiva vía vivienda)
--    Se eliminó cantidad_miembros (atributo derivado)
-- ============================================================
-- 6.1 SIAC_FAMILIA (tabla 6/16)
CREATE TABLE siac_familia (
    id_familia           NUMBER        CONSTRAINT pk_siac_familia PRIMARY KEY,
    nombre_familia       VARCHAR2(200) CONSTRAINT nn_familia_nombre NOT NULL,
    id_jefe_familia      NUMBER,  -- FK deferida a SIAC_PERSONA
    clasificacion_riesgo VARCHAR2(1) DEFAULT 'B' CONSTRAINT nn_familia_riesgo NOT NULL
                         CONSTRAINT ck_familia_riesgo CHECK (clasificacion_riesgo IN ('A','M','B')),
    id_vivienda          NUMBER        CONSTRAINT nn_familia_viv NOT NULL,
    observaciones        VARCHAR2(1000),
    estado               VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_familia_estado NOT NULL
                         CONSTRAINT ck_familia_estado CHECK (estado IN ('A','I')),
    fecha_registro       DATE DEFAULT SYSDATE,
    CONSTRAINT fk_familia_vivienda FOREIGN KEY (id_vivienda)
        REFERENCES siac_vivienda (id_vivienda),
    CONSTRAINT fk_familia_jefe FOREIGN KEY (id_jefe_familia)
        REFERENCES siac_persona (id_persona) DEFERRABLE INITIALLY DEFERRED
) TABLESPACE una;

COMMENT ON TABLE  siac_familia IS 'Grupos familiares registrados en el SIAC';
COMMENT ON COLUMN siac_familia.id_jefe_familia     IS 'FK deferida → SIAC_PERSONA (jefe del hogar)';
COMMENT ON COLUMN siac_familia.clasificacion_riesgo IS 'A=Alto / M=Medio / B=Bajo';
COMMENT ON COLUMN siac_familia.estado              IS 'Estado: A=Activo / I=Inactivo';
COMMENT ON COLUMN siac_familia.id_vivienda         IS 'FK → SIAC_VIVIENDA (la comunidad se deriva vía vivienda)';

-- 6.2 Añadir FK de SIAC_PERSONA → SIAC_FAMILIA
ALTER TABLE siac_persona ADD (id_familia NUMBER);

ALTER TABLE siac_persona
  ADD CONSTRAINT fk_persona_familia FOREIGN KEY (id_familia)
      REFERENCES siac_familia (id_familia);

COMMENT ON COLUMN siac_persona.id_familia IS 'FK → SIAC_FAMILIA: familia a la que pertenece';

-- ============================================================
-- 7. MÓDULO CONTACTOS
-- ============================================================
-- 7.1 SIAC_TIPO_CONTACTO (tabla 7/16 – catálogo)
CREATE TABLE siac_tipo_contacto (
    id_tipo_contacto NUMBER       CONSTRAINT pk_siac_tipo_cont PRIMARY KEY,
    descripcion      VARCHAR2(60) CONSTRAINT nn_tipo_cont_desc NOT NULL,
    estado           VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_tipo_cont_estado NOT NULL
                     CONSTRAINT ck_tipo_cont_estado CHECK (estado IN ('A','I')),
    CONSTRAINT uq_tipo_contacto_desc UNIQUE (descripcion)
) TABLESPACE una;

COMMENT ON TABLE  siac_tipo_contacto IS 'Catálogo de tipos de contacto';
COMMENT ON COLUMN siac_tipo_contacto.descripcion IS 'Ej: TELEFONO, CELULAR, EMAIL, WHATSAPP, FAX';
COMMENT ON COLUMN siac_tipo_contacto.estado      IS 'Estado: A=Activo / I=Inactivo';

-- 7.2 SIAC_CONTACTO (tabla 8/16)
CREATE TABLE siac_contacto (
    id_contacto      NUMBER        CONSTRAINT pk_siac_contacto PRIMARY KEY,
    id_tipo_contacto NUMBER        CONSTRAINT nn_cont_tipo NOT NULL,
    valor            VARCHAR2(200) CONSTRAINT nn_cont_valor NOT NULL,
    id_persona       NUMBER,
    id_familia       NUMBER,
    es_principal     VARCHAR2(1) DEFAULT 'N' CONSTRAINT ck_cont_princ
                     CHECK (es_principal IN ('S','N')),
    estado           VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_cont_estado NOT NULL
                     CONSTRAINT ck_cont_estado CHECK (estado IN ('A','I')),
    fecha_registro   DATE DEFAULT SYSDATE,
    CONSTRAINT fk_contacto_tipo    FOREIGN KEY (id_tipo_contacto)
        REFERENCES siac_tipo_contacto (id_tipo_contacto),
    CONSTRAINT fk_contacto_persona FOREIGN KEY (id_persona)
        REFERENCES siac_persona (id_persona),
    CONSTRAINT fk_contacto_familia FOREIGN KEY (id_familia)
        REFERENCES siac_familia (id_familia),
    CONSTRAINT ck_contacto_dueno CHECK (
        (id_persona IS NOT NULL AND id_familia IS NULL)
     OR (id_persona IS NULL AND id_familia IS NOT NULL)
     OR (id_persona IS NOT NULL AND id_familia IS NOT NULL)
    )
) TABLESPACE una;

COMMENT ON TABLE  siac_contacto IS 'Medios de contacto de personas o familias';
COMMENT ON COLUMN siac_contacto.es_principal IS 'S=contacto preferido / N=no';
COMMENT ON COLUMN siac_contacto.id_persona   IS 'FK opcional → SIAC_PERSONA';
COMMENT ON COLUMN siac_contacto.id_familia   IS 'FK opcional → SIAC_FAMILIA';
COMMENT ON COLUMN siac_contacto.estado       IS 'Estado: A=Activo / I=Inactivo';

-- ============================================================
-- 8. MÓDULO CONTROLES DE SALUD
-- ============================================================
-- 8.1 SIAC_TIPO_CONTROL (tabla 9/16 – catálogo)
CREATE TABLE siac_tipo_control (
    id_tipo_control   NUMBER        CONSTRAINT pk_siac_tipo_ctrl PRIMARY KEY,
    descripcion       VARCHAR2(120) CONSTRAINT nn_tipo_ctrl_desc NOT NULL,
    periodicidad_dias NUMBER(5),
    estado            VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_tipo_ctrl_estado NOT NULL
                      CONSTRAINT ck_tipo_ctrl_estado CHECK (estado IN ('A','I')),
    CONSTRAINT uq_tipo_ctrl_desc UNIQUE (descripcion)
) TABLESPACE una;

COMMENT ON TABLE  siac_tipo_control IS 'Catálogo de tipos de control preventivo';
COMMENT ON COLUMN siac_tipo_control.periodicidad_dias IS 'Frecuencia recomendada en días';
COMMENT ON COLUMN siac_tipo_control.estado            IS 'Estado: A=Activo / I=Inactivo';

-- 8.2 SIAC_CONTROL_SALUD (tabla 10/16)
CREATE TABLE siac_control_salud (
    id_control         NUMBER        CONSTRAINT pk_siac_ctrl_salud PRIMARY KEY,
    id_persona         NUMBER        CONSTRAINT nn_ctrl_persona NOT NULL,
    id_tipo_control    NUMBER        CONSTRAINT nn_ctrl_tipo NOT NULL,
    fecha_control      DATE          CONSTRAINT nn_ctrl_fecha NOT NULL,
    fecha_proxima_cita DATE,
    peso_kg            NUMBER(5,2),
    talla_cm           NUMBER(5,2),
    tension_arterial   VARCHAR2(15),
    resultado          VARCHAR2(1)   CONSTRAINT nn_ctrl_resultado NOT NULL
                     CONSTRAINT ck_ctrl_resultado CHECK (resultado IN ('N','A','C','P')),
    profesional_responsable VARCHAR2(200) CONSTRAINT nn_ctrl_prof NOT NULL,
    numero_expediente  VARCHAR2(50),
    observaciones      VARCHAR2(2000),
    fecha_registro     DATE DEFAULT SYSDATE,
    CONSTRAINT fk_ctrl_persona FOREIGN KEY (id_persona)
        REFERENCES siac_persona (id_persona),
    CONSTRAINT fk_ctrl_tipo FOREIGN KEY (id_tipo_control)
        REFERENCES siac_tipo_control (id_tipo_control)
) TABLESPACE una;

COMMENT ON TABLE  siac_control_salud IS 'Registro de controles preventivos de salud';
COMMENT ON COLUMN siac_control_salud.fecha_proxima_cita IS 'Fecha sugerida para el siguiente control';
COMMENT ON COLUMN siac_control_salud.resultado          IS 'N=Normal / A=Alterado / C=Crítico / P=Pendiente';

-- ============================================================
-- 9. MÓDULO ENFERMEDADES Y CONDICIONES
-- ============================================================
-- 9.1 SIAC_ENFERMEDAD (tabla 11/16 – catálogo)
CREATE TABLE siac_enfermedad (
    id_enfermedad NUMBER        CONSTRAINT pk_siac_enfermedad PRIMARY KEY,
    nombre        VARCHAR2(200) CONSTRAINT nn_enf_nombre NOT NULL,
    codigo_cie10  VARCHAR2(10),
    tipo          VARCHAR2(1) DEFAULT 'C' CONSTRAINT nn_enf_tipo NOT NULL
                  CONSTRAINT ck_enf_tipo CHECK (tipo IN ('C','T','I','M','O')),
    descripcion   VARCHAR2(1000),
    estado        VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_enf_estado NOT NULL
                  CONSTRAINT ck_enf_estado CHECK (estado IN ('A','I')),
    CONSTRAINT uq_enfermedad_nombre UNIQUE (nombre)
) TABLESPACE una;

COMMENT ON TABLE  siac_enfermedad IS 'Catálogo de enfermedades y condiciones médicas';
COMMENT ON COLUMN siac_enfermedad.codigo_cie10 IS 'Código CIE-10 de clasificación internacional';
COMMENT ON COLUMN siac_enfermedad.tipo         IS 'C=Crónica / T=Temporal / I=Infecciosa / M=Mental / O=Otra';
COMMENT ON COLUMN siac_enfermedad.estado       IS 'Estado: A=Activo / I=Inactivo';

-- 9.2 SIAC_PERSONA_ENFERMEDAD (tabla 12/16 – puente N:M)
CREATE TABLE siac_persona_enfermedad (
    id_persona_enf     NUMBER       CONSTRAINT pk_siac_pers_enf PRIMARY KEY,
    id_persona         NUMBER       CONSTRAINT nn_penferm_per NOT NULL,
    id_enfermedad      NUMBER       CONSTRAINT nn_penferm_enf NOT NULL,
    fecha_diagnostico  DATE         CONSTRAINT nn_penferm_fdiag NOT NULL,
    estado_condicion   VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_penferm_estado NOT NULL
                       CONSTRAINT ck_penferm_estado CHECK (estado_condicion IN ('A','C','R','S')),
    medico_diagnostico VARCHAR2(200),
    tratamiento        VARCHAR2(1000),
    seguimiento        VARCHAR2(2000),
    fecha_resolucion   DATE,
    fecha_registro     DATE DEFAULT SYSDATE,
    CONSTRAINT fk_penferm_persona FOREIGN KEY (id_persona)
        REFERENCES siac_persona (id_persona),
    CONSTRAINT fk_penferm_enfer FOREIGN KEY (id_enfermedad)
        REFERENCES siac_enfermedad (id_enfermedad),
    CONSTRAINT uq_persona_enfermedad UNIQUE (id_persona, id_enfermedad)
) TABLESPACE una;

COMMENT ON TABLE  siac_persona_enfermedad IS 'Relación N:M entre personas y enfermedades';
COMMENT ON COLUMN siac_persona_enfermedad.estado_condicion IS 'A=Activa / C=Controlada / R=Resuelta / S=En seguimiento';
COMMENT ON COLUMN siac_persona_enfermedad.tratamiento      IS 'Descripción del tratamiento indicado';

-- ============================================================
-- 10. MÓDULO PROGRAMAS COMUNITARIOS
-- ============================================================
-- 10.1 SIAC_PROGRAMA (tabla 13/16)
CREATE TABLE siac_programa (
    id_programa  NUMBER        CONSTRAINT pk_siac_programa PRIMARY KEY,
    nombre       VARCHAR2(250) CONSTRAINT nn_prog_nombre NOT NULL,
    descripcion  VARCHAR2(1000),
    tipo         VARCHAR2(1)   CONSTRAINT nn_prog_tipo NOT NULL
                 CONSTRAINT ck_prog_tipo CHECK (tipo IN ('S','A','E','N','O')),
    institucion  VARCHAR2(200),
    fecha_inicio DATE,
    fecha_fin    DATE,
    estado       VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_prog_estado NOT NULL
                 CONSTRAINT ck_prog_estado CHECK (estado IN ('A','F','S','I')),
    CONSTRAINT uq_programa_nombre UNIQUE (nombre)
) TABLESPACE una;

COMMENT ON TABLE  siac_programa IS 'Programas comunitarios de apoyo y prevención';
COMMENT ON COLUMN siac_programa.institucion IS 'Entidad responsable del programa';
COMMENT ON COLUMN siac_programa.tipo        IS 'S=Social / A=Sanitario / E=Educativo / N=Nutricional / O=Otro';
COMMENT ON COLUMN siac_programa.estado      IS 'A=Activo / F=Finalizado / S=Suspendido / I=Inactivo';

-- 10.2 SIAC_BENEFICIARIO (tabla 14/16 – puente N:M Persona–Programa)
CREATE TABLE siac_beneficiario (
    id_beneficiario   NUMBER      CONSTRAINT pk_siac_benef PRIMARY KEY,
    id_programa       NUMBER      CONSTRAINT nn_benef_prog NOT NULL,
    id_persona        NUMBER      CONSTRAINT nn_benef_per NOT NULL,
    fecha_inicio_participacion DATE       CONSTRAINT nn_benef_fino NOT NULL,
    fecha_fin_participacion    DATE,
    estado_participacion       VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_benef_estado NOT NULL
                               CONSTRAINT ck_benef_estado CHECK (estado_participacion IN ('A','C','R','S')),
    observaciones     VARCHAR2(1000),
    fecha_registro    DATE DEFAULT SYSDATE,
    CONSTRAINT fk_benef_programa FOREIGN KEY (id_programa)
        REFERENCES siac_programa (id_programa),
    CONSTRAINT fk_benef_persona FOREIGN KEY (id_persona)
        REFERENCES siac_persona (id_persona)
) TABLESPACE una;

COMMENT ON TABLE  siac_beneficiario IS 'Personas beneficiarias de programas comunitarios';
COMMENT ON COLUMN siac_beneficiario.estado_participacion IS 'A=Activo / C=Completado / R=Retirado / S=Suspendido';

-- ============================================================
-- 11. MÓDULO SEGURIDAD
-- ============================================================
-- 11.1 SIAC_ROL (tabla 15/16)
CREATE TABLE siac_rol (
    id_rol      NUMBER       CONSTRAINT pk_siac_rol PRIMARY KEY,
    nombre      VARCHAR2(60) CONSTRAINT nn_rol_nombre NOT NULL,
    descripcion VARCHAR2(500),
    estado      VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_rol_estado NOT NULL
                CONSTRAINT ck_rol_estado CHECK (estado IN ('A','I')),
    CONSTRAINT uq_rol_nombre UNIQUE (nombre)
) TABLESPACE una;

COMMENT ON TABLE  siac_rol IS 'Roles de acceso al sistema SIAC';
COMMENT ON COLUMN siac_rol.nombre IS 'Ej: ADMINISTRADOR, MEDICO, ENFERMERO, CONSULTA';
COMMENT ON COLUMN siac_rol.estado IS 'Estado: A=Activo / I=Inactivo';

-- 11.2 SIAC_USUARIO (tabla 16/16)
CREATE TABLE siac_usuario (
    id_usuario          NUMBER        CONSTRAINT pk_siac_usuario PRIMARY KEY,
    nombre_usuario      VARCHAR2(60)  CONSTRAINT nn_usr_user NOT NULL,
    hash_contrasena     VARCHAR2(512) CONSTRAINT nn_usr_pass NOT NULL,
    id_persona          NUMBER,
    id_rol              NUMBER        CONSTRAINT nn_usr_rol NOT NULL,
    correo              VARCHAR2(200),
    estado              VARCHAR2(1) DEFAULT 'A' CONSTRAINT nn_usr_estado NOT NULL
                        CONSTRAINT ck_usr_estado CHECK (estado IN ('A','B','I','P')),
    intentos_fallidos   NUMBER(2) DEFAULT 0,
    fecha_ultimo_acceso DATE,
    fecha_registro      DATE DEFAULT SYSDATE,
    CONSTRAINT uq_usuario_nombre_usuario UNIQUE (nombre_usuario),
    CONSTRAINT fk_usuario_persona FOREIGN KEY (id_persona)
        REFERENCES siac_persona (id_persona),
    CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol)
        REFERENCES siac_rol (id_rol)
) TABLESPACE una;

COMMENT ON TABLE  siac_usuario IS 'Usuarios con acceso al sistema SIAC';
COMMENT ON COLUMN siac_usuario.hash_contrasena     IS 'Hash de la contraseña (nunca texto plano)';
COMMENT ON COLUMN siac_usuario.estado              IS 'A=Activo / B=Bloqueado / I=Inactivo / P=Pendiente';
COMMENT ON COLUMN siac_usuario.intentos_fallidos   IS 'Contador para bloqueo automático (max 3-5)';
COMMENT ON COLUMN siac_usuario.fecha_ultimo_acceso IS 'Timestamp del último login exitoso';
COMMENT ON COLUMN siac_usuario.fecha_registro      IS 'Fecha de creación del usuario';

-- ============================================================
-- 12. ÍNDICES (FKs y búsquedas frecuentes)
-- ============================================================
CREATE INDEX idx_distrito_region       ON siac_distrito (id_region)         TABLESPACE una;
CREATE INDEX idx_comunidad_distrito    ON siac_comunidad (id_distrito)      TABLESPACE una;
CREATE INDEX idx_vivienda_comunidad    ON siac_vivienda (id_comunidad)      TABLESPACE una;
CREATE INDEX idx_familia_vivienda      ON siac_familia (id_vivienda)        TABLESPACE una;
CREATE INDEX idx_familia_jefe          ON siac_familia (id_jefe_familia)    TABLESPACE una;
CREATE INDEX idx_persona_familia       ON siac_persona (id_familia)         TABLESPACE una;
-- idx_persona_cedula omitido: uq_persona_cedula (UNIQUE) ya crea índice implícito
CREATE INDEX idx_cont_tipo            ON siac_contacto (id_tipo_contacto)   TABLESPACE una;
CREATE INDEX idx_cont_persona          ON siac_contacto (id_persona)        TABLESPACE una;
CREATE INDEX idx_cont_familia          ON siac_contacto (id_familia)        TABLESPACE una;
CREATE INDEX idx_ctrl_persona          ON siac_control_salud (id_persona)   TABLESPACE una;
CREATE INDEX idx_ctrl_tipo             ON siac_control_salud (id_tipo_control) TABLESPACE una;
CREATE INDEX idx_ctrl_fecha            ON siac_control_salud (fecha_control) TABLESPACE una;
CREATE INDEX idx_penf_persona          ON siac_persona_enfermedad (id_persona)    TABLESPACE una;
CREATE INDEX idx_penf_enfer            ON siac_persona_enfermedad (id_enfermedad) TABLESPACE una;
CREATE INDEX idx_benef_programa        ON siac_beneficiario (id_programa)   TABLESPACE una;
CREATE INDEX idx_benef_persona         ON siac_beneficiario (id_persona)    TABLESPACE una;
-- Índice único parcial: solo evita duplicados ACTIVOS en el mismo programa
-- Personas con participación completada/retirada pueden reinscribirse
CREATE UNIQUE INDEX uq_beneficiario_activo ON siac_beneficiario (
    CASE WHEN estado_participacion = 'A' THEN id_programa END,
    CASE WHEN estado_participacion = 'A' THEN id_persona END
) TABLESPACE una;
CREATE INDEX idx_usr_rol               ON siac_usuario (id_rol)             TABLESPACE una;
CREATE INDEX idx_usr_persona           ON siac_usuario (id_persona)         TABLESPACE una;

-- ============================================================
-- 13. TRIGGERS – Autoincrementales
-- ============================================================
CREATE OR REPLACE TRIGGER trg_siac_region_bi
BEFORE INSERT ON siac_region FOR EACH ROW
BEGIN
    IF :NEW.id_region IS NULL THEN :NEW.id_region := siac_seq_region.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_distrito_bi
BEFORE INSERT ON siac_distrito FOR EACH ROW
BEGIN
    IF :NEW.id_distrito IS NULL THEN :NEW.id_distrito := siac_seq_distrito.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_comunidad_bi
BEFORE INSERT ON siac_comunidad FOR EACH ROW
BEGIN
    IF :NEW.id_comunidad IS NULL THEN :NEW.id_comunidad := siac_seq_comunidad.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_vivienda_bi
BEFORE INSERT ON siac_vivienda FOR EACH ROW
BEGIN
    IF :NEW.id_vivienda IS NULL THEN :NEW.id_vivienda := siac_seq_vivienda.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_familia_bi
BEFORE INSERT ON siac_familia FOR EACH ROW
BEGIN
    IF :NEW.id_familia IS NULL THEN :NEW.id_familia := siac_seq_familia.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_persona_bi
BEFORE INSERT ON siac_persona FOR EACH ROW
BEGIN
    IF :NEW.id_persona IS NULL THEN :NEW.id_persona := siac_seq_persona.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_tipo_cont_bi
BEFORE INSERT ON siac_tipo_contacto FOR EACH ROW
BEGIN
    IF :NEW.id_tipo_contacto IS NULL THEN :NEW.id_tipo_contacto := siac_seq_tipo_contacto.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_contacto_bi
BEFORE INSERT ON siac_contacto FOR EACH ROW
BEGIN
    IF :NEW.id_contacto IS NULL THEN :NEW.id_contacto := siac_seq_contacto.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_tipo_ctrl_bi
BEFORE INSERT ON siac_tipo_control FOR EACH ROW
BEGIN
    IF :NEW.id_tipo_control IS NULL THEN :NEW.id_tipo_control := siac_seq_tipo_control.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_ctrl_salud_bi
BEFORE INSERT ON siac_control_salud FOR EACH ROW
BEGIN
    IF :NEW.id_control IS NULL THEN :NEW.id_control := siac_seq_control_salud.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_enfermedad_bi
BEFORE INSERT ON siac_enfermedad FOR EACH ROW
BEGIN
    IF :NEW.id_enfermedad IS NULL THEN :NEW.id_enfermedad := siac_seq_enfermedad.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_pers_enf_bi
BEFORE INSERT ON siac_persona_enfermedad FOR EACH ROW
BEGIN
    IF :NEW.id_persona_enf IS NULL THEN :NEW.id_persona_enf := siac_seq_persona_enf.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_programa_bi
BEFORE INSERT ON siac_programa FOR EACH ROW
BEGIN
    IF :NEW.id_programa IS NULL THEN :NEW.id_programa := siac_seq_programa.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_benef_bi
BEFORE INSERT ON siac_beneficiario FOR EACH ROW
BEGIN
    IF :NEW.id_beneficiario IS NULL THEN :NEW.id_beneficiario := siac_seq_beneficiario.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_rol_bi
BEFORE INSERT ON siac_rol FOR EACH ROW
BEGIN
    IF :NEW.id_rol IS NULL THEN :NEW.id_rol := siac_seq_rol.NEXTVAL; END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_siac_usuario_bi
BEFORE INSERT ON siac_usuario FOR EACH ROW
BEGIN
    IF :NEW.id_usuario IS NULL THEN :NEW.id_usuario := siac_seq_usuario.NEXTVAL; END IF;
END;
/

-- 13.2 Bloquear usuario tras 5 intentos fallidos
CREATE OR REPLACE TRIGGER trg_siac_usr_bloqueo
BEFORE UPDATE OF intentos_fallidos ON siac_usuario FOR EACH ROW
BEGIN
    IF :NEW.intentos_fallidos >= 5 AND :OLD.estado = 'A' THEN
        :NEW.estado := 'B';  -- B = Bloqueado
    END IF;
END;
/

-- ============================================================
-- 14. VISTAS COMPENSATORIAS (reemplazan atributos eliminados
--     por normalización: comunidad y cantidad_miembros)
-- ============================================================
-- 14.1 Vista: familia con su comunidad (resuelve la transitiva)
CREATE OR REPLACE VIEW siac_vw_familia_comunidad AS
SELECT f.id_familia,
       f.nombre_familia,
       f.clasificacion_riesgo,
       f.id_vivienda,
       v.id_comunidad,
       c.nombre  AS nombre_comunidad,
       c.id_distrito,
       d.nombre  AS nombre_distrito,
       d.id_region,
       r.nombre  AS nombre_region,
       f.estado,
       f.fecha_registro
FROM   siac_familia f
JOIN   siac_vivienda v ON v.id_vivienda  = f.id_vivienda
JOIN   siac_comunidad c ON c.id_comunidad = v.id_comunidad
JOIN   siac_distrito  d ON d.id_distrito  = c.id_distrito
JOIN   siac_region    r ON r.id_region    = d.id_region;

COMMENT ON TABLE siac_vw_familia_comunidad IS
'Vista que resuelve la comunidad (y jerarquía geográfica) de cada familia vía vivienda';

-- 14.2 Vista: familia con cantidad de miembros (reemplaza atributo derivado)
CREATE OR REPLACE VIEW siac_vw_familia_miembros AS
SELECT f.id_familia,
       f.nombre_familia,
       f.clasificacion_riesgo,
       f.estado,
       COUNT(CASE WHEN p.estado = 'A' THEN 1 END) AS cantidad_miembros_activos,
       COUNT(p.id_persona)                        AS cantidad_miembros_total
FROM   siac_familia f
LEFT JOIN siac_persona p ON p.id_familia = f.id_familia
GROUP BY f.id_familia, f.nombre_familia, f.clasificacion_riesgo, f.estado;

COMMENT ON TABLE siac_vw_familia_miembros IS
'Vista que calcula la cantidad de miembros por familia (reemplaza atributo derivado)';

-- 14.3 Vista combinada (familia + comunidad + miembros) – útil para reportes
CREATE OR REPLACE VIEW siac_vw_familia_resumen AS
SELECT fc.*,
       m.cantidad_miembros_activos,
       m.cantidad_miembros_total
FROM   siac_vw_familia_comunidad fc
JOIN   siac_vw_familia_miembros  m ON m.id_familia = fc.id_familia;

COMMENT ON TABLE siac_vw_familia_resumen IS
'Vista resumen completa de familia con comunidad y cantidad de miembros';

-- ============================================================
-- 15. DATOS INICIALES (catálogos mínimos)
-- ============================================================
-- Tipos de contacto
INSERT INTO siac_tipo_contacto (descripcion) VALUES ('TELEFONO_FIJO');
INSERT INTO siac_tipo_contacto (descripcion) VALUES ('CELULAR');
INSERT INTO siac_tipo_contacto (descripcion) VALUES ('EMAIL');
INSERT INTO siac_tipo_contacto (descripcion) VALUES ('WHATSAPP');
INSERT INTO siac_tipo_contacto (descripcion) VALUES ('FAX');

-- Tipos de control de salud
INSERT INTO siac_tipo_control (descripcion, periodicidad_dias) VALUES ('CONTROL PRENATAL',       30);
INSERT INTO siac_tipo_control (descripcion, periodicidad_dias) VALUES ('CONTROL NIÑO SANO',      90);
INSERT INTO siac_tipo_control (descripcion, periodicidad_dias) VALUES ('CONTROL ADULTO MAYOR',   60);
INSERT INTO siac_tipo_control (descripcion, periodicidad_dias) VALUES ('CONTROL CRÓNICOS',       90);
INSERT INTO siac_tipo_control (descripcion, periodicidad_dias) VALUES ('VACUNACIÓN',            365);
INSERT INTO siac_tipo_control (descripcion, periodicidad_dias) VALUES ('ODONTOLOGÍA',           180);

-- Enfermedades comunes
INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo) VALUES ('Diabetes Mellitus Tipo 2', 'E11',   'C');
INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo) VALUES ('Hipertensión Arterial',    'I10',   'C');
INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo) VALUES ('Asma Bronquial',           'J45',   'C');
INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo) VALUES ('Depresión',                'F32',   'M');
INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo) VALUES ('Dengue',                   'A90',   'I');
INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo) VALUES ('COVID-19',                 'U07.1', 'I');

-- Roles del sistema
INSERT INTO siac_rol (nombre, descripcion) VALUES ('ADMINISTRADOR',    'Acceso total al sistema');
INSERT INTO siac_rol (nombre, descripcion) VALUES ('MEDICO',           'Gestión de controles y enfermedades');
INSERT INTO siac_rol (nombre, descripcion) VALUES ('ENFERMERO',        'Registro de controles preventivos');
INSERT INTO siac_rol (nombre, descripcion) VALUES ('TRABAJADOR_SOCIAL','Gestión de familias y programas');
INSERT INTO siac_rol (nombre, descripcion) VALUES ('CONSULTA',         'Solo lectura');

-- Programas comunitarios
INSERT INTO siac_programa (nombre, tipo, institucion, fecha_inicio)
VALUES ('Programa Crecimiento y Desarrollo', 'A', 'CCSS', DATE '2026-01-01');
INSERT INTO siac_programa (nombre, tipo, institucion, fecha_inicio)
VALUES ('Avancemos',                         'S', 'IMAS', DATE '2026-01-01');
INSERT INTO siac_programa (nombre, tipo, institucion, fecha_inicio)
VALUES ('Control de Crónicos Comunitario',   'A', 'CCSS', DATE '2026-01-01');

COMMIT;

-- ============================================================
-- 16. VERIFICACIÓN FINAL
-- ============================================================
SELECT table_name, num_rows
FROM   user_tables
WHERE  table_name LIKE 'SIAC\_%' ESCAPE '\'
ORDER BY table_name;

SELECT COUNT(*) AS TOTAL_TABLAS_SIAC
FROM   user_tables
WHERE  table_name LIKE 'SIAC\_%' ESCAPE '\';

SELECT view_name FROM user_views
WHERE view_name LIKE 'SIAC\_VW\_%' ESCAPE '\'
ORDER BY view_name;

SELECT sequence_name, min_value, increment_by, last_number
FROM   user_sequences
WHERE  sequence_name LIKE 'SIAC\_SEQ\_%' ESCAPE '\'
ORDER BY sequence_name;

SELECT table_name, constraint_name, constraint_type, status
FROM   user_constraints
WHERE  table_name LIKE 'SIAC\_%' ESCAPE '\'
ORDER BY table_name, constraint_type;

SELECT trigger_name, table_name, triggering_event, status
FROM   user_triggers
WHERE  trigger_name LIKE 'TRG\_SIAC\_%' ESCAPE '\'
ORDER BY table_name;
