using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
using Viajes.Logica;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;

namespace Viajes.Controllers
{
    public class GestionUsuariosController : Controller
    {

        private readonly ILogger<GestionUsuariosController> _logger;

        public GestionUsuariosController(ILogger<GestionUsuariosController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public IActionResult GestionUsuarios()
        {
            List<UsuarioDetalleDTO> usuarios;

            try
            {
                usuarios = Usuario.ListarUsuarios();

                if (usuarios == null)
                {
                    _logger.LogWarning("ListarUsuarios devolvió null. Se inicializa lista vacía.");
                    usuarios = new List<UsuarioDetalleDTO>();
                }

                if (!usuarios.Any())
                {
                    _logger.LogInformation("No hay usuarios registrados en el sistema.");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al obtener usuarios.");
                usuarios = new List<UsuarioDetalleDTO>();
            }

            return View(usuarios);
        }

        [HttpPost]
        public IActionResult Filtrar(UsuarioFiltroDTO filtro)
        {
            List<UsuarioDetalleDTO> usuarios;

            try
            {
                usuarios = Usuario.FiltrarUsuarios(filtro);
                _logger.LogInformation("Filtro aplicado. Total resultados: {Cantidad}", usuarios.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al filtrar usuarios.");
                usuarios = new List<UsuarioDetalleDTO>();
            }

            return View("GestionUsuarios", usuarios);
        }

       
        [HttpPost]
        public IActionResult Crear(UsuarioDTO dto)
        {
            var resultado = Usuario.InsertarUsuario(dto);

            if (resultado.resultado == 1)
            {
                TempData["Mensaje"] = resultado.mensaje;
                return RedirectToAction("GestionUsuarios");
            }

            // ? Error: mostrar mensaje en la misma vista
            ModelState.AddModelError(string.Empty, resultado.mensaje);
            ViewBag.EsEdicion = false;
            return View("FormularioUsuario", dto);
        }
        [HttpPost]
        public IActionResult Editar(UsuarioDTO dto)
        {
            dto.IdUsuarioModificador = HttpContext.Session.GetInt32("IdUsuario") ?? 0;

            if (dto.IdUsuario <= 0)
            {
                ModelState.AddModelError(string.Empty, "Usuario inválido para actualizar.");
                ViewBag.EsEdicion = true;
                return View("FormularioUsuario", dto);
            }

            var (resultado, mensaje) = Usuario.ActualizarDatosUsuario(dto);

            if (resultado == 1)
            {
                TempData["Mensaje"] = mensaje;
                return RedirectToAction("GestionUsuarios");
            }

            ModelState.AddModelError(string.Empty, mensaje);
            ViewBag.EsEdicion = true;
            return View("FormularioUsuario", dto);
        }


        public IActionResult ObtenerUsuario(int idUsuario)
        {
            var usuario = Usuario.ObtenerUsuarioPorId(idUsuario); // método DAL que devuelve UsuarioDTO
            if (usuario == null) return NotFound();

            ViewBag.EsEdicion = true; // indicamos que es edición
            return PartialView("FormularioUsuario", usuario);
        }

        [HttpPost]
        public IActionResult CambiarEstado(UsuarioEstadoDTO dto)
        {
            int idAuditor = HttpContext.Session.GetInt32("IdUsuario") ?? 0;
            string rol = HttpContext.Session.GetString("nivel") ?? "";
            int idUsuarioActual = idAuditor;
            dto.IdAuditor = idAuditor;

            // Validar que el usuario sea auditor
            if (!string.Equals(rol?.Trim(), "Auditor", StringComparison.OrdinalIgnoreCase))

                {
                    return Json(new { success = false, message = "Solo un auditor puede cambiar el estado de usuarios." });
            }

            // Evitar que un usuario cambie su propio estado
            if (dto.IdUsuario == idUsuarioActual)
            {
                return Json(new { success = false, message = "No puedes cambiar tu propio estado" });
            }

            // Ejecutar procedimiento almacenado
            var resultado = Usuario.CambiarEstadoUsuario(dto);

            if (resultado.resultado == 1)
            {
                // Si el usuario desactivado está logueado, cerrar sesión
                if (dto.NuevoEstado == "Inactivo" && HttpContext.Session.GetInt32("IdUsuario") == dto.IdUsuario)
                {
                    HttpContext.Session.Clear();
                    return Json(new { success = true, message = "El usuario fue desactivado y su sesión ha sido cerrada." });
                }

                return Json(new { success = true, message = resultado.mensaje });
            }
            else
            {
                return Json(new { success = false, message = resultado.mensaje });
            }
        }


        // Helpers institucionales
        private void CargarCombos()
        {
            ViewBag.Roles = ObtenerRoles();
            ViewBag.Departamentos = ObtenerDepartamentos();
        }

        private List<SelectListItem> ObtenerRoles()
        {
            var lista = new List<SelectListItem>();
            using var conexion = Conexion.ObtenerConexion();
            using var comando = new SqlCommand("SELECT Id_Rol, Nombre_Rol FROM tbl_roles WHERE Activo = 1", conexion);
            conexion.Open();
            using var reader = comando.ExecuteReader();
            while (reader.Read())
            {
                lista.Add(new SelectListItem
                {
                    Value = reader["Id_Rol"].ToString(),
                    Text = reader["Nombre_Rol"].ToString()
                });
            }
            return lista;
        }

        private List<SelectListItem> ObtenerDepartamentos()
        {
            var lista = new List<SelectListItem>();
            using var conexion = Conexion.ObtenerConexion();
            using var comando = new SqlCommand("SELECT Id_Tipo_Catalogo, Nombre_Tipo_Catalogo FROM tbl_tipos_catalogos WHERE Activo = 1", conexion);
            conexion.Open();
            using var reader = comando.ExecuteReader();
            while (reader.Read())
            {
                lista.Add(new SelectListItem
                {
                    Value = reader["Id_Tipo_Catalogo"].ToString(),
                    Text = reader["Nombre_Tipo_Catalogo"].ToString()
                });
            }
            return lista;
        }

    }



}



