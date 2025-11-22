USE Viajes;
GO

-- 1. SP PARA LISTAR GASTOS POR SOLICITUD
CREATE OR ALTER PROC sp_gastos_FiltrarPorSolicitud
(
    @Id_Solicitud_Viaje INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Lista todos los gastos registrados para una solicitud de viaje específica.
    
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
                g.Id_Gasto_Viaje,
                g.Id_Solicitud_Viaje,
                g.Id_Tipo_Gasto,
                t.Nombre_Tipo_Catalogo AS Nombre_Tipo_Gasto, 
                g.Descripcion_Gasto,
                g.Monto_Gasto,
                g.Fecha_Creacion,
                g.Fecha_Modificacion
            FROM tbl_gastos_viaje g (NOLOCK)
            INNER JOIN tbl_tipos_catalogos t (NOLOCK) ON g.Id_Tipo_Gasto = t.Id_Tipo_Catalogo
            WHERE g.Id_Solicitud_Viaje = @Id_Solicitud_Viaje
            ORDER BY g.Fecha_Creacion DESC;

            SET @o_Num = 0;
            SET @o_Msg = 'Gastos de la solicitud listados exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 2. SP PARA FILTRAR UN GASTO ESPECIFICO POR SU ID
CREATE OR ALTER PROC sp_gastos_FiltrarPorID
(
    @Id_Gasto_Viaje INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Filtra un registro de gasto único por su llave primaria.
    
    IF ISNULL(@Id_Gasto_Viaje, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un id de gasto valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_gastos_viaje (NOLOCK) WHERE Id_Gasto_Viaje = @Id_Gasto_Viaje)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'El gasto seleccionado no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_Gasto_Viaje,
                Id_Solicitud_Viaje,
                Id_Tipo_Gasto,
                Descripcion_Gasto,
                Monto_Gasto,
                Fecha_Creacion,
                Fecha_Modificacion
            FROM tbl_gastos_viaje (NOLOCK)
            WHERE Id_Gasto_Viaje = @Id_Gasto_Viaje;

            SET @o_Num = 0;
            SET @o_Msg = 'Gasto filtrado exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 3. SP PARA AGREGAR UN NUEVO GASTO DE VIAJE
CREATE OR ALTER PROC sp_gastos_Agregar
(
    @Id_Solicitud_Viaje INT,
    @Id_Tipo_Gasto INT,
    @Descripcion_Gasto NVARCHAR(255),
    @Monto_Gasto DECIMAL(12,2),
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN 
    DECLARE @EstadoSolicitud INT;

    SET @Descripcion_Gasto = LTRIM(RTRIM(@Descripcion_Gasto));

    -- Validaciones
    IF ISNULL(@Id_Solicitud_Viaje, 0) = 0 
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar una solicitud de viaje!';
        RETURN;
    END

    -- para validar el estado de la solicitud (por si acaso)
    SELECT @EstadoSolicitud = Id_Estado 
    FROM tbl_solicitudes_viajes (NOLOCK) 
    WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje;

    IF @EstadoSolicitud IS NULL
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡La solicitud de viaje no existe!';
        RETURN;
    END
    ELSE IF @EstadoSolicitud <> 5 --= 'Aprobado'
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Solo se pueden agregar gastos a solicitudes APROBADAS!';
        RETURN;
    END
    ELSE IF ISNULL(@Id_Tipo_Gasto, 0) = 0
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar un tipo de gasto!';
        RETURN;
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_tipos_catalogos(NOLOCK) WHERE Id_Tipo_Catalogo = @Id_Tipo_Gasto)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El tipo de gasto no existe!';
        RETURN;
    END
    ELSE IF ISNULL(@Monto_Gasto, 0) <= 0
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El monto del gasto debe ser mayor a 0!';
        RETURN;
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_agregar_gasto
            
            INSERT INTO tbl_gastos_viaje (
                Id_Solicitud_Viaje, 
                Id_Tipo_Gasto, 
                Descripcion_Gasto, 
                Monto_Gasto
            )
            VALUES (
                @Id_Solicitud_Viaje,
                @Id_Tipo_Gasto,
                @Descripcion_Gasto,
                @Monto_Gasto
            );

            SET @o_Num = SCOPE_IDENTITY();
            SET @o_Msg = '¡Gasto de viaje agregado exitosamente!';
            
            COMMIT TRAN trx_agregar_gasto
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_agregar_gasto
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 4. SP PARA ACTUALIZAR UN GASTO DE VIAJE
CREATE OR ALTER PROC sp_gastos_Actualizar
(
    @Id_Gasto_Viaje INT,
    @Id_Tipo_Gasto INT = NULL,
    @Descripcion_Gasto NVARCHAR(255) = NULL,
    @Monto_Gasto DECIMAL(12,2) = NULL,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS 
BEGIN
    IF ISNULL(@Id_Gasto_Viaje, 0) = 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar el gasto a actualizar!';
        RETURN;
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_gastos_viaje(NOLOCK) WHERE Id_Gasto_Viaje = @Id_Gasto_Viaje)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El gasto no existe!';
        RETURN;
    END
    ELSE IF @Id_Tipo_Gasto IS NOT NULL AND NOT EXISTS(SELECT 1 FROM tbl_tipos_catalogos(NOLOCK) WHERE Id_Tipo_Catalogo = @Id_Tipo_Gasto)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El nuevo tipo de gasto no existe!';
        RETURN;
    END
    ELSE IF ISNULL(@Monto_Gasto, 1) <= 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El monto del gasto no puede ser 0 o menor!';
        RETURN;
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_actualizar_gasto
            
            UPDATE tbl_gastos_viaje
            SET 
                Id_Tipo_Gasto = COALESCE(@Id_Tipo_Gasto, Id_Tipo_Gasto),
                Descripcion_Gasto = COALESCE(LTRIM(RTRIM(@Descripcion_Gasto)), Descripcion_Gasto),
                Monto_Gasto = COALESCE(@Monto_Gasto, Monto_Gasto),
                Fecha_Modificacion = GETDATE()
            WHERE 
                Id_Gasto_Viaje = @Id_Gasto_Viaje;

            SET @o_Num = 0;
            SET @o_Msg = '¡Gasto actualizado correctamente!';
            
            COMMIT TRAN trx_actualizar_gasto
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_actualizar_gasto
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO