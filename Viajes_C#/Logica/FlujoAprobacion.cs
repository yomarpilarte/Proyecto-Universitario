using Microsoft.Data.SqlClient;
using System.Data;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;

namespace Viajes.Logica
{
    public class FlujoAprobacion
    {
        public static (int resultado, string mensaje) RegistrarDecision(DecisionAprobacionDTO dto)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_flujo_RegistrarDecision", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Solicitud_Viaje", dto.IdSolicitudViaje);
                comando.Parameters.AddWithValue("@Id_Autorizador", dto.IdAutorizador);
                comando.Parameters.AddWithValue("@Nivel_Aprobacion", dto.NivelAprobacion);
                comando.Parameters.AddWithValue("@Id_Estado_Decision", dto.IdEstadoDecision);
                comando.Parameters.AddWithValue("@Comentarios", string.IsNullOrWhiteSpace(dto.Comentarios) ? (object)DBNull.Value : dto.Comentarios);

                var o_Num = new SqlParameter("@o_Num", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var o_Msg = new SqlParameter("@o_Msg", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };

                comando.Parameters.Add(o_Num);
                comando.Parameters.Add(o_Msg);

                conexion.Open();
                comando.ExecuteNonQuery();

                return (
                    resultado: o_Num.Value != DBNull.Value ? (int)o_Num.Value : -1,
                    mensaje: o_Msg.Value?.ToString() ?? "Error desconocido"
                );
            }
            catch (Exception ex)
            {
                return (-99, "Error interno: " + ex.Message);
            }
        }
    }
}

