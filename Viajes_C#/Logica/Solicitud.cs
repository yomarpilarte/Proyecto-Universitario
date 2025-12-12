using iTextSharp.text;
using iTextSharp.text.pdf;
using iTextSharp.text.pdf.draw;
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

        public static ResultadoSolicitudes FiltrarPorEstado(SolicitudDTO filtro)
        {
            var lista = new List<SolicitudDTO>();
            string mensaje = "";
            int num = 0;

            using (var conexion = Conexion.ObtenerConexion())
            using (var comando = new SqlCommand("sp_solicitudes_FiltrarPorEstado", conexion))
            {
                comando.CommandType = CommandType.StoredProcedure;

                // Parámetros de entrada
                comando.Parameters.AddWithValue("@Id_Estado", filtro.IdEstado);
                comando.Parameters.AddWithValue("@Id_Empleado", filtro.IdEmpleado);

                // Parámetros de salida
                var oNum = new SqlParameter("@o_Num", SqlDbType.Int) { Direction = ParameterDirection.Output };
                var oMsg = new SqlParameter("@o_Msg", SqlDbType.NVarChar, 255) { Direction = ParameterDirection.Output };
                comando.Parameters.Add(oNum);
                comando.Parameters.Add(oMsg);

                conexion.Open();
                using (var reader = comando.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        lista.Add(new SolicitudDTO
                        {
                            IdSolicitudViaje = reader.GetInt32(reader.GetOrdinal("Id_Solicitud_Viaje")),
                            IdEmpleado = reader.GetInt32(reader.GetOrdinal("Id_Empleado")),
                            IdTipoDepartamento = reader.GetInt32(reader.GetOrdinal("Id_Tipo_Departamento")),
                            Destino = reader.GetString(reader.GetOrdinal("Destino")),
                            Motivo = reader.GetString(reader.GetOrdinal("Motivo")),
                            PresupuestoEstimado = reader.GetDecimal(reader.GetOrdinal("Presupuesto_Estimado")),

                            // Backend: DateOnly y DateTime
                            FechaInicioViaje = DateOnly.FromDateTime(reader.GetDateTime(reader.GetOrdinal("Fecha_Inicio_Viaje"))),
                            FechaFinViaje = DateOnly.FromDateTime(reader.GetDateTime(reader.GetOrdinal("Fecha_Fin_Viaje"))),
                            FechaCreacion = reader.GetDateTime(reader.GetOrdinal("Fecha_Creacion")),
                            FechaModificacion = reader.IsDBNull(reader.GetOrdinal("Fecha_Modificacion"))
                        ? (DateTime?)null
                        : reader.GetDateTime(reader.GetOrdinal("Fecha_Modificacion")),

                            // Frontend: strings formateados
                            FechaInicioViajeStr = reader.GetDateTime(reader.GetOrdinal("Fecha_Inicio_Viaje")).ToString("dd/MM/yyyy"),
                            FechaFinViajeStr = reader.GetDateTime(reader.GetOrdinal("Fecha_Fin_Viaje")).ToString("dd/MM/yyyy"),
                            FechaCreacionStr = reader.GetDateTime(reader.GetOrdinal("Fecha_Creacion")).ToString("dd/MM/yyyy HH:mm"),
                            FechaModificacionStr = reader.IsDBNull(reader.GetOrdinal("Fecha_Modificacion"))
                            ? ""
                            : reader.GetDateTime(reader.GetOrdinal("Fecha_Modificacion")).ToString("dd/MM/yyyy HH:mm"),

                            IdEstado = reader.GetInt32(reader.GetOrdinal("Id_Estado")),
                            EstadoNombre = reader.GetString(reader.GetOrdinal("Nombre_Estado"))
                        });

                    }
                }

                num = (int)oNum.Value;
                mensaje = (string)oMsg.Value;
            }

            return new ResultadoSolicitudes
            {
                Num = num,
                Msg = mensaje,
                Solicitudes = lista
            };
        
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
                    AND Id_Estado = 4
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

        //  Método para SP de filtros
        public async Task<List<ReporteSolictudDTO>> FiltrarSolicitudesAsync(int? idEmpleado, int? idDepartamento, int? idEstado)
        {
            var lista = new List<ReporteSolictudDTO>();

            using var conexion = Conexion.ObtenerConexion();
            using var command = new SqlCommand("sp_FiltrarSolicitudesViaje", conexion)
            {
                CommandType = CommandType.StoredProcedure
            };


            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@IdEmpleado", (object)idEmpleado ?? DBNull.Value);
                command.Parameters.AddWithValue("@IdDepartamento", (object)idDepartamento ?? DBNull.Value);
                command.Parameters.AddWithValue("@IdEstado", (object)idEstado ?? DBNull.Value);

                await conexion.OpenAsync();
                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        lista.Add(new ReporteSolictudDTO
                        {
                            IdSolicitudViaje = reader.GetInt32(0),
                            IdEmpleado = reader.GetInt32(1),
                            Departamento = reader.GetString(2),
                            Motivo = reader.GetString(3),
                            Destino = reader.GetString(4),
                            FechaInicioViaje = reader.GetDateTime(5),
                            FechaFinViaje = reader.GetDateTime(6),
                            PresupuestoEstimado = reader.GetDecimal(7)
                        });
                    }
                }
            }

            return lista;
        }

        //  Método para SP de detalle
        public async Task<ReporteSolictudDTO> ObtenerReporteSolicitudAsync(int idSolicitudViaje)
        {
            var resultado = new ReporteSolictudDTO();


            using var conexion = Conexion.ObtenerConexion();
            using var command = new SqlCommand("sp_ReporteSolicitudViaje", conexion)
            {
                CommandType = CommandType.StoredProcedure
            };

            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@IdSolicitudViaje", idSolicitudViaje);

                await conexion.OpenAsync();
                using (var reader = await command.ExecuteReaderAsync())
                {
                    // Datos generales
                    if (await reader.ReadAsync())
                    {
                        resultado.IdSolicitudViaje = reader.GetInt32(0);
                        resultado.IdEmpleado = reader.GetInt32(1);
                        resultado.Departamento = reader.GetString(2);
                        resultado.Motivo = reader.GetString(3);
                        resultado.Destino = reader.GetString(4);
                        resultado.FechaInicioViaje = reader.GetDateTime(5);
                        resultado.FechaFinViaje = reader.GetDateTime(6);
                        resultado.PresupuestoEstimado = reader.GetDecimal(7);
                    }

                    // Gastos estimados
                    if (await reader.NextResultAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            resultado.GastosEstimados.Add(new GastoEstimadoDTO
                            {
                                TipoGasto = reader.GetString(0),
                                Descripcion = reader.GetString(1),
                                Monto = reader.GetDecimal(2)
                            });
                        }
                    }

                    // Gastos reales
                    if (await reader.NextResultAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            resultado.GastosReales.Add(new GastoRealDTO
                            {
                                TipoGasto = reader.GetString(0),
                                Descripcion = reader.GetString(1),
                                MontoReal = reader.GetDecimal(2),
                                Retorno = reader.IsDBNull(3) ? null : reader.GetDecimal(3)
                            });
                        }
                    }

                    // Comparación
                    if (await reader.NextResultAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            resultado.ComparacionGasto = new ComparacionGastoDTO
                            {
                                Reembolso = reader.IsDBNull(0) ? null : reader.GetDecimal(0),
                                ExcesoGasto = reader.IsDBNull(1) ? null : reader.GetDecimal(1),
                                JustificacionExceso = reader.IsDBNull(2) ? null : reader.GetString(2)
                            };
                        }
                    }

                    // Flujo aprobaciones
                    if (await reader.NextResultAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            resultado.ComparacionGasto?.Aprobaciones.Add(new AprobacionDTO
                            {
                                IdAutorizador = reader.GetInt32(0),
                                NivelAprobacion = reader.GetInt32(1),
                                Comentario = reader.GetString(2),
                                EstadoDecision = reader.GetString(3)
                            });
                        }
                    }
                    reader.Close();
                    // Obtener nombre completo del empleado
                    using var comandoNombre = new SqlCommand(@"
                     SELECT RTRIM(ISNULL(p.Primer_Nombre, '')) + ' ' +
                            RTRIM(ISNULL(p.Segundo_Nombre, '')) + ' ' +
                            RTRIM(ISNULL(p.Primer_Apellido, '')) + ' ' +
                            RTRIM(ISNULL(p.Segundo_Apellido, '')) AS NombreCompleto
                   FROM tbl_usuarios_login u
                  INNER JOIN tbl_personas p ON u.Id_Persona = p.Id_Persona
                    WHERE u.Id_Usuario = @IdUsuario", conexion);

                    comandoNombre.Parameters.AddWithValue("@IdUsuario", resultado.IdEmpleado);

                    using var readerNombre = await comandoNombre.ExecuteReaderAsync();
                    if (await readerNombre.ReadAsync())
                    {
                        resultado.NombreEmpleado = readerNombre.GetString(0);
                    }
                    readerNombre.Close();
                }
            }

            return resultado;
        }
        public static byte[] GenerarPdf(ReporteSolictudDTO dto, string logoPath)
        {
            using (var ms = new MemoryStream())
            {
                Document doc = new Document(PageSize.A4, 25, 25, 30, 30);
                PdfWriter writer = PdfWriter.GetInstance(doc, ms);
                writer.PageEvent = new Pie_de_pagina(); 

                doc.Open();

                // Fuentes
                var fontTitulo = FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 16);
                var fontSubtitulo = FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 12);
                var fontNormal = FontFactory.GetFont(FontFactory.HELVETICA, 10);

                //  Encabezado con logo y título
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

                var titulo = new Phrase($"Reporte Solicitud #{dto.IdSolicitudViaje}", fontTitulo);
                encabezado.AddCell(new PdfPCell(titulo) { Border = Rectangle.NO_BORDER, HorizontalAlignment = Element.ALIGN_LEFT });
                encabezado.AddCell(new PdfPCell(new Phrase("")) { Border = Rectangle.NO_BORDER });

                doc.Add(encabezado);

                // Línea divisoria
                var linea = new LineSeparator(1f, 100f, BaseColor.Gray, Element.ALIGN_CENTER, -2);
                doc.Add(new Chunk(linea));
                doc.Add(new Paragraph(" "));

                // Datos generales
                
                doc.Add(new Paragraph(" Datos Generales", fontSubtitulo));
                doc.Add(new Paragraph("\n"));
                PdfPTable tablaDatos = new PdfPTable(2);
                tablaDatos.WidthPercentage = 100;
                tablaDatos.AddCell("Empleado"); tablaDatos.AddCell(dto.NombreEmpleado.ToString());
                tablaDatos.AddCell("Departamento"); tablaDatos.AddCell(dto.Departamento);
                tablaDatos.AddCell("Motivo"); tablaDatos.AddCell(dto.Motivo);
                tablaDatos.AddCell("Destino"); tablaDatos.AddCell(dto.Destino);
                tablaDatos.AddCell("Fechas"); tablaDatos.AddCell($"{dto.FechaInicioViaje:dd/MM/yyyy} - {dto.FechaFinViaje:dd/MM/yyyy}");
                tablaDatos.AddCell("Presupuesto Estimado"); tablaDatos.AddCell(dto.PresupuestoEstimado.ToString("C"));
                doc.Add(tablaDatos);
                doc.Add(new Paragraph("\n"));

                // Gastos estimados
                
                doc.Add(new Paragraph(" Gastos Estimados", fontSubtitulo));
                doc.Add(new Paragraph("\n"));
                PdfPTable tableEstimados = new PdfPTable(3);
                tableEstimados.WidthPercentage = 100;
                tableEstimados.AddCell("Tipo"); tableEstimados.AddCell("Descripción"); tableEstimados.AddCell("Monto");
                foreach (var g in dto.GastosEstimados)
                {
                    tableEstimados.AddCell(g.TipoGasto);
                    tableEstimados.AddCell(g.Descripcion);
                    tableEstimados.AddCell(g.Monto.ToString("C"));
                }
                doc.Add(tableEstimados);
                doc.Add(new Paragraph("\n"));

                // Gastos reales
                
                doc.Add(new Paragraph(" Gastos Reales", fontSubtitulo));
                doc.Add(new Paragraph("\n"));
                PdfPTable tableReales = new PdfPTable(4);
                tableReales.WidthPercentage = 100;
                tableReales.AddCell("Tipo"); tableReales.AddCell("Descripción"); tableReales.AddCell("Monto Real"); tableReales.AddCell("Retorno");
                foreach (var g in dto.GastosReales)
                {
                    tableReales.AddCell(g.TipoGasto);
                    tableReales.AddCell(g.Descripcion);
                    tableReales.AddCell(g.MontoReal.ToString("C"));
                    tableReales.AddCell(g.Retorno.HasValue ? g.Retorno.Value.ToString("C") : "-");
                }
                doc.Add(tableReales);
                doc.Add(new Paragraph("\n"));

                //  Comparación
                if (dto.ComparacionGasto != null)
                {
                    
                    doc.Add(new Paragraph(" Comparación de Gastos", fontSubtitulo));
                    doc.Add(new Paragraph("\n"));
                    PdfPTable tablaComparacion = new PdfPTable(3);
                    tablaComparacion.WidthPercentage = 100;
                    tablaComparacion.AddCell("Reembolso");
                    tablaComparacion.AddCell("Exceso");
                    tablaComparacion.AddCell("Justificación");
                    tablaComparacion.AddCell(dto.ComparacionGasto.Reembolso?.ToString("C") ?? "-");
                    tablaComparacion.AddCell(dto.ComparacionGasto.ExcesoGasto?.ToString("C") ?? "-");
                    tablaComparacion.AddCell(dto.ComparacionGasto.JustificacionExceso ?? "-");
                    doc.Add(tablaComparacion);
                    doc.Add(new Paragraph("\n"));

                    //  Flujo de aprobaciones
                    
                    doc.Add(new Paragraph("Flujo de Aprobaciones", fontSubtitulo));
                    doc.Add(new Paragraph("\n"));
                    PdfPTable tableFlujo = new PdfPTable(4);
                    tableFlujo.WidthPercentage = 100;
                    tableFlujo.AddCell("Autorizador"); tableFlujo.AddCell("Nivel"); tableFlujo.AddCell("Estado"); tableFlujo.AddCell("Comentario");
                    foreach (var a in dto.ComparacionGasto.Aprobaciones)
                    {
                        tableFlujo.AddCell(a.IdAutorizador.ToString());
                        tableFlujo.AddCell(a.NivelAprobacion == 1 ? "Supervisor" : "Administrador");
                        tableFlujo.AddCell(a.EstadoDecision);
                        tableFlujo.AddCell(a.Comentario);
                    }
                    doc.Add(tableFlujo);
                }

                doc.Close();
                return ms.ToArray();
            }
        }

       

    }
}

