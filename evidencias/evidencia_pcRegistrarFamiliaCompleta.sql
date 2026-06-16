DECLARE
    v_suffix        VARCHAR2(20) := TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3');
    v_id_region     NUMBER;
    v_id_distrito   NUMBER;
    v_id_comunidad  NUMBER;
    v_mensaje       VARCHAR2(4000);
    v_id_familia    NUMBER;

    v_miembros PckAtencionComunitaria.t_miembros_tab
        := PckAtencionComunitaria.t_miembros_tab();
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('EVIDENCIA: pcRegistrarFamiliaCompleta');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('');

    DBMS_OUTPUT.PUT_LINE('--- Preparando datos base ---');

    INSERT INTO siac_region (nombre) VALUES ('Region EC-' || v_suffix)
    RETURNING id_region INTO v_id_region;

    INSERT INTO siac_distrito (nombre, id_region) VALUES ('Distrito EC-' || v_suffix, v_id_region)
    RETURNING id_distrito INTO v_id_distrito;

    INSERT INTO siac_comunidad (nombre, id_distrito) VALUES ('Comunidad EC-' || v_suffix, v_id_distrito)
    RETURNING id_comunidad INTO v_id_comunidad;

    DBMS_OUTPUT.PUT_LINE('Region ID: ' || v_id_region);
    DBMS_OUTPUT.PUT_LINE('Distrito ID: ' || v_id_distrito);
    DBMS_OUTPUT.PUT_LINE('Comunidad ID: ' || v_id_comunidad);
    DBMS_OUTPUT.PUT_LINE('');

    v_miembros.EXTEND(2);

    v_miembros(1).cedula           := '2-' || v_suffix || '1';
    v_miembros(1).nombre           := 'Maria';
    v_miembros(1).primer_apellido  := 'Perez';
    v_miembros(1).segundo_apellido := 'Lopez';
    v_miembros(1).fecha_nacimiento := DATE '1990-05-15';
    v_miembros(1).genero           := 'F';
    v_miembros(1).estado_civil     := 'C';
    v_miembros(1).nivel_educativo  := 'S';
    v_miembros(1).ocupacion        := 'Ama de casa';
    v_miembros(1).relacion_familia := 'C';

    v_miembros(2).cedula           := '3-' || v_suffix || '1';
    v_miembros(2).nombre           := 'Carlos';
    v_miembros(2).primer_apellido  := 'Perez';
    v_miembros(2).segundo_apellido := 'Perez';
    v_miembros(2).fecha_nacimiento := DATE '2015-08-22';
    v_miembros(2).genero           := 'M';
    v_miembros(2).estado_civil     := 'S';
    v_miembros(2).nivel_educativo  := 'P';
    v_miembros(2).ocupacion        := 'Estudiante';
    v_miembros(2).relacion_familia := 'H';

    DBMS_OUTPUT.PUT_LINE('--- Ejecutando pcRegistrarFamiliaCompleta ---');
    DBMS_OUTPUT.PUT_LINE('');

    PckAtencionComunitaria.pcRegistrarFamiliaCompleta(
        p_direccion_exacta       => '100 mts norte de la Iglesia, Casa #5',
        p_id_comunidad           => v_id_comunidad,
        p_condicion_general      => 'B',
        p_tipo_vivienda          => 'P',
        p_material_paredes       => 'Bloque',
        p_material_techo         => 'Zinc',
        p_acceso_agua            => 'S',
        p_acceso_electricidad    => 'S',
        p_acceso_alcantarillado  => 'N',
        p_acceso_internet        => 'S',
        p_estado_sanitario       => 'A',
        p_observaciones_vivienda => 'Casa en buen estado',
        p_nombre_familia         => 'Familia Perez EC-' || v_suffix,
        p_observaciones_familia  => 'Familia nuclear de 3 miembros',
        p_cedula_jefe            => '1-' || v_suffix || '1',
        p_nombre_jefe            => 'Juan',
        p_primer_apellido_jefe   => 'Perez',
        p_segundo_apellido_jefe  => 'Garcia',
        p_fecha_nacimiento_jefe  => DATE '1985-03-10',
        p_genero_jefe            => 'M',
        p_estado_civil_jefe      => 'C',
        p_nivel_educativo_jefe   => 'T',
        p_ocupacion_jefe         => 'Agricultor',
        p_miembros               => v_miembros,
        p_mensaje                => v_mensaje,
        p_id_familia             => v_id_familia
    );

    DBMS_OUTPUT.PUT_LINE(v_mensaje);

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- Verificacion de datos insertados ---');

    FOR r_familia IN (
        SELECT f.id_familia, f.nombre_familia, f.clasificacion_riesgo,
               v.direccion_exacta, v.tipo_vivienda
        FROM siac_familia f
        JOIN siac_vivienda v ON v.id_vivienda = f.id_vivienda
        WHERE f.id_familia = v_id_familia
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Familia ID: ' || r_familia.id_familia);
        DBMS_OUTPUT.PUT_LINE('Nombre: ' || r_familia.nombre_familia);
        DBMS_OUTPUT.PUT_LINE('Riesgo: ' || r_familia.clasificacion_riesgo);
        DBMS_OUTPUT.PUT_LINE('Direccion: ' || r_familia.direccion_exacta);
        DBMS_OUTPUT.PUT_LINE('Tipo vivienda: ' || r_familia.tipo_vivienda);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Miembros de la familia registrados:');
    FOR r_miembro IN (
        SELECT cedula, nombre, primer_apellido, relacion_familia
        FROM siac_persona
        WHERE id_familia = v_id_familia
        ORDER BY relacion_familia
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            '  - ' || r_miembro.cedula || ' | '
            || r_miembro.nombre || ' ' || r_miembro.primer_apellido
            || ' | Rol: ' || r_miembro.relacion_familia
        );
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/
