



USE Viajes;
GO
CREATE OR ALTER TRIGGER trg_Auditoria_Comparacion_Gastos
ON tbl_comparacion_gastos
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
                'tbl_comparacion_gastos',
                'UPDATE',
                'Modificación en comparación de gastos',
                (
                    SELECT  
                        d.Id_comparacion AS Id_comparacion,
                        d.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        d.Reembolso AS Reembolso,
                        d.Exceso_gasto AS Exceso_gasto,
                        d.Justificacion_exceso AS Justificacion_exceso,
                        d.Fecha_Modificacion AS Fecha_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                (
                    SELECT  
                        i.Id_comparacion AS Id_comparacion,
                        i.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        i.Reembolso AS Reembolso,
                        i.Exceso_gasto AS Exceso_gasto,
                        i.Justificacion_exceso AS Justificacion_exceso,
                        i.Fecha_Modificacion AS Fecha_Modificacion
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                GETDATE(),
                sv.Id_Empleado
            FROM inserted i
            INNER JOIN deleted d ON i.Id_comparacion = d.Id_comparacion
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
                'tbl_comparacion_gastos',
                'INSERT',
                'Registro de comparación de gastos',
                NULL,
                (
                    SELECT  
                        i.Id_comparacion AS Id_comparacion,
                        i.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        i.Reembolso AS Reembolso,
                        i.Exceso_gasto AS Exceso_gasto,
                        i.Justificacion_exceso AS Justificacion_exceso,
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
                'tbl_comparacion_gastos',
                'DELETE',
                'Eliminación de comparación de gastos',
                (
                    SELECT  
                        d.Id_comparacion AS Id_comparacion,
                        d.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        d.Reembolso AS Reembolso,
                        d.Exceso_gasto AS Exceso_gasto,
                        d.Justificacion_exceso AS Justificacion_exceso,
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
        PRINT 'ERROR EN TRIGGER DE AUDITORÍA tbl_comparacion_gastos: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

