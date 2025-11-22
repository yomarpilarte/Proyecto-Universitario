USE Viajes;
GO

-- 1. SP PARA LISTAR TODOS LOS TIPOS DE CATALOGOS ACTIVOS
CREATE OR ALTER PROC sp_tipos_catalogos_Listar
(
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    BEGIN TRY
        SELECT 
            Id_Tipo_Catalogo,
            Id_Catalogo,
            Nombre_Tipo_Catalogo,
            Fecha_Creacion,
            Activo
        FROM tbl_tipos_catalogos (NOLOCK)
        WHERE Activo = 1
        ORDER BY Id_Catalogo, Id_Tipo_Catalogo DESC;

        SET @o_Num = 0;
        SET @o_Msg = 'Tipos de catálogo listados correctamente';
    END TRY
    BEGIN CATCH
        SET @o_Num = -1;
        SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 2. SP PARA FILTRAR UN TIPO DE CATALOGO POR SU ID
CREATE OR ALTER PROC sp_tipos_catalogos_FiltrarPorID
(
    @Id_Tipo_Catalogo INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    IF ISNULL(@Id_Tipo_Catalogo, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un id de tipo catálogo valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_tipos_catalogos (NOLOCK) WHERE Id_Tipo_Catalogo = @Id_Tipo_Catalogo)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'El tipo de catálogo seleccionado no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_Tipo_Catalogo,
                Id_Catalogo,
                Nombre_Tipo_Catalogo,
                Fecha_Creacion,
                Activo
            FROM tbl_tipos_catalogos (NOLOCK)
            WHERE Id_Tipo_Catalogo = @Id_Tipo_Catalogo;

            SET @o_Num = 0;
            SET @o_Msg = 'Tipo de catálogo filtrado exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 3. SP PARA AGREGAR UN NUEVO TIPO DE CATALOGO
CREATE OR ALTER PROC sp_tipos_catalogos_Agregar
(
    @Id_Catalogo INT,
    @Nombre_Tipo_Catalogo NVARCHAR(100),
    @Activo BIT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN 
    SET @Nombre_Tipo_Catalogo = LTRIM(RTRIM(@Nombre_Tipo_Catalogo));

    IF ISNULL(@Id_Catalogo, 0) = 0
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar un catálogo principal!';
    END
    ELSE IF ISNULL(@Nombre_Tipo_Catalogo, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El campo nombre tipo catálogo no puede ir vacio!';
    END
    ELSE IF @Activo IS NULL
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe indicar un estado valido (Activo/Inactivo)!';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_catalogos (NOLOCK) WHERE Id_Catalogo = @Id_Catalogo)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡El catálogo principal seleccionado no existe!';
    END
    ELSE IF EXISTS(SELECT 1 FROM tbl_tipos_catalogos (NOLOCK) WHERE Nombre_Tipo_Catalogo = @Nombre_Tipo_Catalogo AND Id_Catalogo = @Id_Catalogo)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe este tipo de catálogo para el catálogo seleccionado!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_agregar_tipos_catalogos
            
            INSERT INTO tbl_tipos_catalogos (Id_Catalogo, Nombre_Tipo_Catalogo, Activo)
            VALUES (@Id_Catalogo, @Nombre_Tipo_Catalogo, @Activo);

            SET @o_Num = SCOPE_IDENTITY();
            SET @o_Msg = '¡Tipo de catálogo agregado exitosamente!';
            
            COMMIT TRAN trx_agregar_tipos_catalogos
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_agregar_tipos_catalogos
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 4. SP PARA ACTUALIZAR UN TIPO DE CATALOGO EXISTENTE
CREATE OR ALTER PROC sp_tipos_catalogos_Actualizar
(
    @Id_Tipo_Catalogo INT,
    @Id_Catalogo INT,
    @Nombre_Tipo_Catalogo NVARCHAR(100),
    @Activo BIT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS 
BEGIN
    SET @Nombre_Tipo_Catalogo = LTRIM(RTRIM(@Nombre_Tipo_Catalogo));
    
    IF ISNULL(@Id_Tipo_Catalogo, 0) = 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar el tipo de catálogo a actualizar!';
    END
    ELSE IF EXISTS(SELECT 1 FROM tbl_tipos_catalogos (NOLOCK) WHERE Nombre_Tipo_Catalogo = @Nombre_Tipo_Catalogo AND Id_Catalogo = @Id_Catalogo AND Id_Tipo_Catalogo <> @Id_Tipo_Catalogo)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe este tipo de catálogo para el catálogo seleccionado!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_actualizar_tipos_catalogos
            
            UPDATE tbl_tipos_catalogos
            SET 
                Id_Catalogo = COALESCE(@Id_Catalogo, Id_Catalogo),
                Nombre_Tipo_Catalogo = COALESCE(@Nombre_Tipo_Catalogo, Nombre_Tipo_Catalogo),
                Activo = COALESCE(@Activo, Activo)
            WHERE 
                Id_Tipo_Catalogo = @Id_Tipo_Catalogo;

            SET @o_Num = 0;
            SET @o_Msg = '¡Tipo de catálogo actualizado correctamente!';
            
            COMMIT TRAN trx_actualizar_tipos_catalogos
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_actualizar_tipos_catalogos
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO