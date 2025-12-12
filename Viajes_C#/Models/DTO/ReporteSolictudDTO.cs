namespace Viajes.Models.DTO
{
    public class ReporteSolictudDTO
    {
       
        
            // 🟦 Tabla 1: Datos generales de la solicitud
            public int IdSolicitudViaje { get; set; }
            public int IdEmpleado { get; set; }
            public string Departamento { get; set; }
            public string Motivo { get; set; }
            public string Destino { get; set; }
            public DateTime FechaInicioViaje { get; set; }
            public DateTime FechaFinViaje { get; set; }
            public decimal PresupuestoEstimado { get; set; }
            public string NombreEmpleado { get; set; }


        // Tabla 2: Gastos estimados
        public List<GastoEstimadoDTO> GastosEstimados { get; set; } = new();

            // Tabla 2 (paralela): Gastos reales
            public List<GastoRealDTO> GastosReales { get; set; } = new();

            //  Tabla 3: Comparación de gastos + flujo de aprobación
            public ComparacionGastoDTO ComparacionGasto { get; set; }
        

    }
    public class GastoEstimadoDTO
    {
        public string TipoGasto { get; set; }
        public string Descripcion { get; set; }
        public decimal Monto { get; set; }
    }


    public class GastoRealDTO
    {
        public string TipoGasto { get; set; }
        public string Descripcion { get; set; }
        public decimal MontoReal { get; set; }
        public decimal? Retorno { get; set; }
    }

    public class ComparacionGastoDTO
    {
        public decimal? Reembolso { get; set; }
        public decimal? ExcesoGasto { get; set; }
        public string JustificacionExceso { get; set; }

        // Flujo de aprobación
        public List<AprobacionDTO> Aprobaciones { get; set; } = new();
    }
    public class AprobacionDTO
    {
        public int IdAutorizador { get; set; }
        public string Comentario { get; set; }
        public int NivelAprobacion { get; set; } // 1 = Supervisor, 2 = Administrador
        public string EstadoDecision { get; set; } // Aprobado, Rechazado, etc.
    }




}
