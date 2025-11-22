namespace Viajes.Models.DTO
{
    public class UsuarioEstadoDTO
    {
       
            public int IdUsuario { get; set; }
            public string EstadoActual { get; set; }
            public string NuevoEstado { get; set; }
            public int IdAuditor { get; set; } // quien ejecuta el cambio
        
    }
}
