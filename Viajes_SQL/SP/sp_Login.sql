
USE Viajes;
GO

CREATE OR ALTER PROCEDURE sp_usuarios_Login
(
    @Usuario NVARCHAR(100),
    @Contrasena NVARCHAR(255),
    @o_Num INT = NULL OUTPUT,
    @o_Msg NVARCHAR(255) = NULL OUTPUT,
    @RequerirCambio BIT = 0 OUTPUT      -- NUEVO: indica si debe cambiar contraseña
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HashContrasena VARBINARY(64) = HASHBYTES('SHA2_256', @Contrasena + @Usuario);

    DECLARE @UsuarioDB TABLE
    (
        Id_Usuario INT,
        Id_Persona INT,
        Id_Rol INT,
        Usuario NVARCHAR(100),
        Id_Estado INT,
        ContraseñaTemporal BIT,
        FechaExpiracionTemp DATETIME
    );

    INSERT INTO @UsuarioDB
    SELECT 
        Id_Usuario,
        Id_Persona,
        Id_Rol,
        Usuario,
        Id_Estado,
        ContraseñaTemporal,
        FechaExpiracionTemp
    FROM tbl_usuarios_login WITH (NOLOCK)
    WHERE Usuario = @Usuario AND Contrasena = @HashContrasena;

    IF NOT EXISTS(SELECT 1 FROM @UsuarioDB)
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = '¡Usuario o Contraseña incorrectos!';
        RETURN;
    END

    -- Verificar estado
    IF (SELECT Id_Estado FROM @UsuarioDB) <> 1
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'No puede iniciar sesión, contacte al auditor.';
        RETURN;
    END

    -- Verificar expiración de usuario temporal
    IF EXISTS(SELECT 1 FROM @UsuarioDB WHERE FechaExpiracionTemp IS NOT NULL AND FechaExpiracionTemp < GETDATE())
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Usuario temporal expirado, contacte al administrador.';
        RETURN;
    END

    -- Verificar si debe cambiar la contraseña
    IF EXISTS(SELECT 1 FROM @UsuarioDB WHERE ContraseñaTemporal = 1)
    BEGIN
        SET @RequerirCambio = 1;
        SET @o_Num = (SELECT Id_Usuario FROM @UsuarioDB);
        SET @o_Msg = 'Debe cambiar su contraseña por seguridad.';
        RETURN;
    END

    -- Login exitoso
    SET @o_Num = (SELECT Id_Usuario FROM @UsuarioDB);
    SET @o_Msg = '¡INICIO DE SESIÓN EXITOSO!';
END
GO


   -- SP para actualizar contrasena
CREATE OR ALTER PROCEDURE sp_usuarios_ActualizarPassword
(
    @Id_Usuario INT,
    @NuevaContrasena NVARCHAR(255),
    @o_Num INT OUTPUT,
    @o_Msg NVARCHAR(255) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Usuario NVARCHAR(100) = (SELECT Usuario FROM tbl_usuarios_login WHERE Id_Usuario = @Id_Usuario);
    IF @Usuario IS NULL
    BEGIN
        SET @o_Num = -1;
        SET @o_Msg = 'Usuario no encontrado.';
        RETURN;
    END

    DECLARE @Hash VARBINARY(64) = HASHBYTES('SHA2_256', @NuevaContrasena + @Usuario);

    UPDATE tbl_usuarios_login
    SET Contrasena = @Hash,
        ContraseñaTemporal = 0,
        FechaExpiracionTemp = NULL
    WHERE Id_Usuario = @Id_Usuario;

    SET @o_Num = 1;
    SET @o_Msg = 'Contraseña actualizada correctamente.';
END