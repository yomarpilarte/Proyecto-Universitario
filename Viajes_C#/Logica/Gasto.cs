using Microsoft.Data.SqlClient;
using System.Data;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;

namespace Viajes.Logica
{
    public class Gasto
    {
        // agregar gastos supuestos
        public static (int resultado, string mensaje) AgregarGasto(GastoDTO dto)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_gastos_Agregar", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Solicitud_Viaje", dto.IdSolicitudViaje);
                comando.Parameters.AddWithValue("@Id_Tipo_Gasto", dto.IdTipoGasto);
                comando.Parameters.AddWithValue("@Descripcion_Gasto", dto.DescripcionGasto ?? string.Empty);
                comando.Parameters.AddWithValue("@Monto_Gasto", dto.MontoGasto);

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

        //Agregar gastos reales
        public static (int resultado, string mensaje) InsertarGastoReal(
    int idSolicitud, int idTipoGasto, string descripcion, decimal monto, decimal? retorno = null)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_gastos_InsertarReal", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Solicitud_Viaje", idSolicitud);
                comando.Parameters.AddWithValue("@Id_Tipo_Gasto", idTipoGasto);
                comando.Parameters.AddWithValue("@Descripcion_Gasto", descripcion);
                comando.Parameters.AddWithValue("@Monto_Gasto", monto);
                comando.Parameters.AddWithValue("@Retorno", (object)retorno ?? DBNull.Value);

                var o_Num = new SqlParameter("@o_Num", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var o_Msg = new SqlParameter("@o_Msg", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };

                comando.Parameters.Add(o_Num);
                comando.Parameters.Add(o_Msg);

                conexion.Open();
                comando.ExecuteNonQuery();

                return (
                    resultado: o_Num.Value != DBNull.Value ? (int)o_Num.Value : -99,
                    mensaje: o_Msg.Value?.ToString() ?? "Error desconocido"
                );
            }
            catch (Exception ex)
            {
                return (-99, "Error interno: " + ex.Message);
            }
        }



        // Listar gastos supuestos
        public static (DataTable tabla, int resultado, string mensaje) ListarSupuestos(int idSolicitud)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_gastos_ListarSupuestos", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Solicitud_Viaje", idSolicitud);

                var tabla = new DataTable();
                using var adaptador = new SqlDataAdapter(comando);

                conexion.Open();
                adaptador.Fill(tabla);

                return (
                    tabla: tabla,
                    resultado: 1,
                    mensaje: "Consulta ejecutada correctamente"
                );
            }
            catch (Exception ex)
            {
                return (new DataTable(), -99, "Error interno: " + ex.Message);
            }
        }



        // Listar gastos reales
        public static (DataTable tabla, int resultado, string mensaje) ListarReales(int idSolicitud)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_gastos_ListarReales", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Solicitud_Viaje", idSolicitud);

                var tabla = new DataTable();
                using var adaptador = new SqlDataAdapter(comando);

                conexion.Open();
                adaptador.Fill(tabla);

                return (
                    tabla: tabla,
                    resultado: 1,
                    mensaje: "Consulta ejecutada correctamente"
                );
            }
            catch (Exception ex)
            {
                return (new DataTable(), -99, "Error interno: " + ex.Message);
            }
        }

        // Comparar gastos reales con los supuestos
        public static (int resultado, string mensaje) CompararTotales(int idSolicitud, string justificacionExceso = null)
        {
            try
            {
                Console.WriteLine("ID que se envía al SP: " + idSolicitud);

                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_gastos_CompararTotales", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Solicitud_Viaje", idSolicitud);
                comando.Parameters.AddWithValue("@JustificacionExceso", (object)justificacionExceso ?? DBNull.Value);

                var o_Num = new SqlParameter("@o_Num", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var o_Msg = new SqlParameter("@o_Msg", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };

                comando.Parameters.Add(o_Num);
                comando.Parameters.Add(o_Msg);

                conexion.Open();
                comando.ExecuteNonQuery();

                return (
                    resultado: o_Num.Value != DBNull.Value ? (int)o_Num.Value : -99,
                    mensaje: o_Msg.Value?.ToString() ?? "Error desconocido"
                );
            }
            catch (Exception ex)
            {
                return (-99, "Error interno: " + ex.Message);
            }
        }


        public static void CambiarEstadoSolicitud(int idSolicitud, int nuevoEstado)
        {
            using var conexion = Conexion.ObtenerConexion();
            using var comando = new SqlCommand(
                "UPDATE tbl_solicitudes_viajes SET Id_Estado = @Estado WHERE Id_Solicitud_Viaje = @Id",
                conexion
            );

            comando.Parameters.AddWithValue("@Estado", nuevoEstado);
            comando.Parameters.AddWithValue("@Id", idSolicitud);

            conexion.Open();
            comando.ExecuteNonQuery();
        }

    }
}
