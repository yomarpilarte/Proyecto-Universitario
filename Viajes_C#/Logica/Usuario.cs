using iTextSharp.text;
using iTextSharp.text.pdf;
using iTextSharp.text.pdf.draw;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
using System.Data;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;

namespace Viajes.Logica
{
    public class Usuario
    {
        public static (int resultado, string mensaje) InsertarUsuario(UsuarioDTO dto)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_usuarios_Insertar", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Primer_Nombre", dto.PrimerNombre);
                comando.Parameters.AddWithValue("@Segundo_Nombre", dto.SegundoNombre);
                comando.Parameters.AddWithValue("@Primer_Apellido", dto.PrimerApellido);
                comando.Parameters.AddWithValue("@Segundo_Apellido", dto.SegundoApellido);
                comando.Parameters.AddWithValue("@Cedula", dto.Cedula);
                comando.Parameters.AddWithValue("@Direccion", dto.Direccion);
                comando.Parameters.AddWithValue("@Telefono", dto.Telefono);
                comando.Parameters.AddWithValue("@Correo", dto.Correo);
                comando.Parameters.AddWithValue("@Id_Departamento", dto.IdDepartamento);
                comando.Parameters.AddWithValue("@Usuario", dto.Usuario);
                comando.Parameters.AddWithValue("@Contrasena", dto.Contrasena);
                comando.Parameters.AddWithValue("@Id_Rol", dto.IdRol);

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

        public static List<UsuarioDetalleDTO> ListarUsuarios()
        {
            var lista = new List<UsuarioDetalleDTO>();

            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_usuarios_Listar", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                conexion.Open();
                using  var  reader = comando.ExecuteReader();
                while (reader.Read())
                {
                    lista.Add(new UsuarioDetalleDTO
                    {
                        PrimerNombre = reader["Primer_Nombre"].ToString(),
                        SegundoNombre = reader["Segundo_Nombre"].ToString(),
                        PrimerApellido = reader["Primer_Apellido"].ToString(),
                        SegundoApellido = reader["Segundo_Apellido"].ToString(),
                        Correo = reader["Correo"].ToString(),
                        Cedula = reader["Cedula"].ToString(),
                        Departamento = reader["Departamento"].ToString(),
                        Rol = reader["Rol"].ToString(),
                        Estado = reader["Estado"].ToString(),
                        IdUsuario = Convert.ToInt32(reader["Id_Usuario"]),
                    });
                }
            }
            catch (Exception ex)
            {
                // Log o manejo de error
                lista = new List<UsuarioDetalleDTO>(); // Retornar lista vacía en caso de error
            }

            return lista;
        }

        public static (int resultado, string mensaje) ActualizarDatosUsuario(UsuarioDTO dto)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_usuarios_ActualizarDatos", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                // Campos obligatorios
                comando.Parameters.AddWithValue("@Id_Usuario", dto.IdUsuario);
                comando.Parameters.AddWithValue("@Id_Usuario_Modificador", dto.IdUsuarioModificador);

                // Campos opcionales: si vienen vacíos o nulos, se envía DBNull para que el SP no los modifique
                comando.Parameters.AddWithValue("@Primer_Nombre", string.IsNullOrWhiteSpace(dto.PrimerNombre) ? (object)DBNull.Value : dto.PrimerNombre);
                comando.Parameters.AddWithValue("@Segundo_Nombre", string.IsNullOrWhiteSpace(dto.SegundoNombre) ? (object)DBNull.Value : dto.SegundoNombre);
                comando.Parameters.AddWithValue("@Primer_Apellido", string.IsNullOrWhiteSpace(dto.PrimerApellido) ? (object)DBNull.Value : dto.PrimerApellido);
                comando.Parameters.AddWithValue("@Segundo_Apellido", string.IsNullOrWhiteSpace(dto.SegundoApellido) ? (object)DBNull.Value : dto.SegundoApellido);
                comando.Parameters.AddWithValue("@Correo", string.IsNullOrWhiteSpace(dto.Correo) ? (object)DBNull.Value : dto.Correo);
                comando.Parameters.AddWithValue("@Cedula", string.IsNullOrWhiteSpace(dto.Cedula) ? (object)DBNull.Value : dto.Cedula);
                comando.Parameters.AddWithValue("@Telefono", string.IsNullOrWhiteSpace(dto.Telefono) ? (object)DBNull.Value : dto.Telefono);
                comando.Parameters.AddWithValue("@Direccion", string.IsNullOrWhiteSpace(dto.Direccion) ? (object)DBNull.Value : dto.Direccion);
                comando.Parameters.AddWithValue("@Id_Departamento", dto.IdDepartamento > 0 ? (object)dto.IdDepartamento : DBNull.Value);
                comando.Parameters.AddWithValue("@Id_Rol", dto.IdRol > 0 ? (object)dto.IdRol : DBNull.Value);

                // Parámetros de salida del SP
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

        public static (int resultado, string mensaje) CambiarEstadoUsuario(UsuarioEstadoDTO dto)
        {
            try
            {
                //  Evita que un usuario cambie su propio estado
                if (dto.IdUsuario == dto.IdAuditor)
                {
                    return (-1, "No puede cambiar su propio estado.");
                }

                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_usuarios_CambiarEstado", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Id_Usuario", dto.IdUsuario);
                comando.Parameters.AddWithValue("@NuevoEstado", dto.NuevoEstado);
                comando.Parameters.AddWithValue("@Id_Auditor", dto.IdAuditor);

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



        public static List<UsuarioDetalleDTO> FiltrarUsuarios(UsuarioFiltroDTO filtro)
        {
            var lista = new List<UsuarioDetalleDTO>();

            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand("sp_usuarios_Filtrar", conexion)
                {
                    CommandType = CommandType.StoredProcedure
                };

                comando.Parameters.AddWithValue("@Nombre", filtro.Nombre ?? (object)DBNull.Value);
                comando.Parameters.AddWithValue("@Correo", filtro.Correo ?? (object)DBNull.Value);
                comando.Parameters.AddWithValue("@Rol", filtro.Rol ?? (object)DBNull.Value);
                comando.Parameters.AddWithValue("@Estado", filtro.Estado ?? (object)DBNull.Value);
                comando.Parameters.AddWithValue("@Id_Usuario", filtro.IdUsuario ?? (object)DBNull.Value);

                conexion.Open();
                using var reader = comando.ExecuteReader();
                while (reader.Read())
                {
                    lista.Add(new UsuarioDetalleDTO
                    {
                        IdUsuario = Convert.ToInt32(reader["Id_Usuario"]),
                        PrimerNombre = reader["Primer_Nombre"].ToString(),
                        SegundoNombre = reader["Segundo_Nombre"].ToString(),
                        PrimerApellido = reader["Primer_Apellido"].ToString(),
                        SegundoApellido = reader["Segundo_Apellido"].ToString(),
                        Correo = reader["Correo"].ToString(),
                        Cedula = reader["Cedula"].ToString(),
                        Departamento = reader["Departamento"].ToString(),
                        Rol = reader["Rol"].ToString(),
                        Estado = reader["Estado"].ToString()
                    });
                }
            }
            catch
            {
                lista = new List<UsuarioDetalleDTO>();
            }

            return lista;
        }

        public static UsuarioDTO ObtenerUsuarioPorId(int idUsuario)
        {
            UsuarioDTO usuario = null;

            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand(@"
            SELECT u.Id_Usuario, u.Id_Rol, u.Usuario, 
                   p.Primer_Nombre, p.Segundo_Nombre, p.Primer_Apellido, p.Segundo_Apellido,
                   p.Correo, p.Cedula, p.Telefono, p.Direccion, p.Id_Departamento
            FROM tbl_usuarios_login u
            INNER JOIN tbl_personas p ON u.Id_Persona = p.Id_Persona
            WHERE u.Id_Usuario = @Id_Usuario
        ", conexion)
                {
                    CommandType = CommandType.Text
                };

                comando.Parameters.AddWithValue("@Id_Usuario", idUsuario);

                conexion.Open();
                using var reader = comando.ExecuteReader();
                if (reader.Read())
                {
                    usuario = new UsuarioDTO
                    {
                        IdUsuario = Convert.ToInt32(reader["Id_Usuario"]),
                        IdRol = reader["Id_Rol"] != DBNull.Value ? Convert.ToInt32(reader["Id_Rol"]) : 0,
                        Usuario = reader["Usuario"].ToString(),
                        PrimerNombre = reader["Primer_Nombre"].ToString(),
                        SegundoNombre = reader["Segundo_Nombre"].ToString(),
                        PrimerApellido = reader["Primer_Apellido"].ToString(),
                        SegundoApellido = reader["Segundo_Apellido"].ToString(),
                        Correo = reader["Correo"].ToString(),
                        Cedula = reader["Cedula"].ToString(),
                        Telefono = reader["Telefono"].ToString(),
                        Direccion = reader["Direccion"].ToString(),
                        IdDepartamento = reader["Id_Departamento"] != DBNull.Value ? Convert.ToInt32(reader["Id_Departamento"]) : 0
                    };
                }
            }
            catch (Exception)
            {
                // Manejo de errores
                usuario = null;
            }

            return usuario;
        }

        public static byte[] GenerarPdfUsuarios(List<UsuarioDetalleDTO> usuarios, string logoPath)
        {
            using (var ms = new MemoryStream())
            {
                Document doc = new Document(PageSize.A4, 25, 25, 30, 30);
                PdfWriter writer = PdfWriter.GetInstance(doc, ms);
                writer.PageEvent = new Pie_de_pagina(); // Pie de página
                doc.Open();

                // Encabezado con logo y título
                PdfPTable encabezado = new PdfPTable(2);
                encabezado.WidthPercentage = 100;
                encabezado.SetWidths(new float[] { 10f, 90f });

                try
                {
                    if (!File.Exists(logoPath))
                        throw new FileNotFoundException("No se encontró el logo en la ruta especificada.");

                    Image logo = Image.GetInstance(logoPath);
                    logo.ScaleAbsolute(50f, 50f);
                    logo.Alignment = Image.ALIGN_LEFT;

                    encabezado.AddCell(new PdfPCell(logo) { Border = Rectangle.NO_BORDER, Rowspan = 2 });
                }
                catch
                {
                    var mensaje = new Phrase("⚠ Logo no disponible", FontFactory.GetFont(FontFactory.HELVETICA_OBLIQUE, 8, BaseColor.Red));
                    encabezado.AddCell(new PdfPCell(mensaje) { Border = Rectangle.NO_BORDER, Rowspan = 2 });
                }

                var titulo = new Phrase("Reporte de Usuarios", FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 14));
                encabezado.AddCell(new PdfPCell(titulo) { Border = Rectangle.NO_BORDER, HorizontalAlignment = Element.ALIGN_LEFT });
                encabezado.AddCell(new PdfPCell(new Phrase("")) { Border = Rectangle.NO_BORDER });

                doc.Add(encabezado);

                // Línea divisoria
                var linea = new LineSeparator(1f, 100f, BaseColor.Gray, Element.ALIGN_CENTER, -2);
                doc.Add(new Chunk(linea));
                doc.Add(new Paragraph(" "));

                // Tabla de usuarios
                PdfPTable tabla = new PdfPTable(8); // Ajusta columnas según tu DTO
                tabla.WidthPercentage = 100;
                tabla.SetWidths(new float[] { 8, 15, 15, 15, 15, 20, 20, 15 });

                string[] encabezados = { "ID", "Nombre Completo", "Cedula", "Correo", "Teléfono", "Dirección", "Departamento", "Rol/Estado" };
                foreach (var encabezadoTexto in encabezados)
                {
                    var celda = new PdfPCell(new Phrase(encabezadoTexto, FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 9)))
                    {
                        BackgroundColor = BaseColor.LightGray
                    };
                    tabla.AddCell(celda);
                }

                foreach (var u in usuarios)
                {
                    tabla.AddCell(u.IdUsuario.ToString());
                    tabla.AddCell($"{u.PrimerNombre} {u.SegundoNombre} {u.PrimerApellido} {u.SegundoApellido}");
                    tabla.AddCell(u.Cedula);
                    tabla.AddCell(u.Correo);
                    tabla.AddCell(u.Telefono);
                    tabla.AddCell(u.Direccion);
                    tabla.AddCell(u.Departamento);
                    tabla.AddCell($"{u.Rol} / {u.Estado}");
                }

                doc.Add(tabla);
                doc.Close();

                return ms.ToArray();
            }
        }

         public List<UsuarioDetalleDTO> ObtenerDetalleUsuariosReporte(DateTime? fechaInicio, DateTime? fechaFin, int? estado)
         {
             var lista = new List<UsuarioDetalleDTO>();
             try { 
             using var conexion = Conexion.ObtenerConexion();
             using var comando = new SqlCommand("sp_usuarios_ObtenerDetalle_Reporte", conexion)

             {
                 CommandType = CommandType.StoredProcedure
             };

                     comando.Parameters.AddWithValue("@FechaInicio", (object)fechaInicio ?? DBNull.Value);
                     comando.Parameters.AddWithValue("@FechaFin", (object)fechaFin ?? DBNull.Value);
                     comando.Parameters.AddWithValue("@Estado", (object)estado ?? DBNull.Value);

                     conexion.Open();

                     using (var dr = comando.ExecuteReader())
                     {
                         while (dr.Read())
                         {
                             lista.Add(new UsuarioDetalleDTO
                             {
                                 IdUsuario = Convert.ToInt32(dr["IdUsuario"]),
                                 PrimerNombre = dr["PrimerNombre"].ToString(),
                                 SegundoNombre = dr["SegundoNombre"].ToString(),
                                 PrimerApellido = dr["PrimerApellido"].ToString(),
                                 SegundoApellido = dr["SegundoApellido"].ToString(),
                                 Cedula = dr["Cedula"].ToString(),
                                 Correo = dr["Correo"].ToString(),
                                 Telefono = dr["Telefono"].ToString(),
                                 Direccion = dr["Direccion"].ToString(),
                                 Departamento = dr["Departamento"].ToString(),
                                 Rol = dr["Rol"].ToString(),
                                 Estado = dr["Estado"].ToString()
                             });
                         }
                     }

             }
             catch
             {
                 lista = new List<UsuarioDetalleDTO>();
             }

             return lista;
         } 


    }


}
