USE Viajes;
GO

-- 1. SP PARA LISTAR TODOS LOS ROLES ACTIVOS
CREATE OR ALTER PROC sp_roles_Listar
(
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    BEGIN TRY
        SELECT 
            Id_Rol,
            Nombre_Rol,
            Fecha_Creacion,
            Fecha_Modificacion,
            Activo
        FROM tbl_roles (NOLOCK)
        WHERE Activo = 1
        ORDER BY Id_Rol DESC;

        SET @o_Num = 0;
        SET @o_Msg = 'Roles listados correctamente';
    END TRY
    BEGIN CATCH
        SET @o_Num = -1;
        SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 2. SP PARA FILTRAR UN ROL POR SU ID
CREATE OR ALTER PROC sp_roles_FiltrarPorID
(
    @Id_Rol INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    IF ISNULL(@Id_Rol, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un id de rol valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_roles (NOLOCK) WHERE Id_Rol = @Id_Rol)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'El rol seleccionado no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_Rol,
                Nombre_Rol,
                Fecha_Creacion,
                Fecha_Modificacion,
                Activo
            FROM tbl_roles (NOLOCK)
            WHERE Id_Rol = @Id_Rol;

            SET @o_Num = 0;
            SET @o_Msg = 'Rol filtrado exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 3. SP PARA AGREGAR UN NUEVO ROL
CREATE OR ALTER PROC sp_roles_Agregar
(
    @Nombre_Rol NVARCHAR(100),
    @Activo BIT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN 
    SET @Nombre_Rol = LTRIM(RTRIM(@Nombre_Rol));

    IF ISNULL(@Nombre_Rol, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El campo nombre rol no puede ir vacio!';
    END
    ELSE IF @Activo IS NULL
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe indicar un estado valido (Activo/Inactivo)!';
    END
    ELSE IF EXISTS(SELECT 1 FROM tbl_roles (NOLOCK) WHERE Nombre_Rol = @Nombre_Rol)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe un rol con ese nombre!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_agregar_roles
            
            INSERT INTO tbl_roles (Nombre_Rol, Activo)
            VALUES (@Nombre_Rol, @Activo);

            SET @o_Num = SCOPE_IDENTITY();
            SET @o_Msg = '¡Rol agregado exitosamente!';
            
            COMMIT TRAN trx_agregar_roles
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_agregar_roles
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 4. SP PARA ACTUALIZAR UN ROL EXISTENTE
CREATE OR ALTER PROC sp_roles_Actualizar
(
    @Id_Rol INT,
    @Nombre_Rol NVARCHAR(100),
    @Activo BIT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS 
BEGIN
    SET @Nombre_Rol = LTRIM(RTRIM(@Nombre_Rol));
    
    IF ISNULL(@Id_Rol, 0) = 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar el rol a actualizar!';
    END
    ELSE IF EXISTS(SELECT 1 FROM tbl_roles (NOLOCK) WHERE Nombre_Rol = @Nombre_Rol AND Id_Rol <> @Id_Rol)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe un rol con ese nombre!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_actualizar_roles
            
            UPDATE tbl_roles
            SET 
                Nombre_Rol = COALESCE(@Nombre_Rol, Nombre_Rol),
                Fecha_Modificacion = GETDATE(),
                Activo = COALESCE(@Activo, Activo)
            WHERE 
                Id_Rol = @Id_Rol;

            SET @o_Num = 0;
            SET @o_Msg = '¡Rol actualizado correctamente!';
            
            COMMIT TRAN trx_actualizar_roles
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_actualizar_roles
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO