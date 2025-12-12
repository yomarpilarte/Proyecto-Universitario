using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
using System.Data;
using Viajes.Logica;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;

namespace Viajes.Controllers
{
    public class GastosController : Controller
    {
        
        [HttpPost]
        public IActionResult AgregarGasto([FromBody] GastoDTO dto)
        {
            if (dto == null)
            {
                return Json(new { success = false, message = "Los datos enviados no son válidos." });
            }

            var resultado = Gasto.AgregarGasto(dto);

            if (resultado.resultado > 0)
            {
                return Json(new { success = true, message = resultado.mensaje, idGasto = resultado.resultado });
            }
            else
            {
                return Json(new { success = false, message = resultado.mensaje });
            }
        }

        [HttpPost]
        public IActionResult InsertarGastoReal([FromBody] GastoReal dto)
        {
            var resultado = Gasto.InsertarGastoReal(
                dto.IdSolicitudViaje,
                dto.IdTipoGasto,
                dto.DescripcionReal,
                dto.MontoReal,
                dto.Retorno // puede ser null
            );

            if (resultado.resultado > 0)
            {
                return Json(new { success = true, message = resultado.mensaje });
            }
            else
            {
                return Json(new { success = false, message = resultado.mensaje });
            }
        }


        [HttpGet]
        public IActionResult ObtenerTiposGasto()
        {
            var tipos = new List<SelectListItem>();

            using var conexion = Conexion.ObtenerConexion();
            using var comando = new SqlCommand(
                "SELECT Id_Tipo_Catalogo, Nombre_Tipo_Catalogo FROM tbl_tipos_catalogos WHERE Id_Catalogo = 1 AND Activo = 1 ORDER BY Nombre_Tipo_Catalogo",
                conexion
            )
            { CommandType = CommandType.Text };

            conexion.Open();
            using var reader = comando.ExecuteReader();
            while (reader.Read())
            {
                tipos.Add(new SelectListItem
                {
                    Value = reader["Id_Tipo_Catalogo"].ToString(),
                    Text = reader["Nombre_Tipo_Catalogo"].ToString()
                });
            }

            return Json(tipos);
        }

        [HttpGet]
        public IActionResult VerificarGastos(int idSolicitud)
        {
            bool tieneGastos = false;

            using var conexion = Conexion.ObtenerConexion();
            using var comando = new SqlCommand("SELECT COUNT(1) FROM tbl_gastos_viaje_reales WHERE Id_Solicitud_Viaje = @Id_Solicitud_Viaje", conexion);
            comando.Parameters.AddWithValue("@Id_Solicitud_Viaje", idSolicitud);
            conexion.Open();

            int count = (int)comando.ExecuteScalar();
            tieneGastos = count > 0;

            return Json(new { tieneGastos });
        }

         [HttpGet]
         public IActionResult ListarSupuestos(int idSolicitud)
         {
             try
             {
                 var resultado = Gasto.ListarSupuestos(idSolicitud);

                 if (resultado.resultado < 0)
                     return Json(new { success = false, message = resultado.mensaje });

                 var data = resultado.tabla.AsEnumerable().Select(row => new
                 {
                     Id_Gasto_Viaje = row.Field<int>("Id_Gasto_Viaje"),
                     Id_Solicitud_Viaje = row.Field<int>("Id_Solicitud_Viaje"),
                     Id_Tipo_Gasto = row.Field<int>("Id_Tipo_Gasto"),
                     TipoGasto = row.Field<string>("TipoGasto"),          
                     DescripcionSupuesto = row.Field<string>("DescripcionSupuesto"),
                     MontoSupuesto = row.Field<decimal>("MontoSupuesto")  
                 }).ToList();

                 return Json(new { success = true, data });
             }
             catch (Exception ex)
             {
                 return Json(new { success = false, message = "Error interno: " + ex.Message });
             }
         }


        [HttpGet]
        public IActionResult ListarReales(int idSolicitud)
        {
            try
            {
                var resultado = Gasto.ListarReales(idSolicitud);

                if (resultado.resultado < 0)
                    return Json(new { success = false, message = resultado.mensaje });

                var data = resultado.tabla.AsEnumerable().Select(row => new
                {
                    IdGastoSupuesto = row.Field<int>("IdGastoSupuesto"),
                    Id_Gasto_Viaje_real = row.Field<int>("Id_Gasto_Viaje_real"),
                    Id_Solicitud_Viaje = row.Field<int>("Id_Solicitud_Viaje"),
                    Id_Tipo_Gasto = row.Field<int>("Id_Tipo_Gasto"),
                    TipoGasto = row.Field<string>("TipoGasto"),
                    DescripcionReal = row.Field<string>("DescripcionReal"),
                    MontoReal = row.Field<decimal>("MontoReal"),
                    RutaComprobante = row.Table.Columns.Contains("RutaComprobante")
                                      ? row.Field<string>("RutaComprobante")
                                      : null,
                    Retorno = row.Table.Columns.Contains("Retorno")
                              ? row.Field<decimal?>("Retorno")
                              : null,
                    Fecha_Creacion = row.Field<DateTime>("Fecha_Creacion"),
                    Fecha_Modificacion = row.Field<DateTime?>("Fecha_Modificacion")
                }).ToList();

                return Json(new { success = true, data });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Error interno: " + ex.Message });
            }
        }



        [HttpGet]
        public IActionResult JustificarGastos(int idSolicitud)
        {
            ViewBag.IdSolicitud = idSolicitud;
            return View();
        }

        [HttpPost]
        public IActionResult SubirComprobante(IFormFile archivo)
        {
            if (archivo == null || archivo.Length == 0)
                return Json(new { success = false, message = "Archivo inválido" });

            // Validar tamaño máximo (10MB = 10 * 1024 * 1024 bytes)
            if (archivo.Length > 10 * 1024 * 1024)
                return Json(new { success = false, message = "El archivo excede el tamaño máximo de 10MB" });

            // Validar extensión
            var extensionesPermitidas = new[] { ".pdf", ".jpg", ".jpeg", ".png" };
            var extension = Path.GetExtension(archivo.FileName).ToLower();

            if (!extensionesPermitidas.Contains(extension))
                return Json(new { success = false, message = "Solo se permiten archivos PDF, JPG o PNG" });

            // Guardar archivo
            var folderPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "Comprobantes");
            if (!Directory.Exists(folderPath))
                Directory.CreateDirectory(folderPath);

            var fileName = Guid.NewGuid().ToString() + extension;
            var filePath = Path.Combine(folderPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                archivo.CopyTo(stream);
            }

            var relativePath = "/Comprobantes/" + fileName;
            return Json(new { success = true, path = relativePath });
        }

        [HttpPost]
        
        public IActionResult JustificarSolicitud([FromBody] JustificacionDto dto)
        {
            Console.WriteLine("Comparando solicitud: " + dto.IdSolicitud);

            var resultado = Gasto.CompararTotales(dto.IdSolicitud, dto.JustificacionExceso);

            if (resultado.resultado == -1)
            {
                return Json(new { success = false, message = resultado.mensaje, requiereJustificacion = true });
            }
            else if (resultado.resultado == 1)
            {
                Gasto.CambiarEstadoSolicitud(dto.IdSolicitud, 6);  // 6 = Cerrada

                return Json(new
                {
                    success = true,
                    message = resultado.mensaje,
                    redirect = Url.Action("SolicitudesEmpleado")
                });
            }
            else
            {
                return Json(new { success = false, message = resultado.mensaje });
            }
        }


        [HttpPost]
        public IActionResult GuardarRetorno(int idSolicitud, decimal monto)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand(@"
            INSERT INTO tbl_gastos_viaje_reales 
              (Id_Solicitud_Viaje, Monto_Gasto, Retorno, Fecha_Creacion) 
            VALUES (@Id, 0, @Monto, GETDATE())", conexion);

                comando.Parameters.AddWithValue("@Id", idSolicitud);
                comando.Parameters.AddWithValue("@Monto", monto);

                conexion.Open();
                comando.ExecuteNonQuery();

                return Json(new { success = true, message = "Retorno guardado correctamente" });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Error al guardar retorno: " + ex.Message });
            }
        }


    }

}


