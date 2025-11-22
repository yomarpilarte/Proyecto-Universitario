using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Data;
using Viajes.Models.Helpers;
using Microsoft.AspNetCore.Mvc.Rendering;
using Viajes.Logica;
using Viajes.Models.DTO;

namespace Viajes.Controllers
{
    public class GestionSolicitudesController : Controller
    {
     


        private readonly ILogger<GestionSolicitudesController> _logger;

        public GestionSolicitudesController(ILogger<GestionSolicitudesController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public IActionResult RevisionSolicitudes()
        {
            string nivel = HttpContext.Session.GetString("nivel") ?? "";

            // Solo supervisores pueden ver esto
            if (nivel != "Supervisor")
            {
                return RedirectToAction("Index", "Home");
            }

            var solicitudes = Solicitud.ListarPendientesGerente();

            // Agregamos info del empleado y departamento para mostrarla en la vista
            var solicitudesConInfo = new List<object>();
            foreach (var solicitud in solicitudes)
            {
                var infoEmpleado = ObtenerInfoEmpleado(solicitud.IdEmpleado);
                var infoDepartamento = ObtenerNombreDepartamento(solicitud.IdTipoDepartamento);

                solicitudesConInfo.Add(new
                {
                    IdSolicitudViaje = solicitud.IdSolicitudViaje,
                    IdEmpleado = solicitud.IdEmpleado,
                    NombreEmpleado = infoEmpleado.nombre,
                    Departamento = infoDepartamento,
                    Destino = solicitud.Destino,
                    Motivo = solicitud.Motivo,
                    FechaInicioViaje = solicitud.FechaInicioViaje.ToString("dd/MM/yyyy"),
                    FechaFinViaje = solicitud.FechaFinViaje.ToString("dd/MM/yyyy"),
                    PresupuestoEstimado = solicitud.PresupuestoEstimado,
                    FechaCreacion = solicitud.FechaCreacion.ToString("dd/MM/yyyy HH:mm")
                });
            }

            ViewBag.Solicitudes = solicitudesConInfo;
            return View();
        }

        [HttpPost]
        public IActionResult AprobarRechazarSolicitud([FromBody] DecisionAprobacionDTO dto)
        {
            int? idSupervisor = HttpContext.Session.GetInt32("IdUsuario");
            string nivel = HttpContext.Session.GetString("nivel") ?? "";

            if (nivel != "Supervisor")
            {
                return Json(new { success = false, message = "No tiene permisos para realizar esta acción." });
            }

            if (!idSupervisor.HasValue)
            {
                return Json(new { success = false, message = "Sesión no válida. Por favor, inicie sesión nuevamente." });
            }

            if (dto.IdSolicitudViaje <= 0)
            {
                return Json(new { success = false, message = "Debe seleccionar una solicitud válida." });
            }

            if (dto.IdEstadoDecision != 5 && dto.IdEstadoDecision != 6)
            {
                return Json(new { success = false, message = "La decisión debe ser Aprobar (5) o Rechazar (6)." });
            }

            // Si rechaza, tiene que poner un comentario explicando por qué
            if (dto.IdEstadoDecision == 6 && string.IsNullOrWhiteSpace(dto.Comentarios))
            {
                return Json(new { success = false, message = "Debe ingresar un comentario de justificación para el rechazo." });
            }

            dto.IdAutorizador = idSupervisor.Value;
            dto.NivelAprobacion = 1; // Supervisor/Gerente

            var resultado = FlujoAprobacion.RegistrarDecision(dto);

            if (resultado.resultado > 0)
            {
                return Json(new { success = true, message = resultado.mensaje });
            }
            else
            {
                return Json(new { success = false, message = resultado.mensaje });
            }
        }

        // Métodos auxiliares para obtener info
        private (string nombre, string correo) ObtenerInfoEmpleado(int idEmpleado)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand(@"
                    SELECT p.Primer_Nombre, p.Segundo_Nombre, p.Primer_Apellido, p.Segundo_Apellido, p.Correo
                    FROM tbl_usuarios_login u
                    INNER JOIN tbl_personas p ON u.Id_Persona = p.Id_Persona
                    WHERE u.Id_Usuario = @Id_Usuario
                ", conexion)
                {
                    CommandType = CommandType.Text
                };

                comando.Parameters.AddWithValue("@Id_Usuario", idEmpleado);
                conexion.Open();
                using var reader = comando.ExecuteReader();
                if (reader.Read())
                {
                    var nombre = $"{reader["Primer_Nombre"]} {reader["Segundo_Nombre"]} {reader["Primer_Apellido"]} {reader["Segundo_Apellido"]}".Trim();
                    var correo = reader["Correo"].ToString() ?? "";
                    return (nombre, correo);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al obtener información del empleado {IdEmpleado}", idEmpleado);
            }
            return ("Empleado", "");
        }

        private string ObtenerNombreDepartamento(int idDepartamento)
        {
            try
            {
                using var conexion = Conexion.ObtenerConexion();
                using var comando = new SqlCommand(
                    "SELECT Nombre_Tipo_Catalogo FROM tbl_tipos_catalogos WHERE Id_Tipo_Catalogo = @Id_Tipo_Catalogo",
                    conexion)
                {
                    CommandType = CommandType.Text
                };

                comando.Parameters.AddWithValue("@Id_Tipo_Catalogo", idDepartamento);
                conexion.Open();
                var resultado = comando.ExecuteScalar();
                return resultado?.ToString() ?? "N/A";
            }
            catch
            {
                return "N/A";
            }
        }

        [HttpGet]
        public IActionResult GenerarSolicitudes()
        {
            return View();
        }

        [HttpGet]
        public IActionResult AprobacionAdmin()
        {
            string nivel = HttpContext.Session.GetString("nivel") ?? "";

            // Solo admins pueden entrar aquí
            if (nivel != "Administrador")
            {
                return RedirectToAction("Index", "Home");
            }

            var solicitudes = Solicitud.ListarPendientesAdmin();

            // Preparamos los datos con info del empleado para mostrarlos
            var solicitudesConInfo = new List<object>();
            foreach (var solicitud in solicitudes)
            {
                var infoEmpleado = ObtenerInfoEmpleado(solicitud.IdEmpleado);
                var infoDepartamento = ObtenerNombreDepartamento(solicitud.IdTipoDepartamento);

                solicitudesConInfo.Add(new
                {
                    IdSolicitudViaje = solicitud.IdSolicitudViaje,
                    IdEmpleado = solicitud.IdEmpleado,
                    NombreEmpleado = infoEmpleado.nombre,
                    Departamento = infoDepartamento,
                    Destino = solicitud.Destino,
                    Motivo = solicitud.Motivo,
                    FechaInicioViaje = solicitud.FechaInicioViaje.ToString("dd/MM/yyyy"),
                    FechaFinViaje = solicitud.FechaFinViaje.ToString("dd/MM/yyyy"),
                    PresupuestoEstimado = solicitud.PresupuestoEstimado,
                    FechaCreacion = solicitud.FechaCreacion.ToString("dd/MM/yyyy HH:mm")
                });
            }

            ViewBag.Solicitudes = solicitudesConInfo;
            return View();
        }

        [HttpPost]
        public IActionResult AprobarRechazarSolicitudAdmin([FromBody] DecisionAprobacionDTO dto)
        {
            int? idAdmin = HttpContext.Session.GetInt32("IdUsuario");
            string nivel = HttpContext.Session.GetString("nivel") ?? "";

            if (nivel != "Administrador")
            {
                return Json(new { success = false, message = "No tiene permisos para realizar esta acción." });
            }

            if (!idAdmin.HasValue)
            {
                return Json(new { success = false, message = "Sesión no válida. Por favor, inicie sesión nuevamente." });
            }

            if (dto.IdSolicitudViaje <= 0)
            {
                return Json(new { success = false, message = "Debe seleccionar una solicitud válida." });
            }

            if (dto.IdEstadoDecision != 5 && dto.IdEstadoDecision != 6)
            {
                return Json(new { success = false, message = "La decisión debe ser Aprobar (5) o Rechazar (6)." });
            }

            // Si rechaza, tiene que explicar por qué
            if (dto.IdEstadoDecision == 6 && string.IsNullOrWhiteSpace(dto.Comentarios))
            {
                return Json(new { success = false, message = "Debe ingresar un comentario de justificación para el rechazo." });
            }

            dto.IdAutorizador = idAdmin.Value;
            dto.NivelAprobacion = 2; // Admin

            var resultado = FlujoAprobacion.RegistrarDecision(dto);

            if (resultado.resultado > 0)
            {
                return Json(new { success = true, message = resultado.mensaje });
            }
            else
            {
                return Json(new { success = false, message = resultado.mensaje });
            }
        }

        // Métodos para empleados

        [HttpGet]
        public IActionResult SolicitudesEmpleado()
        {
            int? idEmpleado = HttpContext.Session.GetInt32("IdUsuario");
            string nivel = HttpContext.Session.GetString("nivel") ?? "";

            if (nivel != "Empleado")
            {
                return RedirectToAction("Index", "Home");
            }

            if (!idEmpleado.HasValue)
            {
                return RedirectToAction("Login", "Login");
            }

            var solicitudes = Solicitud.ListarSolicitudesPorEmpleado(idEmpleado.Value);
            ViewBag.Solicitudes = solicitudes;

            return View();
        }

        [HttpPost]
        public IActionResult CrearSolicitud([FromBody] SolicitudCrearDTO dto)
        {
            if (dto == null)
            {
                return Json(new { success = false, message = "Los datos enviados no son válidos." });
            }

            int? idEmpleado = HttpContext.Session.GetInt32("IdUsuario");
            string nivel = HttpContext.Session.GetString("nivel") ?? "";

            if (nivel != "Empleado")
            {
                return Json(new { success = false, message = "No tiene permisos para realizar esta acción." });
            }

            if (!idEmpleado.HasValue)
            {
                return Json(new { success = false, message = "Sesión no válida. Por favor, inicie sesión nuevamente." });
            }

            // Buscamos el departamento del empleado automáticamente
            int idDepartamento = Solicitud.ObtenerDepartamentoEmpleado(idEmpleado.Value);

            if (idDepartamento <= 0)
            {
                return Json(new { success = false, message = "No se pudo obtener el departamento del empleado. Contacte al administrador." });
            }

            // Validamos que todo esté bien
            if (string.IsNullOrWhiteSpace(dto.Destino))
            {
                return Json(new { success = false, message = "El destino es requerido." });
            }

            if (string.IsNullOrWhiteSpace(dto.Motivo))
            {
                return Json(new { success = false, message = "El motivo es requerido." });
            }

            if (dto.PresupuestoEstimado <= 0)
            {
                return Json(new { success = false, message = "El presupuesto estimado debe ser mayor a 0." });
            }

            // Convertimos las fechas que vienen como string
            if (!DateOnly.TryParse(dto.FechaInicioViaje, out DateOnly fechaInicio))
            {
                return Json(new { success = false, message = "La fecha de inicio no es válida." });
            }

            if (!DateOnly.TryParse(dto.FechaFinViaje, out DateOnly fechaFin))
            {
                return Json(new { success = false, message = "La fecha de fin no es válida." });
            }

            if (fechaFin < fechaInicio)
            {
                return Json(new { success = false, message = "La fecha de fin debe ser posterior a la fecha de inicio." });
            }

            // Armamos el DTO completo para guardarlo
            var solicitudDTO = new SolicitudDTO
            {
                IdEmpleado = idEmpleado.Value,
                IdTipoDepartamento = idDepartamento,
                Destino = dto.Destino,
                Motivo = dto.Motivo,
                FechaInicioViaje = fechaInicio,
                FechaFinViaje = fechaFin,
                PresupuestoEstimado = dto.PresupuestoEstimado
            };

            var resultado = Solicitud.AgregarSolicitud(solicitudDTO);

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
        public IActionResult ObtenerSolicitudesEmpleado()
        {
            int? idEmpleado = HttpContext.Session.GetInt32("IdUsuario");
            string nivel = HttpContext.Session.GetString("nivel") ?? "";

            if (nivel != "Empleado" || !idEmpleado.HasValue)
            {
                return Json(new { success = false, data = new List<SolicitudDTO>() });
            }

            var solicitudes = Solicitud.ListarSolicitudesPorEmpleado(idEmpleado.Value);
            return Json(new { success = true, data = solicitudes });
        }

    }
}
