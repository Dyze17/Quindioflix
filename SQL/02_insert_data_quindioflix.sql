-- =========================================================
-- QUINDIOFLIX - ENTREGA 1
-- Script 02: Insercion de datos de prueba
-- =========================================================

SET SERVEROUTPUT ON;

PROMPT =====================================================
PROMPT INSERCION DE DATOS BASE
PROMPT =====================================================

INSERT INTO planes (nombre_plan, precio_mensual, max_pantallas, calidad_video, max_perfiles, descripcion) VALUES
('BASICO',   14900, 1, 'SD', 2, 'Plan basico con una pantalla simultanea y calidad SD');

INSERT INTO planes (nombre_plan, precio_mensual, max_pantallas, calidad_video, max_perfiles, descripcion) VALUES
('ESTANDAR', 24900, 2, 'HD', 3, 'Plan estandar con dos pantallas simultaneas y calidad HD');

INSERT INTO planes (nombre_plan, precio_mensual, max_pantallas, calidad_video, max_perfiles, descripcion) VALUES
('PREMIUM',  34900, 4, '4K', 5, 'Plan premium con cuatro pantallas simultaneas y calidad 4K');

INSERT INTO departamentos (nombre_departamento, descripcion) VALUES ('TECNOLOGIA', 'Area responsable de la plataforma y la infraestructura.');
INSERT INTO departamentos (nombre_departamento, descripcion) VALUES ('CONTENIDO', 'Area encargada del catalogo y publicaciones.');
INSERT INTO departamentos (nombre_departamento, descripcion) VALUES ('MARKETING', 'Area responsable de adquisicion y campanas.');
INSERT INTO departamentos (nombre_departamento, descripcion) VALUES ('SOPORTE', 'Area que atiende solicitudes y reportes de usuarios.');
INSERT INTO departamentos (nombre_departamento, descripcion) VALUES ('FINANZAS', 'Area encargada de facturacion y control financiero.');

INSERT INTO roles_app (nombre_rol, descripcion) VALUES ('CLIENTE', 'Usuario final de la plataforma.');
INSERT INTO roles_app (nombre_rol, descripcion) VALUES ('MODERADOR', 'Usuario con capacidad de revisar reportes de contenido.');
INSERT INTO roles_app (nombre_rol, descripcion) VALUES ('CREADOR_RESEÑAS', 'Usuario con actividad frecuente de resenas.');
INSERT INTO roles_app (nombre_rol, descripcion) VALUES ('EMBAJADOR', 'Usuario que refiere nuevos clientes a la plataforma.');

INSERT INTO categorias (nombre_categoria, descripcion) VALUES ('PELICULA', 'Contenido cinematografico unitario.');
INSERT INTO categorias (nombre_categoria, descripcion) VALUES ('SERIE', 'Contenido serializado por temporadas y episodios.');
INSERT INTO categorias (nombre_categoria, descripcion) VALUES ('DOCUMENTAL', 'Contenido documental o de no ficcion.');
INSERT INTO categorias (nombre_categoria, descripcion) VALUES ('MUSICA', 'Contenido musical, conciertos o sesiones.');
INSERT INTO categorias (nombre_categoria, descripcion) VALUES ('PODCAST', 'Contenido de audio seriado.');

INSERT INTO generos (nombre_genero, descripcion) VALUES ('ACCION', 'Genero de accion.');
INSERT INTO generos (nombre_genero, descripcion) VALUES ('COMEDIA', 'Genero comico.');
INSERT INTO generos (nombre_genero, descripcion) VALUES ('DRAMA', 'Genero dramatico.');
INSERT INTO generos (nombre_genero, descripcion) VALUES ('SUSPENSO', 'Genero de suspenso.');
INSERT INTO generos (nombre_genero, descripcion) VALUES ('ROMANCE', 'Genero romantico.');
INSERT INTO generos (nombre_genero, descripcion) VALUES ('CIENCIA FICCION', 'Genero de ciencia ficcion.');
INSERT INTO generos (nombre_genero, descripcion) VALUES ('TERROR', 'Genero de terror.');
INSERT INTO generos (nombre_genero, descripcion) VALUES ('INFANTIL', 'Genero apto para audiencias infantiles.');

COMMIT;

PROMPT =====================================================
PROMPT EMPLEADOS Y ESTRUCTURA INTERNA
PROMPT =====================================================

BEGIN
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (1, NULL, 'Laura', 'Ramirez', 'laura.ramirez@quindioflix.com', '3001000001', 'Jefe Tecnologia', DATE '2022-01-10', 8200000, 'ACTIVO');
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (1, 1, 'Mateo', 'Lopez', 'mateo.lopez@quindioflix.com', '3001000002', 'Arquitecto BD', DATE '2022-03-15', 6100000, 'ACTIVO');
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (1, 1, 'Sofia', 'Perez', 'sofia.perez@quindioflix.com', '3001000003', 'Ingeniera Backend', DATE '2023-06-01', 5400000, 'ACTIVO');

    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (2, NULL, 'Carlos', 'Mejia', 'carlos.mejia@quindioflix.com', '3001000004', 'Jefe Contenido', DATE '2021-11-20', 7900000, 'ACTIVO');
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (2, 4, 'Valentina', 'Gomez', 'valentina.gomez@quindioflix.com', '3001000005', 'Curadora Catalogo', DATE '2023-01-05', 4800000, 'ACTIVO');
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (2, 4, 'Nicolas', 'Torres', 'nicolas.torres@quindioflix.com', '3001000006', 'Analista Editorial', DATE '2023-02-09', 4500000, 'ACTIVO');

    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (3, NULL, 'Daniela', 'Cano', 'daniela.cano@quindioflix.com', '3001000007', 'Jefe Marketing', DATE '2021-09-17', 7300000, 'ACTIVO');
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (3, 7, 'Juan', 'Barrera', 'juan.barrera@quindioflix.com', '3001000008', 'Analista CRM', DATE '2024-01-12', 3900000, 'ACTIVO');
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (3, 7, 'Paula', 'Rios', 'paula.rios@quindioflix.com', '3001000009', 'Especialista Growth', DATE '2023-08-22', 4200000, 'ACTIVO');

    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (4, NULL, 'Andres', 'Mora', 'andres.mora@quindioflix.com', '3001000010', 'Jefe Soporte', DATE '2022-04-14', 6800000, 'ACTIVO');
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (4, 10, 'Sara', 'Osorio', 'sara.osorio@quindioflix.com', '3001000011', 'Moderadora Senior', DATE '2023-05-19', 3700000, 'ACTIVO');
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (4, 10, 'Felipe', 'Castro', 'felipe.castro@quindioflix.com', '3001000012', 'Agente Soporte', DATE '2024-02-03', 3200000, 'ACTIVO');

    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (5, NULL, 'Camila', 'Vargas', 'camila.vargas@quindioflix.com', '3001000013', 'Jefe Finanzas', DATE '2021-07-11', 8100000, 'ACTIVO');
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (5, 13, 'Diego', 'Reyes', 'diego.reyes@quindioflix.com', '3001000014', 'Analista Facturacion', DATE '2023-03-07', 4100000, 'ACTIVO');
    INSERT INTO empleados (id_departamento, supervisor_id, nombres, apellidos, correo, telefono, cargo, fecha_ingreso, salario, estado_empleado)
    VALUES (5, 13, 'Maria', 'Velez', 'maria.velez@quindioflix.com', '3001000015', 'Tesorera', DATE '2022-10-02', 4300000, 'ACTIVO');
END;
/

UPDATE departamentos SET id_jefe = 1  WHERE id_departamento = 1;
UPDATE departamentos SET id_jefe = 4  WHERE id_departamento = 2;
UPDATE departamentos SET id_jefe = 7  WHERE id_departamento = 3;
UPDATE departamentos SET id_jefe = 10 WHERE id_departamento = 4;
UPDATE departamentos SET id_jefe = 13 WHERE id_departamento = 5;

COMMIT;

PROMPT =====================================================
PROMPT USUARIOS Y ROLES DE APLICACION
PROMPT =====================================================

DECLARE
    v_ciudad         VARCHAR2(60);
    v_plan           NUMBER;
    v_referidor      NUMBER;
    v_estado         VARCHAR2(15);
    v_beneficio      VARCHAR2(120);
BEGIN
    FOR i IN 1..30 LOOP
        IF MOD(i,3) = 1 THEN
            v_ciudad := 'Bogota';
        ELSIF MOD(i,3) = 2 THEN
            v_ciudad := 'Medellin';
        ELSE
            v_ciudad := 'Cali';
        END IF;

        v_plan := CASE
                      WHEN i BETWEEN 1 AND 8 THEN 1
                      WHEN i BETWEEN 9 AND 19 THEN 2
                      ELSE 3
                  END;

        v_referidor := CASE
                           WHEN i IN (6, 11, 16, 21, 26) THEN i - 1
                           WHEN i IN (8, 14, 19, 24, 29) THEN i - 2
                           ELSE NULL
                       END;

        v_estado := CASE
                        WHEN i IN (4, 12, 23, 28) THEN 'SUSPENDIDO'
                        WHEN i IN (17) THEN 'INACTIVO'
                        ELSE 'ACTIVO'
                    END;

        v_beneficio := CASE
                           WHEN v_referidor IS NOT NULL THEN '10% descuento siguiente mes'
                           ELSE NULL
                       END;

        INSERT INTO usuarios (
            id_plan_actual, id_usuario_referidor, nombres, apellidos, email, telefono,
            fecha_nacimiento, ciudad, fecha_registro, fecha_ultimo_pago, fecha_vencimiento,
            estado_cuenta, beneficio_referido
        )
        VALUES (
            v_plan,
            v_referidor,
            'Usuario' || TO_CHAR(i),
            'QuindioFlix' || TO_CHAR(i),
            'usuario' || TO_CHAR(i) || '@correo.com',
            '3105' || LPAD(i, 6, '0'),
            ADD_MONTHS(DATE '1988-01-01', i * 8),
            v_ciudad,
            ADD_MONTHS(DATE '2024-01-15', MOD(i, 18)),
            NULL,
            NULL,
            v_estado,
            v_beneficio
        );
    END LOOP;
END;
/

INSERT INTO usuario_rol_app (id_usuario, id_rol_app) SELECT id_usuario, 1 FROM usuarios;
INSERT INTO usuario_rol_app (id_usuario, id_rol_app) VALUES (2, 2);
INSERT INTO usuario_rol_app (id_usuario, id_rol_app) VALUES (5, 2);
INSERT INTO usuario_rol_app (id_usuario, id_rol_app) VALUES (8, 2);
INSERT INTO usuario_rol_app (id_usuario, id_rol_app) VALUES (6, 4);
INSERT INTO usuario_rol_app (id_usuario, id_rol_app) VALUES (11, 4);
INSERT INTO usuario_rol_app (id_usuario, id_rol_app) VALUES (16, 4);
INSERT INTO usuario_rol_app (id_usuario, id_rol_app) VALUES (3, 3);
INSERT INTO usuario_rol_app (id_usuario, id_rol_app) VALUES (9, 3);
INSERT INTO usuario_rol_app (id_usuario, id_rol_app) VALUES (18, 3);

COMMIT;

PROMPT =====================================================
PROMPT PERFILES
PROMPT =====================================================

DECLARE
    v_tipo VARCHAR2(10);
BEGIN
    FOR i IN 1..30 LOOP
        INSERT INTO perfiles (id_usuario, nombre_perfil, avatar, tipo_perfil, fecha_creacion)
        VALUES (i, 'Principal_' || i, 'avatar_' || MOD(i,10) || '.png', 'ADULTO', ADD_MONTHS(DATE '2024-02-01', MOD(i,10)));

        IF i <= 15 THEN
            v_tipo := CASE WHEN MOD(i,4) = 0 THEN 'INFANTIL' ELSE 'ADULTO' END;
            INSERT INTO perfiles (id_usuario, nombre_perfil, avatar, tipo_perfil, fecha_creacion)
            VALUES (i, 'Secundario_' || i, 'avatar_' || MOD(i+3,10) || '.png', v_tipo, ADD_MONTHS(DATE '2024-03-01', MOD(i,10)));
        END IF;

        IF i IN (20, 22, 24, 26, 28) THEN
            INSERT INTO perfiles (id_usuario, nombre_perfil, avatar, tipo_perfil, fecha_creacion)
            VALUES (i, 'Kids_' || i, 'avatar_kids_' || MOD(i,5) || '.png', 'INFANTIL', ADD_MONTHS(DATE '2024-04-01', MOD(i,6)));
        END IF;
    END LOOP;
END;
/

COMMIT;

PROMPT =====================================================
PROMPT CONTENIDO, GENEROS Y RELACIONES
PROMPT =====================================================

DECLARE
    v_categoria NUMBER;
    v_titulo    VARCHAR2(150);
BEGIN
    FOR i IN 1..40 LOOP
        v_categoria := CASE
                           WHEN i <= 10 THEN 1
                           WHEN i <= 20 THEN 2
                           WHEN i <= 26 THEN 3
                           WHEN i <= 33 THEN 4
                           ELSE 5
                       END;

        v_titulo := CASE
                        WHEN v_categoria = 1 THEN 'Pelicula ' || TO_CHAR(i)
                        WHEN v_categoria = 2 THEN 'Serie ' || TO_CHAR(i - 10)
                        WHEN v_categoria = 3 THEN 'Documental ' || TO_CHAR(i - 20)
                        WHEN v_categoria = 4 THEN 'Sesion Musical ' || TO_CHAR(i - 26)
                        ELSE 'Podcast ' || TO_CHAR(i - 33)
                    END;

        INSERT INTO contenido (
            id_categoria, id_empleado_responsable, titulo, anio_lanzamiento,
            duracion_minutos, sinopsis, clasificacion_edad, fecha_agregado_catalogo,
            es_original, popularidad, estado_publicacion
        )
        VALUES (
            v_categoria,
            CASE
                WHEN v_categoria IN (1,2,3,4,5) THEN CASE WHEN MOD(i,2)=0 THEN 5 ELSE 6 END
            END,
            v_titulo,
            2017 + MOD(i, 9),
            CASE
                WHEN v_categoria = 1 THEN 85 + MOD(i * 7, 50)
                WHEN v_categoria = 2 THEN 420 + MOD(i * 9, 180)
                WHEN v_categoria = 3 THEN 55 + MOD(i * 5, 40)
                WHEN v_categoria = 4 THEN 35 + MOD(i * 3, 25)
                ELSE 180 + MOD(i * 7, 70)
            END,
            'Sinopsis del contenido ' || v_titulo || ' dentro del catalogo de QuindioFlix.',
            CASE MOD(i,5)
                WHEN 0 THEN 'TP'
                WHEN 1 THEN '+7'
                WHEN 2 THEN '+13'
                WHEN 3 THEN '+16'
                ELSE '+18'
            END,
            ADD_MONTHS(DATE '2024-01-01', MOD(i, 18)),
            CASE WHEN i IN (2, 7, 12, 18, 22, 27, 35, 38) THEN 'S' ELSE 'N' END,
            0,
            'ACTIVO'
        );
    END LOOP;
END;
/

DECLARE
    g1 NUMBER;
    g2 NUMBER;
    g3 NUMBER;
BEGIN
    FOR i IN 1..40 LOOP
        g1 := MOD(i, 8) + 1;
        g2 := MOD(i + 2, 8) + 1;
        g3 := MOD(i + 4, 8) + 1;

        INSERT INTO contenido_genero (id_contenido, id_genero) VALUES (i, g1);

        IF g2 <> g1 THEN
            INSERT INTO contenido_genero (id_contenido, id_genero) VALUES (i, g2);
        END IF;

        IF MOD(i,3) = 0 AND g3 NOT IN (g1, g2) THEN
            INSERT INTO contenido_genero (id_contenido, id_genero) VALUES (i, g3);
        END IF;
    END LOOP;
END;
/

-- 15 temporadas: 10 para series (contenido 11-20) y 5 para podcasts (contenido 34-38)
BEGIN
    FOR i IN 11..20 LOOP
        INSERT INTO temporadas (id_contenido, numero_temporada, titulo_temporada, fecha_lanzamiento)
        VALUES (i, 1, 'Temporada 1 de Serie ' || TO_CHAR(i - 10), ADD_MONTHS(DATE '2024-02-01', i - 11));
    END LOOP;

    FOR i IN 34..38 LOOP
        INSERT INTO temporadas (id_contenido, numero_temporada, titulo_temporada, fecha_lanzamiento)
        VALUES (i, 1, 'Temporada 1 de Podcast ' || TO_CHAR(i - 33), ADD_MONTHS(DATE '2024-07-01', i - 34));
    END LOOP;
END;
/

-- 50 episodios
DECLARE
    v_num NUMBER;
BEGIN
    FOR t IN 1..15 LOOP
        FOR e IN 1..3 LOOP
            INSERT INTO episodios (id_temporada, numero_episodio, titulo_episodio, duracion_minutos, fecha_publicacion)
            VALUES (
                t,
                e,
                'Episodio ' || e || ' - Temporada ' || t,
                22 + MOD(t * e, 35),
                DATE '2024-02-01' + (t * 7) + e
            );
        END LOOP;
    END LOOP;

    FOR t IN 1..5 LOOP
        INSERT INTO episodios (id_temporada, numero_episodio, titulo_episodio, duracion_minutos, fecha_publicacion)
        VALUES (
            t,
            4,
            'Episodio 4 - Temporada ' || t,
            25 + MOD(t * 4, 35),
            DATE '2024-02-01' + (t * 9)
        );
    END LOOP;
END;
/

INSERT INTO contenido_relacionado (id_contenido_origen, id_contenido_destino, tipo_relacion, descripcion) VALUES (1, 2, 'SECUELA', 'Continuacion directa');
INSERT INTO contenido_relacionado (id_contenido_origen, id_contenido_destino, tipo_relacion, descripcion) VALUES (11, 12, 'SPIN_OFF', 'Serie derivada');
INSERT INTO contenido_relacionado (id_contenido_origen, id_contenido_destino, tipo_relacion, descripcion) VALUES (21, 22, 'VERSION_EXTENDIDA', 'Version extendida del documental');
INSERT INTO contenido_relacionado (id_contenido_origen, id_contenido_destino, tipo_relacion, descripcion) VALUES (34, 35, 'RELACIONADO', 'Podcast con tematica complementaria');
INSERT INTO contenido_relacionado (id_contenido_origen, id_contenido_destino, tipo_relacion, descripcion) VALUES (6, 9, 'REMAKE', 'Nueva version del contenido original');

COMMIT;

PROMPT =====================================================
PROMPT PAGOS
PROMPT =====================================================

DECLARE
    v_usuario   NUMBER;
    v_plan      NUMBER;
    v_mbase     NUMBER(10,2);
    v_desc      NUMBER(10,2);
    v_estado    VARCHAR2(15);
    v_metodo    VARCHAR2(20);
    v_fecha     DATE;
BEGIN
    FOR i IN 1..80 LOOP
        v_usuario := MOD(i - 1, 30) + 1;

        v_plan := CASE
                      WHEN v_usuario BETWEEN 1 AND 8 THEN 1
                      WHEN v_usuario BETWEEN 9 AND 19 THEN 2
                      ELSE 3
                  END;

        v_mbase := CASE v_plan
                       WHEN 1 THEN 14900
                       WHEN 2 THEN 24900
                       ELSE 34900
                   END;

        v_desc := CASE
                      WHEN v_usuario IN (6, 8, 11, 14, 16, 19, 21, 24, 26, 29) THEN ROUND(v_mbase * 0.10, 0)
                      ELSE 0
                  END;

        v_estado := CASE
                        WHEN MOD(i, 10) = 0 THEN 'FALLIDO'
                        WHEN MOD(i, 13) = 0 THEN 'PENDIENTE'
                        WHEN MOD(i, 17) = 0 THEN 'REEMBOLSADO'
                        ELSE 'EXITOSO'
                    END;

        IF MOD(i, 5) = 0 THEN
            v_metodo := 'TCREDITO';
        ELSIF MOD(i, 5) = 1 THEN
            v_metodo := 'TDEBITO';
        ELSIF MOD(i, 5) = 2 THEN
            v_metodo := 'PSE';
        ELSIF MOD(i, 5) = 3 THEN
            v_metodo := 'NEQUI';
        ELSE
            v_metodo := 'DAVIPLATA';
        END IF;

        v_fecha := DATE '2025-08-01' + MOD(i * 9, 210);

        INSERT INTO pagos (
            id_usuario, id_plan, fecha_pago, fecha_vencimiento, monto_base,
            valor_descuento, monto_pagado, metodo_pago, estado_pago, observacion
        )
        VALUES (
            v_usuario,
            v_plan,
            v_fecha,
            ADD_MONTHS(TRUNC(v_fecha, 'MM'), 1),
            v_mbase,
            v_desc,
            CASE WHEN v_estado = 'REEMBOLSADO' THEN 0 ELSE v_mbase - v_desc END,
            v_metodo,
            v_estado,
            CASE
                WHEN v_estado = 'FALLIDO' THEN 'Tarjeta rechazada'
                WHEN v_estado = 'PENDIENTE' THEN 'Pago en validacion'
                WHEN v_estado = 'REEMBOLSADO' THEN 'Reembolso solicitado por soporte'
                ELSE 'Pago procesado correctamente'
            END
        );
    END LOOP;
END;
/

UPDATE usuarios u
SET (fecha_ultimo_pago, fecha_vencimiento) = (
    SELECT MAX(CASE WHEN p.estado_pago = 'EXITOSO' THEN p.fecha_pago END),
           MAX(CASE WHEN p.estado_pago = 'EXITOSO' THEN p.fecha_vencimiento END)
    FROM pagos p
    WHERE p.id_usuario = u.id_usuario
);

UPDATE usuarios
SET estado_cuenta = CASE
                        WHEN fecha_vencimiento IS NULL THEN estado_cuenta
                        WHEN fecha_vencimiento < DATE '2026-02-01' THEN 'SUSPENDIDO'
                        ELSE estado_cuenta
                    END
WHERE id_usuario IN (4, 12, 17, 23, 28);

COMMIT;

PROMPT =====================================================
PROMPT REPRODUCCIONES
PROMPT =====================================================

DECLARE
    v_perfil       NUMBER;
    v_contenido    NUMBER;
    v_episodio     NUMBER;
    v_inicio       TIMESTAMP;
    v_fin          TIMESTAMP;
    v_dispositivo  VARCHAR2(20);
    v_avance       NUMBER(5,2);
BEGIN
    FOR i IN 1..200 LOOP
        v_perfil := MOD(i - 1, 50) + 1;

        v_contenido := CASE
                           WHEN MOD(i,10) IN (1,2,3) THEN MOD(i,5) + 1
                           WHEN MOD(i,10) IN (4,5) THEN 11 + MOD(i,10)
                           ELSE MOD(i - 1, 40) + 1
                       END;

        IF MOD(i,4) = 0 THEN
            v_dispositivo := 'CELULAR';
        ELSIF MOD(i,4) = 1 THEN
            v_dispositivo := 'TABLET';
        ELSIF MOD(i,4) = 2 THEN
            v_dispositivo := 'TV';
        ELSE
            v_dispositivo := 'COMPUTADOR';
        END IF;

        v_avance := CASE
                        WHEN MOD(i,5) = 0 THEN 100
                        WHEN MOD(i,4) = 0 THEN 95
                        ELSE 20 + MOD(i * 7, 65)
                    END;

        IF i <= 100 THEN
            v_inicio := TIMESTAMP '2024-01-01 08:00:00'
                        + NUMTODSINTERVAL(MOD(i * 13, 330), 'DAY')
                        + NUMTODSINTERVAL(MOD(i * 17, 24), 'HOUR')
                        + NUMTODSINTERVAL(MOD(i * 11, 60), 'MINUTE');
        ELSE
            v_inicio := TIMESTAMP '2025-01-01 08:00:00'
                        + NUMTODSINTERVAL(MOD(i * 9, 340), 'DAY')
                        + NUMTODSINTERVAL(MOD(i * 5, 24), 'HOUR')
                        + NUMTODSINTERVAL(MOD(i * 7, 60), 'MINUTE');
        END IF;

        v_fin := v_inicio + NUMTODSINTERVAL(25 + MOD(i, 115), 'MINUTE');

        IF v_contenido BETWEEN 11 AND 15 THEN
            v_episodio := ((v_contenido - 11) * 4) + 1 + MOD(i, 4);
        ELSIF v_contenido BETWEEN 16 AND 20 THEN
            v_episodio := 21 + ((v_contenido - 16) * 3) + MOD(i, 3);
        ELSIF v_contenido BETWEEN 34 AND 38 THEN
            v_episodio := 36 + ((v_contenido - 34) * 3) + MOD(i, 3);
        ELSE
            v_episodio := NULL;
        END IF;

        INSERT INTO reproducciones (
            id_perfil, id_contenido, id_episodio, fecha_hora_inicio,
            fecha_hora_fin, dispositivo, porcentaje_avance
        )
        VALUES (
            v_perfil, v_contenido, v_episodio, v_inicio, v_fin,
            v_dispositivo, v_avance
        );
    END LOOP;
END;
/

COMMIT;

PROMPT =====================================================
PROMPT CALIFICACIONES, FAVORITOS Y REPORTES
PROMPT =====================================================

BEGIN
    FOR i IN 1..60 LOOP
        INSERT INTO calificaciones (
            id_perfil, id_contenido, estrellas, resena, fecha_calificacion
        )
        VALUES (
            MOD(i - 1, 50) + 1,
            MOD((i * 3) - 1, 40) + 1,
            MOD(i, 5) + 1,
            CASE
                WHEN MOD(i,3) = 0 THEN 'Reseña breve del contenido ' || TO_CHAR(MOD((i * 3) - 1, 40) + 1)
                ELSE NULL
            END,
            DATE '2025-09-01' + MOD(i * 4, 150)
        );
    END LOOP;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

BEGIN
    FOR i IN 1..40 LOOP
        INSERT INTO favoritos (id_perfil, id_contenido, fecha_agregado)
        VALUES (i, MOD(i * 2, 40) + 1, DATE '2025-10-01' + MOD(i * 3, 120));
    END LOOP;
END;
/

INSERT INTO reportes_contenido (id_usuario_reporta, id_contenido, id_usuario_moderador, fecha_reporte, motivo, estado_reporte, fecha_resolucion, decision_moderacion)
VALUES (1, 7, 2, DATE '2025-11-04', 'Clasificacion de edad inconsistente', 'RESUELTO', DATE '2025-11-06', 'Se actualizo la clasificacion');

INSERT INTO reportes_contenido (id_usuario_reporta, id_contenido, id_usuario_moderador, fecha_reporte, motivo, estado_reporte, fecha_resolucion, decision_moderacion)
VALUES (3, 15, 5, DATE '2025-11-08', 'Audio fuera de sincronizacion', 'RESUELTO', DATE '2025-11-09', 'Incidencia trasladada a contenido');

INSERT INTO reportes_contenido (id_usuario_reporta, id_contenido, id_usuario_moderador, fecha_reporte, motivo, estado_reporte, fecha_resolucion, decision_moderacion)
VALUES (4, 21, 8, DATE '2025-11-20', 'Contenido potencialmente sensible', 'EN_REVISION', NULL, NULL);

INSERT INTO reportes_contenido (id_usuario_reporta, id_contenido, id_usuario_moderador, fecha_reporte, motivo, estado_reporte, fecha_resolucion, decision_moderacion)
VALUES (6, 34, 2, DATE '2026-01-03', 'Lenguaje inapropiado en episodio', 'PENDIENTE', NULL, NULL);

INSERT INTO reportes_contenido (id_usuario_reporta, id_contenido, id_usuario_moderador, fecha_reporte, motivo, estado_reporte, fecha_resolucion, decision_moderacion)
VALUES (9, 5, 5, DATE '2026-01-10', 'Error en subtitulos', 'RECHAZADO', DATE '2026-01-11', 'No se encontro incumplimiento');

COMMIT;

PROMPT =====================================================
PROMPT RESUMEN DE CARGA
PROMPT =====================================================

SELECT 'PLANES' AS tabla, COUNT(*) AS total FROM planes
UNION ALL SELECT 'USUARIOS', COUNT(*) FROM usuarios
UNION ALL SELECT 'PERFILES', COUNT(*) FROM perfiles
UNION ALL SELECT 'CATEGORIAS', COUNT(*) FROM categorias
UNION ALL SELECT 'GENEROS', COUNT(*) FROM generos
UNION ALL SELECT 'CONTENIDO', COUNT(*) FROM contenido
UNION ALL SELECT 'TEMPORADAS', COUNT(*) FROM temporadas
UNION ALL SELECT 'EPISODIOS', COUNT(*) FROM episodios
UNION ALL SELECT 'REPRODUCCIONES', COUNT(*) FROM reproducciones
UNION ALL SELECT 'CALIFICACIONES', COUNT(*) FROM calificaciones
UNION ALL SELECT 'PAGOS', COUNT(*) FROM pagos
UNION ALL SELECT 'FAVORITOS', COUNT(*) FROM favoritos
UNION ALL SELECT 'REPORTES_CONTENIDO', COUNT(*) FROM reportes_contenido
ORDER BY 1;
