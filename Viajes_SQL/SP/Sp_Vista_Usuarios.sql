
USE Viajes;
GO

CREATE OR ALTER VIEW vw_usuarios_detalle AS
SELECT 
    p.Primer_Nombre,
    p.Segundo_Nombre,
    p.Primer_Apellido,
    p.Segundo_Apellido,
    p.Correo,
    p.Cedula,
    tc.Nombre_Tipo_Catalogo AS Departamento,
    r.Nombre_Rol AS Rol,
    e.Nombre_Estado AS Estado,
	u.Id_Usuario
FROM tbl_usuarios_login u
JOIN tbl_personas p ON u.Id_Persona = p.Id_Persona
JOIN tbl_roles r ON u.Id_Rol = r.Id_Rol
JOIN tbl_estados e ON u.Id_Estado = e.Id_Estado
LEFT JOIN tbl_tipos_catalogos tc ON p.Id_Departamento = tc.Id_Tipo_Catalogo; 

exec vw_usuarios_detalle