USE Viajes;
GO

-- 1. SP PARA LISTAR TODAS LAS SOLICITUDES
CREATE OR ALTER PROC sp_solicitudes_Listar
(
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    BEGIN TRY
        SELECT 
            Id_Solicitud_Viaje,
            Id_Empleado,
            Id_Tipo_Departamento,
            Destino,
            Motivo,
            Fecha_Inicio_Viaje,
            Fecha_Fin_Viaje,
            Presupuesto_Estimado,
            Fecha_Creacion,
            Fecha_Modificacion,
            Id_Estado
        FROM tbl_solicitudes_viajes (NOLOCK)
        ORDER BY Fecha_Creacion DESC;

        SET @o_Num = 0;
        SET @o_Msg = 'Solicitudes listadas correctamente';
    END TRY
    BEGIN CATCH
        SET @o_Num = -1;
        SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 2. SP PARA FILTRAR SOLICITUD POR ID
CREATE OR ALTER PROC sp_solicitudes_FiltrarPorID
(
    @Id_Solicitud_Viaje INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
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
                Id_Solicitud_Viaje,
                Id_Empleado,
                Id_Tipo_Departamento,
                Destino,
                Motivo,
                Fecha_Inicio_Viaje,
                Fecha_Fin_Viaje,
                Presupuesto_Estimado,
                Fecha_Creacion,
                Fecha_Modificacion,
                Id_Estado
            FROM tbl_solicitudes_viajes (NOLOCK)
            WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje;

            SET @o_Num = 0;
            SET @o_Msg = 'Solicitud filtrada exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 3. SP PARA FILTRAR SOLICITUDES POR EMPLEADO
CREATE OR ALTER PROC sp_solicitudes_FiltrarPorEmpleado
(
    @Id_Empleado INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    IF ISNULL(@Id_Empleado, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un empleado valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_usuarios_login (NOLOCK) WHERE Id_Usuario = @Id_Empleado)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'El empleado seleccionado no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_Solicitud_Viaje,
                Id_Empleado,
                Id_Tipo_Departamento,
                Destino,
                Motivo,
                Fecha_Inicio_Viaje,
                Fecha_Fin_Viaje,
                Presupuesto_Estimado,
                Fecha_Creacion,
                Fecha_Modificacion,
                Id_Estado
            FROM tbl_solicitudes_viajes (NOLOCK)
            WHERE Id_Empleado = @Id_Empleado
            ORDER BY Fecha_Creacion DESC;

            SET @o_Num = 0;
            SET @o_Msg = 'Solicitudes filtradas por empleado exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 4. SP PARA FILTRAR SOLICITUDES POR ESTADO
CREATE OR ALTER PROC sp_solicitudes_FiltrarPorEstado
(
    @Id_Estado INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    IF ISNULL(@Id_Estado, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un estado valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_estados (NOLOCK) WHERE Id_Estado = @Id_Estado)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'El estado seleccionado no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_Solicitud_Viaje,
                Id_Empleado,
                Id_Tipo_Departamento,
                Destino,
                Motivo,
                Fecha_Inicio_Viaje,
                Fecha_Fin_Viaje,
                Presupuesto_Estimado,
                Fecha_Creacion,
                Fecha_Modificacion,
                Id_Estado
            FROM tbl_solicitudes_viajes (NOLOCK)
            WHERE Id_Estado = @Id_Estado
            ORDER BY Fecha_Creacion DESC;

            SET @o_Num = 0;
            SET @o_Msg = 'Solicitudes filtradas por estado exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 5. SP PARA AGREGAR UNA NUEVA SOLICITUD DE VIAJE (ACTUALIZADO)
CREATE OR ALTER PROC sp_solicitudes_Agregar
(
    @Id_Empleado INT,
    @Id_Tipo_Departamento INT,
    @Destino NVARCHAR(255),
    @Motivo NVARCHAR(MAX),
    @Fecha_Inicio_Viaje DATETIME,
    @Fecha_Fin_Viaje DATETIME,
    @Presupuesto_Estimado DECIMAL(12,2),
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN 
    SET @Destino = LTRIM(RTRIM(@Destino));
    SET @Motivo = LTRIM(RTRIM(@Motivo));

    IF ISNULL(@Id_Empleado, 0) = 0
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe especificar el empleado que solicita!';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_usuarios_login(NOLOCK) WHERE Id_Usuario = @Id_Empleado)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El empleado especificado no existe!';
    END   
    --Revisar si el empleado ya tiene solicitudes pendientes
    ELSE IF EXISTS(
        SELECT 1 
        FROM tbl_solicitudes_viajes (NOLOCK) 
        WHERE Id_Empleado = @Id_Empleado 
        AND Id_Estado IN (3, 4) -- 3='Pendiente Gerente', 4='Pendiente Admin'
    )
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡No puede crear una nueva solicitud porque ya tiene una pendiente de aprobación!';
    END
    
    -- Revisar si el empleado tiene viajes aprobados sin liquidar
    ELSE IF EXISTS(
        SELECT 1 
        FROM tbl_solicitudes_viajes s (NOLOCK)
        WHERE s.Id_Empleado = @Id_Empleado
        AND s.Id_Estado = 5 -- 5='Aprobado'
        AND NOT EXISTS ( -- Y que NO exista una liquidación para ella
            SELECT 1 
            FROM tbl_comparacion_gastos c (NOLOCK)
            WHERE c.Id_Solicitud_Viaje = s.Id_Solicitud_Viaje
        )
    )
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡No puede crear una nueva solicitud porque tiene un viaje aprobado pendiente de liquidar (rendir cuentas)!';
    END
    ELSE IF ISNULL(@Id_Tipo_Departamento, 0) = 0
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe especificar el departamento!';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_tipos_catalogos(NOLOCK) WHERE Id_Tipo_Catalogo = @Id_Tipo_Departamento)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El departamento especificado no existe!';
    END
    ELSE IF ISNULL(@Destino, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El destino no puede ir vacio!';
    END
    ELSE IF ISNULL(@Motivo, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El motivo no puede ir vacio!';
    END
    ELSE IF @Fecha_Inicio_Viaje IS NULL
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡La fecha de inicio no puede ir vacia!';
    END
    ELSE IF @Fecha_Fin_Viaje IS NULL
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡La fecha de fin no puede ir vacia!';
    END
    ELSE IF (CONVERT(DATE, @Fecha_Inicio_Viaje) < CONVERT(DATE, GETDATE()))
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡La fecha de inicio no puede ser en el pasado!';
    END
    ELSE IF (CONVERT(DATE, @Fecha_Fin_Viaje) < CONVERT(DATE, @Fecha_Inicio_Viaje))
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡La fecha de fin no puede ser anterior a la fecha de inicio!';
    END
    ELSE IF ISNULL(@Presupuesto_Estimado, 0) <= 0
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El presupuesto estimado debe ser mayor a 0!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_agregar_solicitud
            
            -- Asignamos el estado 'Pendiente aprobacion del gerente' (3) por defecto
            INSERT INTO tbl_solicitudes_viajes (
                Id_Empleado, Id_Tipo_Departamento, Destino, Motivo,
                Fecha_Inicio_Viaje, Fecha_Fin_Viaje, Presupuesto_Estimado, Id_Estado
            )
            VALUES (
                @Id_Empleado, @Id_Tipo_Departamento, @Destino, @Motivo,
                @Fecha_Inicio_Viaje, @Fecha_Fin_Viaje, @Presupuesto_Estimado, 3
            );

            SET @o_Num = SCOPE_IDENTITY();
            SET @o_Msg = '¡Solicitud de viaje agregada exitosamente!';
            
            COMMIT TRAN trx_agregar_solicitud
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_agregar_solicitud
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 6. SP PARA ACTUALIZAR UNA SOLICITUD DE VIAJE
CREATE OR ALTER PROC sp_solicitudes_Actualizar
(
    @Id_Solicitud_Viaje INT,
    @Id_Tipo_Departamento INT = NULL,
    @Destino NVARCHAR(255) = NULL,
    @Motivo NVARCHAR(MAX) = NULL,
    @Fecha_Inicio_Viaje DATETIME = NULL,
    @Fecha_Fin_Viaje DATETIME = NULL,
    @Presupuesto_Estimado DECIMAL(12,2) = NULL,
    @Id_Estado INT = NULL,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS 
BEGIN
    IF ISNULL(@Id_Solicitud_Viaje, 0) = 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar la solicitud a actualizar!';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_solicitudes_viajes(NOLOCK) WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡La solicitud no existe!';
    END
    ELSE IF @Id_Tipo_Departamento IS NOT NULL AND NOT EXISTS(SELECT 1 FROM tbl_tipos_catalogos(NOLOCK) WHERE Id_Tipo_Catalogo = @Id_Tipo_Departamento)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El nuevo departamento seleccionado no existe!';
    END
    ELSE IF @Id_Estado IS NOT NULL AND NOT EXISTS(SELECT 1 FROM tbl_estados(NOLOCK) WHERE Id_Estado = @Id_Estado)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El nuevo estado seleccionado no existe!';
    END
    ELSE IF ISNULL(@Presupuesto_Estimado, 1) <= 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El presupuesto no puede ser 0 o menor!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_actualizar_solicitud
            
            UPDATE tbl_solicitudes_viajes
            SET 
                Id_Tipo_Departamento = COALESCE(@Id_Tipo_Departamento, Id_Tipo_Departamento),
                Destino = COALESCE(LTRIM(RTRIM(@Destino)), Destino),
                Motivo = COALESCE(LTRIM(RTRIM(@Motivo)), Motivo),
                Fecha_Inicio_Viaje = COALESCE(@Fecha_Inicio_Viaje, Fecha_Inicio_Viaje),
                Fecha_Fin_Viaje = COALESCE(@Fecha_Fin_Viaje, Fecha_Fin_Viaje),
                Presupuesto_Estimado = COALESCE(@Presupuesto_Estimado, Presupuesto_Estimado),
                Id_Estado = COALESCE(@Id_Estado, Id_Estado),
                Fecha_Modificacion = GETDATE()
            WHERE 
                Id_Solicitud_Viaje = @Id_Solicitud_Viaje;

            SET @o_Num = 0;
            SET @o_Msg = '¡Solicitud actualizada correctamente!';
            
            COMMIT TRAN trx_actualizar_solicitud
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_actualizar_solicitud
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO


-- 7. SP PARA LISTAR SOLICITUDES PENDIENTES (GERENTE)
CREATE OR ALTER PROC sp_solicitudes_ListarPendientesGerente
(
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Este SP lista solo las solicitudes que esperan aprobación de gerente (Id_Estado = 3)
    BEGIN TRY
        SELECT 
            Id_Solicitud_Viaje,
            Id_Empleado,
            Id_Tipo_Departamento,
            Destino,
            Motivo,
            Fecha_Inicio_Viaje,
            Fecha_Fin_Viaje,
            Presupuesto_Estimado,
            Fecha_Creacion,
            Fecha_Modificacion,
            Id_Estado
        FROM tbl_solicitudes_viajes (NOLOCK)
        WHERE Id_Estado = 3 -- 'Pendiente aprobacion del gerente'
        ORDER BY Fecha_Creacion ASC; -- Se ordena ascendente para ver las más antiguas primero

        SET @o_Num = 0;
        SET @o_Msg = 'Solicitudes pendientes de gerente listadas';
    END TRY
    BEGIN CATCH
        SET @o_Num = -1;
        SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
    END CATCH
END
GO


-- 8. SP PARA LISTAR SOLICITUDES PENDIENTES (ADMINISTRADOR)
CREATE OR ALTER PROC sp_solicitudes_ListarPendientesAdmin
(
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Este SP lista solo las solicitudes que esperan aprobación de administrador (Id_Estado = 4)
    BEGIN TRY
        SELECT 
            Id_Solicitud_Viaje,
            Id_Empleado,
            Id_Tipo_Departamento,
            Destino,
            Motivo,
            Fecha_Inicio_Viaje,
            Fecha_Fin_Viaje,
            Presupuesto_Estimado,
            Fecha_Creacion,
            Fecha_Modificacion,
            Id_Estado
        FROM tbl_solicitudes_viajes (NOLOCK)
        WHERE Id_Estado = 4 -- 'Pendiente aprobacion del administrador'
        ORDER BY Fecha_Creacion ASC; -- Se ordena ascendente para ver las más antiguas primero

        SET @o_Num = 0;
        SET @o_Msg = 'Solicitudes pendientes de administrador listadas';
    END TRY
    BEGIN CATCH
        SET @o_Num = -1;
        SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
    END CATCH
END
GO

