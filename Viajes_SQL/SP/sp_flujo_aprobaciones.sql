USE Viajes;
GO

-- 1. SP PARA LISTAR EL HISTORIAL DE UNA SOLICITUD
CREATE OR ALTER PROC sp_flujo_FiltrarPorSolicitud
(
    @Id_Solicitud_Viaje INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Este SP lista todo el historial de decisiones (la bitácora)
    -- para una sola solicitud de viaje.
    
    IF ISNULL(@Id_Solicitud_Viaje, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un id de solicitud valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_solicitudes_viajes (NOLOCK) WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'La solicitud seleccionada no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                f.Id_Flujo_Aprobacion,
                f.Id_Solicitud_Viaje,
                f.Id_Autorizador,
                u.Usuario AS Nombre_Autorizador, -- Unimos para ver el nombre
                f.Nivel_Aprobacion,
                f.Id_Estado_Decision,
                e.Nombre_Estado AS Nombre_Decision, -- Unimos para ver la decisión
                f.Comentarios,
                f.Fecha_Decision,
                f.Activo
            FROM tbl_flujo_aprobaciones f (NOLOCK)
            INNER JOIN tbl_usuarios_login u (NOLOCK) ON f.Id_Autorizador = u.Id_Usuario
            INNER JOIN tbl_estados e (NOLOCK) ON f.Id_Estado_Decision = e.Id_Estado
            WHERE f.Id_Solicitud_Viaje = @Id_Solicitud_Viaje
            ORDER BY f.Fecha_Decision ASC;

            SET @o_Num = 0;
            SET @o_Msg = 'Historial de flujo listado exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 2. SP PARA FILTRAR UNA DECISION ESPECIFICA POR ID
CREATE OR ALTER PROC sp_flujo_FiltrarPorID
(
    @Id_Flujo_Aprobacion INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Este SP es el "FiltrarPorID" estándar para esta tabla.
    
    IF ISNULL(@Id_Flujo_Aprobacion, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un id de flujo valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_flujo_aprobaciones (NOLOCK) WHERE Id_Flujo_Aprobacion = @Id_Flujo_Aprobacion)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'El registro de flujo seleccionado no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_Flujo_Aprobacion,
                Id_Solicitud_Viaje,
                Id_Autorizador,
                Nivel_Aprobacion,
                Id_Estado_Decision,
                Comentarios,
                Fecha_Decision,
                Activo
            FROM tbl_flujo_aprobaciones (NOLOCK)
            WHERE Id_Flujo_Aprobacion = @Id_Flujo_Aprobacion;

            SET @o_Num = 0;
            SET @o_Msg = 'Registro de flujo filtrado exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 3. SP PARA REGISTRAR UNA DECISION (APROBAR/RECHAZAR)
CREATE OR ALTER PROC sp_flujo_RegistrarDecision
(
    @Id_Solicitud_Viaje INT,
    @Id_Autorizador INT,         -- El Gerente o Admin que toma la decisión
    @Nivel_Aprobacion INT,       -- 1 = Gerente, 2 = Admin
    @Id_Estado_Decision INT,     -- 5 (Aprobado) o 6 (Rechazado)
    @Comentarios NVARCHAR(MAX),
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Este SP es el corazón de la lógica de aprobación.
    -- Inserta en esta tabla y actualiza tbl_solicitudes_viajes.
    
    DECLARE @NuevoEstadoSolicitud INT;
    DECLARE @EstadoActualSolicitud INT;

    -- Validaciones
    IF ISNULL(@Id_Solicitud_Viaje, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar una solicitud!';
        RETURN;
    END
    ELSE IF ISNULL(@Id_Autorizador, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡No se ha identificado al autorizador!';
        RETURN;
    END
    ELSE IF @Id_Estado_Decision NOT IN (5, 6)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡La decisión solo puede ser Aprobado (5) o Rechazado (6)!';
        RETURN;
    END
    ELSE IF ISNULL(@Comentarios, '') = '' AND @Id_Estado_Decision = 6 -- Si rechaza, el comentario es obligatorio
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe ingresar un comentario de justificación para el rechazo!';
        RETURN;
    END

    -- Obtenemos el estado actual de la solicitud
    SELECT @EstadoActualSolicitud = Id_Estado 
    FROM tbl_solicitudes_viajes (NOLOCK) 
    WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje;

    IF @EstadoActualSolicitud IS NULL
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡La solicitud de viaje no existe!';
        RETURN;
    END

    -- Validar que la acción coincida con el nivel
    IF (@Nivel_Aprobacion = 1 AND @EstadoActualSolicitud <> 3) -- Un Gerente solo puede aprobar si está en 'Pendiente Gerente' (3)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Esta solicitud no está pendiente de aprobación de gerente!';
        RETURN;
    END
    ELSE IF (@Nivel_Aprobacion = 2 AND @EstadoActualSolicitud <> 4) -- Un Admin solo puede aprobar si está en 'Pendiente Admin' (4)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Esta solicitud no está pendiente de aprobación de administrador!';
        RETURN;
    END

    -- Calcular el nuevo estado de la solicitud
    IF @Id_Estado_Decision = 6 -- RECHAZADO (por Gerente o Admin)
    BEGIN
        SET @NuevoEstadoSolicitud = 6; -- 'Rechazado'
    END
    ELSE IF @Id_Estado_Decision = 5 AND @Nivel_Aprobacion = 1 -- APROBADO (por Gerente)
    BEGIN
        SET @NuevoEstadoSolicitud = 4; -- 'Pendiente aprobacion del administrador'
    END
    ELSE IF @Id_Estado_Decision = 5 AND @Nivel_Aprobacion = 2 -- APROBADO (por Admin)
    BEGIN
        SET @NuevoEstadoSolicitud = 5; -- 'Aprobado' (Estado final)
    END

    -- Inicia la transacción
    BEGIN TRY
        BEGIN TRAN trx_registrar_decision
        
        -- 1. Insertar el registro en la bitácora de flujo
        INSERT INTO tbl_flujo_aprobaciones (
            Id_Solicitud_Viaje, 
            Id_Autorizador, 
            Nivel_Aprobacion, 
            Id_Estado_Decision, 
            Comentarios,
            Fecha_Decision
        )
        VALUES (
            @Id_Solicitud_Viaje,
            @Id_Autorizador,
            @Nivel_Aprobacion,
            @Id_Estado_Decision,
            @Comentarios,
            GETDATE()
        );

        -- 2. Actualizar el estado de la solicitud principal
        UPDATE tbl_solicitudes_viajes
        SET 
            Id_Estado = @NuevoEstadoSolicitud,
            Fecha_Modificacion = GETDATE()
        WHERE 
            Id_Solicitud_Viaje = @Id_Solicitud_Viaje;

        SET @o_Num = SCOPE_IDENTITY();
        SET @o_Msg = '¡Decisión registrada exitosamente!';
        
        COMMIT TRAN trx_registrar_decision
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN trx_registrar_decision
        SET @o_Num = -1;
        SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 4. SP PARA ACTUALIZAR UN REGISTRO DE FLUJO
CREATE OR ALTER PROC sp_flujo_Actualizar -- No es recomendable actualizar esto en un entorno real pero lo pongo porque si 
(
    @Id_Flujo_Aprobacion INT,
    @Comentarios NVARCHAR(MAX),
    @Activo BIT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS 
BEGIN
    IF ISNULL(@Id_Flujo_Aprobacion, 0) = 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar el registro de flujo a actualizar!';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_flujo_aprobaciones(NOLOCK) WHERE Id_Flujo_Aprobacion = @Id_Flujo_Aprobacion)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El registro de flujo no existe!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_actualizar_flujo
            
            UPDATE tbl_flujo_aprobaciones
            SET 
                -- Nota: No permitimos actualizar la decisión, solo comentarios o estado
                Comentarios = COALESCE(LTRIM(RTRIM(@Comentarios)), Comentarios),
                Activo = COALESCE(@Activo, Activo)
            WHERE 
                Id_Flujo_Aprobacion = @Id_Flujo_Aprobacion;

            SET @o_Num = 0;
            SET @o_Msg = '¡Registro de flujo actualizado correctamente!';
            
            COMMIT TRAN trx_actualizar_flujo
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_actualizar_flujo
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO