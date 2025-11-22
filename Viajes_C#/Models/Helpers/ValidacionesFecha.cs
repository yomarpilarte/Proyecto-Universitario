using Microsoft.Data.SqlClient;

namespace Viajes.Models.Helpers
{
    public static class ValidacionesFecha
    {
        
        public static bool RangoValido(DateTime? fechaInicio, DateTime? fechaFin)
        {
            if (fechaInicio == null || fechaFin == null)
                return true; // No validar si falta una fecha

            return fechaInicio <= fechaFin;
        }

        public static bool NoEsFuturo(DateTime? fecha)
        {
            if (fecha == null)
                return true;

            return fecha <= DateTime.Now.Date;
        }
    

        public static int ObtenerAnoMinimo()
        {
            int ano = DateTime.Now.Year;

            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand(@"SELECT MIN(YEAR(Fecha_Creacion)) AS AnoMinimo 
                                             FROM tbl_usuarios_login", conexion);

                conexion.Open();
                var result = comando.ExecuteScalar();
                if (result != DBNull.Value)
                    ano = Convert.ToInt32(result);
            }
            catch
            {
                ano = DateTime.Now.Year;
            }

            return ano;
        }
    }
}
