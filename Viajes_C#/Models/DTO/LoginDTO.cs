namespace Viajes.Models.DTO
{
    public class LoginDTO
    {
        public int Resultado { get; set; }
        public string Mensaje { get; set; } = "";
        public bool RequiereCambio { get; set; }
        public int UsuarioId { get; set; }
        public string Nombre_Rol { get; set; }


    }
}
