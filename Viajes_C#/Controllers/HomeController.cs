using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using Viajes.Logica;
using Viajes.Models;

namespace Viajes.Controllers
{
    public class HomeController : Controller
    {
       
        private readonly ILogger<HomeController> _logger;

        public HomeController(ILogger<HomeController> logger)
        {
            _logger = logger;
        }

        public IActionResult Index()
        {
            // Si es empleado, vemos si tiene solicitudes aprobadas para mostrarle la notificación
            string nivel = HttpContext.Session.GetString("nivel") ?? "";
            int? idEmpleado = HttpContext.Session.GetInt32("IdUsuario");

            if (nivel == "Empleado" && idEmpleado.HasValue)
            {
                int cantidadAprobadas = Solicitud.ContarSolicitudesAprobadas(idEmpleado.Value);
                ViewBag.TieneSolicitudesAprobadas = cantidadAprobadas > 0;
                ViewBag.CantidadAprobadas = cantidadAprobadas;
            }
            else
            {
                ViewBag.TieneSolicitudesAprobadas = false;
                ViewBag.CantidadAprobadas = 0;
            }

            return View();
        }
        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }

        public IActionResult CerrarSesion()
        {
            HttpContext.Session.Clear();

            return RedirectToAction("Login","Login");
        }


    }
}
