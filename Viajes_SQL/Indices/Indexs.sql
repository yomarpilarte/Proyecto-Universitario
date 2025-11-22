USE Viajes;
GO

-- tbl_usuarios_login
CREATE NONCLUSTERED INDEX IX_UsuariosLogin_Persona ON tbl_usuarios_login(Id_Persona);
CREATE NONCLUSTERED INDEX IX_UsuariosLogin_RolEstado ON tbl_usuarios_login(Id_Rol, Id_Estado);

-- tbl_solicitudes_viajes
CREATE NONCLUSTERED INDEX IX_Solicitudes_EmpleadoEstado ON tbl_solicitudes_viajes(Id_Empleado, Id_Estado);
CREATE NONCLUSTERED INDEX IX_Solicitudes_TipoDepartamento ON tbl_solicitudes_viajes(Id_Tipo_Departamento);

-- tbl_flujo_aprobaciones
CREATE NONCLUSTERED INDEX IX_Flujo_Solicitud ON tbl_flujo_aprobaciones(Id_Solicitud_Viaje);
CREATE NONCLUSTERED INDEX IX_Flujo_Autorizador ON tbl_flujo_aprobaciones(Id_Autorizador);
CREATE NONCLUSTERED INDEX IX_Flujo_EstadoDecision ON tbl_flujo_aprobaciones(Id_Estado_Decision);

-- tbl_gastos_viaje
CREATE NONCLUSTERED INDEX IX_Gastos_Solicitud ON tbl_gastos_viaje(Id_Solicitud_Viaje);
CREATE NONCLUSTERED INDEX IX_Gastos_TipoGasto ON tbl_gastos_viaje(Id_Tipo_Gasto);

-- tbl_gastos_viaje_reales
CREATE NONCLUSTERED INDEX IX_GastosReales_Solicitud ON tbl_gastos_viaje_reales(Id_Solicitud_Viaje);
CREATE NONCLUSTERED INDEX IX_GastosReales_TipoGasto ON tbl_gastos_viaje_reales(Id_Tipo_Gasto);

-- tbl_comparacion_gastos
CREATE NONCLUSTERED INDEX IX_Comparacion_Solicitud ON tbl_comparacion_gastos(Id_Solicitud_Viaje);

-- tbl_personas
CREATE NONCLUSTERED INDEX IX_Personas_Cedula ON tbl_personas(Cedula);
CREATE NONCLUSTERED INDEX IX_Personas_Nombres ON tbl_personas(Primer_Nombre, Primer_Apellido);

-- tbl_tipos_catalogos
CREATE NONCLUSTERED INDEX IX_TiposCatalogo_Catalogo ON tbl_tipos_catalogos(Id_Catalogo);

-- tbl_catalogos
CREATE NONCLUSTERED INDEX IX_Catalogos_Nombre ON tbl_catalogos(Nombre_Catalogo);

-- tbl_estados
CREATE NONCLUSTERED INDEX IX_Estados_Nombre ON tbl_estados(Nombre_Estado);

-- tbl_roles
CREATE NONCLUSTERED INDEX IX_Roles_Nombre ON tbl_roles(Nombre_Rol);

-- tbl_auditoria
CREATE NONCLUSTERED INDEX IX_Auditoria_Usuario_Fecha ON tbl_auditoria(Id_Usuario, Fecha_Accion DESC);
CREATE NONCLUSTERED INDEX IX_Auditoria_TipoOperacion ON tbl_auditoria(Tipo_Operacion);

