


USE Viajes;
GO

CREATE OR ALTER TRIGGER trg_Auditoria_Flujo_Aprobaciones
ON tbl_flujo_aprobaciones
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @IdUsuario INT = CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

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
                'tbl_flujo_aprobaciones',
                'UPDATE',
                'Modificación en flujo de aprobación',
                (
                    SELECT  
                        d.Id_Flujo_Aprobacion AS Id_Flujo_Aprobacion,
                        d.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        d.Id_Autorizador AS Id_Autorizador,
                        d.Nivel_Aprobacion AS Nivel_Aprobacion,
                        d.Id_Estado_Decision AS Id_Estado_Decision,
                        d.Comentarios AS Comentarios,
                        d.Fecha_Decision AS Fecha_Decision,
                        d.Activo AS Activo
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                (
                    SELECT  
                        i.Id_Flujo_Aprobacion AS Id_Flujo_Aprobacion,
                        i.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        i.Id_Autorizador AS Id_Autorizador,
                        i.Nivel_Aprobacion AS Nivel_Aprobacion,
                        i.Id_Estado_Decision AS Id_Estado_Decision,
                        i.Comentarios AS Comentarios,
                        i.Fecha_Decision AS Fecha_Decision,
                        i.Activo AS Activo
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                GETDATE(),
                sv.Id_Empleado
            FROM inserted i
            INNER JOIN deleted d ON i.Id_Flujo_Aprobacion = d.Id_Flujo_Aprobacion
            INNER JOIN tbl_solicitudes_viajes sv ON i.Id_Solicitud_Viaje = sv.Id_Solicitud_Viaje;
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
                'tbl_flujo_aprobaciones',
                'INSERT',
                'Registro de aprobación en flujo',
                NULL,
                (
                    SELECT  
                        i.Id_Flujo_Aprobacion AS Id_Flujo_Aprobacion,
                        i.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        i.Id_Autorizador AS Id_Autorizador,
                        i.Nivel_Aprobacion AS Nivel_Aprobacion,
                        i.Id_Estado_Decision AS Id_Estado_Decision,
                        i.Comentarios AS Comentarios,
                        i.Fecha_Decision AS Fecha_Decision,
                        i.Activo AS Activo
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                GETDATE(),
                sv.Id_Empleado
            FROM inserted i
            INNER JOIN tbl_solicitudes_viajes sv ON i.Id_Solicitud_Viaje = sv.Id_Solicitud_Viaje;
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
                'tbl_flujo_aprobaciones',
                'DELETE',
                'Eliminación de aprobación en flujo',
                (
                    SELECT  
                        d.Id_Flujo_Aprobacion AS Id_Flujo_Aprobacion,
                        d.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        d.Id_Autorizador AS Id_Autorizador,
                        d.Nivel_Aprobacion AS Nivel_Aprobacion,
                        d.Id_Estado_Decision AS Id_Estado_Decision,
                        d.Comentarios AS Comentarios,
                        d.Fecha_Decision AS Fecha_Decision,
                        d.Activo AS Activo
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                NULL,
                GETDATE(),
                sv.Id_Empleado
            FROM deleted d
            INNER JOIN tbl_solicitudes_viajes sv ON d.Id_Solicitud_Viaje = sv.Id_Solicitud_Viaje;
        END
    END TRY
    BEGIN CATCH
        PRINT 'ERROR EN TRIGGER DE AUDITORÍA tbl_flujo_aprobaciones: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
