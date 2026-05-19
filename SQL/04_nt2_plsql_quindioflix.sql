-- =========================================================
-- QUINDIOFLIX - ENTREGA 2
-- Script 04: Nucleo 2 - PL/SQL
--   Cursores, Procedimientos, Funciones,
--   Excepciones y Disparadores
-- =========================================================

SET SERVEROUTPUT ON SIZE 1000000;
SET DEFINE OFF;
SET PAGESIZE 100;
SET LINESIZE 200;

PROMPT =====================================================
PROMPT LIMPIEZA PREVIA DE OBJETOS PL/SQL
PROMPT =====================================================

BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_rep_cuenta_activa';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_perf_max_plan';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_calif_avance_min';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_pago_activa_cuenta';   EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION fn_contenido_recomendado'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION fn_calcular_monto';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_reporte_consumo';      EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_cambiar_plan';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE sp_registrar_usuario';    EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE cur_popularidad_contenido'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE cur_usuarios_morosos';      EXCEPTION WHEN OTHERS THEN NULL; END;
/

PROMPT =====================================================
PROMPT 1. CURSORES
PROMPT =====================================================

-- -------------------------------------------------------
-- CURSOR 1: Usuarios con suscripcion vencida (mora > 30 dias)
--   Recorre todos los usuarios cuya fecha_vencimiento
--   ya paso hace mas de 30 dias y genera un reporte con
--   nombre, email, plan, dias de mora y monto adeudado.
-- -------------------------------------------------------

CREATE OR REPLACE PROCEDURE cur_usuarios_morosos AS

    -- Cursor explícito parametrizado con los datos del usuario moroso
    CURSOR c_morosos IS
        SELECT
            u.id_usuario,
            u.nombres || ' ' || u.apellidos  AS nombre_completo,
            u.email,
            pl.nombre_plan,
            pl.precio_mensual,
            TRUNC(SYSDATE - u.fecha_vencimiento) AS dias_mora
        FROM usuarios u
        JOIN planes pl ON pl.id_plan = u.id_plan_actual
        WHERE u.fecha_vencimiento IS NOT NULL
          AND TRUNC(SYSDATE - u.fecha_vencimiento) > 30
        ORDER BY dias_mora DESC;

    -- Variables de registro
    v_nombre       VARCHAR2(200);
    v_email        VARCHAR2(120);
    v_plan         VARCHAR2(20);
    v_precio       NUMBER(10,2);
    v_dias         NUMBER;
    v_monto        NUMBER(10,2);
    v_contador     NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('REPORTE DE USUARIOS MOROSOS  (mora > 30 dias)');
    DBMS_OUTPUT.PUT_LINE('Generado: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('NOMBRE',35) || RPAD('EMAIL',35) ||
        RPAD('PLAN',10)   || RPAD('DIAS MORA',12) || 'MONTO ADEUDADO'
    );
    DBMS_OUTPUT.PUT_LINE(RPAD('-',110,'-'));

    FOR rec IN c_morosos LOOP
        -- El monto adeudado se estima como la cantidad de meses de mora
        -- (redondeando hacia arriba) por el precio del plan
        v_monto := CEIL(rec.dias_mora / 30) * rec.precio_mensual;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(SUBSTR(rec.nombre_completo,1,34), 35) ||
            RPAD(SUBSTR(rec.email,1,34), 35)           ||
            RPAD(rec.nombre_plan, 10)                  ||
            RPAD(rec.dias_mora, 12)                    ||
            TO_CHAR(v_monto, 'FM$999,990.00')
        );
        v_contador := v_contador + 1;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-',110,'-'));
    DBMS_OUTPUT.PUT_LINE('Total de usuarios morosos: ' || v_contador);
    DBMS_OUTPUT.PUT_LINE('==========================================================');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR en cur_usuarios_morosos: ' || SQLERRM);
        RAISE;
END cur_usuarios_morosos;
/

-- Ejecucion de prueba del cursor de morosos
BEGIN
    cur_usuarios_morosos;
END;
/

-- -------------------------------------------------------
-- CURSOR 2: Popularidad del catalogo
--   Recorre todos los contenidos, calcula reproducciones
--   completas (avance >= 90%) y actualiza el campo
--   CONTENIDO.POPULARIDAD.
-- -------------------------------------------------------

CREATE OR REPLACE PROCEDURE cur_popularidad_contenido AS

    -- Cursor que agrega reproducciones completas por contenido
    CURSOR c_popularidad IS
        SELECT
            c.id_contenido,
            c.titulo,
            COUNT(r.id_reproduccion)                                        AS total_rep,
            SUM(CASE WHEN r.porcentaje_avance >= 90 THEN 1 ELSE 0 END)     AS rep_completas
        FROM contenido c
        LEFT JOIN reproducciones r ON r.id_contenido = c.id_contenido
        GROUP BY c.id_contenido, c.titulo
        ORDER BY c.id_contenido;

    v_actualizados  NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('ACTUALIZACION DE POPULARIDAD DEL CATALOGO');
    DBMS_OUTPUT.PUT_LINE('Procesando...');
    DBMS_OUTPUT.PUT_LINE('==========================================================');

    FOR rec IN c_popularidad LOOP
        -- Actualizar el campo popularidad con las reproducciones completas
        UPDATE contenido
           SET popularidad = rec.rep_completas
         WHERE id_contenido = rec.id_contenido;

        v_actualizados := v_actualizados + 1;

        DBMS_OUTPUT.PUT_LINE(
            'Contenido [' || rec.id_contenido || '] ' ||
            RPAD(SUBSTR(rec.titulo,1,40), 42) ||
            ' | Reproducciones: ' || RPAD(rec.total_rep, 5) ||
            ' | Completas (>=90%): ' || rec.rep_completas
        );
    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE(RPAD('-',70,'-'));
    DBMS_OUTPUT.PUT_LINE('Contenidos actualizados: ' || v_actualizados);
    DBMS_OUTPUT.PUT_LINE('COMMIT realizado.');
    DBMS_OUTPUT.PUT_LINE('==========================================================');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR en cur_popularidad_contenido: ' || SQLERRM);
        RAISE;
END cur_popularidad_contenido;
/

-- Ejecucion de prueba del cursor de popularidad
BEGIN
    cur_popularidad_contenido;
END;
/

PROMPT =====================================================
PROMPT 2. PROCEDIMIENTOS ALMACENADOS + EXCEPCIONES
PROMPT =====================================================

-- -------------------------------------------------------
-- SP_REGISTRAR_USUARIO
--   Recibe datos del usuario y el plan elegido.
--   Valida que el email no exista (excepcion personalizada),
--   valida que el plan sea valido (NO_DATA_FOUND),
--   crea la cuenta, el perfil predeterminado y
--   registra el primer pago.
--
-- EXCEPCIONES manejadas (requisito 3.2.4.a):
--   e_email_duplicado  -> codigo -20001
--   NO_DATA_FOUND      -> plan invalido
-- -------------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_registrar_usuario (
    p_nombres          IN VARCHAR2,
    p_apellidos        IN VARCHAR2,
    p_email            IN VARCHAR2,
    p_telefono         IN VARCHAR2,
    p_fecha_nacimiento IN DATE,
    p_ciudad           IN VARCHAR2,
    p_id_plan          IN NUMBER,
    p_metodo_pago      IN VARCHAR2,
    p_id_referidor     IN NUMBER  DEFAULT NULL
)
AS
    -- Excepcion personalizada: email ya existe
    e_email_duplicado  EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_email_duplicado, -20001);

    v_count         NUMBER;
    v_id_usuario    NUMBER;
    v_precio        NUMBER(10,2);
    v_max_perfiles  NUMBER(2);
    v_nombre_plan   VARCHAR2(20);
    v_fecha_venc    DATE;
    v_descuento     NUMBER(10,2) := 0;

BEGIN
    -- 1. Validar que el email no exista
    SELECT COUNT(*) INTO v_count
      FROM usuarios
     WHERE LOWER(email) = LOWER(p_email);

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            'El email ' || p_email || ' ya esta registrado en el sistema.');
    END IF;

    -- 2. Obtener datos del plan (lanza NO_DATA_FOUND si no existe)
    SELECT precio_mensual, max_perfiles, nombre_plan
      INTO v_precio, v_max_perfiles, v_nombre_plan
      FROM planes
     WHERE id_plan = p_id_plan;

    -- 3. Calcular descuento si existe referidor activo
    IF p_id_referidor IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count
          FROM usuarios
         WHERE id_usuario = p_id_referidor
           AND estado_cuenta = 'ACTIVO';

        IF v_count > 0 THEN
            v_descuento := ROUND(v_precio * 0.10, 2); -- 10% de descuento
        END IF;
    END IF;

    v_fecha_venc := ADD_MONTHS(TRUNC(SYSDATE), 1);

    -- 4. Insertar el usuario
    INSERT INTO usuarios (
        id_plan_actual, id_usuario_referidor,
        nombres, apellidos, email, telefono,
        fecha_nacimiento, ciudad,
        fecha_registro, fecha_ultimo_pago, fecha_vencimiento,
        estado_cuenta,
        beneficio_referido
    ) VALUES (
        p_id_plan, p_id_referidor,
        p_nombres, p_apellidos, p_email, p_telefono,
        p_fecha_nacimiento, p_ciudad,
        TRUNC(SYSDATE), TRUNC(SYSDATE), v_fecha_venc,
        'ACTIVO',
        CASE WHEN v_descuento > 0 THEN '10% de descuento primer mes por referido' ELSE NULL END
    ) RETURNING id_usuario INTO v_id_usuario;

    -- 5. Crear perfil predeterminado
    INSERT INTO perfiles (id_usuario, nombre_perfil, avatar, tipo_perfil, fecha_creacion)
    VALUES (v_id_usuario, p_nombres, 'avatar_default.png', 'ADULTO', TRUNC(SYSDATE));

    -- 6. Registrar primer pago
    INSERT INTO pagos (
        id_usuario, id_plan,
        fecha_pago, fecha_vencimiento,
        monto_base, valor_descuento, monto_pagado,
        metodo_pago, estado_pago, observacion
    ) VALUES (
        v_id_usuario, p_id_plan,
        TRUNC(SYSDATE), v_fecha_venc,
        v_precio, v_descuento, v_precio - v_descuento,
        p_metodo_pago, 'EXITOSO',
        'Primer pago al registrarse. Plan: ' || v_nombre_plan
    );

    -- 7. Si el referidor existe y es valido, aplicarle beneficio
    IF p_id_referidor IS NOT NULL AND v_descuento > 0 THEN
        UPDATE usuarios
           SET beneficio_referido = 'Descuento del 10% en proximo mes por referir a ' || p_email
         WHERE id_usuario = p_id_referidor;
    END IF;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('==> Usuario registrado con exito.');
    DBMS_OUTPUT.PUT_LINE('    ID       : ' || v_id_usuario);
    DBMS_OUTPUT.PUT_LINE('    Nombre   : ' || p_nombres || ' ' || p_apellidos);
    DBMS_OUTPUT.PUT_LINE('    Plan     : ' || v_nombre_plan);
    DBMS_OUTPUT.PUT_LINE('    Pago     : $' || TO_CHAR(v_precio - v_descuento, 'FM999,990.00'));
    DBMS_OUTPUT.PUT_LINE('    Vencimiento: ' || TO_CHAR(v_fecha_venc, 'DD/MM/YYYY'));

EXCEPTION
    WHEN e_email_duplicado THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR [-20001]: ' || SQLERRM);
        RAISE;
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR [NO_DATA_FOUND]: El plan con ID ' || p_id_plan || ' no existe.');
        RAISE_APPLICATION_ERROR(-20002, 'Plan invalido: no se encontro el plan con ID ' || p_id_plan);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR inesperado en sp_registrar_usuario: ' || SQLERRM);
        RAISE;
END sp_registrar_usuario;
/

-- Prueba: registro exitoso
BEGIN
    sp_registrar_usuario(
        p_nombres          => 'Carlos',
        p_apellidos        => 'Ramirez Soto',
        p_email            => 'carlos.ramirez.nuevo@test.com',
        p_telefono         => '3001234567',
        p_fecha_nacimiento => DATE '1995-06-15',
        p_ciudad           => 'Armenia',
        p_id_plan          => 1,
        p_metodo_pago      => 'NEQUI'
    );
END;
/

-- Prueba: email duplicado (debe lanzar excepcion -20001)
BEGIN
    sp_registrar_usuario(
        p_nombres          => 'Carlos',
        p_apellidos        => 'Ramirez Soto',
        p_email            => 'carlos.ramirez.nuevo@test.com',
        p_telefono         => '3001234567',
        p_fecha_nacimiento => DATE '1995-06-15',
        p_ciudad           => 'Armenia',
        p_id_plan          => 1,
        p_metodo_pago      => 'NEQUI'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Capturado correctamente: ' || SQLERRM);
END;
/

-- Prueba: plan invalido (debe lanzar NO_DATA_FOUND -> -20002)
BEGIN
    sp_registrar_usuario(
        p_nombres          => 'Test',
        p_apellidos        => 'Invalido',
        p_email            => 'test.invalido.plan@test.com',
        p_telefono         => '3009999999',
        p_fecha_nacimiento => DATE '1990-01-01',
        p_ciudad           => 'Bogota',
        p_id_plan          => 9999,
        p_metodo_pago      => 'PSE'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Capturado correctamente: ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- SP_CAMBIAR_PLAN
--   Recibe el id del usuario y el nuevo plan.
--   Valida que no haya mas perfiles de los que permite el
--   nuevo plan (excepcion personalizada -20003).
--   Actualiza el plan y registra el cambio como nuevo pago.
--
-- EXCEPCIONES manejadas (requisito 3.2.4.b):
--   e_perfiles_excedidos -> codigo -20003
-- -------------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_cambiar_plan (
    p_id_usuario    IN NUMBER,
    p_nuevo_id_plan IN NUMBER
)
AS
    -- Excepcion personalizada: el usuario tiene mas perfiles de los permitidos
    e_perfiles_excedidos EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_perfiles_excedidos, -20003);

    v_plan_actual       NUMBER;
    v_nombre_plan_nuevo VARCHAR2(20);
    v_max_perfiles_nuevo NUMBER(2);
    v_precio_nuevo      NUMBER(10,2);
    v_perfiles_actuales NUMBER;
    v_nombre_usuario    VARCHAR2(200);
    v_estado_cuenta     VARCHAR2(15);
    v_fecha_venc        DATE;

BEGIN
    -- 1. Obtener datos del usuario
    SELECT id_plan_actual, nombres || ' ' || apellidos, estado_cuenta
      INTO v_plan_actual, v_nombre_usuario, v_estado_cuenta
      FROM usuarios
     WHERE id_usuario = p_id_usuario;

    IF v_estado_cuenta = 'INACTIVO' THEN
        RAISE_APPLICATION_ERROR(-20004, 'La cuenta del usuario esta INACTIVA y no puede cambiar de plan.');
    END IF;

    IF v_plan_actual = p_nuevo_id_plan THEN
        RAISE_APPLICATION_ERROR(-20005, 'El usuario ya tiene el plan indicado.');
    END IF;

    -- 2. Obtener datos del nuevo plan (NO_DATA_FOUND si no existe)
    SELECT nombre_plan, max_perfiles, precio_mensual
      INTO v_nombre_plan_nuevo, v_max_perfiles_nuevo, v_precio_nuevo
      FROM planes
     WHERE id_plan = p_nuevo_id_plan;

    -- 3. Contar perfiles activos del usuario
    SELECT COUNT(*) INTO v_perfiles_actuales
      FROM perfiles
     WHERE id_usuario = p_id_usuario;

    -- 4. Validar que los perfiles actuales caben en el nuevo plan
    IF v_perfiles_actuales > v_max_perfiles_nuevo THEN
        RAISE_APPLICATION_ERROR(-20003,
            'No se puede cambiar al plan ' || v_nombre_plan_nuevo ||
            ' porque el usuario tiene ' || v_perfiles_actuales ||
            ' perfiles y el nuevo plan permite maximo ' || v_max_perfiles_nuevo || '.');
    END IF;

    v_fecha_venc := ADD_MONTHS(TRUNC(SYSDATE), 1);

    -- 5. Actualizar el plan del usuario
    UPDATE usuarios
       SET id_plan_actual    = p_nuevo_id_plan,
           fecha_vencimiento = v_fecha_venc,
           fecha_ultimo_pago = TRUNC(SYSDATE)
     WHERE id_usuario = p_id_usuario;

    -- 6. Registrar el pago del nuevo plan
    INSERT INTO pagos (
        id_usuario, id_plan,
        fecha_pago, fecha_vencimiento,
        monto_base, valor_descuento, monto_pagado,
        metodo_pago, estado_pago, observacion
    ) VALUES (
        p_id_usuario, p_nuevo_id_plan,
        TRUNC(SYSDATE), v_fecha_venc,
        v_precio_nuevo, 0, v_precio_nuevo,
        'PSE', 'EXITOSO',
        'Cambio de plan registrado. Plan nuevo: ' || v_nombre_plan_nuevo
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('==> Plan cambiado con exito.');
    DBMS_OUTPUT.PUT_LINE('    Usuario   : ' || v_nombre_usuario);
    DBMS_OUTPUT.PUT_LINE('    Nuevo plan: ' || v_nombre_plan_nuevo);
    DBMS_OUTPUT.PUT_LINE('    Precio    : $' || TO_CHAR(v_precio_nuevo, 'FM999,990.00'));
    DBMS_OUTPUT.PUT_LINE('    Vencimiento: ' || TO_CHAR(v_fecha_venc, 'DD/MM/YYYY'));

EXCEPTION
    WHEN e_perfiles_excedidos THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR [-20003] Perfiles excedidos: ' || SQLERRM);
        RAISE;
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20006,
            'No se encontro el usuario con ID ' || p_id_usuario ||
            ' o el plan con ID ' || p_nuevo_id_plan || '.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR inesperado en sp_cambiar_plan: ' || SQLERRM);
        RAISE;
END sp_cambiar_plan;
/

-- Prueba cambio valido (usuario 1 cambia a plan 3 si existe)
BEGIN
    sp_cambiar_plan(p_id_usuario => 1, p_nuevo_id_plan => 3);
EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Resultado: ' || SQLERRM);
END;
/

-- -------------------------------------------------------
-- SP_REPORTE_CONSUMO
--   Recibe un id de usuario y un rango de fechas.
--   Genera un reporte detallado de reproducciones por
--   perfil agrupadas por categoria, con totales de tiempo.
-- -------------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_reporte_consumo (
    p_id_usuario    IN NUMBER,
    p_fecha_inicio  IN DATE,
    p_fecha_fin     IN DATE
)
AS
    -- Cursor con el consumo del usuario en el rango dado
    CURSOR c_consumo IS
        SELECT
            pf.nombre_perfil,
            cat.nombre_categoria,
            COUNT(r.id_reproduccion)                                    AS total_rep,
            SUM(CASE WHEN r.fecha_hora_fin IS NOT NULL
                     THEN ROUND((CAST(r.fecha_hora_fin AS DATE) -
                                 CAST(r.fecha_hora_inicio AS DATE)) * 1440)
                     ELSE 0 END)                                         AS minutos_consumidos
        FROM perfiles pf
        JOIN reproducciones r   ON r.id_perfil      = pf.id_perfil
        JOIN contenido c        ON c.id_contenido   = r.id_contenido
        JOIN categorias cat     ON cat.id_categoria = c.id_categoria
        WHERE pf.id_usuario  = p_id_usuario
          AND CAST(r.fecha_hora_inicio AS DATE) BETWEEN p_fecha_inicio AND p_fecha_fin
        GROUP BY pf.nombre_perfil, cat.nombre_categoria
        ORDER BY pf.nombre_perfil, cat.nombre_categoria;

    v_nombre_usuario  VARCHAR2(200);
    v_total_min       NUMBER := 0;
    v_total_rep       NUMBER := 0;
    v_perfil_anterior VARCHAR2(60) := NULL;

BEGIN
    -- Obtener nombre del usuario
    SELECT nombres || ' ' || apellidos INTO v_nombre_usuario
      FROM usuarios WHERE id_usuario = p_id_usuario;

    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('REPORTE DE CONSUMO - USUARIO: ' || v_nombre_usuario);
    DBMS_OUTPUT.PUT_LINE('Periodo: ' || TO_CHAR(p_fecha_inicio,'DD/MM/YYYY') ||
                         ' al '     || TO_CHAR(p_fecha_fin,   'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('==========================================================');

    FOR rec IN c_consumo LOOP
        -- Separador de perfil
        IF v_perfil_anterior IS NULL OR rec.nombre_perfil != v_perfil_anterior THEN
            IF v_perfil_anterior IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE(RPAD(' ',4) || RPAD('-',55,'-'));
            END IF;
            DBMS_OUTPUT.PUT_LINE('Perfil: >> ' || rec.nombre_perfil);
            DBMS_OUTPUT.PUT_LINE(
                RPAD('  CATEGORIA',22) || RPAD('REPRODUCCIONES',18) || 'TIEMPO (min)'
            );
            v_perfil_anterior := rec.nombre_perfil;
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            RPAD('  ' || rec.nombre_categoria, 22) ||
            RPAD(rec.total_rep, 18) ||
            rec.minutos_consumidos
        );

        v_total_rep := v_total_rep + rec.total_rep;
        v_total_min := v_total_min + rec.minutos_consumidos;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('=',60,'='));
    DBMS_OUTPUT.PUT_LINE('TOTAL REPRODUCCIONES : ' || v_total_rep);
    DBMS_OUTPUT.PUT_LINE('TOTAL TIEMPO (min)   : ' || v_total_min ||
                         ' (' || ROUND(v_total_min/60, 1) || ' horas)');
    DBMS_OUTPUT.PUT_LINE('==========================================================');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: No se encontro el usuario con ID ' || p_id_usuario);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR en sp_reporte_consumo: ' || SQLERRM);
        RAISE;
END sp_reporte_consumo;
/

-- Prueba: reporte del usuario 1, todo el anio 2024-2025
BEGIN
    sp_reporte_consumo(
        p_id_usuario   => 1,
        p_fecha_inicio => DATE '2024-01-01',
        p_fecha_fin    => DATE '2025-12-31'
    );
END;
/

PROMPT =====================================================
PROMPT 3. FUNCIONES
PROMPT =====================================================

-- -------------------------------------------------------
-- FN_CALCULAR_MONTO
--   Recibe el id de usuario y retorna el monto del
--   proximo mes considerando:
--     - Plan actual del usuario
--     - Descuento por antiguedad:
--         > 12 meses: 10%
--         > 24 meses: 15%
--     - Descuento adicional si tiene referido activo
-- -------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_calcular_monto (
    p_id_usuario IN NUMBER
) RETURN NUMBER
AS
    v_precio       NUMBER(10,2);
    v_antiguedad   NUMBER;
    v_descuento    NUMBER(5,2) := 0;
    v_monto_final  NUMBER(10,2);
    v_referidor    NUMBER;
    v_ref_activo   NUMBER;

BEGIN
    -- Obtener precio del plan, antiguedad en meses y referidor
    SELECT pl.precio_mensual,
           MONTHS_BETWEEN(TRUNC(SYSDATE), u.fecha_registro),
           u.id_usuario_referidor
      INTO v_precio, v_antiguedad, v_referidor
      FROM usuarios u
      JOIN planes pl ON pl.id_plan = u.id_plan_actual
     WHERE u.id_usuario = p_id_usuario;

    -- Aplicar descuento por antiguedad
    IF v_antiguedad > 24 THEN
        v_descuento := 15;
    ELSIF v_antiguedad > 12 THEN
        v_descuento := 10;
    END IF;

    -- Si tiene referido activo, sumar 5% adicional de descuento
    IF v_referidor IS NOT NULL THEN
        SELECT COUNT(*) INTO v_ref_activo
          FROM usuarios
         WHERE id_usuario = v_referidor
           AND estado_cuenta = 'ACTIVO';

        IF v_ref_activo > 0 THEN
            v_descuento := v_descuento + 5;
        END IF;
    END IF;

    -- Calcular monto final
    v_monto_final := ROUND(v_precio * (1 - v_descuento / 100), 2);

    RETURN v_monto_final;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20010,
            'No se encontro el usuario con ID ' || p_id_usuario);
    WHEN OTHERS THEN
        RAISE;
END fn_calcular_monto;
/

-- Prueba de la funcion
DECLARE
    v_monto NUMBER;
BEGIN
    FOR u IN (SELECT id_usuario, nombres FROM usuarios WHERE ROWNUM <= 5) LOOP
        v_monto := fn_calcular_monto(u.id_usuario);
        DBMS_OUTPUT.PUT_LINE(
            'Usuario ' || u.id_usuario || ' - ' ||
            RPAD(u.nombres,20) ||
            ' => Monto proximo mes: $' || TO_CHAR(v_monto,'FM999,990.00')
        );
    END LOOP;
END;
/

-- -------------------------------------------------------
-- FN_CONTENIDO_RECOMENDADO
--   Recibe el id de perfil y retorna el titulo del
--   contenido mas afin al perfil basandose en los
--   generos mas reproducidos (que el perfil aun no haya
--   visto o haya visto menos del 50%).
-- -------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_contenido_recomendado (
    p_id_perfil IN NUMBER
) RETURN VARCHAR2
AS
    v_titulo     VARCHAR2(150);

BEGIN
    -- Encontrar el genero favorito del perfil (mas reproducido)
    -- y luego el contenido mas popular de ese genero que no
    -- haya sido completado por el perfil (avance < 50%).
    SELECT titulo INTO v_titulo
      FROM (
          -- Contenido del genero favorito del perfil, ordenado por popularidad
          SELECT c.titulo,
                 c.popularidad,
                 NVL(MAX(r.porcentaje_avance), 0) AS max_avance
            FROM contenido c
            JOIN contenido_genero cg ON cg.id_contenido = c.id_contenido
            JOIN (
                -- Genero mas reproducido por el perfil
                SELECT cg2.id_genero
                  FROM reproducciones r2
                  JOIN contenido c2        ON c2.id_contenido = r2.id_contenido
                  JOIN contenido_genero cg2 ON cg2.id_contenido = c2.id_contenido
                 WHERE r2.id_perfil = p_id_perfil
                 GROUP BY cg2.id_genero
                 ORDER BY COUNT(*) DESC
                 FETCH FIRST 1 ROW ONLY
            ) gf ON gf.id_genero = cg.id_genero
            LEFT JOIN reproducciones r ON r.id_contenido = c.id_contenido
                                      AND r.id_perfil    = p_id_perfil
           WHERE c.estado_publicacion = 'ACTIVO'
           GROUP BY c.id_contenido, c.titulo, c.popularidad
          HAVING NVL(MAX(r.porcentaje_avance), 0) < 50
           ORDER BY c.popularidad DESC
      )
     WHERE ROWNUM = 1;

    RETURN v_titulo;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Si no hay preferencias, devolver el mas popular de toda la plataforma
        BEGIN
            SELECT titulo INTO v_titulo
              FROM contenido
             WHERE estado_publicacion = 'ACTIVO'
             ORDER BY popularidad DESC
             FETCH FIRST 1 ROW ONLY;
            RETURN v_titulo;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'Sin recomendacion disponible';
        END;
    WHEN OTHERS THEN
        RAISE;
END fn_contenido_recomendado;
/

-- Prueba de la funcion de recomendacion
DECLARE
    v_rec VARCHAR2(150);
BEGIN
    FOR p IN (SELECT id_perfil, nombre_perfil FROM perfiles WHERE ROWNUM <= 5) LOOP
        v_rec := fn_contenido_recomendado(p.id_perfil);
        DBMS_OUTPUT.PUT_LINE(
            'Perfil [' || p.id_perfil || '] ' ||
            RPAD(p.nombre_perfil, 20) ||
            ' => Recomendado: ' || v_rec
        );
    END LOOP;
END;
/

PROMPT =====================================================
PROMPT 4. DISPARADORES (TRIGGERS)
PROMPT =====================================================

-- -------------------------------------------------------
-- TRIGGER 1 (a nivel de fila, BEFORE INSERT en REPRODUCCIONES)
--   Verifica que el usuario propietario del perfil tenga
--   estado_cuenta = 'ACTIVO'. Si no, rechaza la insercion.
-- -------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_rep_cuenta_activa
BEFORE INSERT ON reproducciones
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(15);
BEGIN
    SELECT u.estado_cuenta INTO v_estado
      FROM perfiles pf
      JOIN usuarios u ON u.id_usuario = pf.id_usuario
     WHERE pf.id_perfil = :NEW.id_perfil;

    IF v_estado != 'ACTIVO' THEN
        RAISE_APPLICATION_ERROR(-20020,
            'La cuenta del usuario propietario del perfil ' ||
            :NEW.id_perfil || ' no esta activa (estado: ' || v_estado || ').');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20021,
            'No se encontro el perfil con ID ' || :NEW.id_perfil || '.');
END trg_rep_cuenta_activa;
/

-- -------------------------------------------------------
-- TRIGGER 2 (a nivel de fila, BEFORE INSERT en PERFILES)
--   Verifica que el usuario no exceda el maximo de
--   perfiles segun su plan (Basico:2, Estandar:3, Premium:5).
-- -------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_perf_max_plan
BEFORE INSERT ON perfiles
FOR EACH ROW
DECLARE
    v_max_perfiles  NUMBER(2);
    v_total_perfiles NUMBER;
    v_nombre_plan   VARCHAR2(20);
BEGIN
    -- Obtener limite del plan actual del usuario
    SELECT pl.max_perfiles, pl.nombre_plan
      INTO v_max_perfiles, v_nombre_plan
      FROM usuarios u
      JOIN planes pl ON pl.id_plan = u.id_plan_actual
     WHERE u.id_usuario = :NEW.id_usuario;

    -- Contar perfiles existentes del usuario
    SELECT COUNT(*) INTO v_total_perfiles
      FROM perfiles
     WHERE id_usuario = :NEW.id_usuario;

    IF v_total_perfiles >= v_max_perfiles THEN
        RAISE_APPLICATION_ERROR(-20030,
            'El usuario ya tiene ' || v_total_perfiles ||
            ' perfiles y su plan ' || v_nombre_plan ||
            ' permite maximo ' || v_max_perfiles || '. No se puede agregar mas perfiles.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20031,
            'No se encontro el usuario con ID ' || :NEW.id_usuario || '.');
END trg_perf_max_plan;
/

-- -------------------------------------------------------
-- TRIGGER 3 (a nivel de fila, BEFORE INSERT en CALIFICACIONES)
--   Verifica que el perfil haya reproducido al menos el
--   50% del contenido antes de permitir la calificacion.
-- -------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_calif_avance_min
BEFORE INSERT ON calificaciones
FOR EACH ROW
DECLARE
    v_max_avance NUMBER(5,2);
BEGIN
    -- Obtener el maximo porcentaje de avance del perfil en ese contenido
    SELECT NVL(MAX(porcentaje_avance), 0) INTO v_max_avance
      FROM reproducciones
     WHERE id_perfil    = :NEW.id_perfil
       AND id_contenido = :NEW.id_contenido;

    IF v_max_avance < 50 THEN
        RAISE_APPLICATION_ERROR(-20040,
            'El perfil ' || :NEW.id_perfil ||
            ' solo ha reproducido el ' || v_max_avance ||
            '% del contenido ' || :NEW.id_contenido ||
            '. Se requiere al menos 50% para poder calificarlo.');
    END IF;

END trg_calif_avance_min;
/

-- -------------------------------------------------------
-- TRIGGER 4 (a nivel de sentencia, AFTER INSERT en PAGOS)
--   Despues de insertar un pago exitoso, actualiza
--   estado_cuenta del usuario a 'ACTIVO' y fecha_ultimo_pago.
--   Es un trigger de sentencia porque puede procesar
--   multiples pagos en un batch.
-- -------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_pago_activa_cuenta
AFTER INSERT ON pagos
DECLARE
BEGIN
    -- Actualizar en bloque todos los usuarios que tengan
    -- un pago EXITOSO insertado en la misma transaccion
    -- (fecha_pago = hoy y estado = EXITOSO)
    UPDATE usuarios u
       SET u.estado_cuenta    = 'ACTIVO',
           u.fecha_ultimo_pago = TRUNC(SYSDATE),
           u.fecha_vencimiento = (
               SELECT MAX(p2.fecha_vencimiento)
                 FROM pagos p2
                WHERE p2.id_usuario  = u.id_usuario
                  AND p2.estado_pago = 'EXITOSO'
           )
     WHERE u.id_usuario IN (
         SELECT p.id_usuario
           FROM pagos p
          WHERE TRUNC(p.fecha_pago) = TRUNC(SYSDATE)
            AND p.estado_pago       = 'EXITOSO'
     );

    DBMS_OUTPUT.PUT_LINE(
        '[TRIGGER trg_pago_activa_cuenta] Usuarios actualizados a ACTIVO: ' || SQL%ROWCOUNT
    );
END trg_pago_activa_cuenta;
/

PROMPT =====================================================
PROMPT VERIFICACION DE OBJETOS CREADOS
PROMPT =====================================================

SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_type IN ('PROCEDURE','FUNCTION','TRIGGER')
   AND object_name IN (
       'CUR_USUARIOS_MOROSOS',
       'CUR_POPULARIDAD_CONTENIDO',
       'SP_REGISTRAR_USUARIO',
       'SP_CAMBIAR_PLAN',
       'SP_REPORTE_CONSUMO',
       'FN_CALCULAR_MONTO',
       'FN_CONTENIDO_RECOMENDADO',
       'TRG_REP_CUENTA_ACTIVA',
       'TRG_PERF_MAX_PLAN',
       'TRG_CALIF_AVANCE_MIN',
       'TRG_PAGO_ACTIVA_CUENTA'
   )
ORDER BY object_type, object_name;

PROMPT =====================================================
PROMPT FIN DEL SCRIPT NT2 - PL/SQL
PROMPT =====================================================
