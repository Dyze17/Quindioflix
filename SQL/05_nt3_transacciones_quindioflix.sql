-- =========================================================
-- QUINDIOFLIX - ENTREGA 2
-- Script 05: Nucleo 3 - Transacciones y Concurrencia
--
-- Cubre:
--   3.3.1 Tres transacciones criticas con COMMIT / ROLLBACK
--         / SAVEPOINT y estados documentados
--   3.3.2 Escenario de concurrencia con SELECT FOR UPDATE
-- =========================================================

SET SERVEROUTPUT ON SIZE 1000000;
SET DEFINE OFF;
SET LINESIZE 200;
SET PAGESIZE 100;

-- =========================================================
-- ESTADOS DE UNA TRANSACCION EN ORACLE (referencia)
--
--   ACTIVA            -> La transaccion ha iniciado y esta
--                        ejecutando operaciones DML.
--   PARCIALMENTE      -> Las operaciones han sido ejecutadas
--   CONFIRMADA           pero aun no se ha emitido COMMIT.
--   CONFIRMADA        -> COMMIT emitido; cambios son permanentes.
--   FALLIDA           -> Ocurrio un error; los cambios DML
--                        no se pueden completar.
--   ABORTADA          -> Se emitio ROLLBACK; la BD vuelve
--                        al estado anterior al BEGIN.
-- =========================================================

PROMPT =====================================================
PROMPT TRANSACCION 1: REGISTRO COMPLETO
PROMPT  Usuario + Perfil + Primer Pago
PROMPT  Si falla cualquier paso, se deshace todo (ROLLBACK)
PROMPT =====================================================

-- -------------------------------------------------------
-- DESCRIPCION:
--   Escenario: Un nuevo usuario se registra en QuindioFlix.
--   Pasos atomicos:
--     1. INSERT en USUARIOS
--     2. INSERT en PERFILES (perfil predeterminado)
--     3. INSERT en PAGOS (primer pago)
--   Si cualquiera de los tres falla -> ROLLBACK total.
--   Si todos tienen exito           -> COMMIT.
--
-- ESTADOS:
--   Inicio INSERT usuarios   -> ACTIVA
--   Despues INSERT perfiles  -> ACTIVA (parcialmente confirmada internamente)
--   Despues INSERT pagos     -> PARCIALMENTE CONFIRMADA
--   COMMIT                   -> CONFIRMADA
--   Cualquier excepcion      -> FALLIDA -> ROLLBACK -> ABORTADA
-- -------------------------------------------------------

DECLARE
    -- Parametros del nuevo usuario
    v_nombres       VARCHAR2(80)  := 'Laura';
    v_apellidos     VARCHAR2(80)  := 'Ospina Vargas';
    v_email         VARCHAR2(120) := 'laura.ospina.trans1@quindioflix.co';
    v_telefono      VARCHAR2(20)  := '3154441122';
    v_fecha_nac     DATE          := DATE '1998-03-22';
    v_ciudad        VARCHAR2(60)  := 'Pereira';
    v_id_plan       NUMBER        := 2;   -- ESTANDAR
    v_metodo_pago   VARCHAR2(20)  := 'TCREDITO';

    -- Variables internas
    v_id_usuario    NUMBER;
    v_precio_plan   NUMBER(10,2);
    v_fecha_venc    DATE;
    v_count         NUMBER;

BEGIN
    -- === ESTADO: ACTIVA ===
    DBMS_OUTPUT.PUT_LINE('>> [T1] INICIO: Transaccion de registro completo');

    -- Paso 0: Validacion de email unico (no DML, solo SELECT)
    SELECT COUNT(*) INTO v_count
      FROM usuarios WHERE LOWER(email) = LOWER(v_email);

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            '[T1] Email ya registrado: ' || v_email);
    END IF;

    -- Obtener precio del plan
    SELECT precio_mensual INTO v_precio_plan
      FROM planes WHERE id_plan = v_id_plan;

    v_fecha_venc := ADD_MONTHS(TRUNC(SYSDATE), 1);

    -- Paso 1: Insertar usuario  [ESTADO: ACTIVA]
    INSERT INTO usuarios (
        id_plan_actual, nombres, apellidos, email, telefono,
        fecha_nacimiento, ciudad, fecha_registro,
        fecha_ultimo_pago, fecha_vencimiento, estado_cuenta
    ) VALUES (
        v_id_plan, v_nombres, v_apellidos, v_email, v_telefono,
        v_fecha_nac, v_ciudad, TRUNC(SYSDATE),
        TRUNC(SYSDATE), v_fecha_venc, 'ACTIVO'
    ) RETURNING id_usuario INTO v_id_usuario;

    DBMS_OUTPUT.PUT_LINE('   Paso 1 OK: Usuario insertado, ID=' || v_id_usuario);

    -- Paso 2: Insertar perfil predeterminado  [ESTADO: ACTIVA]
    INSERT INTO perfiles (id_usuario, nombre_perfil, avatar, tipo_perfil, fecha_creacion)
    VALUES (v_id_usuario, v_nombres, 'avatar_default.png', 'ADULTO', TRUNC(SYSDATE));

    DBMS_OUTPUT.PUT_LINE('   Paso 2 OK: Perfil predeterminado creado');

    -- Paso 3: Insertar primer pago  [ESTADO: PARCIALMENTE CONFIRMADA]
    INSERT INTO pagos (
        id_usuario, id_plan, fecha_pago, fecha_vencimiento,
        monto_base, valor_descuento, monto_pagado,
        metodo_pago, estado_pago, observacion
    ) VALUES (
        v_id_usuario, v_id_plan, TRUNC(SYSDATE), v_fecha_venc,
        v_precio_plan, 0, v_precio_plan,
        v_metodo_pago, 'EXITOSO',
        'Primer pago al registrarse - Transaccion 1'
    );

    DBMS_OUTPUT.PUT_LINE('   Paso 3 OK: Primer pago registrado por $' ||
                         TO_CHAR(v_precio_plan, 'FM999,990.00'));

    -- Todos los pasos exitosos -> CONFIRMADA
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('>> [T1] COMMIT: Transaccion CONFIRMADA exitosamente.');
    DBMS_OUTPUT.PUT_LINE('   Usuario ID=' || v_id_usuario || ' registrado.');

EXCEPTION
    -- Estado FALLIDA -> ROLLBACK -> ABORTADA
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('>> [T1] ERROR: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('>> [T1] ROLLBACK ejecutado. Transaccion ABORTADA.');
        RAISE;
END;
/

-- Verificacion del resultado de la transaccion 1
SELECT u.id_usuario, u.nombres, u.estado_cuenta,
       COUNT(pf.id_perfil) AS perfiles,
       COUNT(pg.id_pago)   AS pagos
  FROM usuarios u
  LEFT JOIN perfiles pf ON pf.id_usuario = u.id_usuario
  LEFT JOIN pagos pg    ON pg.id_usuario = u.id_usuario
 WHERE LOWER(u.email) = 'laura.ospina.trans1@quindioflix.co'
 GROUP BY u.id_usuario, u.nombres, u.estado_cuenta;


PROMPT =====================================================
PROMPT TRANSACCION 2: RENOVACION MENSUAL EN LOTE
PROMPT  SAVEPOINT por usuario para que el fallo de uno
PROMPT  no revierta los anteriores ya procesados.
PROMPT =====================================================

-- -------------------------------------------------------
-- DESCRIPCION:
--   Escenario: Proceso nocturno que recorre los usuarios
--   activos, verifica si deben renovar su suscripcion
--   (fecha_vencimiento <= hoy), calcula el monto,
--   registra el pago y actualiza el estado.
--
--   Se usa SAVEPOINT sp_antes_pago_N antes de cada
--   usuario. Si falla el pago de un usuario, se hace
--   ROLLBACK TO SAVEPOINT (solo ese usuario se revierte)
--   y el proceso continua con los siguientes.
--
-- ESTADOS POR USUARIO:
--   Inicio del loop   -> ACTIVA
--   Antes de INSERT   -> SAVEPOINT establecido
--   INSERT exitoso    -> PARCIALMENTE CONFIRMADA (acumulada)
--   Error en INSERT   -> FALLIDA parcial -> ROLLBACK TO SP
--   Al final del loop -> COMMIT global -> CONFIRMADA
-- -------------------------------------------------------

DECLARE
    -- Cursor de usuarios que requieren renovacion
    CURSOR c_renovar IS
        SELECT
            u.id_usuario,
            u.nombres || ' ' || u.apellidos AS nombre,
            u.id_plan_actual,
            pl.precio_mensual,
            pl.nombre_plan,
            u.fecha_vencimiento
        FROM usuarios u
        JOIN planes pl ON pl.id_plan = u.id_plan_actual
       WHERE u.estado_cuenta IN ('ACTIVO', 'SUSPENDIDO')
         AND (u.fecha_vencimiento IS NULL OR u.fecha_vencimiento <= TRUNC(SYSDATE))
       ORDER BY u.id_usuario;

    v_sp_name       VARCHAR2(40);
    v_fecha_venc    DATE;
    v_monto         NUMBER(10,2);
    v_ok            NUMBER := 0;
    v_err           NUMBER := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('>> [T2] INICIO: Renovacion mensual en lote');
    DBMS_OUTPUT.PUT_LINE('   Fecha de proceso: ' || TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('==========================================================');

    FOR rec IN c_renovar LOOP
        -- Definir nombre del SAVEPOINT para este usuario
        v_sp_name := 'sp_usr_' || rec.id_usuario;

        -- Establecer SAVEPOINT antes de procesar este usuario
        SAVEPOINT sp_renovacion_usuario;  -- ESTADO: SAVEPOINT establecido

        BEGIN
            v_fecha_venc := ADD_MONTHS(TRUNC(SYSDATE), 1);
            v_monto      := fn_calcular_monto(rec.id_usuario);

            -- Registrar el pago de renovacion  [ESTADO: ACTIVA]
            INSERT INTO pagos (
                id_usuario, id_plan, fecha_pago, fecha_vencimiento,
                monto_base, valor_descuento, monto_pagado,
                metodo_pago, estado_pago, observacion
            ) VALUES (
                rec.id_usuario, rec.id_plan_actual,
                TRUNC(SYSDATE), v_fecha_venc,
                rec.precio_mensual,
                rec.precio_mensual - v_monto,
                v_monto,
                'PSE', 'EXITOSO',
                'Renovacion automatica mensual - T2'
            );

            -- Actualizar estado y fechas del usuario
            UPDATE usuarios
               SET estado_cuenta    = 'ACTIVO',
                   fecha_ultimo_pago = TRUNC(SYSDATE),
                   fecha_vencimiento = v_fecha_venc
             WHERE id_usuario = rec.id_usuario;

            v_ok := v_ok + 1;
            DBMS_OUTPUT.PUT_LINE(
                '   OK  | ID ' || RPAD(rec.id_usuario,5) ||
                RPAD(rec.nombre,30) ||
                ' | Plan: ' || RPAD(rec.nombre_plan,8) ||
                ' | Cobro: $' || TO_CHAR(v_monto, 'FM999,990.00')
            );

        EXCEPTION
            -- Error en este usuario: revertir solo hasta el SAVEPOINT
            WHEN OTHERS THEN
                ROLLBACK TO SAVEPOINT sp_renovacion_usuario; -- ESTADO: ABORTADA parcial
                v_err := v_err + 1;
                DBMS_OUTPUT.PUT_LINE(
                    '   ERR | ID ' || RPAD(rec.id_usuario,5) ||
                    RPAD(rec.nombre,30) ||
                    ' | ERROR: ' || SUBSTR(SQLERRM,1,60)
                );
        END;
    END LOOP;

    -- Confirmar todos los pagos exitosos  [ESTADO: CONFIRMADA]
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('>> [T2] COMMIT: Renovacion masiva CONFIRMADA.');
    DBMS_OUTPUT.PUT_LINE('   Renovaciones exitosas : ' || v_ok);
    DBMS_OUTPUT.PUT_LINE('   Renovaciones fallidas  : ' || v_err);
    DBMS_OUTPUT.PUT_LINE('==========================================================');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('>> [T2] ERROR CRITICO: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('>> [T2] ROLLBACK TOTAL. Transaccion ABORTADA.');
        RAISE;
END;
/


PROMPT =====================================================
PROMPT TRANSACCION 3: ELIMINACION COMPLETA DE CUENTA
PROMPT  Elimina en cascada: calificaciones, favoritos,
PROMPT  reproducciones, perfiles, pagos y usuario.
PROMPT  Operacion TODO O NADA.
PROMPT =====================================================

-- -------------------------------------------------------
-- DESCRIPCION:
--   Escenario: Un usuario solicita eliminar su cuenta.
--   El proceso debe borrar todos sus datos en el orden
--   correcto (respetando FK) y de forma atomica.
--
--   Orden de eliminacion (respetando integridad referencial):
--     1. reportes_contenido (como moderador o como reportante)
--     2. calificaciones
--     3. favoritos
--     4. reproducciones (via perfiles)
--     5. perfiles
--     6. pagos
--     7. usuario_rol_app
--     8. usuarios (actualizar referidos antes de borrar)
--
-- ESTADOS:
--   Inicio            -> ACTIVA
--   Despues cada DELETE -> ACTIVA (acumulando)
--   Todos exitosos    -> PARCIALMENTE CONFIRMADA -> COMMIT -> CONFIRMADA
--   Cualquier error   -> FALLIDA -> ROLLBACK -> ABORTADA
-- -------------------------------------------------------

DECLARE
    -- ID del usuario a eliminar (se usa el recien creado para no afectar datos reales)
    v_id_eliminar   NUMBER;
    v_nombre        VARCHAR2(200);
    v_reps          NUMBER;
    v_califs        NUMBER;
    v_favs          NUMBER;
    v_pagos         NUMBER;
    v_perfs         NUMBER;

BEGIN
    -- Buscar el usuario creado en la Transaccion 1 para la demo
    SELECT id_usuario, nombres || ' ' || apellidos
      INTO v_id_eliminar, v_nombre
      FROM usuarios
     WHERE LOWER(email) = 'laura.ospina.trans1@quindioflix.co'
       AND ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('>> [T3] INICIO: Eliminacion de cuenta');
    DBMS_OUTPUT.PUT_LINE('   Usuario: ' || v_nombre || ' (ID=' || v_id_eliminar || ')');
    DBMS_OUTPUT.PUT_LINE('==========================================================');

    -- [ESTADO: ACTIVA]

    -- Paso 1: Eliminar reportes donde el usuario es moderador o reportante
    DELETE FROM reportes_contenido
     WHERE id_usuario_reporta  = v_id_eliminar
        OR id_usuario_moderador = v_id_eliminar;
    DBMS_OUTPUT.PUT_LINE('   Paso 1 OK: Reportes eliminados -> ' || SQL%ROWCOUNT);

    -- Paso 2: Eliminar calificaciones de todos sus perfiles
    DELETE FROM calificaciones
     WHERE id_perfil IN (
         SELECT id_perfil FROM perfiles WHERE id_usuario = v_id_eliminar
     );
    v_califs := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('   Paso 2 OK: Calificaciones eliminadas -> ' || v_califs);

    -- Paso 3: Eliminar favoritos de todos sus perfiles
    DELETE FROM favoritos
     WHERE id_perfil IN (
         SELECT id_perfil FROM perfiles WHERE id_usuario = v_id_eliminar
     );
    v_favs := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('   Paso 3 OK: Favoritos eliminados -> ' || v_favs);

    -- Paso 4: Eliminar reproducciones de todos sus perfiles
    DELETE FROM reproducciones
     WHERE id_perfil IN (
         SELECT id_perfil FROM perfiles WHERE id_usuario = v_id_eliminar
     );
    v_reps := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('   Paso 4 OK: Reproducciones eliminadas -> ' || v_reps);

    -- Paso 5: Eliminar perfiles
    DELETE FROM perfiles WHERE id_usuario = v_id_eliminar;
    v_perfs := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('   Paso 5 OK: Perfiles eliminados -> ' || v_perfs);

    -- Paso 6: Eliminar pagos
    DELETE FROM pagos WHERE id_usuario = v_id_eliminar;
    v_pagos := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('   Paso 6 OK: Pagos eliminados -> ' || v_pagos);

    -- Paso 7: Eliminar roles de aplicacion
    DELETE FROM usuario_rol_app WHERE id_usuario = v_id_eliminar;
    DBMS_OUTPUT.PUT_LINE('   Paso 7 OK: Roles de app eliminados -> ' || SQL%ROWCOUNT);

    -- Paso 8: Desvincular usuarios que fueron referidos por este usuario
    UPDATE usuarios
       SET id_usuario_referidor = NULL,
           beneficio_referido   = NULL
     WHERE id_usuario_referidor = v_id_eliminar;
    DBMS_OUTPUT.PUT_LINE('   Paso 8 OK: Referidos desvinculados -> ' || SQL%ROWCOUNT);

    -- Paso 9: Eliminar el usuario  [ESTADO: PARCIALMENTE CONFIRMADA]
    DELETE FROM usuarios WHERE id_usuario = v_id_eliminar;
    DBMS_OUTPUT.PUT_LINE('   Paso 9 OK: Usuario eliminado.');

    -- Todo exitoso -> CONFIRMADA
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('>> [T3] COMMIT: Cuenta eliminada de forma CONFIRMADA.');
    DBMS_OUTPUT.PUT_LINE('==========================================================');

EXCEPTION
    -- Error en cualquier paso -> FALLIDA -> ROLLBACK -> ABORTADA
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('>> [T3] ERROR: Usuario no encontrado o ya eliminado.');
        DBMS_OUTPUT.PUT_LINE('>> [T3] ROLLBACK. Transaccion ABORTADA.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('>> [T3] ERROR: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('>> [T3] ROLLBACK TOTAL. Transaccion ABORTADA.');
        RAISE;
END;
/


PROMPT =====================================================
PROMPT TRANSACCION 3b: ELIMINACION - USUARIO INEXISTENTE
PROMPT  Demostracion del manejo de error y ROLLBACK
PROMPT =====================================================

DECLARE
    v_id_eliminar NUMBER := 999999; -- ID que no existe
    v_nombre      VARCHAR2(200);
BEGIN
    DBMS_OUTPUT.PUT_LINE('>> [T3b] Intentando eliminar usuario ID=999999 (no existe)...');

    SELECT nombres || ' ' || apellidos INTO v_nombre
      FROM usuarios WHERE id_usuario = v_id_eliminar;

    DELETE FROM usuarios WHERE id_usuario = v_id_eliminar;
    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('>> [T3b] ERROR capturado: Usuario no encontrado.');
        DBMS_OUTPUT.PUT_LINE('>> [T3b] ROLLBACK ejecutado. Transaccion ABORTADA correctamente.');
END;
/


PROMPT =====================================================
PROMPT 3.3.2 ESCENARIO DE CONCURRENCIA
PROMPT  Dos sesiones intentan cambiar el plan del mismo
PROMPT  usuario simultáneamente.
PROMPT  Se usa SELECT FOR UPDATE para gestionar el bloqueo.
PROMPT =====================================================

-- -------------------------------------------------------
-- DOCUMENTACION DEL ESCENARIO DE CONCURRENCIA
-- -------------------------------------------------------
-- ESCENARIO:
--   - Usuario ID=5 tiene plan BASICO y desea cambiarlo.
--   - Dos agentes (Agente A y Agente B) intentan
--     cambiar el plan del mismo usuario al mismo tiempo.
--
-- SIN CONTROL:
--   - Ambos leen el plan actual como BASICO.
--   - Ambos calculan el cambio.
--   - El ultimo en hacer UPDATE sobrescribe al primero
--     (dirty read / lost update).
--
-- CON SELECT FOR UPDATE:
--   - El primer agente que ejecute SELECT FOR UPDATE
--     adquiere el bloqueo de fila.
--   - El segundo agente queda en espera (WAIT) o
--     recibe error inmediato (NOWAIT).
--   - Oracle garantiza que solo uno procesa a la vez.
--   - Cuando el primero hace COMMIT, el segundo
--     puede proceder con los datos actualizados.
--
-- COMO REPRODUCIRLO EN SQL DEVELOPER (dos hojas):
--
--   SESION A (ejecutar primero):
--     BEGIN
--         -- Adquirir bloqueo exclusivo sobre la fila
--         SELECT id_plan_actual
--           INTO :v_plan
--           FROM usuarios
--          WHERE id_usuario = 5
--            FOR UPDATE;                     -- BLOQUEO ADQUIRIDO
--         -- Aqui la sesion A "piensa" (simula latencia)
--         -- No hacer COMMIT aun
--     END;
--
--   SESION B (ejecutar mientras A tiene el bloqueo):
--     SELECT id_plan_actual
--       FROM usuarios
--      WHERE id_usuario = 5
--        FOR UPDATE NOWAIT;   -- Lanzara: ORA-00054 resource busy
--
--   SESION A (continua):
--     UPDATE usuarios SET id_plan_actual = 3 WHERE id_usuario = 5;
--     COMMIT;                               -- LIBERA EL BLOQUEO
--
--   SESION B (puede proceder ahora):
--     SELECT id_plan_actual
--       FROM usuarios
--      WHERE id_usuario = 5
--        FOR UPDATE;          -- Ahora adquiere el bloqueo
--     -- ... continua su logica
--
-- -------------------------------------------------------

-- ===== SIMULACION EN UNA SOLA SESION (para entregar) =====

-- Paso 1: Identificar el usuario objetivo
DECLARE
    v_id_usuario   NUMBER;
    v_plan_actual  NUMBER;
    v_nombre_plan  VARCHAR2(20);
    v_nombre_usr   VARCHAR2(200);
BEGIN
    -- Buscar el primer usuario activo con plan BASICO
    SELECT u.id_usuario, u.id_plan_actual, pl.nombre_plan,
           u.nombres || ' ' || u.apellidos
      INTO v_id_usuario, v_plan_actual, v_nombre_plan, v_nombre_usr
      FROM usuarios u
      JOIN planes pl ON pl.id_plan = u.id_plan_actual
     WHERE pl.nombre_plan = 'BASICO'
       AND u.estado_cuenta = 'ACTIVO'
       AND ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('ESCENARIO DE CONCURRENCIA - SELECT FOR UPDATE');
    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('Usuario objetivo: ' || v_nombre_usr || ' (ID=' || v_id_usuario || ')');
    DBMS_OUTPUT.PUT_LINE('Plan actual: ' || v_nombre_plan);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-- SESION A --');
    DBMS_OUTPUT.PUT_LINE('Paso 1: Adquiriendo bloqueo con SELECT FOR UPDATE...');

    -- SELECT FOR UPDATE: bloquea la fila para escritura exclusiva
    -- En produccion, esta sentencia en Sesion A bloquearia a Sesion B
    SELECT id_plan_actual INTO v_plan_actual
      FROM usuarios
     WHERE id_usuario = v_id_usuario
       FOR UPDATE;           -- BLOQUEO ADQUIRIDO POR SESION A

    DBMS_OUTPUT.PUT_LINE('Paso 2: Bloqueo adquirido. Plan leido: ' || v_plan_actual);
    DBMS_OUTPUT.PUT_LINE('Paso 3: Procesando cambio de plan a ESTANDAR...');

    -- Sesion A actualiza el plan
    UPDATE usuarios
       SET id_plan_actual = (SELECT id_plan FROM planes WHERE nombre_plan = 'ESTANDAR')
     WHERE id_usuario = v_id_usuario;

    DBMS_OUTPUT.PUT_LINE('Paso 4: UPDATE ejecutado. Emitiendo COMMIT...');
    COMMIT;   -- Libera el bloqueo de fila
    DBMS_OUTPUT.PUT_LINE('Paso 5: COMMIT emitido. Bloqueo LIBERADO.');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-- SESION B (simulada) --');
    DBMS_OUTPUT.PUT_LINE('Paso 6: Sesion B intenta SELECT FOR UPDATE NOWAIT...');

    -- Sesion B intenta con NOWAIT (en una sesion real lanzaria ORA-00054)
    -- En esta simulacion ya no hay bloqueo porque A hizo COMMIT
    DECLARE
        v_plan_b NUMBER;
    BEGIN
        SELECT id_plan_actual INTO v_plan_b
          FROM usuarios
         WHERE id_usuario = v_id_usuario
           FOR UPDATE NOWAIT;

        DBMS_OUTPUT.PUT_LINE('Paso 7: Sesion B adquirio el bloqueo (A ya hizo COMMIT).');
        DBMS_OUTPUT.PUT_LINE('        Plan leido por Sesion B: ' || v_plan_b ||
                             ' (ya actualizado por A)');
        DBMS_OUTPUT.PUT_LINE('Paso 8: Sesion B decide no cambiar (plan ya es ESTANDAR).');
        ROLLBACK;  -- B libera el bloqueo sin cambiar nada
        DBMS_OUTPUT.PUT_LINE('Paso 9: Sesion B hizo ROLLBACK. Bloqueo liberado.');
    EXCEPTION
        WHEN OTHERS THEN
            -- ORA-00054: resource busy (si A no hubiera hecho COMMIT aun)
            DBMS_OUTPUT.PUT_LINE('ERROR Sesion B: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('=> Oracle protegio la integridad: B no pudo leer la fila bloqueada.');
            ROLLBACK;
    END;

    DBMS_OUTPUT.PUT_LINE('==========================================================');
    DBMS_OUTPUT.PUT_LINE('CONCLUSION:');
    DBMS_OUTPUT.PUT_LINE('  SELECT FOR UPDATE garantiza que solo una sesion modifica');
    DBMS_OUTPUT.PUT_LINE('  el registro a la vez, previniendo actualizaciones perdidas');
    DBMS_OUTPUT.PUT_LINE('  (lost updates) en escenarios de alta concurrencia.');
    DBMS_OUTPUT.PUT_LINE('  NOWAIT permite que la sesion falle rapido en lugar de');
    DBMS_OUTPUT.PUT_LINE('  esperar indefinidamente, habilitando reintentos controlados.');
    DBMS_OUTPUT.PUT_LINE('==========================================================');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No se encontro un usuario ACTIVO con plan BASICO para la demo.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR en escenario concurrencia: ' || SQLERRM);
END;
/

-- Revertir el cambio de plan de la demo de concurrencia
-- (restaurar el plan BASICO al usuario de prueba)
DECLARE
    v_id_usuario NUMBER;
BEGIN
    SELECT u.id_usuario INTO v_id_usuario
      FROM usuarios u
      JOIN planes pl ON pl.id_plan = u.id_plan_actual
     WHERE pl.nombre_plan = 'ESTANDAR'
       AND u.estado_cuenta = 'ACTIVO'
       AND ROWNUM = 1;

    UPDATE usuarios
       SET id_plan_actual = (SELECT id_plan FROM planes WHERE nombre_plan = 'BASICO')
     WHERE id_usuario = v_id_usuario;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[RESTAURACION] Plan del usuario ' || v_id_usuario || ' restaurado a BASICO.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Restauracion omitida: ' || SQLERRM);
END;
/

PROMPT =====================================================
PROMPT FIN DEL SCRIPT NT3 - TRANSACCIONES Y CONCURRENCIA
PROMPT =====================================================
