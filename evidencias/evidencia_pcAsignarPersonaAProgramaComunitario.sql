DECLARE
    v_suffix          VARCHAR2(20) := TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3');
    v_id_region       NUMBER;
    v_id_distrito     NUMBER;
    v_id_comunidad    NUMBER;
    v_id_vivienda     NUMBER;
    v_id_familia      NUMBER;
    v_id_persona      NUMBER;
    v_id_programa     NUMBER;
    v_mensaje         VARCHAR2(4000);
    v_id_beneficiario NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('EVIDENCIA: pcAsignarPersonaAProgramaComunitario');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Preparando datos base ---');

    INSERT INTO siac_region (nombre) VALUES ('Region PA-' || v_suffix)
    RETURNING id_region INTO v_id_region;

    INSERT INTO siac_distrito (nombre, id_region) VALUES ('Distrito PA-' || v_suffix, v_id_region)
    RETURNING id_distrito INTO v_id_distrito;

    INSERT INTO siac_comunidad (nombre, id_distrito) VALUES ('Comunidad PA-' || v_suffix, v_id_distrito)
    RETURNING id_comunidad INTO v_id_comunidad;

    INSERT INTO siac_vivienda (direccion_exacta, id_comunidad)
    VALUES ('200 mts sur del parque', v_id_comunidad)
    RETURNING id_vivienda INTO v_id_vivienda;

    INSERT INTO siac_familia (nombre_familia, id_vivienda)
    VALUES ('Familia Programa PA-' || v_suffix, v_id_vivienda)
    RETURNING id_familia INTO v_id_familia;

    INSERT INTO siac_persona (cedula, nombre, primer_apellido, fecha_nacimiento,
                              genero, relacion_familia, id_familia)
    VALUES ('1-' || v_suffix || '1', 'Luis', 'Mora', DATE '1990-04-20', 'M', 'J', v_id_familia)
    RETURNING id_persona INTO v_id_persona;

    UPDATE siac_familia SET id_jefe_familia = v_id_persona WHERE id_familia = v_id_familia;

    INSERT INTO siac_programa (nombre, tipo, institucion, fecha_inicio)
    VALUES ('Programa PA-' || v_suffix, 'S', 'IMAS', SYSDATE)
    RETURNING id_programa INTO v_id_programa;

    DBMS_OUTPUT.PUT_LINE('Persona ID: ' || v_id_persona || ' (Luis Mora)');
    DBMS_OUTPUT.PUT_LINE('Programa ID: ' || v_id_programa);

    FOR r_prog IN (
        SELECT nombre, tipo, estado FROM siac_programa WHERE id_programa = v_id_programa
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Programa: ' || r_prog.nombre || ' (' || r_prog.estado || ')');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Ejecutando pcAsignarPersonaAProgramaComunitario (1ra vez) ---');
    DBMS_OUTPUT.PUT_LINE('');

    PckAtencionComunitaria.pcAsignarPersonaAProgramaComunitario(
        p_id_persona      => v_id_persona,
        p_id_programa     => v_id_programa,
        p_observaciones   => 'Ingreso por campana de salud',
        p_mensaje         => v_mensaje,
        p_id_beneficiario => v_id_beneficiario
    );

    DBMS_OUTPUT.PUT_LINE(v_mensaje);
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Verificando inscripcion ---');
    FOR r_benef IN (
        SELECT b.id_beneficiario, b.estado_participacion,
               b.fecha_inicio_participacion
        FROM siac_beneficiario b
        WHERE b.id_beneficiario = v_id_beneficiario
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Beneficiario ID: ' || r_benef.id_beneficiario);
        DBMS_OUTPUT.PUT_LINE('Estado: ' || r_benef.estado_participacion);
        DBMS_OUTPUT.PUT_LINE('Fecha inicio: ' || r_benef.fecha_inicio_participacion);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Ejecutando (2da vez - debe fallar por duplicado) ---');
    DBMS_OUTPUT.PUT_LINE('');

    PckAtencionComunitaria.pcAsignarPersonaAProgramaComunitario(
        p_id_persona      => v_id_persona,
        p_id_programa     => v_id_programa,
        p_observaciones   => NULL,
        p_mensaje         => v_mensaje,
        p_id_beneficiario => v_id_beneficiario
    );

    DBMS_OUTPUT.PUT_LINE(v_mensaje);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;

