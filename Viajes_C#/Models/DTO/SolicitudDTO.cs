namespace Viajes.Models.DTO
{
    public class SolicitudDTO
    {
        public int IdSolicitudViaje { get; set; }
        public int IdEmpleado { get; set; }
        public int IdTipoDepartamento { get; set; }
        public string Destino { get; set; } = "";
        public string Motivo { get; set; } = "";
        public DateOnly FechaInicioViaje { get; set; }
        public DateOnly FechaFinViaje { get; set; }
        public decimal PresupuestoEstimado { get; set; }
        public int IdEstado { get; set; }
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaModificacion { get; set; }
        public string EstadoNombre { get; set; } // nuevo campo para mostrar el nombre del estado

        public string FechaInicioViajeStr { get; set; }
        public string FechaFinViajeStr { get; set; }
        public string FechaCreacionStr { get; set; }
        public string FechaModificacionStr { get; set; }

      
    }

    public class ResultadoSolicitudes
    {
        public int Num { get; set; }
        public string Msg { get; set; }
        public List<SolicitudDTO> Solicitudes { get; set; }
    }

}

