CREATE DATABASE Viajes;
GO

USE Viajes;
GO

-- =====================================================

-- =====================================================

CREATE TABLE tbl_estados (
    Id_Estado INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Estado NVARCHAR(50) NOT NULL UNIQUE,  -- Ej: Pendiente, Aprobado, Rechazado, Activo, Inactivo
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME NULL,
    Activo BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE tbl_roles (
    Id_Rol INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Rol NVARCHAR(100) NOT NULL UNIQUE,    -- Ej: Administrador, Supervisor, Empleado
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME NULL,
    Activo BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE tbl_catalogos (
    Id_Catalogo INT PRIMARY KEY IDENTITY(1,1),
    Nombre_Catalogo NVARCHAR(100) NOT NULL,      -- Ej: gastos, departamentos
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
    Activo BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE tbl_tipos_catalogos (
    Id_Tipo_Catalogo INT PRIMARY KEY IDENTITY(1,1),
	Id_Catalogo INT REFERENCES tbl_catalogos(Id_Catalogo),
    Nombre_Tipo_Catalogo NVARCHAR(100) NOT NULL, --  Ej: transporte, contabilidad
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
    Activo BIT NOT NULL DEFAULT 1
);
GO

-- =====================================================

-- =====================================================

CREATE TABLE tbl_personas (
    Id_Persona INT PRIMARY KEY IDENTITY(1,1),
    Primer_Nombre NVARCHAR(100) NOT NULL,
    Segundo_Nombre NVARCHAR(100) NOT NULL,
    Primer_Apellido NVARCHAR(100) NOT NULL,
    Segundo_Apellido NVARCHAR(100) NOT NULL,
    Cedula  NVARCHAR(100) NOT NULL,
    Direccion  NVARCHAR(100) NOT NULL,
    Telefono  NVARCHAR(100) NOT NULL,
	Correo  NVARCHAR(100) NOT NULL,
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
	Fecha_Modificacion DATETIME NULL

);
GO

CREATE TABLE tbl_usuarios_login (
    Id_Usuario INT PRIMARY KEY IDENTITY(1,1),
    Id_Persona INT REFERENCES tbl_personas(Id_Persona),
	Id_Rol INT REFERENCES tbl_roles(Id_Rol),
    Usuario NVARCHAR(100) NOT NULL UNIQUE,
    Contrasena VARBINARY(64) NOT NULL UNIQUE,  -- Hash de la contraseña
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME NULL,
    Id_Estado INT REFERENCES tbl_estados(Id_Estado)
);
GO

-- =====================================================

-- =====================================================

CREATE TABLE tbl_solicitudes_viajes (
    Id_Solicitud_Viaje INT PRIMARY KEY IDENTITY(1,1),
    Id_Empleado INT REFERENCES tbl_usuarios_login(Id_Usuario),
    Id_Tipo_Departamento INT REFERENCES tbl_tipos_catalogos(Id_Tipo_Catalogo),
    Destino NVARCHAR(255) NOT NULL,
    Motivo NVARCHAR(MAX) NOT NULL,
    Fecha_Inicio_Viaje DATETIME NOT NULL,
    Fecha_Fin_Viaje DATETIME NOT NULL,
    Presupuesto_Estimado DECIMAL(12,2) NOT NULL CHECK (Presupuesto_Estimado > 0),
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME NULL,
    Id_Estado INT REFERENCES tbl_estados(Id_Estado)
);
GO
select * from tbl_solicitudes_viajes
CREATE TABLE tbl_flujo_aprobaciones (
    Id_Flujo_Aprobacion INT PRIMARY KEY IDENTITY(1,1),
    Id_Solicitud_Viaje INT REFERENCES tbl_solicitudes_viajes(Id_Solicitud_Viaje),
    Id_Autorizador INT REFERENCES tbl_usuarios_login(Id_Usuario),
    Nivel_Aprobacion INT DEFAULT 1,  -- Ej: 1 Supervisor, 2 Gerente
    Id_Estado_Decision INT REFERENCES tbl_estados(Id_Estado),
    Comentarios NVARCHAR(MAX),
    Fecha_Decision DATETIME NOT NULL DEFAULT GETDATE(),
    Activo BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE tbl_gastos_viaje (
    Id_Gasto_Viaje INT PRIMARY KEY IDENTITY(1,1),
    Id_Solicitud_Viaje INT REFERENCES tbl_solicitudes_viajes(Id_Solicitud_Viaje),
    Id_Tipo_Gasto INT REFERENCES tbl_tipos_catalogos(Id_Tipo_Catalogo),
    Descripcion_Gasto NVARCHAR(255),
    Monto_Gasto DECIMAL(12,2) NOT NULL CHECK (Monto_Gasto > 0),
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME NULL
);
GO

CREATE TABLE tbl_gastos_viaje_reales (
    Id_Gasto_Viaje_real INT PRIMARY KEY IDENTITY(1,1),
    Id_Solicitud_Viaje INT REFERENCES tbl_solicitudes_viajes(Id_Solicitud_Viaje),
    Id_Tipo_Gasto INT REFERENCES tbl_tipos_catalogos(Id_Tipo_Catalogo),
    Descripcion_Gasto NVARCHAR(255),
    Monto_Gasto DECIMAL(12,2) NOT NULL CHECK (Monto_Gasto > 0),
	Retorno DECIMAL(12,2)  NULL,            -- cuando el empleado regresa todo el dinero por viaje cancelado.
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME NULL
);
GO

CREATE TABLE tbl_comparacion_gastos (
    Id_comparacion INT PRIMARY KEY IDENTITY(1,1),
    Id_Solicitud_Viaje INT REFERENCES tbl_solicitudes_viajes(Id_Solicitud_Viaje),
    Reembolso DECIMAL(12,2)  NULL,          -- cuando el empleado regresa dinero sobrante 
	Exceso_gasto DECIMAL(12,2)  NULL,       -- cuando el empleado usa mas dinero del presupuestado
    Justificacion_exceso NVARCHAR(255),
    Fecha_Creacion DATETIME NOT NULL DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME NULL
);
GO

CREATE TABLE tbl_auditoria (
    Id_Auditoria INT PRIMARY KEY IDENTITY(1,1),
    Id_Usuario INT NULL REFERENCES tbl_usuarios_login(Id_Usuario),
    Nombre_Tabla NVARCHAR(100) NULL,
    Tipo_Operacion NVARCHAR(50) NOT NULL,  -- Ej: INSERT, UPDATE, DELETE, LOGIN, LOGOUT, REPORTE
    Descripcion NVARCHAR(MAX) NULL,        -- Detalles del cambio o acción realizada
    Dato_Anterior NVARCHAR(MAX) NULL,     -- Datos anteriores (solo en UPDATE o DELETE)
    Dato_Nuevo NVARCHAR(MAX) NULL,        -- Datos nuevos (solo en INSERT o UPDATE)
    Fecha_Accion DATETIME NOT NULL DEFAULT GETDATE()
);
GO



ALTER TABLE tbl_usuarios_login
ADD 
    FechaExpiracionTemp DATETIME NULL,  -- Para usuarios temporales (administrador/auditor inicial)
    ContraseñaTemporal BIT DEFAULT 1,  -- Indica si la contraseña debe ser reemplazada
    FechaUltimoCambio DATETIME NULL;   -- Para registro de cuándo se cambió la contraseña


ALTER TABLE tbl_personas
ADD Id_Departamento INT NULL REFERENCES tbl_tipos_catalogos(Id_Tipo_Catalogo);

ALTER TABLE tbl_auditoria
ADD Id_Usuario_Afectado INT NULL; -- Puede ser NULL si no aplica (ej. login/logout)

select * from tbl_auditoria


SELECT *
FROM tbl_auditoria
WHERE Nombre_Tabla = 'tbl_usuarios_login / tbl_personas'
  AND Tipo_Operacion = 'UPDATE'
ORDER BY Fecha_Accion DESC;
