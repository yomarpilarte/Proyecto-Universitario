USE Viajes;
GO

-- 1. SP PARA FILTRAR LA COMPARACION POR ID DE SOLICITUD
CREATE OR ALTER PROC sp_comparacion_FiltrarPorSolicitud
(
    @Id_Solicitud_Viaje INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Este SP obtiene el registro de liquidación (comparación)
    -- de una solicitud de viaje específica.
    
    IF ISNULL(@Id_Solicitud_Viaje, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un id de solicitud valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_comparacion_gastos (NOLOCK) WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Aún no existe un registro de comparación/liquidación para esta solicitud.';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_comparacion,
                Id_Solicitud_Viaje,
                Reembolso,
                Exceso_gasto,
                Justificacion_exceso,
                Fecha_Creacion,
                Fecha_Modificacion
            FROM tbl_comparacion_gastos (NOLOCK)
            WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje;

            SET @o_Num = 0;
            SET @o_Msg = 'Comparación de gastos filtrada exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 2. SP PARA FILTRAR UNA COMPARACION POR SU ID
CREATE OR ALTER PROC sp_comparacion_FiltrarPorID
(
    @Id_comparacion INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Filtra un registro de comparación único por su llave primaria.
    
    IF ISNULL(@Id_comparacion, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un id de comparación valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_comparacion_gastos (NOLOCK) WHERE Id_comparacion = @Id_comparacion)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'La comparación seleccionada no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_comparacion,
                Id_Solicitud_Viaje,
                Reembolso,
                Exceso_gasto,
                Justificacion_exceso,
                Fecha_Creacion,
                Fecha_Modificacion
            FROM tbl_comparacion_gastos (NOLOCK)
            WHERE Id_comparacion = @Id_comparacion;

            SET @o_Num = 0;
            SET @o_Msg = 'Comparación filtrada exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 3. SP PARA AGREGAR (CALCULAR) UNA NUEVA COMPARACION
CREATE OR ALTER PROC sp_comparacion_Agregar
(
    @Id_Solicitud_Viaje INT,
    @Justificacion_exceso NVARCHAR(255) = NULL,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN 
    -- Este SP calcula y registra la liquidación final del viaje.
    
    DECLARE @PresupuestoEstimado DECIMAL(12,2);
    DECLARE @GastoTotalReal DECIMAL(12,2);
    DECLARE @Diferencia DECIMAL(12,2);
    
    DECLARE @Reembolso DECIMAL(12,2) = NULL;
    DECLARE @ExcesoGasto DECIMAL(12,2) = NULL;

    -- Validaciones
    IF ISNULL(@Id_Solicitud_Viaje, 0) = 0 
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar una solicitud de viaje!';
        RETURN;
    END

    -- Validamos si la solicitud existe
    SELECT @PresupuestoEstimado = Presupuesto_Estimado 
    FROM tbl_solicitudes_viajes (NOLOCK) 
    WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje;

    IF @PresupuestoEstimado IS NULL
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡La solicitud de viaje no existe!';
        RETURN;
    END

    -- Validamos que la liquidación no exista ya
    IF EXISTS(SELECT 1 FROM tbl_comparacion_gastos (NOLOCK) WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe una liquidación para esta solicitud de viaje!';
        RETURN;
    END

    -- Calculamos el gasto total
    SELECT @GastoTotalReal = ISNULL(SUM(Monto_Gasto), 0) 
    FROM tbl_gastos_viaje (NOLOCK)
    WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje;
    
    -- Calculamos la diferencia
    SET @Diferencia = @PresupuestoEstimado - @GastoTotalReal;

    IF @Diferencia > 0
    BEGIN
        -- Sobró dinero, el empleado debe un Reembolso
        SET @Reembolso = @Diferencia;
    END
    ELSE IF @Diferencia < 0
    BEGIN
        -- Faltó dinero, es un Exceso de Gasto
        SET @ExcesoGasto = ABS(@Diferencia);
        
        IF ISNULL(@Justificacion_exceso, '') = ''
        BEGIN
            SET @o_Num = -1;
            SET @o_Msg = '¡Debe proporcionar una justificación para el exceso de gasto!';
            RETURN;
        END
    END
    -- Si @Diferencia = 0, ambos (Reembolso y Exceso) quedan en NULL (gasto exacto)
    
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_agregar_comparacion
            
            INSERT INTO tbl_comparacion_gastos (
                Id_Solicitud_Viaje, 
                Reembolso, 
                Exceso_gasto, 
                Justificacion_exceso
            )
            VALUES (
                @Id_Solicitud_Viaje,
                @Reembolso,
                @ExcesoGasto,
                @Justificacion_exceso
            );

            SET @o_Num = SCOPE_IDENTITY();
            SET @o_Msg = '¡Liquidación de viaje registrada exitosamente!';
            
            COMMIT TRAN trx_agregar_comparacion
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_agregar_comparacion
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 4. SP PARA ACTUALIZAR UNA COMPARACION (EJ: CORREGIR JUSTIFICACION)
CREATE OR ALTER PROC sp_comparacion_Actualizar
(
    @Id_comparacion INT,
    @Reembolso DECIMAL(12,2) = NULL,
    @Exceso_gasto DECIMAL(12,2) = NULL,
    @Justificacion_exceso NVARCHAR(255) = NULL,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS 
BEGIN
    -- Este SP permite corregir una liquidación,
    -- principalmente la justificación o los montos si se recalcularon.
    
    IF ISNULL(@Id_comparacion, 0) = 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar la comparación a actualizar!';
        RETURN;
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_comparacion_gastos(NOLOCK) WHERE Id_comparacion = @Id_comparacion)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡La comparación no existe!';
        RETURN;
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_actualizar_comparacion
            
            UPDATE tbl_comparacion_gastos
            SET 
                Reembolso = @Reembolso, -- Se actualiza a NULL si el parámetro es NULL
                Exceso_gasto = @Exceso_gasto, -- Se actualiza a NULL si el parámetro es NULL
                Justificacion_exceso = COALESCE(LTRIM(RTRIM(@Justificacion_exceso)), Justificacion_exceso),
                Fecha_Modificacion = GETDATE()
            WHERE 
                Id_comparacion = @Id_comparacion;

            SET @o_Num = 0;
            SET @o_Msg = '¡Comparación actualizada correctamente!';
            
            COMMIT TRAN trx_actualizar_comparacion
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_actualizar_comparacion
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO