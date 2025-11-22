USE Viajes;
GO

-- 1. SP PARA LISTAR TODAS LAS PERSONAS
CREATE OR ALTER PROC sp_personas_Listar
(
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    BEGIN TRY
        SELECT 
            Id_Persona,
            Primer_Nombre,
            Segundo_Nombre,
            Primer_Apellido,
            Segundo_Apellido,
            Cedula,
            Direccion,
            Telefono,
            Correo,
            Fecha_Creacion,
            Fecha_Modificacion
        FROM tbl_personas (NOLOCK)
        ORDER BY Id_Persona DESC;

        SET @o_Num = 0;
        SET @o_Msg = 'Personas listadas correctamente';
    END TRY
    BEGIN CATCH
        SET @o_Num = -1;
        SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- 2. SP PARA FILTRAR UNA PERSONA POR SU ID
CREATE OR ALTER PROC sp_personas_FiltrarPorID
(
    @Id_Persona INT,
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN
    IF ISNULL(@Id_Persona, 0) = 0 
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Debe seleccionar un id de persona valido';
    END
    ELSE IF NOT EXISTS(SELECT 1 FROM tbl_personas (NOLOCK) WHERE Id_Persona = @Id_Persona)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'La persona seleccionada no existe';
    END
    ELSE
    BEGIN
        BEGIN TRY
            SELECT 
                Id_Persona,
                Primer_Nombre,
                Segundo_Nombre,
                Primer_Apellido,
                Segundo_Apellido,
                Cedula,
                Direccion,
                Telefono,
                Correo,
                Fecha_Creacion,
                Fecha_Modificacion
            FROM tbl_personas (NOLOCK)
            WHERE Id_Persona = @Id_Persona;

            SET @o_Num = 0;
            SET @o_Msg = 'Persona filtrada exitosamente';
        END TRY
        BEGIN CATCH
            SET @o_Num = -1;
            SET @o_Msg = 'Error interno del servidor: ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 3. SP PARA AGREGAR UNA NUEVA PERSONA
CREATE OR ALTER PROC sp_personas_Agregar
(
    @Primer_Nombre NVARCHAR(100),
    @Segundo_Nombre NVARCHAR(100),
    @Primer_Apellido NVARCHAR(100),
    @Segundo_Apellido NVARCHAR(100),
    @Cedula NVARCHAR(100),
    @Direccion NVARCHAR(100),
    @Telefono NVARCHAR(100),
    @Correo NVARCHAR(100),
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS
BEGIN 
    SET @Primer_Nombre = UPPER(LTRIM(RTRIM(@Primer_Nombre)));
    SET @Segundo_Nombre = UPPER(LTRIM(RTRIM(@Segundo_Nombre)));
    SET @Primer_Apellido = UPPER(LTRIM(RTRIM(@Primer_Apellido)));
    SET @Segundo_Apellido = UPPER(LTRIM(RTRIM(@Segundo_Apellido)));
    SET @Cedula = UPPER(LTRIM(RTRIM(@Cedula)));
    SET @Direccion = LTRIM(RTRIM(@Direccion));
    SET @Telefono = LTRIM(RTRIM(@Telefono));
    SET @Correo = LTRIM(RTRIM(@Correo));

    IF ISNULL(@Primer_Nombre, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El primer nombre no puede ir vacio!';
    END
    ELSE IF ISNULL(@Segundo_Nombre, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El segundo nombre no puede ir vacio!';
    END
    ELSE IF ISNULL(@Primer_Apellido, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El primer apellido no puede ir vacio!';
    END
    ELSE IF ISNULL(@Segundo_Apellido, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El segundo apellido no puede ir vacio!';
    END
    ELSE IF ISNULL(@Cedula, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡La cédula no puede ir vacia!';
    END
    ELSE IF ISNULL(@Direccion, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡La dirección no puede ir vacia!';
    END
    ELSE IF ISNULL(@Telefono, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El teléfono no puede ir vacio!';
    END
    ELSE IF ISNULL(@Correo, '') = ''
    BEGIN 
        SET @o_Num = -1;
        SET @o_Msg = '¡El correo no puede ir vacio!';
    END
    ELSE IF EXISTS(SELECT 1 FROM tbl_personas (NOLOCK) WHERE Cedula = @Cedula)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe una persona con esa cédula!';
    END
    ELSE IF EXISTS(SELECT 1 FROM tbl_personas (NOLOCK) WHERE Correo = @Correo)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe una persona con ese correo!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_agregar_personas
            
            INSERT INTO tbl_personas (
                Primer_Nombre, Segundo_Nombre, Primer_Apellido, Segundo_Apellido, 
                Cedula, Direccion, Telefono, Correo
            )
            VALUES (
                @Primer_Nombre, @Segundo_Nombre, @Primer_Apellido, @Segundo_Apellido, 
                @Cedula, @Direccion, @Telefono, @Correo
            );

            SET @o_Num = SCOPE_IDENTITY();
            SET @o_Msg = '¡Persona agregada exitosamente!';
            
            COMMIT TRAN trx_agregar_personas
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_agregar_personas
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO

-- 4. SP PARA ACTUALIZAR UNA PERSONA EXISTENTE
CREATE OR ALTER PROC sp_personas_Actualizar
(
    @Id_Persona INT,
    @Primer_Nombre NVARCHAR(100),
    @Segundo_Nombre NVARCHAR(100),
    @Primer_Apellido NVARCHAR(100),
    @Segundo_Apellido NVARCHAR(100),
    @Cedula NVARCHAR(100),
    @Direccion NVARCHAR(100),
    @Telefono NVARCHAR(100),
    @Correo NVARCHAR(100),
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT
)
AS 
BEGIN
    SET @Primer_Nombre = CASE WHEN @Primer_Nombre IS NOT NULL THEN UPPER(LTRIM(RTRIM(@Primer_Nombre))) ELSE NULL END;
    SET @Segundo_Nombre = CASE WHEN @Segundo_Nombre IS NOT NULL THEN UPPER(LTRIM(RTRIM(@Segundo_Nombre))) ELSE NULL END;
    SET @Primer_Apellido = CASE WHEN @Primer_Apellido IS NOT NULL THEN UPPER(LTRIM(RTRIM(@Primer_Apellido))) ELSE NULL END;
    SET @Segundo_Apellido = CASE WHEN @Segundo_Apellido IS NOT NULL THEN UPPER(LTRIM(RTRIM(@Segundo_Apellido))) ELSE NULL END;
    SET @Cedula = CASE WHEN @Cedula IS NOT NULL THEN UPPER(LTRIM(RTRIM(@Cedula))) ELSE NULL END;
    SET @Direccion = CASE WHEN @Direccion IS NOT NULL THEN LTRIM(RTRIM(@Direccion)) ELSE NULL END;
    SET @Telefono = CASE WHEN @Telefono IS NOT NULL THEN LTRIM(RTRIM(@Telefono)) ELSE NULL END;
    SET @Correo = CASE WHEN @Correo IS NOT NULL THEN LTRIM(RTRIM(@Correo)) ELSE NULL END;

    IF ISNULL(@Id_Persona, 0) = 0
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Debe seleccionar la persona a actualizar!';
    END
    ELSE IF EXISTS(SELECT 1 FROM tbl_personas (NOLOCK) WHERE Cedula = @Cedula AND Id_Persona <> @Id_Persona)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe otra persona con esa cédula!';
    END
    ELSE IF EXISTS(SELECT 1 FROM tbl_personas (NOLOCK) WHERE Correo = @Correo AND Id_Persona <> @Id_Persona)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Ya existe otra persona con ese correo!';
    END
    ELSE
    BEGIN
        BEGIN TRY
            BEGIN TRAN trx_actualizar_personas
            
            UPDATE tbl_personas
            SET 
                Primer_Nombre = COALESCE(@Primer_Nombre, Primer_Nombre),
                Segundo_Nombre = COALESCE(@Segundo_Nombre, Segundo_Nombre),
                Primer_Apellido = COALESCE(@Primer_Apellido, Primer_Apellido),
                Segundo_Apellido = COALESCE(@Segundo_Apellido, Segundo_Apellido),
                Cedula = COALESCE(@Cedula, Cedula),
                Direccion = COALESCE(@Direccion, Direccion),
                Telefono = COALESCE(@Telefono, Telefono),
                Correo = COALESCE(@Correo, Correo),
                Fecha_Modificacion = GETDATE()
            WHERE 
                Id_Persona = @Id_Persona;

            SET @o_Num = 0;
            SET @o_Msg = '¡Persona actualizada correctamente!';
            
            COMMIT TRAN trx_actualizar_personas
        END TRY
        BEGIN CATCH
            ROLLBACK TRAN trx_actualizar_personas
            SET @o_Num = -1;
            SET @o_Msg = '¡Error interno del servidor! ' + ERROR_MESSAGE();
        END CATCH
    END
END
GO



