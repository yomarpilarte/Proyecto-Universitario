
USE Viajes
GO
CREATE OR ALTER TRIGGER trg_Auditoria_Gastos
ON tbl_gastos_viaje
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
                'tbl_gastos_viaje',
                'UPDATE',
                'Modificación de gasto de viaje',
                (
                    SELECT  
                        d.Id_Gasto_Viaje AS Id_Gasto_Viaje,
                        d.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        d.Id_Tipo_Gasto AS Id_Tipo_Gasto,
                        d.Descripcion_Gasto AS Descripcion_Gasto,
                        d.Monto_Gasto AS Monto_Gasto,
                        d.Fecha_Modificacion AS Fecha_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                (
                    SELECT  
                        i.Id_Gasto_Viaje AS Id_Gasto_Viaje,
                        i.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        i.Id_Tipo_Gasto AS Id_Tipo_Gasto,
                        i.Descripcion_Gasto AS Descripcion_Gasto,
                        i.Monto_Gasto AS Monto_Gasto,
                        i.Fecha_Modificacion AS Fecha_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                GETDATE(),
                sv.Id_Empleado
            FROM inserted i
            INNER JOIN deleted d ON i.Id_Gasto_Viaje = d.Id_Gasto_Viaje
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
                'tbl_gastos_viaje',
                'INSERT',
                'Nuevo gasto de viaje registrado',
                NULL,
                (
                    SELECT  
                        i.Id_Gasto_Viaje AS Id_Gasto_Viaje,
                        i.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        i.Id_Tipo_Gasto AS Id_Tipo_Gasto,
                        i.Descripcion_Gasto AS Descripcion_Gasto,
                        i.Monto_Gasto AS Monto_Gasto,
                        i.Fecha_Modificacion AS Fecha_Modificacion
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
                'tbl_gastos_viaje',
                'DELETE',
                'Eliminación de gasto de viaje',
                (
                    SELECT  
                        d.Id_Gasto_Viaje AS Id_Gasto_Viaje,
                        d.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        d.Id_Tipo_Gasto AS Id_Tipo_Gasto,
                        d.Descripcion_Gasto AS Descripcion_Gasto,
                        d.Monto_Gasto AS Monto_Gasto,
                        d.Fecha_Modificacion AS Fecha_Modificacion
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
        PRINT 'ERROR EN TRIGGER DE AUDITORÍA tbl_gastos_viaje: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
