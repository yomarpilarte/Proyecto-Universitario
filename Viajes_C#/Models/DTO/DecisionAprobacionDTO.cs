namespace Viajes.Models.DTO
{
    public class DecisionAprobacionDTO
    {
        public int IdSolicitudViaje { get; set; }
        public int IdAutorizador { get; set; }
        public int NivelAprobacion { get; set; } // 1 es supervisor, 2 es admin
        public int IdEstadoDecision { get; set; } // 5 aprobado, 6 rechazado
        public string Comentarios { get; set; } = "";
    }
}

