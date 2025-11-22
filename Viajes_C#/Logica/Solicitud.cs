using Microsoft.Data.SqlClient;
using System.Data;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;

namespace Viajes.Logica
{
    public class Solicitud
    {
        public static (int resultado, string mensaje) AgregarSolicitud(SolicitudDTO dto)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_solicitudes_Agregar", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Empleado", dto.IdEmpleado);
                comando.Parameters.AddWithValue("@Id_Tipo_Departamento", dto.IdTipoDepartamento);
                comando.Parameters.AddWithValue("@Destino", dto.Destino);
                comando.Parameters.AddWithValue("@Motivo", dto.Motivo);
                comando.Parameters.AddWithValue("@Fecha_Inicio_Viaje", dto.FechaInicioViaje.ToDateTime(TimeOnly.MinValue));
                comando.Parameters.AddWithValue("@Fecha_Fin_Viaje", dto.FechaFinViaje.ToDateTime(TimeOnly.MinValue));
                comando.Parameters.AddWithValue("@Presupuesto_Estimado", dto.PresupuestoEstimado);

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

        public static List<SolicitudDTO> ListarSolicitudesPorEmpleado(int idEmpleado)
        {
            var lista = new List<SolicitudDTO>();

            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_solicitudes_FiltrarPorEmpleado", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Empleado", idEmpleado);

                var o_Num = new SqlParameter("@o_Num", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var o_Msg = new SqlParameter("@o_Msg", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };

                comando.Parameters.Add(o_Num);
                comando.Parameters.Add(o_Msg);

                conexion.Open();
                using var reader = comando.ExecuteReader();
                while (reader.Read())
                {
                    lista.Add(new SolicitudDTO
                    {
                        IdSolicitudViaje = Convert.ToInt32(reader["Id_Solicitud_Viaje"]),
                        IdEmpleado = Convert.ToInt32(reader["Id_Empleado"]),
                        IdTipoDepartamento = Convert.ToInt32(reader["Id_Tipo_Departamento"]),
                        Destino = reader["Destino"].ToString() ?? "",
                        Motivo = reader["Motivo"].ToString() ?? "",
                        FechaInicioViaje = DateOnly.FromDateTime(Convert.ToDateTime(reader["Fecha_Inicio_Viaje"])),
                        FechaFinViaje = DateOnly.FromDateTime(Convert.ToDateTime(reader["Fecha_Fin_Viaje"])),
                        PresupuestoEstimado = Convert.ToDecimal(reader["Presupuesto_Estimado"]),
                        IdEstado = Convert.ToInt32(reader["Id_Estado"]),
                        FechaCreacion = Convert.ToDateTime(reader["Fecha_Creacion"]),
                        FechaModificacion = reader["Fecha_Modificacion"] != DBNull.Value ? Convert.ToDateTime(reader["Fecha_Modificacion"]) : null
                    });
                }
            }
            catch (Exception ex)
            {
                lista = new List<SolicitudDTO>();
            }

            return lista;
        }

        public static SolicitudDTO ObtenerSolicitudPorId(int idSolicitud)
        {
            SolicitudDTO solicitud = null;

            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_solicitudes_FiltrarPorID", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Solicitud_Viaje", idSolicitud);

                var o_Num = new SqlParameter("@o_Num", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var o_Msg = new SqlParameter("@o_Msg", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };

                comando.Parameters.Add(o_Num);
                comando.Parameters.Add(o_Msg);

                conexion.Open();
                using var reader = comando.ExecuteReader();
                if (reader.Read())
                {
                    solicitud = new SolicitudDTO
                    {
                        IdSolicitudViaje = Convert.ToInt32(reader["Id_Solicitud_Viaje"]),
                        IdEmpleado = Convert.ToInt32(reader["Id_Empleado"]),
                        IdTipoDepartamento = Convert.ToInt32(reader["Id_Tipo_Departamento"]),
                        Destino = reader["Destino"].ToString() ?? "",
                        Motivo = reader["Motivo"].ToString() ?? "",
                        FechaInicioViaje = DateOnly.FromDateTime(Convert.ToDateTime(reader["Fecha_Inicio_Viaje"])),
                        FechaFinViaje = DateOnly.FromDateTime(Convert.ToDateTime(reader["Fecha_Fin_Viaje"])),
                        PresupuestoEstimado = Convert.ToDecimal(reader["Presupuesto_Estimado"]),
                        IdEstado = Convert.ToInt32(reader["Id_Estado"]),
                        FechaCreacion = Convert.ToDateTime(reader["Fecha_Creacion"]),
                        FechaModificacion = reader["Fecha_Modificacion"] != DBNull.Value ? Convert.ToDateTime(reader["Fecha_Modificacion"]) : null
                    };
                }
            }
            catch (Exception)
            {
                solicitud = null;
            }

            return solicitud;
        }

        public static List<SolicitudDTO> ListarPendientesGerente()
        {
            var lista = new List<SolicitudDTO>();

            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_solicitudes_ListarPendientesGerente", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                var o_Num = new SqlParameter("@o_Num", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var o_Msg = new SqlParameter("@o_Msg", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };

                comando.Parameters.Add(o_Num);
                comando.Parameters.Add(o_Msg);

                conexion.Open();
                using var reader = comando.ExecuteReader();
                while (reader.Read())
                {
                    lista.Add(new SolicitudDTO
                    {
                        IdSolicitudViaje = Convert.ToInt32(reader["Id_Solicitud_Viaje"]),
                        IdEmpleado = Convert.ToInt32(reader["Id_Empleado"]),
                        IdTipoDepartamento = Convert.ToInt32(reader["Id_Tipo_Departamento"]),
                        Destino = reader["Destino"].ToString() ?? "",
                        Motivo = reader["Motivo"].ToString() ?? "",
                        FechaInicioViaje = DateOnly.FromDateTime(Convert.ToDateTime(reader["Fecha_Inicio_Viaje"])),
                        FechaFinViaje = DateOnly.FromDateTime(Convert.ToDateTime(reader["Fecha_Fin_Viaje"])),
                        PresupuestoEstimado = Convert.ToDecimal(reader["Presupuesto_Estimado"]),
                        IdEstado = Convert.ToInt32(reader["Id_Estado"]),
                        FechaCreacion = Convert.ToDateTime(reader["Fecha_Creacion"]),
                        FechaModificacion = reader["Fecha_Modificacion"] != DBNull.Value ? Convert.ToDateTime(reader["Fecha_Modificacion"]) : null
                    });
                }
            }
            catch (Exception ex)
            {
                lista = new List<SolicitudDTO>();
            }

            return lista;
        }

        public static List<SolicitudDTO> ListarPendientesAdmin()
        {
            var lista = new List<SolicitudDTO>();

            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_solicitudes_ListarPendientesAdmin", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                var o_Num = new SqlParameter("@o_Num", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var o_Msg = new SqlParameter("@o_Msg", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };

                comando.Parameters.Add(o_Num);
                comando.Parameters.Add(o_Msg);

                conexion.Open();
                using var reader = comando.ExecuteReader();
                while (reader.Read())
                {
                    lista.Add(new SolicitudDTO
                    {
                        IdSolicitudViaje = Convert.ToInt32(reader["Id_Solicitud_Viaje"]),
                        IdEmpleado = Convert.ToInt32(reader["Id_Empleado"]),
                        IdTipoDepartamento = Convert.ToInt32(reader["Id_Tipo_Departamento"]),
                        Destino = reader["Destino"].ToString() ?? "",
                        Motivo = reader["Motivo"].ToString() ?? "",
                        FechaInicioViaje = DateOnly.FromDateTime(Convert.ToDateTime(reader["Fecha_Inicio_Viaje"])),
                        FechaFinViaje = DateOnly.FromDateTime(Convert.ToDateTime(reader["Fecha_Fin_Viaje"])),
                        PresupuestoEstimado = Convert.ToDecimal(reader["Presupuesto_Estimado"]),
                        IdEstado = Convert.ToInt32(reader["Id_Estado"]),
                        FechaCreacion = Convert.ToDateTime(reader["Fecha_Creacion"]),
                        FechaModificacion = reader["Fecha_Modificacion"] != DBNull.Value ? Convert.ToDateTime(reader["Fecha_Modificacion"]) : null
                    });
                }
            }
            catch (Exception ex)
            {
                lista = new List<SolicitudDTO>();
            }

            return lista;
        }

        public static int ContarSolicitudesAprobadas(int idEmpleado)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand(@"
                    SELECT COUNT(*) 
                    FROM tbl_solicitudes_viajes (NOLOCK)
                    WHERE Id_Empleado = @Id_Empleado 
                    AND Id_Estado = 5
                ", conexion)
                {
                    CommandType = CommandType.Text
                };

                comando.Parameters.AddWithValue("@Id_Empleado", idEmpleado);
                conexion.Open();
                var resultado = comando.ExecuteScalar();
                
                return resultado != null && resultado != DBNull.Value ? Convert.ToInt32(resultado) : 0;
            }
            catch (Exception)
            {
                return 0;
            }
        }

        public static int ObtenerDepartamentoEmpleado(int idEmpleado)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand(@"
                    SELECT p.Id_Departamento
                    FROM tbl_usuarios_login u
                    INNER JOIN tbl_personas p ON u.Id_Persona = p.Id_Persona
                    WHERE u.Id_Usuario = @Id_Usuario
                ", conexion)
                {
                    CommandType = CommandType.Text
                };

                comando.Parameters.AddWithValue("@Id_Usuario", idEmpleado);

                conexion.Open();
                var resultado = comando.ExecuteScalar();
                
                if (resultado != null && resultado != DBNull.Value)
                {
                    return Convert.ToInt32(resultado);
                }
                
                return 0;
            }
            catch (Exception)
            {
                return 0;
            }
        }

        public static (int resultado, string mensaje) ActualizarSolicitud(SolicitudDTO dto)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_solicitudes_Actualizar", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Solicitud_Viaje", dto.IdSolicitudViaje);
                
                if (dto.IdTipoDepartamento > 0)
                    comando.Parameters.AddWithValue("@Id_Tipo_Departamento", dto.IdTipoDepartamento);
                else
                    comando.Parameters.AddWithValue("@Id_Tipo_Departamento", DBNull.Value);
                
                if (!string.IsNullOrWhiteSpace(dto.Destino))
                    comando.Parameters.AddWithValue("@Destino", dto.Destino);
                else
                    comando.Parameters.AddWithValue("@Destino", DBNull.Value);
                
                if (!string.IsNullOrWhiteSpace(dto.Motivo))
                    comando.Parameters.AddWithValue("@Motivo", dto.Motivo);
                else
                    comando.Parameters.AddWithValue("@Motivo", DBNull.Value);
                
                if (dto.FechaInicioViaje != default(DateOnly))
                    comando.Parameters.AddWithValue("@Fecha_Inicio_Viaje", dto.FechaInicioViaje.ToDateTime(TimeOnly.MinValue));
                else
                    comando.Parameters.AddWithValue("@Fecha_Inicio_Viaje", DBNull.Value);
                
                if (dto.FechaFinViaje != default(DateOnly))
                    comando.Parameters.AddWithValue("@Fecha_Fin_Viaje", dto.FechaFinViaje.ToDateTime(TimeOnly.MinValue));
                else
                    comando.Parameters.AddWithValue("@Fecha_Fin_Viaje", DBNull.Value);
                
                if (dto.PresupuestoEstimado > 0)
                    comando.Parameters.AddWithValue("@Presupuesto_Estimado", dto.PresupuestoEstimado);
                else
                    comando.Parameters.AddWithValue("@Presupuesto_Estimado", DBNull.Value);
                
                if (dto.IdEstado > 0)
                    comando.Parameters.AddWithValue("@Id_Estado", dto.IdEstado);
                else
                    comando.Parameters.AddWithValue("@Id_Estado", DBNull.Value);

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

