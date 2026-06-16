DECLARE
    v_suffix          VARCHAR2(20) := TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3');
    v_id_region       NUMBER;
    v_id_distrito     NUMBER;
    v_id_comunidad    NUMBER;
    v_id_vivienda     NUMBER;
    v_id_familia      NUMBER;
    v_id_persona1     NUMBER;
    v_id_persona2     NUMBER;
    v_id_programa     NUMBER;
    v_id_benef1       NUMBER;
    v_id_benef2       NUMBER;
    v_mensaje         VARCHAR2(4000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('EVIDENCIA: pcCerrarProgramaComunitario');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Preparando datos base ---');

    INSERT INTO siac_region (nombre) VALUES ('Region CC-' || v_suffix)
    RETURNING id_region INTO v_id_region;

    INSERT INTO siac_distrito (nombre, id_region) VALUES ('Distrito CC-' || v_suffix, v_id_region)
    RETURNING id_distrito INTO v_id_distrito;

    INSERT INTO siac_comunidad (nombre, id_distrito) VALUES ('Comunidad CC-' || v_suffix, v_id_distrito)
    RETURNING id_comunidad INTO v_id_comunidad;

    INSERT INTO siac_vivienda (direccion_exacta, id_comunidad)
    VALUES ('Frente a la escuela', v_id_comunidad)
    RETURNING id_vivienda INTO v_id_vivienda;

    INSERT INTO siac_familia (nombre_familia, id_vivienda)
    VALUES ('Familia Cierre CC-' || v_suffix, v_id_vivienda)
    RETURNING id_familia INTO v_id_familia;

    INSERT INTO siac_persona (cedula, nombre, primer_apellido, fecha_nacimiento,
                              genero, relacion_familia, id_familia)
    VALUES ('1-' || v_suffix || '1', 'Sofia', 'Castro', DATE '1988-03-12', 'F', 'J', v_id_familia)
    RETURNING id_persona INTO v_id_persona1;

    UPDATE siac_familia SET id_jefe_familia = v_id_persona1 WHERE id_familia = v_id_familia;

    INSERT INTO siac_persona (cedula, nombre, primer_apellido, fecha_nacimiento,
                              genero, relacion_familia, id_familia)
    VALUES ('1-' || v_suffix || '2', 'Diego', 'Castro', DATE '2010-11-25', 'M', 'H', v_id_familia)
    RETURNING id_persona INTO v_id_persona2;

    INSERT INTO siac_programa (nombre, tipo, institucion, fecha_inicio)
    VALUES ('Programa Cierre CC-' || v_suffix, 'A', 'CCSS', DATE '2025-06-01')
    RETURNING id_programa INTO v_id_programa;

    INSERT INTO siac_beneficiario (id_programa, id_persona, fecha_inicio_participacion,
                                   estado_participacion)
    VALUES (v_id_programa, v_id_persona1, DATE '2025-06-15', 'A')
    RETURNING id_beneficiario INTO v_id_benef1;

    INSERT INTO siac_beneficiario (id_programa, id_persona, fecha_inicio_participacion,
                                   estado_participacion)
    VALUES (v_id_programa, v_id_persona2, DATE '2025-06-15', 'A')
    RETURNING id_beneficiario INTO v_id_benef2;

    DBMS_OUTPUT.PUT_LINE('Programa ID: ' || v_id_programa);
    DBMS_OUTPUT.PUT_LINE('Beneficiario 1 ID: ' || v_id_benef1 || ' (Sofia)');
    DBMS_OUTPUT.PUT_LINE('Beneficiario 2 ID: ' || v_id_benef2 || ' (Diego)');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Estado ANTES del cierre ---');
    FOR r_ant IN (
        SELECT pe.nombre, p.estado as prog_estado, p.fecha_fin,
               b.estado_participacion, b.fecha_fin_participacion
        FROM siac_programa p
        LEFT JOIN siac_beneficiario b ON b.id_programa = p.id_programa
        LEFT JOIN siac_persona pe ON pe.id_persona = b.id_persona
        WHERE p.id_programa = v_id_programa
        ORDER BY pe.nombre
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  Programa: ' || r_ant.prog_estado
                             || ' | Fecha fin: ' || NVL(TO_CHAR(r_ant.fecha_fin, 'YYYY-MM-DD'), '(null)'));
        DBMS_OUTPUT.PUT_LINE('  Beneficiario (' || r_ant.nombre
                             || '): ' || r_ant.estado_participacion);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Ejecutando pcCerrarProgramaComunitario ---');
    DBMS_OUTPUT.PUT_LINE('');

    PckAtencionComunitaria.pcCerrarProgramaComunitario(
        p_id_programa => v_id_programa,
        p_mensaje     => v_mensaje
    );

    DBMS_OUTPUT.PUT_LINE(v_mensaje);
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Estado DESPUES del cierre ---');
    FOR r_desp IN (
        SELECT pe.nombre, p.estado as prog_estado,
               TO_CHAR(p.fecha_fin, 'YYYY-MM-DD') as fecha_fin_prog,
               b.estado_participacion,
               TO_CHAR(b.fecha_fin_participacion, 'YYYY-MM-DD') as fecha_fin_benef
        FROM siac_programa p
        LEFT JOIN siac_beneficiario b ON b.id_programa = p.id_programa
        LEFT JOIN siac_persona pe ON pe.id_persona = b.id_persona
        WHERE p.id_programa = v_id_programa
        ORDER BY pe.nombre
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  Programa: ' || r_desp.prog_estado
                             || ' | Fecha fin: ' || r_desp.fecha_fin_prog);
        DBMS_OUTPUT.PUT_LINE('  Beneficiario (' || r_desp.nombre
                             || '): ' || r_desp.estado_participacion
                             || ' | Fecha fin part.: ' || r_desp.fecha_fin_benef);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- Intentando cerrar nuevamente (debe fallar) ---');
    DBMS_OUTPUT.PUT_LINE('');

    PckAtencionComunitaria.pcCerrarProgramaComunitario(
        p_id_programa => v_id_programa,
        p_mensaje     => v_mensaje
    );

    DBMS_OUTPUT.PUT_LINE(v_mensaje);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;

