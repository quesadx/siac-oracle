-- ============================================================
-- AVANCE 3: PAQUETE PckAtencionComunitaria — Cuerpo
-- Sistema de Informacion para Atencion Comunitaria (SIAC)
-- ============================================================

CREATE OR REPLACE PACKAGE BODY PckAtencionComunitaria IS

    -- ============================================================
    -- Constantes del paquete
    -- ============================================================
    c_estado_activo         CONSTANT VARCHAR2(1) := 'A';
    c_estado_inactivo       CONSTANT VARCHAR2(1) := 'I';
    c_estado_finalizado     CONSTANT VARCHAR2(1) := 'F';
    c_riesgo_alto           CONSTANT VARCHAR2(1) := 'A';
    c_riesgo_medio          CONSTANT VARCHAR2(1) := 'M';
    c_riesgo_bajo           CONSTANT VARCHAR2(1) := 'B';
    c_relacion_jefe         CONSTANT VARCHAR2(1) := 'J';
    c_programa_finalizado   CONSTANT VARCHAR2(1) := 'F';
    c_benef_completado      CONSTANT VARCHAR2(1) := 'C';

    -- ============================================================
    -- Procedimientos privados (internos del paquete)
    -- ============================================================

    -- Inserta una vivienda y retorna su ID
    PROCEDURE insertar_vivienda(
        p_direccion_exacta      IN VARCHAR2,
        p_id_comunidad          IN NUMBER,
        p_condicion_general     IN VARCHAR2,
        p_tipo_vivienda         IN VARCHAR2,
        p_material_paredes      IN VARCHAR2,
        p_material_techo        IN VARCHAR2,
        p_acceso_agua           IN VARCHAR2,
        p_acceso_electricidad   IN VARCHAR2,
        p_acceso_alcantarillado IN VARCHAR2,
        p_acceso_internet       IN VARCHAR2,
        p_estado_sanitario      IN VARCHAR2,
        p_observaciones         IN VARCHAR2,
        p_id_vivienda           OUT NUMBER
    ) IS
    BEGIN
        INSERT INTO siac_vivienda (
            direccion_exacta,
            id_comunidad,
            condicion_general,
            tipo_vivienda,
            material_paredes,
            material_techo,
            acceso_agua,
            acceso_electricidad,
            acceso_alcantarillado,
            acceso_internet,
            estado_sanitario,
            observaciones
        ) VALUES (
            p_direccion_exacta,
            p_id_comunidad,
            p_condicion_general,
            p_tipo_vivienda,
            p_material_paredes,
            p_material_techo,
            p_acceso_agua,
            p_acceso_electricidad,
            p_acceso_alcantarillado,
            p_acceso_internet,
            p_estado_sanitario,
            p_observaciones
        ) RETURNING id_vivienda INTO p_id_vivienda;
    END insertar_vivienda;

    -- ============================================================
    -- Procedimientos publicos
    -- ============================================================

    -- ---------------------------------------------------------
    -- 1. pcRegistrarFamiliaCompleta
    -- ---------------------------------------------------------
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
    ) IS
        v_id_vivienda       NUMBER;
        v_id_persona_jefe   NUMBER;

        -- Excepcion personalizada
        ex_comunidad_invalida EXCEPTION;
        PRAGMA EXCEPTION_INIT(ex_comunidad_invalida, -20001);

        CURSOR c_comunidad IS
            SELECT 1 FROM siac_comunidad
            WHERE id_comunidad = p_id_comunidad
              AND estado = c_estado_activo;

        v_existe_comunidad NUMBER := 0;
        v_idx              NUMBER;
    BEGIN
        -- Iniciar transaccion
        SAVEPOINT sp_registrar_familia;

        -- Validar parametros obligatorios
        IF p_direccion_exacta IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Error (VIV-001): La direccion exacta de la vivienda es obligatoria.');
        END IF;

        IF p_nombre_familia IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Error (FAM-001): El nombre de la familia es obligatorio.');
        END IF;

        IF p_cedula_jefe IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Error (PER-001): La cedula del jefe de familia es obligatoria.');
        END IF;

        -- Validar que la comunidad existe y esta activa
        OPEN c_comunidad;
        FETCH c_comunidad INTO v_existe_comunidad;
        CLOSE c_comunidad;

        IF v_existe_comunidad = 0 THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Error (VIV-002): La comunidad con ID ' || p_id_comunidad ||
                ' no existe o no esta activa.');
        END IF;

        -- Validar que la cedula del jefe no exista ya
        BEGIN
            SELECT 1 INTO v_existe_comunidad
            FROM siac_persona
            WHERE cedula = p_cedula_jefe
              AND estado <> c_estado_inactivo;
            RAISE_APPLICATION_ERROR(-20001,
                'Error (PER-002): Ya existe una persona activa con la cedula ' ||
                p_cedula_jefe || '.');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL; -- OK, no existe
        END;

        -- Validar miembros: no puede haber otro Jefe en los miembros
        IF p_miembros IS NOT NULL AND p_miembros.COUNT > 0 THEN
            FOR v_idx IN 1 .. p_miembros.COUNT LOOP
                IF p_miembros(v_idx).relacion_familia = c_relacion_jefe THEN
                    RAISE_APPLICATION_ERROR(-20001,
                        'Error (FAM-002): Los miembros no pueden tener relacion "J" (Jefe). ' ||
                        'El jefe ya se registra por separado.');
                END IF;
                IF p_miembros(v_idx).cedula = p_cedula_jefe THEN
                    RAISE_APPLICATION_ERROR(-20001,
                        'Error (PER-003): Un miembro tiene la misma cedula que el jefe.');
                END IF;
            END LOOP;
        END IF;

        -- 1. Insertar vivienda
        insertar_vivienda(
            p_direccion_exacta      => p_direccion_exacta,
            p_id_comunidad          => p_id_comunidad,
            p_condicion_general     => p_condicion_general,
            p_tipo_vivienda         => p_tipo_vivienda,
            p_material_paredes      => p_material_paredes,
            p_material_techo        => p_material_techo,
            p_acceso_agua           => p_acceso_agua,
            p_acceso_electricidad   => p_acceso_electricidad,
            p_acceso_alcantarillado => p_acceso_alcantarillado,
            p_acceso_internet       => p_acceso_internet,
            p_estado_sanitario      => p_estado_sanitario,
            p_observaciones         => p_observaciones_vivienda,
            p_id_vivienda           => v_id_vivienda
        );

        -- 2. Insertar familia (sin jefe aun, FK deferida)
        INSERT INTO siac_familia (
            nombre_familia,
            id_vivienda,
            clasificacion_riesgo,
            observaciones
        ) VALUES (
            p_nombre_familia,
            v_id_vivienda,
            c_riesgo_bajo,
            p_observaciones_familia
        ) RETURNING id_familia INTO p_id_familia;

        -- 3. Insertar jefe de familia
        INSERT INTO siac_persona (
            cedula,
            nombre,
            primer_apellido,
            segundo_apellido,
            fecha_nacimiento,
            genero,
            estado_civil,
            nivel_educativo,
            ocupacion,
            relacion_familia,
            id_familia
        ) VALUES (
            p_cedula_jefe,
            p_nombre_jefe,
            p_primer_apellido_jefe,
            p_segundo_apellido_jefe,
            p_fecha_nacimiento_jefe,
            p_genero_jefe,
            p_estado_civil_jefe,
            p_nivel_educativo_jefe,
            p_ocupacion_jefe,
            c_relacion_jefe,
            p_id_familia
        ) RETURNING id_persona INTO v_id_persona_jefe;

        -- 4. Asignar jefe en la familia
        UPDATE siac_familia
        SET id_jefe_familia = v_id_persona_jefe
        WHERE id_familia = p_id_familia;

        -- 5. Insertar miembros adicionales
        IF p_miembros IS NOT NULL AND p_miembros.COUNT > 0 THEN
            FOR v_idx IN 1 .. p_miembros.COUNT LOOP
                -- Validar cedula duplicada dentro de los miembros
                BEGIN
                    SELECT 1 INTO v_existe_comunidad
                    FROM siac_persona
                    WHERE cedula = p_miembros(v_idx).cedula
                      AND estado <> c_estado_inactivo;
                    RAISE_APPLICATION_ERROR(-20001,
                        'Error (PER-004): Ya existe una persona activa con la cedula ' ||
                        p_miembros(v_idx).cedula ||
                        ' (miembro #' || v_idx || ').');
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL;
                END;

                INSERT INTO siac_persona (
                    cedula,
                    nombre,
                    primer_apellido,
                    segundo_apellido,
                    fecha_nacimiento,
                    genero,
                    estado_civil,
                    nivel_educativo,
                    ocupacion,
                    relacion_familia,
                    id_familia
                ) VALUES (
                    p_miembros(v_idx).cedula,
                    p_miembros(v_idx).nombre,
                    p_miembros(v_idx).primer_apellido,
                    p_miembros(v_idx).segundo_apellido,
                    p_miembros(v_idx).fecha_nacimiento,
                    p_miembros(v_idx).genero,
                    p_miembros(v_idx).estado_civil,
                    p_miembros(v_idx).nivel_educativo,
                    p_miembros(v_idx).ocupacion,
                    p_miembros(v_idx).relacion_familia,
                    p_id_familia
                );
            END LOOP;
        END IF;

        -- Confirmar transaccion
        COMMIT;

        p_mensaje := 'EXITO: Familia "' || p_nombre_familia ||
                     '" registrada correctamente con ID ' || p_id_familia ||
                     '. Vivienda ID: ' || v_id_vivienda ||
                     '. Jefe ID: ' || v_id_persona_jefe || '.';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_registrar_familia;
            p_id_familia := NULL;
            p_mensaje := 'ERROR: No se pudo registrar la familia. ' || SQLERRM;
    END pcRegistrarFamiliaCompleta;

    -- ---------------------------------------------------------
    -- 2. pcCambiarClasificacionRiesgoFamilia
    -- ---------------------------------------------------------
    PROCEDURE pcCambiarClasificacionRiesgoFamilia(
        p_id_familia          IN NUMBER,
        p_mensaje             OUT VARCHAR2,
        p_nueva_clasificacion OUT VARCHAR2
    ) IS
        v_enf_activas       NUMBER := 0;
        v_enf_cronicas      NUMBER := 0;
        v_controles_pend    NUMBER := 0;
        v_existe_familia    NUMBER := 0;
        v_clasif_actual     VARCHAR2(1);
        v_clasif_nueva      VARCHAR2(1);
    BEGIN
        SAVEPOINT sp_cambiar_riesgo;

        -- Validar existencia de la familia y estado activo
        BEGIN
            SELECT 1, clasificacion_riesgo
            INTO v_existe_familia, v_clasif_actual
            FROM siac_familia
            WHERE id_familia = p_id_familia
              AND estado = c_estado_activo;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20002,
                    'Error (FAM-003): La familia con ID ' || p_id_familia ||
                    ' no existe o no esta activa.');
        END;

        -- Contar enfermedades activas (estado_condicion = 'A') en miembros
        SELECT COUNT(*)
        INTO v_enf_activas
        FROM siac_persona_enfermedad pe
        JOIN siac_persona p ON p.id_persona = pe.id_persona
        WHERE p.id_familia = p_id_familia
          AND pe.estado_condicion = c_estado_activo;

        -- Contar condiciones cronicas activas (tipo = 'C' en siac_enfermedad)
        SELECT COUNT(*)
        INTO v_enf_cronicas
        FROM siac_persona_enfermedad pe
        JOIN siac_persona p ON p.id_persona = pe.id_persona
        JOIN siac_enfermedad e ON e.id_enfermedad = pe.id_enfermedad
        WHERE p.id_familia = p_id_familia
          AND pe.estado_condicion = c_estado_activo
          AND e.tipo = 'C';

        -- Contar controles de salud pendientes/vencidos
        -- (fecha_proxima_cita < SYSDATE indica que el control esta vencido)
        SELECT COUNT(*)
        INTO v_controles_pend
        FROM siac_control_salud cs
        JOIN siac_persona p ON p.id_persona = cs.id_persona
        WHERE p.id_familia = p_id_familia
          AND cs.fecha_proxima_cita IS NOT NULL
          AND cs.fecha_proxima_cita < SYSDATE;

        -- Recalcular clasificacion (usa: enf. activas, cronicas, controles pend.)
        IF v_enf_cronicas >= 2 OR v_controles_pend >= 4 OR v_enf_activas >= 4 THEN
            v_clasif_nueva := c_riesgo_alto;
        ELSIF v_enf_cronicas >= 1 OR v_controles_pend >= 2 OR v_enf_activas >= 2 THEN
            v_clasif_nueva := c_riesgo_medio;
        ELSE
            v_clasif_nueva := c_riesgo_bajo;
        END IF;

        -- Actualizar si cambio
        IF v_clasif_nueva = v_clasif_actual THEN
            p_nueva_clasificacion := v_clasif_actual;
            p_mensaje := 'INFO: La clasificacion de riesgo ya es "' ||
                         CASE v_clasif_actual
                             WHEN 'A' THEN 'Alto'
                             WHEN 'M' THEN 'Medio'
                             WHEN 'B' THEN 'Bajo'
                         END ||
                         '". Activas: ' || v_enf_activas ||
                         ', Cronicas: ' || v_enf_cronicas ||
                         ', Controles pend.: ' || v_controles_pend || '.';
        ELSE
            UPDATE siac_familia
            SET clasificacion_riesgo = v_clasif_nueva
            WHERE id_familia = p_id_familia;

            p_nueva_clasificacion := v_clasif_nueva;
            p_mensaje := 'EXITO: Clasificacion de riesgo actualizada de "' ||
                         CASE v_clasif_actual
                             WHEN 'A' THEN 'Alto'
                             WHEN 'M' THEN 'Medio'
                             WHEN 'B' THEN 'Bajo'
                         END ||
                         '" a "' ||
                         CASE v_clasif_nueva
                             WHEN 'A' THEN 'Alto'
                             WHEN 'M' THEN 'Medio'
                             WHEN 'B' THEN 'Bajo'
                         END ||
                         '". Activas: ' || v_enf_activas ||
                         ', Cronicas: ' || v_enf_cronicas ||
                         ', Controles pend.: ' || v_controles_pend || '.';
        END IF;

        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_cambiar_riesgo;
            p_nueva_clasificacion := NULL;
            p_mensaje := 'ERROR: No se pudo actualizar la clasificacion de riesgo. ' || SQLERRM;
    END pcCambiarClasificacionRiesgoFamilia;

    -- ---------------------------------------------------------
    -- 3. pcAsignarPersonaAProgramaComunitario
    -- ---------------------------------------------------------
    PROCEDURE pcAsignarPersonaAProgramaComunitario(
        p_id_persona      IN NUMBER,
        p_id_programa     IN NUMBER,
        p_observaciones   IN VARCHAR2 DEFAULT NULL,
        p_mensaje         OUT VARCHAR2,
        p_id_beneficiario OUT NUMBER
    ) IS
        v_existe_persona   NUMBER := 0;
        v_existe_programa  NUMBER := 0;
        v_estado_persona   VARCHAR2(1);
        v_estado_programa  VARCHAR2(1);
        v_duplicado        NUMBER := 0;
    BEGIN
        SAVEPOINT sp_asignar_programa;

        -- Validar que la persona existe y esta activa
        BEGIN
            SELECT 1, estado
            INTO v_existe_persona, v_estado_persona
            FROM siac_persona
            WHERE id_persona = p_id_persona;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20003,
                    'Error (PER-005): La persona con ID ' || p_id_persona ||
                    ' no existe.');
        END;

        IF v_estado_persona <> c_estado_activo THEN
            RAISE_APPLICATION_ERROR(-20003,
                'Error (PER-006): La persona con ID ' || p_id_persona ||
                ' no esta activa. Estado actual: ' || v_estado_persona || '.');
        END IF;

        -- Validar que el programa existe
        BEGIN
            SELECT 1, estado
            INTO v_existe_programa, v_estado_programa
            FROM siac_programa
            WHERE id_programa = p_id_programa;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20003,
                    'Error (PRO-001): El programa con ID ' || p_id_programa ||
                    ' no existe.');
        END;

        -- Validar vigencia del programa
        IF v_estado_programa <> c_estado_activo THEN
            RAISE_APPLICATION_ERROR(-20003,
                'Error (PRO-002): El programa "' || p_id_programa ||
                '" no esta activo. Estado actual: ' || v_estado_programa ||
                ' (' ||
                CASE v_estado_programa
                    WHEN 'F' THEN 'Finalizado'
                    WHEN 'S' THEN 'Suspendido'
                    WHEN 'I' THEN 'Inactivo'
                    ELSE v_estado_programa
                END || ').');
        END IF;

        -- Validar que la fecha de inicio del programa ya paso (si tiene)
        -- (no requerido explicitamente, pero es buena practica)

        -- Validar que no existe un duplicado activo
        BEGIN
            SELECT 1 INTO v_duplicado
            FROM siac_beneficiario
            WHERE id_persona = p_id_persona
              AND id_programa = p_id_programa
              AND estado_participacion = c_estado_activo;
            RAISE_APPLICATION_ERROR(-20003,
                'Error (BEN-001): La persona ya esta inscrita activamente ' ||
                'en este programa (ID beneficiario existente).');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL; -- OK
        END;

        -- Insertar beneficiario
        INSERT INTO siac_beneficiario (
            id_programa,
            id_persona,
            fecha_inicio_participacion,
            estado_participacion,
            observaciones
        ) VALUES (
            p_id_programa,
            p_id_persona,
            SYSDATE,
            c_estado_activo,
            p_observaciones
        ) RETURNING id_beneficiario INTO p_id_beneficiario;

        COMMIT;

        p_mensaje := 'EXITO: Persona ID ' || p_id_persona ||
                     ' inscrita en el programa ID ' || p_id_programa ||
                     '. Beneficiario ID: ' || p_id_beneficiario || '.';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_asignar_programa;
            p_id_beneficiario := NULL;
            p_mensaje := 'ERROR: No se pudo asignar la persona al programa. ' || SQLERRM;
    END pcAsignarPersonaAProgramaComunitario;

    -- ---------------------------------------------------------
    -- 4. pcCerrarProgramaComunitario
    -- ---------------------------------------------------------
    PROCEDURE pcCerrarProgramaComunitario(
        p_id_programa IN NUMBER,
        p_mensaje     OUT VARCHAR2
    ) IS
        v_existe_programa  NUMBER := 0;
        v_estado_programa  VARCHAR2(1);
        v_benef_afectados  NUMBER := 0;
    BEGIN
        SAVEPOINT sp_cerrar_programa;

        -- Validar que el programa existe
        BEGIN
            SELECT 1, estado
            INTO v_existe_programa, v_estado_programa
            FROM siac_programa
            WHERE id_programa = p_id_programa;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20004,
                    'Error (PRO-003): El programa con ID ' || p_id_programa ||
                    ' no existe.');
        END;

        -- Validar que el programa no este ya cerrado/suspendido
        IF v_estado_programa IN (c_programa_finalizado, c_estado_inactivo, 'S') THEN
            RAISE_APPLICATION_ERROR(-20004,
                'Error (PRO-004): El programa ya esta ' ||
                CASE v_estado_programa
                    WHEN 'F' THEN 'Finalizado'
                    WHEN 'I' THEN 'Inactivo'
                    WHEN 'S' THEN 'Suspendido'
                    ELSE v_estado_programa
                END || '. No se puede cerrar nuevamente.');
        END IF;

        -- 1. Actualizar estado del programa
        UPDATE siac_programa
        SET estado = c_programa_finalizado,
            fecha_fin = SYSDATE
        WHERE id_programa = p_id_programa;

        -- 2. Actualizar beneficiarios activos a completado
        UPDATE siac_beneficiario
        SET estado_participacion = c_benef_completado,
            fecha_fin_participacion = SYSDATE
        WHERE id_programa = p_id_programa
          AND estado_participacion = c_estado_activo;

        v_benef_afectados := SQL%ROWCOUNT;

        COMMIT;

        p_mensaje := 'EXITO: Programa ID ' || p_id_programa ||
                     ' cerrado correctamente. ' ||
                     v_benef_afectados ||
                     ' beneficiario(s) actualizado(s).';

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_cerrar_programa;
            p_mensaje := 'ERROR: No se pudo cerrar el programa. ' || SQLERRM;
    END pcCerrarProgramaComunitario;

    -- ============================================================
    -- Funciones publicas
    -- ============================================================

    -- ---------------------------------------------------------
    -- fcIndiceRiesgoFamiliar
    -- ---------------------------------------------------------
    FUNCTION fcIndiceRiesgoFamiliar(
        p_id_familia IN NUMBER
    ) RETURN NUMBER IS
        v_miembros_activos    NUMBER := 0;
        v_enf_cronicas        NUMBER := 0;
        v_controles_vencidos  NUMBER := 0;
        v_programas_activos   NUMBER := 0;
        v_indice              NUMBER := 0;
        v_existe_familia      NUMBER := 0;
    BEGIN
        -- Validar existencia de la familia
        BEGIN
            SELECT 1 INTO v_existe_familia
            FROM siac_familia
            WHERE id_familia = p_id_familia;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN -1;
        END;

        -- 1. Numero de miembros activos
        SELECT COUNT(*)
        INTO v_miembros_activos
        FROM siac_persona
        WHERE id_familia = p_id_familia
          AND estado = c_estado_activo;

        -- 2. Enfermedades cronicas activas en miembros
        SELECT COUNT(*)
        INTO v_enf_cronicas
        FROM siac_persona_enfermedad pe
        JOIN siac_persona p ON p.id_persona = pe.id_persona
        JOIN siac_enfermedad e ON e.id_enfermedad = pe.id_enfermedad
        WHERE p.id_familia = p_id_familia
          AND pe.estado_condicion = c_estado_activo
          AND e.tipo = 'C';

        -- 3. Controles de salud vencidos
        --    (fecha_proxima_cita < SYSDATE, sin un control posterior)
        SELECT COUNT(*)
        INTO v_controles_vencidos
        FROM siac_control_salud cs
        JOIN siac_persona p ON p.id_persona = cs.id_persona
        WHERE p.id_familia = p_id_familia
          AND cs.fecha_proxima_cita IS NOT NULL
          AND cs.fecha_proxima_cita < SYSDATE;

        -- 4. Programas comunitarios activos de los miembros
        SELECT COUNT(DISTINCT b.id_programa)
        INTO v_programas_activos
        FROM siac_beneficiario b
        JOIN siac_persona p ON p.id_persona = b.id_persona
        WHERE p.id_familia = p_id_familia
          AND b.estado_participacion = c_estado_activo;

        -- Formula del indice de riesgo:
        --   Peso miembros:        3 puntos por miembro
        --   Peso enf. cronicas:   7 puntos por enfermedad
        --   Peso controles venc.:10 puntos por control vencido
        --   Peso programas:       5 puntos por programa
        v_indice := (v_miembros_activos * 3)
                  + (v_enf_cronicas * 7)
                  + (v_controles_vencidos * 10)
                  + (v_programas_activos * 5);

        RETURN v_indice;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN -1;
    END fcIndiceRiesgoFamiliar;

END PckAtencionComunitaria;
