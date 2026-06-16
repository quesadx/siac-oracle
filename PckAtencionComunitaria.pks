-- ============================================================
-- AVANCE 3: PAQUETE PckAtencionComunitaria — Especificacion
-- Sistema de Informacion para Atencion Comunitaria (SIAC)
-- ============================================================

CREATE OR REPLACE PACKAGE PckAtencionComunitaria IS

    -- ============================================================
    -- Tipos definidos por el usuario
    -- ============================================================

    -- Registro para un miembro de familia (sin jefe)
    TYPE t_miembro_rec IS RECORD (
        cedula           VARCHAR2(30),
        nombre           VARCHAR2(100),
        primer_apellido  VARCHAR2(100),
        segundo_apellido VARCHAR2(100),
        fecha_nacimiento DATE,
        genero           VARCHAR2(1),
        estado_civil     VARCHAR2(1),
        nivel_educativo  VARCHAR2(1),
        ocupacion        VARCHAR2(150),
        relacion_familia VARCHAR2(1)
    );

    -- Tabla anidada de miembros
    TYPE t_miembros_tab IS TABLE OF t_miembro_rec;

    -- ============================================================
    -- Procedimientos
    -- ============================================================

    -- 1. Registrar familia completa en una sola transaccion
    --    Incluye: vivienda, familia, jefe y miembros iniciales
    PROCEDURE pcRegistrarFamiliaCompleta(
        p_direccion_exacta      IN VARCHAR2,
        p_id_comunidad          IN NUMBER,
        p_condicion_general     IN VARCHAR2 DEFAULT 'R',
        p_tipo_vivienda         IN VARCHAR2 DEFAULT NULL,
        p_material_paredes      IN VARCHAR2 DEFAULT NULL,
        p_material_techo        IN VARCHAR2 DEFAULT NULL,
        p_acceso_agua           IN VARCHAR2 DEFAULT 'N',
        p_acceso_electricidad   IN VARCHAR2 DEFAULT 'N',
        p_acceso_alcantarillado IN VARCHAR2 DEFAULT 'N',
        p_acceso_internet       IN VARCHAR2 DEFAULT 'N',
        p_estado_sanitario      IN VARCHAR2 DEFAULT 'A',
        p_observaciones_vivienda IN VARCHAR2 DEFAULT NULL,

        p_nombre_familia        IN VARCHAR2,
        p_observaciones_familia IN VARCHAR2 DEFAULT NULL,

        p_cedula_jefe           IN VARCHAR2,
        p_nombre_jefe           IN VARCHAR2,
        p_primer_apellido_jefe  IN VARCHAR2,
        p_segundo_apellido_jefe IN VARCHAR2 DEFAULT NULL,
        p_fecha_nacimiento_jefe IN DATE,
        p_genero_jefe           IN VARCHAR2,
        p_estado_civil_jefe     IN VARCHAR2 DEFAULT NULL,
        p_nivel_educativo_jefe  IN VARCHAR2 DEFAULT NULL,
        p_ocupacion_jefe        IN VARCHAR2 DEFAULT NULL,

        p_miembros              IN t_miembros_tab DEFAULT NULL,

        p_mensaje               OUT VARCHAR2,
        p_id_familia            OUT NUMBER
    );

    -- 2. Actualizar clasificacion de riesgo de una familia
    --    en funcion de enfermedades activas, cronicas y controles pendientes
    PROCEDURE pcCambiarClasificacionRiesgoFamilia(
        p_id_familia          IN NUMBER,
        p_mensaje             OUT VARCHAR2,
        p_nueva_clasificacion OUT VARCHAR2
    );

    -- 3. Inscribir persona en un programa comunitario
    --    Valida: no duplicados activos, vigencia del programa, estado persona
    PROCEDURE pcAsignarPersonaAProgramaComunitario(
        p_id_persona      IN NUMBER,
        p_id_programa     IN NUMBER,
        p_observaciones   IN VARCHAR2 DEFAULT NULL,
        p_mensaje         OUT VARCHAR2,
        p_id_beneficiario OUT NUMBER
    );

    -- 4. Cerrar programa comunitario
    --    Actualiza estado del programa y todos sus beneficiarios activos
    PROCEDURE pcCerrarProgramaComunitario(
        p_id_programa IN NUMBER,
        p_mensaje     OUT VARCHAR2
    );

    -- ============================================================
    -- Funciones
    -- ============================================================

    -- Indice numerico de riesgo familiar
    -- Calculo basado en: miembros, enfermedades cronicas,
    --   controles vencidos y participacion en programas
    FUNCTION fcIndiceRiesgoFamiliar(
        p_id_familia IN NUMBER
    ) RETURN NUMBER;

END PckAtencionComunitaria;
