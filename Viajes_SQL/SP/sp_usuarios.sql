USE Viajes;
GO



           
--  SP PARA AGREGAR USUARIOS
CREATE OR ALTER PROCEDURE sp_usuarios_Insertar
(
    @Primer_Nombre NVARCHAR(100),
    @Segundo_Nombre NVARCHAR(100),
    @Primer_Apellido NVARCHAR(100),
    @Segundo_Apellido NVARCHAR(100),
    @Cedula NVARCHAR(100),
    @Direccion NVARCHAR(100),
    @Telefono NVARCHAR(100),
    @Correo NVARCHAR(100),
    @Id_Departamento INT,
    @Usuario NVARCHAR(100),
    @Contrasena NVARCHAR(100),
    @Id_Rol INT,
    @o_Num INT OUTPUT,
    @o_Msg NVARCHAR(255) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- VALIDACIONES DE CAMPOS
        IF @Primer_Nombre IS NULL OR LTRIM(RTRIM(@Primer_Nombre)) = ''
        BEGIN SET @o_Num = -10; SET @o_Msg = 'Debe completar el campo Primer Nombre.'; RETURN; END
        IF @Segundo_Nombre IS NULL OR LTRIM(RTRIM(@Segundo_Nombre)) = ''
        BEGIN SET @o_Num = -11; SET @o_Msg = 'Debe completar el campo Segundo Nombre.'; RETURN; END
        IF @Primer_Apellido IS NULL OR LTRIM(RTRIM(@Primer_Apellido)) = ''
        BEGIN SET @o_Num = -12; SET @o_Msg = 'Debe completar el campo Primer Apellido.'; RETURN; END
        IF @Segundo_Apellido IS NULL OR LTRIM(RTRIM(@Segundo_Apellido)) = ''
        BEGIN SET @o_Num = -13; SET @o_Msg = 'Debe completar el campo Segundo Apellido.'; RETURN; END
        IF @Cedula IS NULL OR LTRIM(RTRIM(@Cedula)) = ''
        BEGIN SET @o_Num = -14; SET @o_Msg = 'Debe completar el campo Cédula.'; RETURN; END
        IF @Direccion IS NULL OR LTRIM(RTRIM(@Direccion)) = ''
        BEGIN SET @o_Num = -15; SET @o_Msg = 'Debe completar el campo Dirección.'; RETURN; END
        IF @Telefono IS NULL OR LTRIM(RTRIM(@Telefono)) = ''
        BEGIN SET @o_Num = -16; SET @o_Msg = 'Debe completar el campo Teléfono.'; RETURN; END
        IF @Correo IS NULL OR LTRIM(RTRIM(@Correo)) = ''
        BEGIN SET @o_Num = -17; SET @o_Msg = 'Debe completar el campo Correo.'; RETURN; END
        IF @Usuario IS NULL OR LTRIM(RTRIM(@Usuario)) = ''
        BEGIN SET @o_Num = -18; SET @o_Msg = 'Debe completar el campo Usuario.'; RETURN; END
        IF @Contrasena IS NULL OR LTRIM(RTRIM(@Contrasena)) = ''
        BEGIN SET @o_Num = -19; SET @o_Msg = 'Debe completar el campo Contraseña.'; RETURN; END
        IF @Id_Departamento IS NULL
        BEGIN SET @o_Num = -20; SET @o_Msg = 'Debe seleccionar un Departamento.'; RETURN; END
        IF @Id_Rol IS NULL
        BEGIN SET @o_Num = -21; SET @o_Msg = 'Debe seleccionar un Rol.'; RETURN; END

        -- VALIDACIONES DE UNICIDAD
        IF EXISTS (SELECT 1 FROM tbl_usuarios_login WHERE Usuario = @Usuario)
        BEGIN SET @o_Num = -1; SET @o_Msg = 'El nombre de usuario ya está registrado.'; RETURN; END
        IF EXISTS (SELECT 1 FROM tbl_personas WHERE Cedula = @Cedula)
        BEGIN SET @o_Num = -3; SET @o_Msg = 'La cédula ya está registrada.'; RETURN; END
        IF EXISTS (SELECT 1 FROM tbl_personas WHERE Correo = @Correo)
        BEGIN SET @o_Num = -4; SET @o_Msg = 'El correo ya está registrado.'; RETURN; END
        IF EXISTS (SELECT 1 FROM tbl_personas WHERE Telefono = @Telefono)
        BEGIN SET @o_Num = -5; SET @o_Msg = 'El teléfono ya está registrado.'; RETURN; END

        -- Calcular hash de contraseña
        DECLARE @Hash VARBINARY(64) = HASHBYTES('SHA2_256', @Contrasena + @Usuario);

        -- Validar que la contraseña no exista
        IF EXISTS (SELECT 1 FROM tbl_usuarios_login WHERE Contrasena = @Hash)
        BEGIN SET @o_Num = -2; SET @o_Msg = 'La contraseña ya está en uso por otro usuario.'; RETURN; END

        -- INICIAR TRANSACCIÓN
        BEGIN TRAN;

        -- Insertar persona
        INSERT INTO tbl_personas (
            Primer_Nombre, Segundo_Nombre, Primer_Apellido, Segundo_Apellido,
            Cedula, Direccion, Telefono, Correo, Id_Departamento
        )
        VALUES (
            @Primer_Nombre, @Segundo_Nombre, @Primer_Apellido, @Segundo_Apellido,
            @Cedula, @Direccion, @Telefono, @Correo, @Id_Departamento
        );

        DECLARE @Id_Persona INT = SCOPE_IDENTITY();

        -- Obtener estado "Inactivo"
        DECLARE @Id_Estado_Inactivo INT;

     SELECT TOP 1 @Id_Estado_Inactivo = Id_Estado
    FROM tbl_estados
    WHERE LTRIM(RTRIM(LOWER(Nombre_Estado))) = 'inactivo';

     IF @Id_Estado_Inactivo IS NULL
     BEGIN
    SET @o_Num = -30;
    SET @o_Msg = 'No se encontró el estado "Inactivo" en la tabla tbl_estados.';
    RETURN;
    END

        -- Insertar usuario
        INSERT INTO tbl_usuarios_login (
            Id_Persona, Id_Rol, Usuario, Contrasena, Id_Estado,
            ContraseñaTemporal, FechaExpiracionTemp, FechaUltimoCambio
        )
        VALUES (
            @Id_Persona, @Id_Rol, @Usuario, @Hash, @Id_Estado_Inactivo,
            1, DATEADD(DAY, 7, GETDATE()), NULL
        );

        -- Auditoría
        INSERT INTO tbl_auditoria (
            Id_Usuario, Nombre_Tabla, Tipo_Operacion, Descripcion, Dato_Nuevo
        )
        VALUES (
            NULL,
            'tbl_usuarios_login',
            'INSERT',
            'Alta de nuevo usuario institucional',
            CONCAT('Usuario: ', @Usuario, ', Rol: ', @Id_Rol, ', Persona: ', @Id_Persona)
        );

        COMMIT TRAN;

        SET @o_Num = 1;
        SET @o_Msg = 'Usuario registrado correctamente. Pendiente de activación.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SET @o_Num = -99;
        SET @o_Msg = ERROR_MESSAGE();
    END CATCH
END


-- Declarar variables de salida
DECLARE @o_Num INT, @o_Msg NVARCHAR(255);

-- Ejecutar el procedimiento almacenado con datos de prueba
EXEC sp_usuarios_Insertar
    @Primer_Nombre = 'Lert',
    @Segundo_Nombre = 'oliu',
    @Primer_Apellido = 'Martínez',
    @Segundo_Apellido = 'González',
    @Cedula = '125689',
    @Direccion = 'Avenida Siempre Viva 742',
    @Telefono = '558975',
    @Correo = 'oliu@gmail.com',
    @Id_Departamento = 3,
    @Usuario = 'oliu635',
    @Contrasena = 'ClaveSegura123',
    @Id_Rol = 4,
    @o_Num = @o_Num OUTPUT,
    @o_Msg = @o_Msg OUTPUT;

-- Mostrar los resultados
SELECT @o_Num AS Numero, @o_Msg AS Mensaje;

-- =====================================================

CREATE OR ALTER PROCEDURE sp_usuarios_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.Primer_Nombre,
        p.Segundo_Nombre,
        p.Primer_Apellido,
        p.Segundo_Apellido,
        p.Correo,
        p.Cedula,
        tc.Nombre_Tipo_Catalogo AS Departamento,
        r.Nombre_Rol AS Rol,
        e.Nombre_Estado AS Estado,
        u.Id_Usuario
    FROM tbl_usuarios_login u
    JOIN tbl_personas p ON u.Id_Persona = p.Id_Persona
    JOIN tbl_roles r ON u.Id_Rol = r.Id_Rol
    JOIN tbl_estados e ON u.Id_Estado = e.Id_Estado
    LEFT JOIN tbl_tipos_catalogos tc ON p.Id_Departamento = tc.Id_Tipo_Catalogo;
END
exec sp_usuarios_Listar
select * from tbl_personas
-- =====================================================
CREATE OR ALTER PROCEDURE sp_usuarios_ActualizarDatos
(
    @Id_Usuario INT,
    @Primer_Nombre NVARCHAR(100) = NULL,
    @Segundo_Nombre NVARCHAR(100) = NULL,
    @Primer_Apellido NVARCHAR(100) = NULL,
    @Segundo_Apellido NVARCHAR(100) = NULL,
    @Correo NVARCHAR(100) = NULL,
    @Cedula NVARCHAR(100) = NULL,
    @Telefono NVARCHAR(100) = NULL,
    @Direccion NVARCHAR(100) = NULL,
    @Id_Departamento INT = NULL,
    @Id_Rol INT = NULL,
    @Id_Usuario_Modificador INT, -- quien ejecuta la modificación
    @o_Num INT OUTPUT,
    @o_Msg NVARCHAR(255) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @Id_Persona INT = (SELECT Id_Persona FROM tbl_usuarios_login WHERE Id_Usuario = @Id_Usuario);

        -- Validaciones de unicidad solo si los campos se van a modificar
        IF @Correo IS NOT NULL AND EXISTS(SELECT 1 FROM tbl_personas WHERE Correo = @Correo AND Id_Persona <> @Id_Persona)
        BEGIN SET @o_Num = -2; SET @o_Msg = 'El correo ya está registrado por otra persona.'; RETURN; END
        IF @Cedula IS NOT NULL AND EXISTS(SELECT 1 FROM tbl_personas WHERE Cedula = @Cedula AND Id_Persona <> @Id_Persona)
        BEGIN SET @o_Num = -3; SET @o_Msg = 'La cédula ya está registrada por otra persona.'; RETURN; END
        IF @Telefono IS NOT NULL AND EXISTS(SELECT 1 FROM tbl_personas WHERE Telefono = @Telefono AND Id_Persona <> @Id_Persona)
        BEGIN SET @o_Num = -4; SET @o_Msg = 'El teléfono ya está registrado por otra persona.'; RETURN; END

        BEGIN TRAN;

        -- Obtener datos anteriores
        DECLARE @DatosAnteriores NVARCHAR(MAX) = (
            SELECT CONCAT(
                'Nombre: ', Primer_Nombre, ' ', Segundo_Nombre, ' ', Primer_Apellido, ' ', Segundo_Apellido,
                ', Correo: ', Correo, ', Cédula: ', Cedula, ', Teléfono: ', Telefono,
                ', Dirección: ', Direccion, ', Departamento: ', Id_Departamento
            )
            FROM tbl_personas WHERE Id_Persona = @Id_Persona
        );

        DECLARE @RolAnterior NVARCHAR(100) = (
            SELECT r.Nombre_Rol
            FROM tbl_usuarios_login u
            JOIN tbl_roles r ON u.Id_Rol = r.Id_Rol
            WHERE u.Id_Usuario = @Id_Usuario
        );

        -- Actualizar persona solo con los campos que se pasan
        UPDATE tbl_personas
        SET Primer_Nombre = COALESCE(@Primer_Nombre, Primer_Nombre),
            Segundo_Nombre = COALESCE(@Segundo_Nombre, Segundo_Nombre),
            Primer_Apellido = COALESCE(@Primer_Apellido, Primer_Apellido),
            Segundo_Apellido = COALESCE(@Segundo_Apellido, Segundo_Apellido),
            Correo = COALESCE(@Correo, Correo),
            Cedula = COALESCE(@Cedula, Cedula),
            Telefono = COALESCE(@Telefono, Telefono),
            Direccion = COALESCE(@Direccion, Direccion),
            Id_Departamento = COALESCE(@Id_Departamento, Id_Departamento),
            Fecha_Modificacion = GETDATE()
        WHERE Id_Persona = @Id_Persona;

        -- Actualizar rol solo si se envía
        IF @Id_Rol IS NOT NULL
        BEGIN
            UPDATE tbl_usuarios_login
            SET Id_Rol = @Id_Rol,
                Fecha_Modificacion = GETDATE()
            WHERE Id_Usuario = @Id_Usuario;
        END

        -- Datos nuevos para auditoría
        DECLARE @DatosNuevos NVARCHAR(MAX) = (
            SELECT CONCAT(
                'Nombre: ', Primer_Nombre, ' ', Segundo_Nombre, ' ', Primer_Apellido, ' ', Segundo_Apellido,
                ', Correo: ', Correo, ', Cédula: ', Cedula, ', Teléfono: ', Telefono,
                ', Dirección: ', Direccion, ', Departamento: ', Id_Departamento,
                ', Rol: ', r.Nombre_Rol
            )
            FROM tbl_personas p
            JOIN tbl_usuarios_login u ON p.Id_Persona = u.Id_Persona
            JOIN tbl_roles r ON u.Id_Rol = r.Id_Rol
            WHERE u.Id_Usuario = @Id_Usuario
        );

        -- Auditoría
        INSERT INTO tbl_auditoria (
            Id_Usuario,
            Nombre_Tabla,
            Tipo_Operacion,
            Descripcion,
            Dato_Anterior,
            Dato_Nuevo
        )
        VALUES (
            @Id_Usuario_Modificador,
            'tbl_usuarios_login / tbl_personas',
            'UPDATE',
            'Modificación de datos generales de usuario',
            CONCAT(@DatosAnteriores, ', Rol: ', @RolAnterior),
            @DatosNuevos
        );

        COMMIT TRAN;

        SET @o_Num = 1;
        SET @o_Msg = 'Datos actualizados correctamente.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        SET @o_Num = -99;
        SET @o_Msg = ERROR_MESSAGE();
    END CATCH
END

-- Declarar variables de salida
DECLARE @o_Num INT, @o_Msg NVARCHAR(255);

-- Ejecutar SP solo actualizando Correo y Telefono
EXEC sp_usuarios_ActualizarDatos
    @Id_Usuario = 5,               -- Usuario que se va a actualizar
    @Telefono = '555-9999',
    @Id_Usuario_Modificador = 1,   -- Usuario que realiza la modificación
    @o_Num = @o_Num OUTPUT,
    @o_Msg = @o_Msg OUTPUT;

-- Mostrar resultados
SELECT @o_Num AS Numero, @o_Msg AS Mensaje;


-- =====================================================

CREATE OR ALTER PROCEDURE sp_usuarios_CambiarEstado
(
    @Id_Usuario INT,
    @NuevoEstado NVARCHAR(50),
    @Id_Auditor INT,
    @o_Num INT OUTPUT,
    @o_Msg NVARCHAR(255) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar que quien ejecuta sea auditor
        IF NOT EXISTS (
            SELECT 1 FROM tbl_usuarios_login
            WHERE Id_Usuario = @Id_Auditor
              AND Id_Rol = (SELECT Id_Rol FROM tbl_roles WHERE Nombre_Rol = 'Auditor')
        )
        BEGIN
            SET @o_Num = -1;
            SET @o_Msg = 'Solo un auditor puede cambiar el estado de usuarios.';
            RETURN;
        END

        DECLARE @Id_Estado INT = (
            SELECT Id_Estado FROM tbl_estados WHERE Nombre_Estado = @NuevoEstado
        );

        UPDATE tbl_usuarios_login
        SET Id_Estado = @Id_Estado,
            Fecha_Modificacion = GETDATE()
        WHERE Id_Usuario = @Id_Usuario;

        -- Auditoría
        INSERT INTO tbl_auditoria (
            Id_Usuario,
            Nombre_Tabla,
            Tipo_Operacion,
            Descripcion,
            Dato_Nuevo
        )
        VALUES (
            @Id_Auditor,
            'tbl_usuarios_login',
            'UPDATE',
            'Cambio de estado de usuario',
            CONCAT('Usuario: ', @Id_Usuario, ', Nuevo Estado: ', @NuevoEstado)
        );

        SET @o_Num = 1;
        SET @o_Msg = 'Estado actualizado correctamente.';
    END TRY
    BEGIN CATCH
        SET @o_Num = -99;
        SET @o_Msg = ERROR_MESSAGE();
    END CATCH
END

DECLARE @resultado INT;
DECLARE @mensaje NVARCHAR(255);

EXEC sp_usuarios_CambiarEstado
    @Id_Usuario = 24,          -- ID del usuario cuyo estado quieres cambiar
    @NuevoEstado = 'Activo',  -- o 'Activo'
    @Id_Auditor = 3,          -- ID del auditor (el que ejecuta la acción)
    @o_Num = @resultado OUTPUT,
    @o_Msg = @mensaje OUTPUT;

SELECT @resultado AS Resultado, @mensaje AS Mensaje;

select * from tbl_usuarios_login
-- =====================================================

CREATE OR ALTER PROCEDURE sp_usuarios_Filtrar
(
    @Nombre NVARCHAR(100) = NULL,
    @Correo NVARCHAR(100) = NULL,
    @Rol NVARCHAR(100) = NULL,
    @Estado NVARCHAR(50) = NULL,
    @Id_Usuario INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.Primer_Nombre,
        p.Segundo_Nombre,
        p.Primer_Apellido,
        p.Segundo_Apellido,
        p.Correo,
        p.Cedula,
        tc.Nombre_Tipo_Catalogo AS Departamento,
        r.Nombre_Rol AS Rol,
        e.Nombre_Estado AS Estado,
        u.Id_Usuario
    FROM tbl_usuarios_login u
    JOIN tbl_personas p ON u.Id_Persona = p.Id_Persona
    JOIN tbl_roles r ON u.Id_Rol = r.Id_Rol
    JOIN tbl_estados e ON u.Id_Estado = e.Id_Estado
    LEFT JOIN tbl_tipos_catalogos tc ON p.Id_Departamento = tc.Id_Tipo_Catalogo
    WHERE (@Nombre IS NULL OR p.Primer_Nombre LIKE '%' + @Nombre + '%')
      AND (@Correo IS NULL OR p.Correo LIKE '%' + @Correo + '%')
      AND (@Rol IS NULL OR r.Nombre_Rol = @Rol)
      AND (@Estado IS NULL OR e.Nombre_Estado = @Estado)
      AND (@Id_Usuario IS NULL OR u.Id_Usuario = @Id_Usuario);
END

-- =====================================================



CREATE OR ALTER PROCEDURE sp_usuarios_ObtenerDetalle_Reporte
(
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @Estado INT = NULL -- 1 = Activo, 0 = Inactivo, NULL = Todos
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.Id_Usuario AS IdUsuario,
        p.Primer_Nombre AS PrimerNombre,
        p.Segundo_Nombre AS SegundoNombre,
        p.Primer_Apellido AS PrimerApellido,
        p.Segundo_Apellido AS SegundoApellido,
        p.Cedula,
        p.Direccion,
        p.Telefono,
        p.Correo,

        tc.Nombre_Tipo_Catalogo AS Departamento,
        r.Nombre_Rol AS Rol,

        CASE 
            WHEN e.Nombre_Estado = 'Activo' THEN 'Activo'
            WHEN e.Nombre_Estado = 'Inactivo' THEN 'Inactivo'
            ELSE e.Nombre_Estado
        END AS Estado

    FROM tbl_usuarios_login u
    INNER JOIN tbl_personas p ON u.Id_Persona = p.Id_Persona
    INNER JOIN tbl_roles r ON u.Id_Rol = r.Id_Rol
    INNER JOIN tbl_estados e ON u.Id_Estado = e.Id_Estado
    LEFT JOIN tbl_tipos_catalogos tc ON p.Id_Departamento = tc.Id_Tipo_Catalogo

    WHERE
        -- FILTRO DE FECHA (fecha de creación del usuario)
        (@FechaInicio IS NULL OR u.Fecha_Creacion >= @FechaInicio)
        AND (@FechaFin IS NULL OR u.Fecha_Creacion <= DATEADD(DAY, 1, @FechaFin))

        -- FILTRO DE ESTADO (activo / inactivo / todos)
        AND (@Estado IS NULL 
            OR ( @Estado = 1 AND e.Nombre_Estado = 'Activo')
            OR ( @Estado = 0 AND e.Nombre_Estado = 'Inactivo')
        )

    ORDER BY p.Primer_Nombre, p.Primer_Apellido;
END
GO

