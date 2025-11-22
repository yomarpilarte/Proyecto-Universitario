

USE Viajes
GO
CREATE OR ALTER TRIGGER trg_Auditoria_Personas
ON tbl_personas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    --BEGIN TRY
        --DECLARE @IdUsuario INT = CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));
BEGIN TRY
        DECLARE @IdUsuarioRaw SQL_VARIANT = SESSION_CONTEXT(N'IdUsuario');
        DECLARE @IdUsuario INT = NULL;

        IF @IdUsuarioRaw IS NOT NULL
            SET @IdUsuario = TRY_CONVERT(INT, @IdUsuarioRaw)
        ------------------------------------------------------------------
        -- UPDATE
        ------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO tbl_auditoria (
                Id_Usuario,
                Nombre_Tabla,
                Tipo_Operacion,
                Descripcion,
                Dato_Anterior,
                Dato_Nuevo,
                Fecha_Accion,
                Id_Usuario_Afectado
            )
            SELECT
                @IdUsuario,
                'tbl_personas',
                'UPDATE',
                'Actualización de datos en tbl_personas',
                
                -- JSON anterior con claves consistentes
                (
                    SELECT  
                        d.Primer_Nombre AS Primer_Nombre,
                        d.Segundo_Nombre AS Segundo_Nombre,
                        d.Primer_Apellido AS Primer_Apellido,
                        d.Segundo_Apellido AS Segundo_Apellido,
                        d.Cedula AS Cedula,
                        d.Direccion AS Direccion,
                        d.Telefono AS Telefono,
                        d.Correo AS Correo,
                        d.Fecha_Modificacion AS Fecha_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                
                -- JSON nuevo con las mismas claves
                (
                    SELECT  
                        i.Primer_Nombre AS Primer_Nombre,
                        i.Segundo_Nombre AS Segundo_Nombre,
                        i.Primer_Apellido AS Primer_Apellido,
                        i.Segundo_Apellido AS Segundo_Apellido,
                        i.Cedula AS Cedula,
                        i.Direccion AS Direccion,
                        i.Telefono AS Telefono,
                        i.Correo AS Correo,
                        i.Fecha_Modificacion AS Fecha_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                
                GETDATE(),
                ul.Id_Usuario
            FROM inserted i
            INNER JOIN deleted d ON i.Id_Persona = d.Id_Persona
            LEFT JOIN tbl_usuarios_login ul ON ul.Id_Persona = i.Id_Persona;
        END

        ------------------------------------------------------------------
        -- INSERT
        ------------------------------------------------------------------
        ELSE IF EXISTS (SELECT 1 FROM inserted)
        BEGIN
            INSERT INTO tbl_auditoria (
                Id_Usuario,
                Nombre_Tabla,
                Tipo_Operacion,
                Descripcion,
                Dato_Anterior,
                Dato_Nuevo,
                Fecha_Accion,
                Id_Usuario_Afectado
            )
            SELECT
                @IdUsuario,
                'tbl_personas',
                'INSERT',
                'Nuevo registro en tbl_personas',
                NULL,
                (
                    SELECT  
                        i.Primer_Nombre AS Primer_Nombre,
                        i.Segundo_Nombre AS Segundo_Nombre,
                        i.Primer_Apellido AS Primer_Apellido,
                        i.Segundo_Apellido AS Segundo_Apellido,
                        i.Cedula AS Cedula,
                        i.Direccion AS Direccion,
                        i.Telefono AS Telefono,
                        i.Correo AS Correo,
                        i.Fecha_Modificacion AS Fecha_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                GETDATE(),
                ul.Id_Usuario
            FROM inserted i
            LEFT JOIN tbl_usuarios_login ul ON ul.Id_Persona = i.Id_Persona;
        END

        ------------------------------------------------------------------
        -- DELETE
        ------------------------------------------------------------------
        ELSE IF EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO tbl_auditoria (
                Id_Usuario,
                Nombre_Tabla,
                Tipo_Operacion,
                Descripcion,
                Dato_Anterior,
                Dato_Nuevo,
                Fecha_Accion,
                Id_Usuario_Afectado
            )
            SELECT
                @IdUsuario,
                'tbl_personas',
                'DELETE',
                'Borrado de registro en tbl_personas',
                (
                    SELECT  
                        d.Primer_Nombre AS Primer_Nombre,
                        d.Segundo_Nombre AS Segundo_Nombre,
                        d.Primer_Apellido AS Primer_Apellido,
                        d.Segundo_Apellido AS Segundo_Apellido,
                        d.Cedula AS Cedula,
                        d.Direccion AS Direccion,
                        d.Telefono AS Telefono,
                        d.Correo AS Correo,
                        d.Fecha_Modificacion AS Fecha_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                NULL,
                GETDATE(),
                ul.Id_Usuario
            FROM deleted d
            LEFT JOIN tbl_usuarios_login ul ON ul.Id_Persona = d.Id_Persona;
        END
    END TRY
    BEGIN CATCH
        PRINT 'ERROR EN TRIGGER DE AUDITORÍA tbl_personas: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


