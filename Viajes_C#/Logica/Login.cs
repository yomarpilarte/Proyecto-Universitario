using Microsoft.Data.SqlClient;
using System.Data;
using System.Text.RegularExpressions;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;

namespace Viajes.Logica
{
    public class LoginService
    {

        public static LoginDTO ValidarLogin(string usuario, string contrasena)
        {
            using var conexion = Conexion.ObtenerConexion();
            using var comando = new SqlCommand("sp_usuarios_Login", conexion)
            {
                CommandType = CommandType.StoredProcedure
            };

            // Parámetros del SP
            comando.Parameters.AddWithValue("@Usuario", usuario);
            comando.Parameters.AddWithValue("@Contrasena", contrasena);

            var o_Num = new SqlParameter("@o_Num", SqlDbType.Int) { Direction = ParameterDirection.Output };
            var o_Msg = new SqlParameter("@o_Msg", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };
            var requerirCambio = new SqlParameter("@RequerirCambio", SqlDbType.Bit) { Direction = ParameterDirection.Output };

            comando.Parameters.Add(o_Num);
            comando.Parameters.Add(o_Msg);
            comando.Parameters.Add(requerirCambio);

            conexion.Open();
            comando.ExecuteNonQuery();

            // Obtener el Id del usuario validado
            int resultadoSP = o_Num.Value != DBNull.Value ? (int)o_Num.Value : -1;

            // 🔹 Consulta adicional para obtener el rol del usuario
            string rol = "";
            if (resultadoSP > 0)
            {
                using var cmdRol = new SqlCommand(
                    "SELECT r.Nombre_Rol FROM tbl_usuarios_login u " +
                    "JOIN tbl_roles r ON u.Id_Rol = r.Id_Rol " +
                    "WHERE u.Id_Usuario = @IdUsuario", conexion);
                cmdRol.Parameters.AddWithValue("@IdUsuario", resultadoSP);
                rol = cmdRol.ExecuteScalar()?.ToString() ?? "";
            }

            return new LoginDTO
            {
                Resultado = resultadoSP,
                Mensaje = o_Msg.Value?.ToString() ?? "Error desconocido",
                RequiereCambio = requerirCambio.Value != DBNull.Value && Convert.ToBoolean(requerirCambio.Value),
                UsuarioId = resultadoSP,
                Nombre_Rol = rol
            };
        }



        public static (int resultado, string mensaje) ActualizarPassword(int usuarioId, string usuario, string nuevaContrasena)
        {
            if (!ValidacionContrasena.EsContrasenaValida(nuevaContrasena, usuario, out string mensaje))
                return (-1, mensaje);

            using var conexion = Conexion.ObtenerConexion();
            using var comando = new SqlCommand("sp_usuarios_ActualizarPassword", conexion)
            {
                CommandType = CommandType.StoredProcedure
            };

            comando.Parameters.AddWithValue("@Id_Usuario", usuarioId);
            comando.Parameters.AddWithValue("@NuevaContrasena", nuevaContrasena);

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



    }
}
