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
    }
}

