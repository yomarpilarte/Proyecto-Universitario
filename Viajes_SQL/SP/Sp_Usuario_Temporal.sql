

USE Viajes;
GO

-- SP para crear usuario temporal
CREATE OR ALTER PROCEDURE sp_CrearUsuarioTemporal
(
    @IdPersona INT,
    @IdRol INT,               -- Rol: Administrador o Auditor
    @Usuario NVARCHAR(100),
    @Contrasena NVARCHAR(255), -- Contraseña temporal en texto plano
    @HorasExpiracion INT = 1   -- Tiempo de vida del usuario en horas
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO tbl_usuarios_login
    (
        Id_Persona,
        Id_Rol,
        Usuario,
        Contrasena,
        Id_Estado,
        ContraseñaTemporal,
        FechaExpiracionTemp,
        Fecha_Creacion
    )
    VALUES
    (
        @IdPersona,
        @IdRol,
        @Usuario,
        HASHBYTES('SHA2_256', @Contrasena + @Usuario),
        1, -- Activo
        1, -- Contraseña temporal
        DATEADD(HOUR, @HorasExpiracion, GETDATE()),
        GETDATE()
    );
END
GO

-- SP para eliminar usuarios temporales expirados
CREATE OR ALTER PROCEDURE sp_EliminarUsuariosTemporalesExpirados
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM tbl_usuarios_login
    WHERE FechaExpiracionTemp IS NOT NULL
      AND FechaExpiracionTemp <= GETDATE();
END
GO
