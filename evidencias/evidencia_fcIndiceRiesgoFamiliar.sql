DECLARE
    v_suffix          VARCHAR2(20) := TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3');
    v_id_region       NUMBER;
    v_id_distrito     NUMBER;
    v_id_comunidad    NUMBER;
    v_id_vivienda     NUMBER;
    v_id_familia      NUMBER;
    v_id_persona_jefe NUMBER;
    v_id_persona_hijo NUMBER;
    v_id_enfermedad   NUMBER;
    v_id_tipo_control NUMBER;
    v_id_programa     NUMBER;
    v_indice          NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('EVIDENCIA: fcIndiceRiesgoFamiliar');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Preparando datos base ---');

    INSERT INTO siac_region (nombre) VALUES ('Region IR-' || v_suffix)
    RETURNING id_region INTO v_id_region;

    INSERT INTO siac_distrito (nombre, id_region) VALUES ('Distrito IR-' || v_suffix, v_id_region)
    RETURNING id_distrito INTO v_id_distrito;

    INSERT INTO siac_comunidad (nombre, id_distrito) VALUES ('Comunidad IR-' || v_suffix, v_id_distrito)
    RETURNING id_comunidad INTO v_id_comunidad;

    INSERT INTO siac_vivienda (direccion_exacta, id_comunidad)
    VALUES ('300 mts oeste del supermercado', v_id_comunidad)
    RETURNING id_vivienda INTO v_id_vivienda;

    INSERT INTO siac_familia (nombre_familia, id_vivienda, clasificacion_riesgo)
    VALUES ('Familia Indice IR-' || v_suffix, v_id_vivienda, 'B')
    RETURNING id_familia INTO v_id_familia;

    INSERT INTO siac_persona (cedula, nombre, primer_apellido, fecha_nacimiento,
                              genero, relacion_familia, id_familia)
    VALUES ('1-' || v_suffix || '1', 'Carlos', 'Mendez', DATE '1975-02-10', 'M', 'J', v_id_familia)
    RETURNING id_persona INTO v_id_persona_jefe;

    UPDATE siac_familia SET id_jefe_familia = v_id_persona_jefe WHERE id_familia = v_id_familia;

    INSERT INTO siac_persona (cedula, nombre, primer_apellido, fecha_nacimiento,
                              genero, relacion_familia, id_familia)
    VALUES ('1-' || v_suffix || '2', 'Rosa', 'Mendez', DATE '1978-07-22', 'F', 'C', v_id_familia);

    INSERT INTO siac_persona (cedula, nombre, primer_apellido, fecha_nacimiento,
                              genero, relacion_familia, id_familia)
    VALUES ('1-' || v_suffix || '3', 'Jose', 'Mendez', DATE '2005-08-15', 'M', 'H', v_id_familia)
    RETURNING id_persona INTO v_id_persona_hijo;

    BEGIN
        SELECT id_enfermedad INTO v_id_enfermedad
        FROM siac_enfermedad WHERE TRANSLATE(nombre, 'áéíóúÁÉÍÓÚñÑ', 'aeiouAEIOUnN') = 'Diabetes Mellitus Tipo 2';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_enfermedad := NULL;
    END;
    IF v_id_enfermedad IS NOT NULL THEN
        INSERT INTO siac_persona_enfermedad (id_persona, id_enfermedad, fecha_diagnostico,
                                             estado_condicion)
        VALUES (v_id_persona_jefe, v_id_enfermedad, DATE '2019-01-20', 'A');
        DBMS_OUTPUT.PUT_LINE('  - Diabetes asignada');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  - AVISO: Diabetes no encontrada en catalogo, se omite');
    END IF;

    BEGIN
        SELECT id_enfermedad INTO v_id_enfermedad
        FROM siac_enfermedad
        WHERE UPPER(TRANSLATE(nombre, 'áéíóúÁÉÍÓÚñÑ', 'aeiouAEIOUnN')) = 'HIPERTENSION ARTERIAL';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_enfermedad := NULL;
    END;
    IF v_id_enfermedad IS NOT NULL THEN
        INSERT INTO siac_persona_enfermedad (id_persona, id_enfermedad, fecha_diagnostico,
                                             estado_condicion)
        VALUES (v_id_persona_jefe, v_id_enfermedad, DATE '2018-06-15', 'A');
        DBMS_OUTPUT.PUT_LINE('  - Hipertension asignada');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  - AVISO: Hipertension no encontrada en catalogo, se omite');
    END IF;

    BEGIN
        SELECT id_tipo_control INTO v_id_tipo_control
        FROM siac_tipo_control WHERE TRANSLATE(descripcion, 'áéíóúÁÉÍÓÚñÑ', 'aeiouAEIOUnN') = 'CONTROL NINIO SANO';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_tipo_control := NULL;
    END;
    IF v_id_tipo_control IS NOT NULL THEN
        INSERT INTO siac_control_salud (id_persona, id_tipo_control, fecha_control,
                                        fecha_proxima_cita, resultado, profesional_responsable)
        VALUES (v_id_persona_hijo, v_id_tipo_control, DATE '2025-01-10',
                DATE '2025-04-10', 'N', 'Dra. Evidencia');
        DBMS_OUTPUT.PUT_LINE('  - Control nino sano vencido agregado');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  - AVISO: CONTROL NINIO SANO no encontrado en catalogo, se omite');
    END IF;

    INSERT INTO siac_programa (nombre, tipo, institucion, fecha_inicio)
    VALUES ('Programa Indice IR-' || v_suffix, 'A', 'CCSS', SYSDATE)
    RETURNING id_programa INTO v_id_programa;

    INSERT INTO siac_beneficiario (id_programa, id_persona, fecha_inicio_participacion,
                                   estado_participacion)
    VALUES (v_id_programa, v_id_persona_hijo, SYSDATE, 'A');

    DBMS_OUTPUT.PUT_LINE('Familia ID: ' || v_id_familia);
    DBMS_OUTPUT.PUT_LINE('Miembros: 3 activos');
    DBMS_OUTPUT.PUT_LINE('Programas activos: 1');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Calculo esperado ---');
    DBMS_OUTPUT.PUT_LINE('  (miembros * 3) + (cronicas * 7) + (controles_venc * 10) + (programas * 5)');
    DBMS_OUTPUT.PUT_LINE('  (3 * 3) + (2 * 7) + (1 * 10) + (1 * 5)');
    DBMS_OUTPUT.PUT_LINE('  9 + 14 + 10 + 5 = 38');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Ejecutando fcIndiceRiesgoFamiliar ---');
    DBMS_OUTPUT.PUT_LINE('');

    v_indice := PckAtencionComunitaria.fcIndiceRiesgoFamiliar(
        p_id_familia => v_id_familia
    );

    DBMS_OUTPUT.PUT_LINE('INDICE DE RIESGO FAMILIAR: ' || v_indice);
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Probando con familia inexistente (ID 99999) ---');
    v_indice := PckAtencionComunitaria.fcIndiceRiesgoFamiliar(99999);
    DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_indice || ' (debe ser -1)');

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;

