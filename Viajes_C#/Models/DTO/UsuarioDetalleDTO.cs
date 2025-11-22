namespace Viajes.Models.DTO
{
    public class UsuarioDetalleDTO
    {
        
        public string PrimerNombre { get; set; }
        public string SegundoNombre { get; set; }
        public string PrimerApellido { get; set; }
        public string SegundoApellido { get; set; }
        public string Correo { get; set; }
        public string Cedula { get; set; }
        public string Direccion { get; set; }
        public string Telefono { get; set; }
        public string Departamento { get; set; }
        public string Rol { get; set; }
        public string Estado { get; set; }
        public int IdUsuario { get; set; }

    }

    public class ReporteUsuariosFiltro
    {
        public DateTime? FechaInicio { get; set; }
        public DateTime? FechaFin { get; set; }
        public string EstadoUsuario { get; set; }
        public string TextoBusqueda { get; set; }

        public List<UsuarioDetalleDTO> ListaUsuarios { get; set; }
    }
}
