USE Viajes
GO

INSERT INTO tbl_estados (Nombre_Estado, Fecha_Creacion, Fecha_Modificacion, Activo) VALUES
('Activo', GETDATE(), GETDATE(),1),
('Inactivo', GETDATE(), GETDATE(),1),
('Pendiente', GETDATE(), GETDATE(),1),
('Aprobado', GETDATE(), GETDATE(),1),
('Rechazado', GETDATE(), GETDATE(),1);

INSERT INTO tbl_roles (Nombre_Rol, Fecha_Creacion, Fecha_Modificacion,Activo) VALUES
('Administrador', GETDATE(), GETDATE(),1),
('Supervisor', GETDATE(), GETDATE(),1),
('Auditor', GETDATE(), GETDATE(),1),
('Empleado', GETDATE(), GETDATE(),1);

INSERT INTO tbl_catalogos (Nombre_Catalogo, Fecha_Creacion,Activo) VALUES
('Tipo de gasto', GETDATE(), 1),
('Departamentos', GETDATE(), 1);

INSERT INTO tbl_tipos_catalogos (Id_Catalogo,Nombre_Tipo_Catalogo, Fecha_Creacion, Activo) VALUES
(1, 'Transporte', GETDATE(), 1),
(1, 'Hospedaje', GETDATE(), 1),
(1, 'Alimentacion', GETDATE(), 1),
(1, 'Combustible', GETDATE(), 1),
(2, 'Ventas', GETDATE(), 1),
(2, 'Operaciones', GETDATE(), 1),
(2, 'Recursos humanos', GETDATE(), 1),
(2, 'Contabilidad y finanzas', GETDATE(), 1),
(2, 'Mantenimiento', GETDATE(), 1),
(2, 'Tecnologia y Sistema', GETDATE(), 1),
(2, 'Gerencia general', GETDATE(), 1);


INSERT INTO tbl_personas (Primer_Nombre, Segundo_Nombre, Primer_Apellido, Segundo_Apellido, Cedula, Direccion, Telefono, Correo,Id_Departamento) VALUES
(
    'Juan', 
    'Carlos', 
    'Pérez', 
    'López', 
    '001-150790-0001A', 
    'Reparto San Juan, de la Rotonda 1c. al sur, Casa L-20', 
    '8877-1234', 
    'juan.perez.l@gmail.com',
	'6'
),
(
    'María', 
    'Fernanda', 
    'García', 
    'Martínez', 
    '001-200388-0002B', 
    'Bello Horizonte, de la rotonda 2c. arriba, 1c. al lago, Casa 5', 
    '8654-3210', 
    'maria.garcia.m@gmail.com',
	'7'
),
(
    'Luis', 
    'Alberto', 
    'Rodríguez', 
    'Sánchez', 
    '002-010195-0003C', 
    'Villa Fontana, semáforos 3c. al sur, Contiguo a Farmacia', 
    '7788-9900', 
    'luis.rodriguez.s@gmail.com',
	'8'
),
(
    'Ana', 
    'Isabel', 
    'Hernández', 
    'Gómez', 
    '001-301192-0004D', 
    'Altamira, de donde fue el Cine González, 1c. al este, Casa 12', 
    '8123-4567', 
    'ana.hernandez.g@gmail.com',
	 '6'
),
(
    'Miguel', 
    'Ángel', 
    'González', 
    'Díaz', 
    '003-101285-0005E', 
    'Bolonia, del Canal 2, 3 cuadras al sur, Casa 112', 
    '7654-8901', 
    'miguel.gonzalez.d@gmail.com',
	'9'
),
(
    'Sofía', 
    'Valentina', 
    'Ramírez', 
    'Moreno', 
    '001-050600-0006F', 
    'Colonia Centroamérica, del Supermercado 1c. al oeste, Casa B-45', 
    '8901-2345', 
    'sofia.ramirez.m@gmail.com',
	'6'
),
(
    'Diego', 
    'Alejandro', 
    'Torres', 
    'Ruiz', 
    '001-121098-0007G', 
    'Linda Vista, de los semáforos, 4 cuadras al norte, M-10', 
    '2266-7788', 
    'diego.torres.r@gmail.com',
	'7'
),
(
    'Gabriela', 
    'del Carmen', 
    'Sánchez', 
    'Vásquez', 
    '441-090889-0008H', 
    'Reparto El Dorado, frente al Parque, Casa 30', 
    '8555-6677', 
    'gabriela.sanchez.v@gmail.com',
	'8'
),
(
    'Javier', 
    'Antonio', 
    'Martínez', 
    'Jiménez', 
    '001-250493-0009J', 
    'Las Colinas, del Colegio Lincoln, 200mts al este, Casa 44', 
    '7111-3344', 
    'javier.martinez.j@gmail.com',
	'6'
),
(
    'Camila', 
    'Lucía', 
    'López', 
    'Pérez', 
    '001-180901-0010K', 
    'Carretera a Masaya, Km 10.5, Residencial Las Cumbres, Lote 15', 
    '8222-4455', 
    'camila.lopez.p@gmail.com',
	'6'
);



INSERT INTO tbl_usuarios_login (Id_Persona, Id_Rol, Usuario, Contrasena, Id_Estado) VALUES
(1, 1, 'juan.perez.l', HASHBYTES('SHA2_256', N'Demo.1234' + N'juan.perez.l'), 1),
(2, 2, 'maria.garcia.m', HASHBYTES('SHA2_256', N'Demo.1234' + N'maria.garcia.m'), 1),
(3, 3, 'luis.rodriguez.s', HASHBYTES('SHA2_256', N'Demo.1234' + N'luis.rodriguez.s'), 1),
(4, 3, 'ana.hernandez.g', HASHBYTES('SHA2_256', N'Demo.1234' + N'ana.hernandez.g'), 1),
(5, 2, 'miguel.gonzalez.d', HASHBYTES('SHA2_256', N'Demo.1234' + N'miguel.gonzalez.d'), 1),
(6, 3, 'sofia.ramirez.m', HASHBYTES('SHA2_256', N'Demo.1234' + N'sofia.ramirez.m'), 1),
(7, 3, 'diego.torres.r', HASHBYTES('SHA2_256', N'Demo.1234' + N'diego.torres.r'), 1),
(8, 2, 'gabriela.sanchez.v', HASHBYTES('SHA2_256', N'Demo.1234' + N'gabriela.sanchez.v'), 1),
(9, 4, 'javier.martinez.j', HASHBYTES('SHA2_256', N'Demo.1234' + N'javier.martinez.j'), 1),
(10, 3, 'camila.lopez.p', HASHBYTES('SHA2_256', N'Demo.1234' + N'camila.lopez.p'), 1);

select * from tbl_usuarios_login



INSERT INTO tbl_solicitudes_viajes (Id_Empleado, Id_Tipo_Departamento, Destino, Motivo, Fecha_Inicio_Viaje, Fecha_Fin_Viaje, Presupuesto_Estimado, Id_Estado) VALUES
(
    3, -- Id_Empleado (Luis Rodríguez)
    6, -- Id_Tipo_Departamento (Ventas)
    'Ciudad de Panamá, Panamá', 
    'Asistir a la Conferencia Anual de Ventas LATAM y reunión con socios clave.', 
    '2025-11-20 08:00:00', 
    '2025-11-23 18:00:00', 
    1500.00, 
    3  -- solicitud pendiente a aprobacion
),
(
    4, -- Id_Empleado (Ana Hernández)
    7, -- Id_Tipo_Departamento (Operaciones)
    'San José, Costa Rica', 
    'Auditoría de procesos en la sucursal de Costa Rica y capacitación de nuevo personal de logística.', 
    '2025-11-25 07:00:00', 
    '2025-11-28 17:00:00', 
    950.50, 
    3  -- Pendiente aprobacion
);


INSERT INTO tbl_flujo_aprobaciones (Id_Solicitud_Viaje, Id_Autorizador, Nivel_Aprobacion, Id_Estado_Decision, Comentarios) VALUES 
(
    1,  -- ID de la Solicitud (de Luis Rodríguez)
    8,  -- ID del Gerente que autoriza (Gabriela Sánchez)
    1,  -- Este es el Nivel 1 de aprobación
    5,  -- ID del estado 'Aprobado' (Esta es la decisión que tomó)
    'Presupuesto y motivo revisados. Aprobado por Gerencia.'
);

EXEC sp_CrearUsuarioTemporal
    @IdPersona = 1,
    @IdRol = 1, -- Administrador
    @Usuario = 'admin_temp',
    @Contrasena = 'Temp123!',
    @HorasExpiracion = 1;







