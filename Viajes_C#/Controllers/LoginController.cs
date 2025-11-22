using Microsoft.AspNetCore.Mvc;
using Viajes.Logica;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;

namespace Viajes.Controllers
{
    public class LoginController : Controller
    {
        

        private readonly ILogger<LoginController> _logger;

        public LoginController(ILogger<LoginController> logger)
        {
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Login()
        {
            if (TempData["MensajeLogin"] != null)
                ViewBag.Mensaje = TempData["MensajeLogin"];

            return View();
        }


        [HttpPost]
        public IActionResult Login(string usuario, string contrasena)
        {
            var resultado = LoginService.ValidarLogin(usuario, contrasena);

            if (resultado.Resultado == -1)
            {
                _logger.LogWarning("Intento fallido de login para usuario {Usuario}", usuario);
                ViewBag.Error = resultado.Mensaje;
                return View();
            }


            // 🔹 Guardar en sesión 

            HttpContext.Session.SetInt32("IdUsuario", resultado.UsuarioId);
            HttpContext.Session.SetString("Usuario", usuario);
            HttpContext.Session.SetString("nivel", resultado.Nombre_Rol); 


            // 🔹 Guardar también en TempData para el cambio de contraseña
            TempData["UsuarioId"] = resultado.UsuarioId;
            TempData["Usuario"] = usuario;

            if (resultado.RequiereCambio)
                return RedirectToAction("CambiarContrasena");

            return RedirectToAction("Index", "Home");
        }

        // ============================================================
        // GET - CAMBIAR CONTRASEÑA
        // ============================================================
        [HttpGet]
        public IActionResult CambiarContrasena()
        {
            TempData.Keep("UsuarioId");
            TempData.Keep("Usuario");

            if (TempData.Peek("Usuario") == null)
            {
                // Si no hay usuario, redirige a login
                return RedirectToAction("Login");
            }

            return View();
        }

        // ============================================================
        // POST - CAMBIAR CONTRASEÑA
        // ============================================================
        [HttpPost]
        public IActionResult CambiarContrasena(string nuevaContrasena)
        {
            // Recuperar datos sin consumir TempData
            int usuarioId = TempData.Peek("UsuarioId") is int id ? id : 0;
            string usuario = TempData.Peek("Usuario")?.ToString() ?? "";

            // Validación básica
            if (string.IsNullOrWhiteSpace(usuario) || string.IsNullOrWhiteSpace(nuevaContrasena))
            {
                ViewBag.Mensaje = "La contraseña o el usuario no pueden estar vacíos.";
                TempData.Keep("UsuarioId");
                TempData.Keep("Usuario");
                return View();
            }

            // Validar seguridad de la contraseña
            if (!ValidacionContrasena.EsContrasenaValida(nuevaContrasena, usuario, out string mensaje, _logger))
            {
                ViewBag.Mensaje = mensaje;
                TempData.Keep("UsuarioId");
                TempData.Keep("Usuario");
                return View();
            }

            // Actualizar contraseña vía servicio
            var resultado = LoginService.ActualizarPassword(usuarioId, usuario, nuevaContrasena);

            if (resultado.resultado == 1)
            {
                _logger.LogInformation("Contraseña actualizada para usuario {UsuarioId}", usuarioId);
                TempData["MensajeLogin"] = "Contraseña actualizada con éxito. Por favor, inicie sesión.";
                return RedirectToAction("Login");
            }

            // Si falla el SP
            ViewBag.Mensaje = resultado.mensaje;
            TempData.Keep("UsuarioId");
            TempData.Keep("Usuario");
            return View();
        }
    }
}
