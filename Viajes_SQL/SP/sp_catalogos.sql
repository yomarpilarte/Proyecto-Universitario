USE Viajes;
GO

-- 1. SP PARA LISTAR TODOS LOS CATALOGOS ACTIVOS
CREATE OR ALTER PROC sp_catalogos_Listar
(
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    BEGIN TRY
        SELECT 
            Id_Catalogo,
            Nombre_Catalogo,
            Fecha_Creacion,
            Activo
        FROM tbl_catalogos (NOLOCK)
        WHERE Activo = 1
        ORDER BY Id_Catalogo DESC;

        SET @o_Num = 0;
        SET @o_Msg = 'Catálogos listados correctamente';
    END TRY
    BEGIN CATCH
        SET @o_Num = -1;
        SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 2. SP PARA FILTRAR UN CATALOGO POR SU ID
CREATE OR ALTER PROC sp_catalogos_FiltrarPorID
(
    @Id_Catalogo INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    IF ISNULL(@Id_Catalogo, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un id de catálogo valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_catalogos (NOLOCK) WHERE Id_Catalogo = @Id_Catalogo)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'El catálogo seleccionado no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_Catalogo,
                Nombre_Catalogo,
                Fecha_Creacion,
                Activo
            FROM tbl_catalogos (NOLOCK)
            WHERE Id_Catalogo = @Id_Catalogo;

            SET @o_Num = 0;
            SET @o_Msg = 'Catálogo filtrado exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 3. SP PARA AGREGAR UN NUEVO CATALOGO
CREATE OR ALTER PROC sp_catalogos_Agregar
(
    @Nombre_Catalogo NVARCHAR(100),
    @Activo BIT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN 
    SET @Nombre_Catalogo = LTRIM(RTRIM(@Nombre_Catalogo));

    IF ISNULL(@Nombre_Catalogo, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El campo nombre catálogo no puede ir vacio!';
    END
    ELSE IF @Activo IS NULL
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe indicar un estado valido (Activo/Inactivo)!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_agregar_catalogos
            
            INSERT INTO tbl_catalogos (Nombre_Catalogo, Activo)
            VALUES (@Nombre_Catalogo, @Activo);

            SET @o_Num = SCOPE_IDENTITY();
            SET @o_Msg = '¡Catálogo agregado exitosamente!';
            
            COMMIT TRAN trx_agregar_catalogos
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_agregar_catalogos
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 4. SP PARA ACTUALIZAR UN CATALOGO EXISTENTE
CREATE OR ALTER PROC sp_catalogos_Actualizar
(
    @Id_Catalogo INT,
    @Nombre_Catalogo NVARCHAR(100),
    @Activo BIT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS 
BEGIN
    SET @Nombre_Catalogo = LTRIM(RTRIM(@Nombre_Catalogo));
    
    IF ISNULL(@Id_Catalogo, 0) = 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar el catálogo a actualizar!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_actualizar_catalogos
            
            UPDATE tbl_catalogos
            SET 
                Nombre_Catalogo = COALESCE(@Nombre_Catalogo, Nombre_Catalogo),
                Activo = COALESCE(@Activo, Activo)
            WHERE 
                Id_Catalogo = @Id_Catalogo;

            SET @o_Num = 0;
            SET @o_Msg = '¡Catálogo actualizado correctamente!';
            
            COMMIT TRAN trx_actualizar_catalogos
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_actualizar_catalogos
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO