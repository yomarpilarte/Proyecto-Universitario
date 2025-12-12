namespace Viajes.Models.DTO
{
    public class GastoDTO
    {
        
            public int IdSolicitudViaje { get; set; }   
            public int IdTipoGasto { get; set; }        
            public string DescripcionGasto { get; set; } = string.Empty; 
            public decimal MontoGasto { get; set; }    
        

    }
    public class GastoReal
    {
        public int IdSolicitudViaje { get; set; }       // Solicitud a la que pertenece
        public int IdGastoSupuesto { get; set; }        // Gasto supuesto que se está justificando
        public int IdTipoGasto { get; set; }            // Tipo de gasto (debe coincidir con el supuesto)
        public string DescripcionReal { get; set; } = string.Empty; // Descripción del gasto real
        public decimal MontoReal { get; set; }          // Monto del gasto real
        public decimal? Retorno { get; set; } // puede ser null
        public string RutaComprobante { get; set; } = string.Empty; // Ruta del comprobante en el sistema
    }

    public class JustificacionDto
    {
        public int IdSolicitud { get; set; }
        public string JustificacionExceso { get; set; }
    }



}
