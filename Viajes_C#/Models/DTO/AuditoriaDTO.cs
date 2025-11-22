namespace Viajes.Models.DTO
{
    public class AuditoriaDTO
    {
        
        
            public int Id_Auditoria { get; set; }
            public int? Id_Usuario { get; set; }
            public string? Nombre_Tabla { get; set; }
            public string? Tipo_Operacion { get; set; }
            public string? Descripcion { get; set; }
            public string? Dato_Anterior { get; set; }
            public string? Dato_Nuevo { get; set; }
            public DateTime Fecha_Accion { get; set; }
            public int? Id_Usuario_Afectado { get; set; }

        public string? Cambios_Anterior { get; set; }
        public string? Cambios_Nuevo { get; set; }




    }

    public class AuditoriaFiltroDto
    {
        public DateTime? FechaDesde { get; set; }
        public DateTime? FechaHasta { get; set; }
        public string? Nombre_Tabla { get; set; }
        public string? Tipo_Operacion { get; set; }
        public int? IdUsuarioAccion { get; set; }
        public int? IdUsuarioAfectado { get; set; }
    }

  
}
