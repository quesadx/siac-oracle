DECLARE
    v_suffix            VARCHAR2(20) := TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3');
    v_id_region         NUMBER;
    v_id_distrito       NUMBER;
    v_id_comunidad      NUMBER;
    v_id_vivienda       NUMBER;
    v_id_familia        NUMBER;
    v_id_persona1       NUMBER;
    v_id_persona2       NUMBER;
    v_id_enfermedad     NUMBER;
    v_mensaje           VARCHAR2(4000);
    v_nueva_clasific    VARCHAR2(1);
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('EVIDENCIA: pcCambiarClasificacionRiesgoFamilia');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Preparando datos base ---');

    INSERT INTO siac_region (nombre) VALUES ('Region CR-' || v_suffix)
    RETURNING id_region INTO v_id_region;

    INSERT INTO siac_distrito (nombre, id_region) VALUES ('Distrito CR-' || v_suffix, v_id_region)
    RETURNING id_distrito INTO v_id_distrito;

    INSERT INTO siac_comunidad (nombre, id_distrito) VALUES ('Comunidad CR-' || v_suffix, v_id_distrito)
    RETURNING id_comunidad INTO v_id_comunidad;

    INSERT INTO siac_vivienda (direccion_exacta, id_comunidad)
    VALUES ('Calle Principal, Casa #10', v_id_comunidad)
    RETURNING id_vivienda INTO v_id_vivienda;

    INSERT INTO siac_familia (nombre_familia, id_vivienda, clasificacion_riesgo)
    VALUES ('Familia Riesgo CR-' || v_suffix, v_id_vivienda, 'B')
    RETURNING id_familia INTO v_id_familia;

    INSERT INTO siac_persona (cedula, nombre, primer_apellido, fecha_nacimiento, genero,
                              relacion_familia, id_familia)
    VALUES ('1-' || v_suffix || '1', 'Pedro', 'Rojas', DATE '1980-01-15', 'M', 'J', v_id_familia)
    RETURNING id_persona INTO v_id_persona1;

    UPDATE siac_familia SET id_jefe_familia = v_id_persona1 WHERE id_familia = v_id_familia;

    INSERT INTO siac_persona (cedula, nombre, primer_apellido, fecha_nacimiento, genero,
                              relacion_familia, id_familia)
    VALUES ('1-' || v_suffix || '2', 'Ana', 'Rojas', DATE '1982-06-20', 'F', 'C', v_id_familia)
    RETURNING id_persona INTO v_id_persona2;

    DBMS_OUTPUT.PUT_LINE('Familia ID: ' || v_id_familia);
    DBMS_OUTPUT.PUT_LINE('Persona 1 (jefe) ID: ' || v_id_persona1);
    DBMS_OUTPUT.PUT_LINE('Persona 2 ID: ' || v_id_persona2);
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Asignando enfermedades cronicas ---');

    SELECT id_enfermedad INTO v_id_enfermedad
    FROM siac_enfermedad WHERE nombre = 'Diabetes Mellitus Tipo 2';
    INSERT INTO siac_persona_enfermedad (id_persona, id_enfermedad, fecha_diagnostico,
                                         estado_condicion)
    VALUES (v_id_persona1, v_id_enfermedad, DATE '2020-03-15', 'A');
    DBMS_OUTPUT.PUT_LINE('  - Diabetes (Cronica) asignada al jefe');

    BEGIN
        SELECT id_enfermedad INTO v_id_enfermedad
        FROM siac_enfermedad
        WHERE UPPER(TRANSLATE(nombre, 'áéíóúÁÉÍÓÚñÑ', 'aeiouAEIOUnN')) = 'HIPERTENSION ARTERIAL';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_enfermedad := NULL;
    END;
    IF v_id_enfermedad IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('  - ADVERTENCIA: No se encontro Hipertension en el catalogo');
    ELSE
        INSERT INTO siac_persona_enfermedad (id_persona, id_enfermedad, fecha_diagnostico,
                                             estado_condicion)
        VALUES (v_id_persona2, v_id_enfermedad, DATE '2021-07-10', 'A');
        DBMS_OUTPUT.PUT_LINE('  - Hipertension (Cronica) asignada al conyuge');
    END IF;
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Agregando control de salud vencido ---');

    INSERT INTO siac_control_salud (id_persona, id_tipo_control, fecha_control,
                                    fecha_proxima_cita, resultado, profesional_responsable)
    SELECT v_id_persona1, id_tipo_control, DATE '2025-01-15',
           DATE '2025-02-15', 'N', 'Dr. Evidencia'
    FROM siac_tipo_control WHERE descripcion = 'CONTROL CRONICOS';

    DBMS_OUTPUT.PUT_LINE('  - Control vencido agregado al jefe');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Estado actual antes del cambio ---');
    FOR r_estado IN (
        SELECT f.clasificacion_riesgo,
               (SELECT COUNT(*) FROM siac_persona_enfermedad pe
                JOIN siac_persona p ON p.id_persona = pe.id_persona
                WHERE p.id_familia = f.id_familia
                  AND pe.estado_condicion = 'A') as enf_activas,
               (SELECT COUNT(*) FROM siac_persona_enfermedad pe
                JOIN siac_persona p ON p.id_persona = pe.id_persona
                JOIN siac_enfermedad e ON e.id_enfermedad = pe.id_enfermedad
                WHERE p.id_familia = f.id_familia
                  AND pe.estado_condicion = 'A'
                  AND e.tipo = 'C') as enf_cronicas,
               (SELECT COUNT(*) FROM siac_control_salud cs
                JOIN siac_persona p ON p.id_persona = cs.id_persona
                WHERE p.id_familia = f.id_familia
                  AND cs.fecha_proxima_cita IS NOT NULL
                  AND cs.fecha_proxima_cita < SYSDATE) as controles_pend
        FROM siac_familia f
        WHERE f.id_familia = v_id_familia
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  Clasificacion actual: ' || r_estado.clasificacion_riesgo);
        DBMS_OUTPUT.PUT_LINE('  Enf. activas: ' || r_estado.enf_activas);
        DBMS_OUTPUT.PUT_LINE('  Enf. cronicas: ' || r_estado.enf_cronicas);
        DBMS_OUTPUT.PUT_LINE('  Controles pend.: ' || r_estado.controles_pend);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Ejecutando pcCambiarClasificacionRiesgoFamilia ---');
    DBMS_OUTPUT.PUT_LINE('');

    PckAtencionComunitaria.pcCambiarClasificacionRiesgoFamilia(
        p_id_familia           => v_id_familia,
        p_mensaje              => v_mensaje,
        p_nueva_clasificacion  => v_nueva_clasific
    );

    DBMS_OUTPUT.PUT_LINE(v_mensaje);
    DBMS_OUTPUT.PUT_LINE('Nueva clasificacion: ' || v_nueva_clasific);

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- Verificacion en tabla siac_familia ---');
    FOR r_final IN (
        SELECT id_familia, nombre_familia, clasificacion_riesgo
        FROM siac_familia
        WHERE id_familia = v_id_familia
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Familia: ' || r_final.nombre_familia);
        DBMS_OUTPUT.PUT_LINE('Riesgo final: ' || r_final.clasificacion_riesgo);
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/
