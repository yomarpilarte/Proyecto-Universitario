
USE Viajes
GO
CREATE OR ALTER VIEW vw_auditoria_filtrable AS
SELECT
    Id_Auditoria,
    Id_Usuario,
    Id_Usuario_Afectado,
    Nombre_Tabla,
    Tipo_Operacion,
    Descripcion,
    Dato_Anterior,
    Dato_Nuevo,
    Fecha_Accion
FROM tbl_auditoria;
GO
CREATE OR ALTER PROCEDURE sp_ConsultarAuditoriaFiltrada
    @FechaDesde DATETIME = NULL,
    @FechaHasta DATETIME = NULL,
    @NombreTabla NVARCHAR(100) = NULL,
    @TipoOperacion NVARCHAR(50) = NULL,
    @IdUsuarioAccion INT = NULL,
    @IdUsuarioAfectado INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id_Auditoria,
        Id_Usuario,
        Id_Usuario_Afectado,
        Nombre_Tabla,
        Tipo_Operacion,
        Descripcion,
        Dato_Anterior,
        Dato_Nuevo,
        Fecha_Accion,

        -- Cambios anteriores con sufijo dinámico
        CASE 
            WHEN Tipo_Operacion = 'UPDATE' THEN dbo.fn_CompararDatos(Dato_Anterior, Dato_Nuevo, 'Anterior')
            WHEN Tipo_Operacion = 'DELETE' THEN Dato_Anterior
            WHEN Tipo_Operacion = 'INSERT' THEN NULL
            ELSE ''
        END AS Cambios_Anterior,

        -- Cambios nuevos con sufijo dinámico
        CASE 
            WHEN Tipo_Operacion = 'UPDATE' THEN dbo.fn_CompararDatos(Dato_Anterior, Dato_Nuevo, 'Nuevo')
            WHEN Tipo_Operacion = 'INSERT' THEN Dato_Nuevo
            WHEN Tipo_Operacion = 'DELETE' THEN NULL
            ELSE ''
        END AS Cambios_Nuevo

    FROM tbl_auditoria
    WHERE (@FechaDesde IS NULL OR Fecha_Accion >= @FechaDesde)
      AND (@FechaHasta IS NULL OR Fecha_Accion <= @FechaHasta)
      AND (@NombreTabla IS NULL OR Nombre_Tabla = @NombreTabla)
      AND (@TipoOperacion IS NULL OR Tipo_Operacion = @TipoOperacion)
      AND (@IdUsuarioAccion IS NULL OR Id_Usuario = @IdUsuarioAccion)
      AND (@IdUsuarioAfectado IS NULL OR Id_Usuario_Afectado = @IdUsuarioAfectado)
    ORDER BY Fecha_Accion DESC;
END;
GO




select * from tbl_auditoria

--Funcion escalar para comparar los datos JSON

CREATE OR ALTER FUNCTION fn_CompararDatos
(
    @Antes NVARCHAR(MAX),
    @Despues NVARCHAR(MAX),
    @Modo NVARCHAR(10) -- 'Anterior' o 'Nuevo'
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Resultado NVARCHAR(MAX) = '';
    DECLARE @Campos TABLE (
        Nombre NVARCHAR(100) COLLATE Modern_Spanish_CI_AS,
        ValorAntes NVARCHAR(MAX) COLLATE Modern_Spanish_CI_AS,
        ValorDespues NVARCHAR(MAX) COLLATE Modern_Spanish_CI_AS
    );

    -- Cargar valores anteriores
    INSERT INTO @Campos (Nombre, ValorAntes)
    SELECT [key] COLLATE Modern_Spanish_CI_AS, CAST([value] AS NVARCHAR(MAX)) COLLATE Modern_Spanish_CI_AS
    FROM OPENJSON(@Antes);

    -- Actualizar con valores nuevos
    UPDATE c
    SET ValorDespues = CAST(d.[value] AS NVARCHAR(MAX)) COLLATE Modern_Spanish_CI_AS
    FROM @Campos c
    INNER JOIN OPENJSON(@Despues) d ON c.Nombre = d.[key] COLLATE Modern_Spanish_CI_AS;

    -- Generar resultado con etiquetas
  IF @Modo = 'Anterior'
BEGIN
    SELECT @Resultado = STRING_AGG(CONCAT(c.Nombre, 'Anterior: ', c.ValorAntes), ', ')
    FROM @Campos c
    WHERE ISNULL(c.ValorAntes, '') <> ISNULL(c.ValorDespues, '');
END
ELSE IF @Modo = 'Nuevo'
BEGIN
    SELECT @Resultado = STRING_AGG(CONCAT(c.Nombre, 'Nuevo: ', c.ValorDespues), ', ')
    FROM @Campos c
    WHERE ISNULL(c.ValorAntes, '') <> ISNULL(c.ValorDespues, '');
END


    RETURN @Resultado;
END;
GO



