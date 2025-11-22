namespace Viajes.Models.DTO
{
    public class UsuarioDTO
    {
       
            public string PrimerNombre { get; set; }
            public string SegundoNombre { get; set; }
            public string PrimerApellido { get; set; }
            public string SegundoApellido { get; set; }
            public string Cedula { get; set; }
            public string Direccion { get; set; }
            public string Telefono { get; set; }
            public string Correo { get; set; }
            public int IdDepartamento { get; set; }
            public string Usuario { get; set; }
            public string Contrasena { get; set; }
            public int IdRol { get; set; }
        public int IdUsuarioModificador { get; set; } // quien ejecuta la modificación

        public int IdUsuario { get; set; }

    }


}

