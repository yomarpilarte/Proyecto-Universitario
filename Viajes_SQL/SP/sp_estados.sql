USE Viajes
GO

USE Viajes;
GO

-- 1. SP PARA LISTAR TODOS LOS ESTADOS ACTIVOS
CREATE OR ALTER PROC sp_estados_Listar
(
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    BEGIN TRY
        SELECT 
            Id_Estado,
            Nombre_Estado,
            Fecha_Creacion,
            Fecha_Modificacion,
            Activo
        FROM tbl_estados (NOLOCK)
        WHERE Activo = 1
        ORDER BY Id_Estado DESC;

        SET @o_Num = 0;
        SET @o_Msg = 'Estados listados correctamente';
    END TRY
    BEGIN CATCH
        SET @o_Num = -1;
        SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 2. SP PARA FILTRAR UN ESTADO POR SU ID
CREATE OR ALTER PROC sp_estados_FiltrarPorID
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
        SET @o_Msg = 'Debe seleccionar un id de estado valido';
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
                Id_Estado,
                Nombre_Estado,
                Fecha_Creacion,
                Fecha_Modificacion,
                Activo
            FROM tbl_estados (NOLOCK)
            WHERE Id_Estado = @Id_Estado;

            SET @o_Num = 0;
            SET @o_Msg = 'Estado filtrado exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 3. SP PARA AGREGAR UN NUEVO ESTADO
CREATE OR ALTER PROC sp_estados_Agregar
(
    @Nombre_Estado NVARCHAR(50),
    @Activo BIT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN 
    SET @Nombre_Estado = LTRIM(RTRIM(@Nombre_Estado));

    IF ISNULL(@Nombre_Estado, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El campo nombre estado no puede ir vacio!';
    END
    ELSE IF @Activo IS NULL
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe indicar un estado valido (Activo/Inactivo)!';
    END
    ELSE IF EXISTS(SELECT 1 FROM tbl_estados (NOLOCK) WHERE Nombre_Estado = @Nombre_Estado)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe un estado con ese nombre!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_agregar_estados
            
            INSERT INTO tbl_estados (Nombre_Estado, Activo)
            VALUES (@Nombre_Estado, @Activo);

            SET @o_Num = SCOPE_IDENTITY();
            SET @o_Msg = '¡Estado agregado exitosamente!';
            
            COMMIT TRAN trx_agregar_estados
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_agregar_estados
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 4. SP PARA ACTUALIZAR UN ESTADO EXISTENTE
CREATE OR ALTER PROC sp_estados_Actualizar
(
    @Id_Estado INT,
    @Nombre_Estado NVARCHAR(50),
    @Activo BIT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS 
BEGIN
    SET @Nombre_Estado = LTRIM(RTRIM(@Nombre_Estado));
    
    IF ISNULL(@Id_Estado, 0) = 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar el estado a actualizar!';
    END
    ELSE IF EXISTS(SELECT 1 FROM tbl_estados (NOLOCK) WHERE Nombre_Estado = @Nombre_Estado AND Id_Estado <> @Id_Estado)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe un estado con ese nombre!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_actualizar_estados
            
            UPDATE tbl_estados
            SET 
                Nombre_Estado = COALESCE(@Nombre_Estado, Nombre_Estado),
                Fecha_Modificacion = GETDATE(),
                Activo = COALESCE(@Activo, Activo)
            WHERE 
                Id_Estado = @Id_Estado;

            SET @o_Num = 0;
            SET @o_Msg = '¡Estado actualizado correctamente!';
            
            COMMIT TRAN trx_actualizar_estados
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_actualizar_estados
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO


