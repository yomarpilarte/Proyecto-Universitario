namespace Viajes.Models.DTO
{
    public class SolicitudCrearDTO
    {
        public string Destino { get; set; } = "";
        public string Motivo { get; set; } = "";
        public string FechaInicioViaje { get; set; } = "";
        public string FechaFinViaje { get; set; } = "";
        public decimal PresupuestoEstimado { get; set; }
    }
}

