-- ============================================================
-- SIAC — Datos de prueba (2+ filas por tabla)
-- Ejecutar DESPUES de siac-db.ddl
-- Idempotente: INSERT solo si NOT EXISTS
-- SQL puro (sin PL/SQL) para compatibilidad con DBeaver
-- ============================================================

-- ============================================================
-- 1. MODULO GEOGRAFICO
-- ============================================================

-- 1.1 SIAC_REGION
INSERT INTO siac_region (nombre, descripcion)
SELECT 'Region Central', 'Region central del pais' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_region WHERE nombre = 'Region Central');

INSERT INTO siac_region (nombre, descripcion)
SELECT 'Region Chorotega', 'Region Chorotega (Guanacaste)' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_region WHERE nombre = 'Region Chorotega');

-- 1.2 SIAC_DISTRITO
INSERT INTO siac_distrito (nombre, descripcion, id_region)
SELECT 'Distrito Central', 'Distrito central de la region', id_region
FROM siac_region WHERE nombre = 'Region Central'
  AND NOT EXISTS (SELECT 1 FROM siac_distrito WHERE nombre = 'Distrito Central');

INSERT INTO siac_distrito (nombre, descripcion, id_region)
SELECT 'Distrito Liberia', 'Distrito de Liberia', id_region
FROM siac_region WHERE nombre = 'Region Chorotega'
  AND NOT EXISTS (SELECT 1 FROM siac_distrito WHERE nombre = 'Distrito Liberia');

-- 1.3 SIAC_COMUNIDAD
INSERT INTO siac_comunidad (nombre, descripcion, id_distrito)
SELECT 'Comunidad La Carpio', 'Comunidad urbana en La Uruca', id_distrito
FROM siac_distrito WHERE nombre = 'Distrito Central'
  AND NOT EXISTS (SELECT 1 FROM siac_comunidad WHERE nombre = 'Comunidad La Carpio');

INSERT INTO siac_comunidad (nombre, descripcion, id_distrito)
SELECT 'Comunidad Curubande', 'Comunidad rural en Liberia', id_distrito
FROM siac_distrito WHERE nombre = 'Distrito Liberia'
  AND NOT EXISTS (SELECT 1 FROM siac_comunidad WHERE nombre = 'Comunidad Curubande');

-- ============================================================
-- 2. MODULO VIVIENDAS
-- ============================================================

-- 2.1 SIAC_VIVIENDA
INSERT INTO siac_vivienda (
    direccion_exacta, id_comunidad, condicion_general, tipo_vivienda,
    material_paredes, material_techo, acceso_agua, acceso_electricidad,
    acceso_alcantarillado, acceso_internet, estado_sanitario
)
SELECT 'Calle 3, Av 2, Casa 15', id_comunidad, 'R', 'P',
       'Bloque', 'Zinc', 'S', 'S', 'N', 'N', 'A'
FROM siac_comunidad WHERE nombre = 'Comunidad La Carpio'
  AND NOT EXISTS (SELECT 1 FROM siac_vivienda WHERE direccion_exacta = 'Calle 3, Av 2, Casa 15');

INSERT INTO siac_vivienda (
    direccion_exacta, id_comunidad, condicion_general, tipo_vivienda,
    material_paredes, material_techo, acceso_agua, acceso_electricidad,
    acceso_alcantarillado, acceso_internet, estado_sanitario
)
SELECT 'Camino Real 200m Sur de la Escuela', id_comunidad, 'B', 'P',
       'Madera', 'Teja', 'S', 'S', 'S', 'S', 'A'
FROM siac_comunidad WHERE nombre = 'Comunidad Curubande'
  AND NOT EXISTS (SELECT 1 FROM siac_vivienda WHERE direccion_exacta = 'Camino Real 200m Sur de la Escuela');

-- ============================================================
-- 3. MODULO FAMILIAS
-- ============================================================

-- 3.1 SIAC_FAMILIA (id_jefe_familia = NULL, FK diferida)
INSERT INTO siac_familia (nombre_familia, clasificacion_riesgo, id_vivienda)
SELECT 'Familia Rodriguez', 'M', id_vivienda
FROM siac_vivienda WHERE direccion_exacta = 'Calle 3, Av 2, Casa 15'
  AND NOT EXISTS (SELECT 1 FROM siac_familia WHERE nombre_familia = 'Familia Rodriguez');

INSERT INTO siac_familia (nombre_familia, clasificacion_riesgo, id_vivienda)
SELECT 'Familia Martinez', 'B', id_vivienda
FROM siac_vivienda WHERE direccion_exacta = 'Camino Real 200m Sur de la Escuela'
  AND NOT EXISTS (SELECT 1 FROM siac_familia WHERE nombre_familia = 'Familia Martinez');

-- ============================================================
-- 4. MODULO PERSONAS
-- ============================================================

-- 4.1 SIAC_PERSONA
-- Familia Rodriguez: Juan (jefe), Maria (conyuge)
INSERT INTO siac_persona (
    cedula, nombre, primer_apellido, segundo_apellido,
    fecha_nacimiento, genero, estado_civil, nivel_educativo,
    ocupacion, relacion_familia, id_familia
)
SELECT '12345678', 'Juan', 'Rodriguez', 'Perez',
       DATE '1980-05-15', 'M', 'C', 'S',
       'Albanil', 'J', id_familia
FROM siac_familia WHERE nombre_familia = 'Familia Rodriguez'
  AND NOT EXISTS (SELECT 1 FROM siac_persona WHERE cedula = '12345678');

INSERT INTO siac_persona (
    cedula, nombre, primer_apellido, segundo_apellido,
    fecha_nacimiento, genero, estado_civil, nivel_educativo,
    ocupacion, relacion_familia, id_familia
)
SELECT '87654321', 'Maria', 'Rodriguez', 'Lopez',
       DATE '1983-08-22', 'F', 'C', 'P',
       'Ama de casa', 'C', id_familia
FROM siac_familia WHERE nombre_familia = 'Familia Rodriguez'
  AND NOT EXISTS (SELECT 1 FROM siac_persona WHERE cedula = '87654321');

-- Familia Martinez: Carlos (jefe), Ana (conyuge)
INSERT INTO siac_persona (
    cedula, nombre, primer_apellido, segundo_apellido,
    fecha_nacimiento, genero, estado_civil, nivel_educativo,
    ocupacion, relacion_familia, id_familia
)
SELECT '23456789', 'Carlos', 'Martinez', 'Rojas',
       DATE '1975-11-03', 'M', 'C', 'U',
       'Profesor', 'J', id_familia
FROM siac_familia WHERE nombre_familia = 'Familia Martinez'
  AND NOT EXISTS (SELECT 1 FROM siac_persona WHERE cedula = '23456789');

INSERT INTO siac_persona (
    cedula, nombre, primer_apellido, segundo_apellido,
    fecha_nacimiento, genero, estado_civil, nivel_educativo,
    ocupacion, relacion_familia, id_familia
)
SELECT '98765432', 'Ana', 'Martinez', 'Sanchez',
       DATE '1978-02-17', 'F', 'C', 'U',
       'Enfermera', 'C', id_familia
FROM siac_familia WHERE nombre_familia = 'Familia Martinez'
  AND NOT EXISTS (SELECT 1 FROM siac_persona WHERE cedula = '98765432');

-- ============================================================
-- Actualizar jefes de familia (FK diferida se resuelve al COMMIT)
-- ============================================================
UPDATE siac_familia f
SET f.id_jefe_familia = (
    SELECT p.id_persona FROM siac_persona p
    WHERE p.id_familia = f.id_familia AND p.relacion_familia = 'J'
      AND ROWNUM = 1
)
WHERE f.id_jefe_familia IS NULL
  AND EXISTS (SELECT 1 FROM siac_persona WHERE id_familia = f.id_familia AND relacion_familia = 'J');

-- ============================================================
-- 5. MODULO CONTACTOS
-- ============================================================

-- 5.1 SIAC_TIPO_CONTACTO (solo si el DDL no lo poblo)
INSERT INTO siac_tipo_contacto (descripcion)
SELECT 'TELEFONO_FIJO' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_contacto WHERE descripcion = 'TELEFONO_FIJO');

INSERT INTO siac_tipo_contacto (descripcion)
SELECT 'CELULAR' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_contacto WHERE descripcion = 'CELULAR');

INSERT INTO siac_tipo_contacto (descripcion)
SELECT 'EMAIL' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_contacto WHERE descripcion = 'EMAIL');

INSERT INTO siac_tipo_contacto (descripcion)
SELECT 'WHATSAPP' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_contacto WHERE descripcion = 'WHATSAPP');

INSERT INTO siac_tipo_contacto (descripcion)
SELECT 'FAX' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_contacto WHERE descripcion = 'FAX');

-- 5.2 SIAC_CONTACTO
INSERT INTO siac_contacto (id_tipo_contacto, valor, id_persona, es_principal)
SELECT tc.id_tipo_contacto, '8888-1111', p.id_persona, 'S'
FROM siac_tipo_contacto tc, siac_persona p
WHERE tc.descripcion = 'CELULAR' AND p.cedula = '12345678'
  AND NOT EXISTS (
      SELECT 1 FROM siac_contacto c
      WHERE c.id_persona = p.id_persona
        AND c.id_tipo_contacto = tc.id_tipo_contacto
        AND c.valor = '8888-1111'
  );

INSERT INTO siac_contacto (id_tipo_contacto, valor, id_persona, es_principal)
SELECT tc.id_tipo_contacto, 'maria.r@email.com', p.id_persona, 'S'
FROM siac_tipo_contacto tc, siac_persona p
WHERE tc.descripcion = 'EMAIL' AND p.cedula = '87654321'
  AND NOT EXISTS (
      SELECT 1 FROM siac_contacto c
      WHERE c.id_persona = p.id_persona
        AND c.id_tipo_contacto = tc.id_tipo_contacto
        AND c.valor = 'maria.r@email.com'
  );

-- ============================================================
-- 6. MODULO CONTROLES DE SALUD
-- ============================================================

-- 6.1 SIAC_TIPO_CONTROL (solo si el DDL no lo poblo)
INSERT INTO siac_tipo_control (descripcion, periodicidad_dias)
SELECT 'CONTROL PRENATAL', 30 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_control WHERE descripcion = 'CONTROL PRENATAL');

INSERT INTO siac_tipo_control (descripcion, periodicidad_dias)
SELECT 'CONTROL NINO SANO', 90 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_control WHERE descripcion = 'CONTROL NINO SANO');

INSERT INTO siac_tipo_control (descripcion, periodicidad_dias)
SELECT 'CONTROL ADULTO MAYOR', 60 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_control WHERE descripcion = 'CONTROL ADULTO MAYOR');

INSERT INTO siac_tipo_control (descripcion, periodicidad_dias)
SELECT 'CONTROL CRONICOS', 90 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_control WHERE descripcion = 'CONTROL CRONICOS');

INSERT INTO siac_tipo_control (descripcion, periodicidad_dias)
SELECT 'VACUNACION', 365 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_control WHERE descripcion = 'VACUNACION');

INSERT INTO siac_tipo_control (descripcion, periodicidad_dias)
SELECT 'ODONTOLOGIA', 180 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_tipo_control WHERE descripcion = 'ODONTOLOGIA');

-- 6.2 SIAC_CONTROL_SALUD
INSERT INTO siac_control_salud (
    id_persona, id_tipo_control, fecha_control, fecha_proxima_cita,
    peso_kg, talla_cm, tension_arterial, resultado, profesional_responsable
)
SELECT p.id_persona, tc.id_tipo_control, DATE '2026-05-10', DATE '2026-07-10',
       75.5, 170, '120/80', 'N', 'Dr. Luis Mora'
FROM siac_persona p, siac_tipo_control tc
WHERE p.cedula = '12345678' AND tc.descripcion = 'CONTROL ADULTO MAYOR'
  AND NOT EXISTS (
      SELECT 1 FROM siac_control_salud cs
      WHERE cs.id_persona = p.id_persona AND cs.fecha_control = DATE '2026-05-10'
  );

INSERT INTO siac_control_salud (
    id_persona, id_tipo_control, fecha_control, fecha_proxima_cita,
    peso_kg, talla_cm, tension_arterial, resultado, profesional_responsable
)
SELECT p.id_persona, tc.id_tipo_control, DATE '2026-05-12', DATE '2026-08-12',
       65.0, 165, '130/85', 'A', 'Dra. Karina Vega'
FROM siac_persona p, siac_tipo_control tc
WHERE p.cedula = '98765432' AND tc.descripcion = 'CONTROL CRONICOS'
  AND NOT EXISTS (
      SELECT 1 FROM siac_control_salud cs
      WHERE cs.id_persona = p.id_persona AND cs.fecha_control = DATE '2026-05-12'
  );

-- ============================================================
-- 7. MODULO ENFERMEDADES Y CONDICIONES
-- ============================================================

-- 7.1 SIAC_ENFERMEDAD (solo si el DDL no lo poblo)
INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo)
SELECT 'Hipertension Arterial', 'I10', 'C' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_enfermedad WHERE nombre = 'Hipertension Arterial');

INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo)
SELECT 'Diabetes Mellitus Tipo 2', 'E11', 'C' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_enfermedad WHERE nombre = 'Diabetes Mellitus Tipo 2');

INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo)
SELECT 'Asma Bronquial', 'J45', 'C' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_enfermedad WHERE nombre = 'Asma Bronquial');

INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo)
SELECT 'Depresion', 'F32', 'M' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_enfermedad WHERE nombre = 'Depresion');

INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo)
SELECT 'Dengue', 'A90', 'I' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_enfermedad WHERE nombre = 'Dengue');

INSERT INTO siac_enfermedad (nombre, codigo_cie10, tipo)
SELECT 'COVID-19', 'U07.1', 'I' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_enfermedad WHERE nombre = 'COVID-19');

-- 7.2 SIAC_PERSONA_ENFERMEDAD
INSERT INTO siac_persona_enfermedad (
    id_persona, id_enfermedad, fecha_diagnostico, estado_condicion,
    medico_diagnostico, tratamiento
)
SELECT p.id_persona, e.id_enfermedad, DATE '2020-03-15', 'A',
       'Dr. Pablo Herrera', 'Enalapril 10mg/dia, dieta baja en sodio'
FROM siac_persona p, siac_enfermedad e
WHERE p.cedula = '12345678' AND e.nombre = 'Hipertension Arterial'
  AND NOT EXISTS (
      SELECT 1 FROM siac_persona_enfermedad pe
      WHERE pe.id_persona = p.id_persona AND pe.id_enfermedad = e.id_enfermedad
  );

INSERT INTO siac_persona_enfermedad (
    id_persona, id_enfermedad, fecha_diagnostico, estado_condicion,
    medico_diagnostico, tratamiento
)
SELECT p.id_persona, e.id_enfermedad, DATE '2021-07-20', 'A',
       'Dra. Ana Quesada', 'Metformina 850mg, control glucemico'
FROM siac_persona p, siac_enfermedad e
WHERE p.cedula = '23456789' AND e.nombre = 'Diabetes Mellitus Tipo 2'
  AND NOT EXISTS (
      SELECT 1 FROM siac_persona_enfermedad pe
      WHERE pe.id_persona = p.id_persona AND pe.id_enfermedad = e.id_enfermedad
  );

-- ============================================================
-- 8. MODULO PROGRAMAS COMUNITARIOS
-- ============================================================

-- 8.1 SIAC_PROGRAMA (solo si el DDL no lo poblo)
INSERT INTO siac_programa (nombre, tipo, institucion, fecha_inicio)
SELECT 'Programa Crecimiento y Desarrollo', 'A', 'CCSS', DATE '2026-01-01' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_programa WHERE nombre = 'Programa Crecimiento y Desarrollo');

INSERT INTO siac_programa (nombre, tipo, institucion, fecha_inicio)
SELECT 'Avancemos', 'S', 'IMAS', DATE '2026-01-01' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_programa WHERE nombre = 'Avancemos');

INSERT INTO siac_programa (nombre, tipo, institucion, fecha_inicio)
SELECT 'Control de Cronicos Comunitario', 'A', 'CCSS', DATE '2026-01-01' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_programa WHERE nombre = 'Control de Cronicos Comunitario');

-- 8.2 SIAC_BENEFICIARIO
INSERT INTO siac_beneficiario (id_programa, id_persona, fecha_inicio_participacion, estado_participacion)
SELECT pr.id_programa, pe.id_persona, DATE '2026-02-01', 'A'
FROM siac_programa pr, siac_persona pe
WHERE pr.nombre = 'Avancemos' AND pe.cedula = '87654321'
  AND NOT EXISTS (
      SELECT 1 FROM siac_beneficiario b
      WHERE b.id_programa = pr.id_programa AND b.id_persona = pe.id_persona
        AND b.estado_participacion = 'A'
  );

INSERT INTO siac_beneficiario (id_programa, id_persona, fecha_inicio_participacion, estado_participacion)
SELECT pr.id_programa, pe.id_persona, DATE '2026-01-15', 'A'
FROM siac_programa pr, siac_persona pe
WHERE pr.nombre = 'Control de Cronicos Comunitario' AND pe.cedula = '23456789'
  AND NOT EXISTS (
      SELECT 1 FROM siac_beneficiario b
      WHERE b.id_programa = pr.id_programa AND b.id_persona = pe.id_persona
        AND b.estado_participacion = 'A'
  );

-- ============================================================
-- 9. MODULO SEGURIDAD
-- ============================================================

-- 9.1 SIAC_ROL (solo si el DDL no lo poblo)
INSERT INTO siac_rol (nombre, descripcion)
SELECT 'ADMINISTRADOR', 'Acceso total al sistema' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_rol WHERE nombre = 'ADMINISTRADOR');

INSERT INTO siac_rol (nombre, descripcion)
SELECT 'MEDICO', 'Gestion de controles y enfermedades' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_rol WHERE nombre = 'MEDICO');

INSERT INTO siac_rol (nombre, descripcion)
SELECT 'ENFERMERO', 'Registro de controles preventivos' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_rol WHERE nombre = 'ENFERMERO');

INSERT INTO siac_rol (nombre, descripcion)
SELECT 'TRABAJADOR_SOCIAL', 'Gestion de familias y programas' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_rol WHERE nombre = 'TRABAJADOR_SOCIAL');

INSERT INTO siac_rol (nombre, descripcion)
SELECT 'CONSULTA', 'Solo lectura' FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM siac_rol WHERE nombre = 'CONSULTA');

-- 9.2 SIAC_USUARIO
INSERT INTO siac_usuario (nombre_usuario, hash_contrasena, id_persona, id_rol, correo)
SELECT 'jrodriguez', RAWTOHEX(STANDARD_HASH('SiacPass2026#', 'SHA256')),
       p.id_persona, r.id_rol, 'juan.rodriguez@siac.go.cr'
FROM siac_persona p, siac_rol r
WHERE p.cedula = '12345678' AND r.nombre = 'TRABAJADOR_SOCIAL'
  AND NOT EXISTS (SELECT 1 FROM siac_usuario WHERE nombre_usuario = 'jrodriguez');

INSERT INTO siac_usuario (nombre_usuario, hash_contrasena, id_persona, id_rol, correo)
SELECT 'cmartinez', RAWTOHEX(STANDARD_HASH('SiacPass2026#', 'SHA256')),
       p.id_persona, r.id_rol, 'carlos.martinez@siac.go.cr'
FROM siac_persona p, siac_rol r
WHERE p.cedula = '23456789' AND r.nombre = 'MEDICO'
  AND NOT EXISTS (SELECT 1 FROM siac_usuario WHERE nombre_usuario = 'cmartinez');

-- ============================================================
-- 10. CONFIRMAR TRANSACCION
-- ============================================================
COMMIT;

-- ============================================================
-- 11. VERIFICACION
-- ============================================================
SELECT table_name, num_rows
FROM user_tables
WHERE table_name LIKE 'SIAC\_%' ESCAPE '\'
ORDER BY table_name;
