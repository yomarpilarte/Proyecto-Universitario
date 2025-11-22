


USE Viajes;
GO
CREATE OR ALTER TRIGGER trg_Auditoria_Gastos_Reales
ON tbl_gastos_viaje_reales
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
                'tbl_gastos_viaje_reales',
                'UPDATE',
                'Modificación de gasto real de viaje',
                (
                    SELECT  
                        d.Id_Gasto_Viaje_real AS Id_Gasto_Viaje_real,
                        d.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        d.Id_Tipo_Gasto AS Id_Tipo_Gasto,
                        d.Descripcion_Gasto AS Descripcion_Gasto,
                        d.Monto_Gasto AS Monto_Gasto,
                        d.Retorno AS Retorno,
                        d.Fecha_Modificacion AS Fecha_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                (
                    SELECT  
                        i.Id_Gasto_Viaje_real AS Id_Gasto_Viaje_real,
                        i.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        i.Id_Tipo_Gasto AS Id_Tipo_Gasto,
                        i.Descripcion_Gasto AS Descripcion_Gasto,
                        i.Monto_Gasto AS Monto_Gasto,
                        i.Retorno AS Retorno,
                        i.Fecha_Modificacion AS Fecha_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                GETDATE(),
                sv.Id_Empleado
            FROM inserted i
            INNER JOIN deleted d ON i.Id_Gasto_Viaje_real = d.Id_Gasto_Viaje_real
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
                'tbl_gastos_viaje_reales',
                'INSERT',
                'Registro de gasto real de viaje',
                NULL,
                (
                    SELECT  
                        i.Id_Gasto_Viaje_real AS Id_Gasto_Viaje_real,
                        i.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        i.Id_Tipo_Gasto AS Id_Tipo_Gasto,
                        i.Descripcion_Gasto AS Descripcion_Gasto,
                        i.Monto_Gasto AS Monto_Gasto,
                        i.Retorno AS Retorno,
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
                'tbl_gastos_viaje_reales',
                'DELETE',
                'Eliminación de gasto real de viaje',
                (
                    SELECT  
                        d.Id_Gasto_Viaje_real AS Id_Gasto_Viaje_real,
                        d.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        d.Id_Tipo_Gasto AS Id_Tipo_Gasto,
                        d.Descripcion_Gasto AS Descripcion_Gasto,
                        d.Monto_Gasto AS Monto_Gasto,
                        d.Retorno AS Retorno,
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
        PRINT 'ERROR EN TRIGGER DE AUDITORÍA tbl_gastos_viaje_reales: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
