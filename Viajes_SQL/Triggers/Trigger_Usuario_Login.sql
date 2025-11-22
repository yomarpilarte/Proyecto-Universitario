
USE Viajes
GO

CREATE OR ALTER TRIGGER trg_Auditoria_Usuarios
ON tbl_usuarios_login
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
        --------------------------------------------------------------------
        -- OPERACIÓN UPDATE
        --------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO tbl_auditoria
            (
                Id_Usuario,
                Nombre_Tabla,
                Tipo_Operacion,
                Descripcion,
                Dato_Anterior,
                Dato_Nuevo,
                Fecha_Accion
            )
            SELECT
                i.Id_Usuario,
                'tbl_usuarios_login',
                'UPDATE',
                'Actualización de usuario',
                
                -- JSON datos anteriores (claves consistentes)
                (
                    SELECT  
                        d.Usuario AS Usuario,
                        d.Id_Rol AS Rol,
                        d.Id_Estado AS Estado,
                        d.Fecha_Modificacion AS Ultima_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                
                -- JSON datos nuevos (claves iguales)
                (
                    SELECT  
                        i.Usuario AS Usuario,
                        i.Id_Rol AS Rol,
                        i.Id_Estado AS Estado,
                        i.Fecha_Modificacion AS Ultima_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                
                GETDATE()
            FROM inserted i
            INNER JOIN deleted d ON d.Id_Usuario = i.Id_Usuario;
        END

        --------------------------------------------------------------------
        -- OPERACIÓN INSERT
        --------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        BEGIN
            INSERT INTO tbl_auditoria
            (
                Id_Usuario,
                Nombre_Tabla,
                Tipo_Operacion,
                Descripcion,
                Dato_Nuevo,
                Fecha_Accion
            )
            SELECT
                i.Id_Usuario,
                'tbl_usuarios_login',
                'INSERT',
                'Nuevo usuario creado',
                
                (
                    SELECT  
                        i.Usuario AS Usuario,
                        i.Id_Rol AS Rol,
                        i.Id_Estado AS Estado,
                        i.Fecha_Modificacion AS Ultima_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                
                GETDATE()
            FROM inserted i;
        END

        --------------------------------------------------------------------
        -- OPERACIÓN DELETE
        --------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        BEGIN
            INSERT INTO tbl_auditoria
            (
                Id_Usuario,
                Nombre_Tabla,
                Tipo_Operacion,
                Descripcion,
                Dato_Anterior,
                Fecha_Accion
            )
            SELECT
                d.Id_Usuario,
                'tbl_usuarios_login',
                'DELETE',
                'Usuario eliminado',
                
                (
                    SELECT  
                        d.Usuario AS Usuario,
                        d.Id_Rol AS Rol,
                        d.Id_Estado AS Estado,
                        d.Fecha_Modificacion AS Ultima_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                
                GETDATE()
            FROM deleted d;
        END

    END TRY
    BEGIN CATCH
        PRINT 'Error en trigger de auditoría de usuarios: ' + ERROR_MESSAGE();
    END CATCH;

END;
GO

