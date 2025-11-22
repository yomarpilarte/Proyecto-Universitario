USE Viajes;
GO

-- 1. SP PARA LISTAR COMPROBANTES POR GASTO
CREATE OR ALTER PROC sp_comprobantes_FiltrarPorGasto
(
    @Id_Gasto_Viaje INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Lista todos los comprobantes (archivos) asociados a un gasto específico.
    
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
                Id_Comprobante,
                Id_Gasto_Viaje,
                Nombre_Archivo_Original,
                Ruta_Archivo,
                Tipo_MIME,
                Tamano_Bytes,
                Fecha_Creacion
            FROM tbl_comprobantes (NOLOCK)
            WHERE Id_Gasto_Viaje = @Id_Gasto_Viaje
            ORDER BY Fecha_Creacion DESC;

            SET @o_Num = 0;
            SET @o_Msg = 'Comprobantes listados exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 2. SP PARA FILTRAR UN COMPROBANTE POR SU ID
CREATE OR ALTER PROC sp_comprobantes_FiltrarPorID
(
    @Id_Comprobante INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    -- Filtra un comprobante único por su llave primaria.
    
    IF ISNULL(@Id_Comprobante, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un id de comprobante valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_comprobantes (NOLOCK) WHERE Id_Comprobante = @Id_Comprobante)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'El comprobante seleccionado no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_Comprobante,
                Id_Gasto_Viaje,
                Nombre_Archivo_Original,
                Ruta_Archivo,
                Tipo_MIME,
                Tamano_Bytes,
                Fecha_Creacion
            FROM tbl_comprobantes (NOLOCK)
            WHERE Id_Comprobante = @Id_Comprobante;

            SET @o_Num = 0;
            SET @o_Msg = 'Comprobante filtrado exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 3. SP PARA AGREGAR UN NUEVO COMPROBANTE
CREATE OR ALTER PROC sp_comprobantes_Agregar
(
    @Id_Gasto_Viaje INT,
    @Nombre_Archivo_Original NVARCHAR(255),
    @Ruta_Archivo NVARCHAR(500),
    @Tipo_MIME NVARCHAR(100),
    @Tamano_Bytes INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN 
    -- Valida que el gasto exista y que los datos del archivo sean correctos.
	SET @Nombre_Archivo_Original = (LTRIM(RTRIM(@Nombre_Archivo_Original));
    SET @Ruta_Archivo = (LTRIM(RTRIM(@Ruta_Archivo));

    IF ISNULL(@Id_Gasto_Viaje, 0) = 0 
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe asociar el comprobante a un gasto!';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_gastos_viaje (NOLOCK) WHERE Id_Gasto_Viaje = @Id_Gasto_Viaje)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El gasto asociado no existe!';
    END
    ELSE IF ISNULL(@Nombre_Archivo_Original, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El nombre original del archivo no puede ir vacio!';
    END
    ELSE IF ISNULL(@Ruta_Archivo, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡La ruta del archivo no puede ir vacia!';
    END
    ELSE IF ISNULL(@Tamano_Bytes, 0) <= 0
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El tamaño del archivo debe ser mayor a 0!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_agregar_comprobante
            
            INSERT INTO tbl_comprobantes (
                Id_Gasto_Viaje,
                Nombre_Archivo_Original,
                Ruta_Archivo,
                Tipo_MIME,
                Tamano_Bytes
            )
            VALUES (
                @Id_Gasto_Viaje,
                LTRIM(RTRIM(@Nombre_Archivo_Original)),
                LTRIM(RTRIM(@Ruta_Archivo)),
                LTRIM(RTRIM(@Tipo_MIME)),
                @Tamano_Bytes
            );

            SET @o_Num = SCOPE_IDENTITY();
            SET @o_Msg = '¡Comprobante agregado exitosamente!';
            
            COMMIT TRAN trx_agregar_comprobante
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_agregar_comprobante
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 4. SP PARA ACTUALIZAR UN COMPROBANTE
CREATE OR ALTER PROC sp_comprobantes_Actualizar
(
    @Id_Comprobante INT,
    @Nombre_Archivo_Original NVARCHAR(255) = NULL,
    @Ruta_Archivo NVARCHAR(500) = NULL,
    @Tipo_MIME NVARCHAR(100) = NULL,
    @Tamano_Bytes INT = NULL,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS 
BEGIN
    
    IF ISNULL(@Id_Comprobante, 0) = 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar el comprobante a actualizar!';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_comprobantes(NOLOCK) WHERE Id_Comprobante = @Id_Comprobante)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El comprobante no existe!';
    END
    ELSE IF ISNULL(@Tamano_Bytes, 1) <= 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El tamaño no puede ser 0 o menor!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_actualizar_comprobante
            
            UPDATE tbl_comprobantes
            SET 
                Nombre_Archivo_Original = COALESCE(LTRIM(RTRIM(@Nombre_Archivo_Original)), Nombre_Archivo_Original),
                Ruta_Archivo = COALESCE(LTRIM(RTRIM(@Ruta_Archivo)), Ruta_Archivo),
                Tipo_MIME = COALESCE(LTRIM(RTRIM(@Tipo_MIME)), Tipo_MIME),
                Tamano_Bytes = COALESCE(@Tamano_Bytes, Tamano_Bytes)
            WHERE 
                Id_Comprobante = @Id_Comprobante;

            SET @o_Num = 0;
            SET @o_Msg = '¡Comprobante actualizado correctamente!';
            
            COMMIT TRAN trx_actualizar_comprobante
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_actualizar_comprobante
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO