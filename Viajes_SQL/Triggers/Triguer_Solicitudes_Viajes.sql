
USE Viajes
GO
CREATE OR ALTER TRIGGER trg_Auditoria_SolicitudesViajes
ON tbl_solicitudes_viajes
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @IdUsuario INT = CONVERT(INT, SESSION_CONTEXT(N'IdUsuario'));

        -- ==========================================
        -- UPDATE
        -- ==========================================
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
                'tbl_solicitudes_viajes',
                'UPDATE',
                'Actualización de solicitud de viaje',
                (
                    SELECT  
                        d.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        d.Id_Empleado AS Id_Empleado,
                        d.Id_Tipo_Departamento AS Id_Tipo_Departamento,
                        d.Destino AS Destino,
                        d.Motivo AS Motivo,
                        d.Fecha_Inicio_Viaje AS Fecha_Inicio_Viaje,
                        d.Fecha_Fin_Viaje AS Fecha_Fin_Viaje,
                        d.Presupuesto_Estimado AS Presupuesto_Estimado,
                        d.Fecha_Modificacion AS Fecha_Modificacion,
                        d.Id_Estado AS Id_Estado
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                (
                    SELECT  
                        i.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        i.Id_Empleado AS Id_Empleado,
                        i.Id_Tipo_Departamento AS Id_Tipo_Departamento,
                        i.Destino AS Destino,
                        i.Motivo AS Motivo,
                        i.Fecha_Inicio_Viaje AS Fecha_Inicio_Viaje,
                        i.Fecha_Fin_Viaje AS Fecha_Fin_Viaje,
                        i.Presupuesto_Estimado AS Presupuesto_Estimado,
                        i.Fecha_Modificacion AS Fecha_Modificacion,
                        i.Id_Estado AS Id_Estado
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                GETDATE(),
                i.Id_Empleado
            FROM inserted i
            INNER JOIN deleted d ON i.Id_Solicitud_Viaje = d.Id_Solicitud_Viaje;
        END

        -- ==========================================
        -- INSERT
        -- ==========================================
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
                'tbl_solicitudes_viajes',
                'INSERT',
                'Nueva solicitud de viaje creada',
                NULL,
                (
                    SELECT  
                        i.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        i.Id_Empleado AS Id_Empleado,
                        i.Id_Tipo_Departamento AS Id_Tipo_Departamento,
                        i.Destino AS Destino,
                        i.Motivo AS Motivo,
                        i.Fecha_Inicio_Viaje AS Fecha_Inicio_Viaje,
                        i.Fecha_Fin_Viaje AS Fecha_Fin_Viaje,
                        i.Presupuesto_Estimado AS Presupuesto_Estimado,
                        i.Fecha_Modificacion AS Fecha_Modificacion,
                        i.Id_Estado AS Id_Estado
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                GETDATE(),
                i.Id_Empleado
            FROM inserted i;
        END

        -- ==========================================
        -- DELETE
        -- ==========================================
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
                'tbl_solicitudes_viajes',
                'DELETE',
                'Solicitud de viaje eliminada',
                (
                    SELECT  
                        d.Id_Solicitud_Viaje AS Id_Solicitud_Viaje,
                        d.Id_Empleado AS Id_Empleado,
                        d.Id_Tipo_Departamento AS Id_Tipo_Departamento,
                        d.Destino AS Destino,
                        d.Motivo AS Motivo,
                        d.Fecha_Inicio_Viaje AS Fecha_Inicio_Viaje,
                        d.Fecha_Fin_Viaje AS Fecha_Fin_Viaje,
                        d.Presupuesto_Estimado AS Presupuesto_Estimado,
                        d.Fecha_Modificacion AS Fecha_Modificacion,
                        d.Id_Estado AS Id_Estado
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                ),
                NULL,
                GETDATE(),
                d.Id_Empleado
            FROM deleted d;
        END
    END TRY
    BEGIN CATCH
        PRINT 'Error en auditoría de solicitudes de viajes: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
