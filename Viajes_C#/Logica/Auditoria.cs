using Humanizer;
using iTextSharp.text;
using iTextSharp.text.pdf;
using iTextSharp.text.pdf.draw;
using Microsoft.CodeAnalysis.Elfie.Serialization;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Text;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;

namespace Viajes.Logica
{
    public class AuditoriaService
    {
       


         public static List<AuditoriaDTO> ConsultarAuditoriaFiltrada(AuditoriaFiltroDto filtro)
          {
              var lista = new List<AuditoriaDTO>();

              try
              {
                  using var conexion = Conexion.ObtenerConexion();
                  using var comando = new SqlCommand("sp_ConsultarAuditoriaFiltrada", conexion)
                  {
                      CommandType = CommandType.StoredProcedure
                  };

                  // Parámetros
                  comando.Parameters.AddWithValue("@FechaDesde", filtro.FechaDesde ?? (object)DBNull.Value);
                  comando.Parameters.AddWithValue("@FechaHasta", filtro.FechaHasta ?? (object)DBNull.Value);
                  comando.Parameters.AddWithValue("@NombreTabla", filtro.Nombre_Tabla ?? (object)DBNull.Value);
                  comando.Parameters.AddWithValue("@TipoOperacion", filtro.Tipo_Operacion ?? (object)DBNull.Value);
                  comando.Parameters.AddWithValue("@IdUsuarioAccion", filtro.IdUsuarioAccion ?? (object)DBNull.Value);
                  comando.Parameters.AddWithValue("@IdUsuarioAfectado", filtro.IdUsuarioAfectado ?? (object)DBNull.Value);

                  conexion.Open();
                  using var reader = comando.ExecuteReader();
                  while (reader.Read())
                  {
                      lista.Add(new AuditoriaDTO
                      {
                          Id_Auditoria = Convert.ToInt32(reader["Id_Auditoria"]),
                          Id_Usuario = int.TryParse(reader["Id_Usuario"]?.ToString(), out int Id_Usuario) ? Id_Usuario : 0,
                          Id_Usuario_Afectado = int.TryParse(reader["Id_Usuario_Afectado"]?.ToString(), out int Id_Usuario_Afectado) ? Id_Usuario_Afectado : 0,
                          Nombre_Tabla = reader["Nombre_Tabla"].ToString(),
                          Tipo_Operacion = reader["Tipo_Operacion"].ToString(),
                          Descripcion = reader["Descripcion"].ToString(),
                          Dato_Anterior = reader["Dato_Anterior"].ToString(),
                          Dato_Nuevo = reader["Dato_Nuevo"].ToString(),
                          Fecha_Accion = Convert.ToDateTime(reader["Fecha_Accion"]),
                          Cambios_Anterior = reader["Cambios_Anterior"].ToString(),
                          Cambios_Nuevo = reader["Cambios_Nuevo"].ToString()



                      });
                  }
                  
              }
              catch (Exception ex)
              {
                  // Log institucional si lo tienes
                  Console.WriteLine($"Error en auditoría: {ex.Message}");
                  lista = new List<AuditoriaDTO>();
              }

              return lista;
          }

        public static List<string> ObtenerTablasAuditoria()
        {
            var lista = new List<string>();
            using var conexion = Conexion.ObtenerConexion();
            using var comando = new SqlCommand("SELECT DISTINCT Nombre_Tabla FROM tbl_auditoria Where Nombre_Tabla != 'tbl_usuarios_login / tbl_personas' ORDER BY Nombre_Tabla", conexion);
            conexion.Open();
            using var reader = comando.ExecuteReader();
            while (reader.Read())
            {
                lista.Add(reader["Nombre_Tabla"].ToString());
            }
            return lista;
        }

        public static List<string> ObtenerOperacionesAuditoria()
        {
            var lista = new List<string>();
            using var conexion = Conexion.ObtenerConexion();
            using var comando = new SqlCommand("SELECT DISTINCT Tipo_Operacion FROM tbl_auditoria Where Tipo_operacion != 'Creación de persona' and tipo_operacion != 'Modificación de datos personales' ORDER BY Tipo_Operacion", conexion);
            conexion.Open();
            using var reader = comando.ExecuteReader();
            while (reader.Read())
            {
                lista.Add(reader["Tipo_Operacion"].ToString());
            }
            return lista;
        }

        private static string FormatearCambios(string cambiosAnterior, string cambiosNuevo)
        {
            var partesAnterior = cambiosAnterior?.Split(',') ?? Array.Empty<string>();
            var partesNuevo = cambiosNuevo?.Split(',') ?? Array.Empty<string>();

            var sb = new StringBuilder();

            for (int i = 0; i < Math.Max(partesAnterior.Length, partesNuevo.Length); i++)
            {
                if (i < partesAnterior.Length)
                    sb.AppendLine($"•  {partesAnterior[i].Trim()}");

                if (i < partesNuevo.Length)
                    sb.AppendLine($"•  {partesNuevo[i].Trim()}");

                sb.AppendLine();
            }

            return sb.ToString();
        }


        public static byte[] GenerarPdfAuditoria(List<AuditoriaDTO> registros, string logoPath)
        {
            using (var ms = new MemoryStream())
            {
                Document doc = new Document(PageSize.A4, 25, 25, 30, 30);
                PdfWriter writer = PdfWriter.GetInstance(doc, ms);
                writer.PageEvent = new Pie_de_pagina();
                doc.Open();

                // Encabezado con logo y título
                PdfPTable encabezado = new PdfPTable(2);
                encabezado.WidthPercentage = 100;
                encabezado.SetWidths(new float[] { 10f, 90f });
                try
                {
                    if (!File.Exists(logoPath))
                        throw new FileNotFoundException("Logo no encontrado en la ruta especificada.");

                    Image logo = Image.GetInstance(logoPath);
                    logo.ScaleAbsolute(50f, 50f);
                    logo.Alignment = Image.ALIGN_LEFT;

                    encabezado.AddCell(new PdfPCell(logo) { Border = Rectangle.NO_BORDER, Rowspan = 2 });
                }
                catch
                {
                    encabezado.AddCell(new PdfPCell(new Phrase("⚠ Logo no disponible", FontFactory.GetFont(FontFactory.HELVETICA_OBLIQUE, 8, BaseColor.Red)))
                    { Border = Rectangle.NO_BORDER, Rowspan = 2 });
                }

                var titulo = new Phrase("Reporte de Auditoría del Sistema", FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 14));
                encabezado.AddCell(new PdfPCell(titulo) { Border = Rectangle.NO_BORDER, HorizontalAlignment = Element.ALIGN_LEFT });
                encabezado.AddCell(new PdfPCell(new Phrase("")) { Border = Rectangle.NO_BORDER });

                doc.Add(encabezado);
                // Línea divisoria
                var linea = new LineSeparator(1f, 100f, BaseColor.Gray, Element.ALIGN_CENTER, -2);
                doc.Add(new Chunk(linea));
                doc.Add(new Paragraph(" "));

                // Tabla
                PdfPTable tabla = new PdfPTable(6);
                tabla.WidthPercentage = 100;
                tabla.SetWidths(new float[] { 10, 15, 15, 15, 25, 20 });

                string[] encabezados = { "ID", "Tabla", "Operación", "Usuario", "Fecha", "Cambios" };
                foreach (var encabezadoTexto in encabezados)
                {
                    var celda = new PdfPCell(new Phrase(encabezadoTexto, FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 10)))
                    {
                        BackgroundColor = BaseColor.LightGray
                    };
                    tabla.AddCell(celda);
                }

                foreach (var r in registros)
                {
                    tabla.AddCell(r.Id_Auditoria.ToString());
                    tabla.AddCell(r.Nombre_Tabla);
                    tabla.AddCell(r.Tipo_Operacion);
                    tabla.AddCell(r.Id_Usuario.ToString());
                    tabla.AddCell(r.Fecha_Accion.ToString("dd/MM/yyyy HH:mm"));
                    tabla.AddCell(new PdfPCell(new Phrase(FormatearCambios(r.Cambios_Anterior, r.Cambios_Nuevo), FontFactory.GetFont(FontFactory.HELVETICA, 8)))
                    {
                        MinimumHeight = 40f,
                        VerticalAlignment = Element.ALIGN_TOP
                    });
                }

                doc.Add(tabla);
                doc.Close();

                return ms.ToArray();
            }
        }




    }
}
