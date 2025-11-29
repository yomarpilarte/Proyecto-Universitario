using iTextSharp.text;
using iTextSharp.text.pdf;
using Microsoft.AspNetCore.Mvc;
using Viajes.Logica;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;

namespace Viajes.Controllers
{
    public class ReportesController : Controller
    {
        private readonly IWebHostEnvironment _env;
        private readonly Usuario _usuarioLogica = new Usuario();

        public ReportesController(IWebHostEnvironment env)
        {
            _env = env;
        }

        [HttpGet]
        public IActionResult Reportes()
        {
            ViewBag.AnoMin = ValidacionesFecha.ObtenerAnoMinimo();
            ViewBag.AnoMax = DateTime.Now.Year;
            return View(new List<UsuarioDetalleDTO>());
        }

        [HttpPost]
        public IActionResult Reportes(DateTime? fechaInicio, DateTime? fechaFin, int? estado)
        {
            ViewBag.AnoMin = ValidacionesFecha.ObtenerAnoMinimo();

            // 1. Validaciones de Fecha (Lógica de Negocio)
            if (!ValidacionesFecha.NoEsFuturo(fechaInicio) || !ValidacionesFecha.NoEsFuturo(fechaFin))
            {
                ViewBag.Error = "No puede seleccionar fechas futuras.";
                return View(new List<UsuarioDetalleDTO>());
            }

            if (!ValidacionesFecha.RangoValido(fechaInicio, fechaFin))
            {
                ViewBag.Error = "La fecha de inicio no puede ser mayor que la fecha fin.";
                return View(new List<UsuarioDetalleDTO>());
            }

            // 2. Obtener datos
            var lista = _usuarioLogica.ObtenerDetalleUsuariosReporte(fechaInicio, fechaFin, estado);

            // 3. Mantener los filtros en la vista al recargar
            ViewBag.FechaInicio = fechaInicio?.ToString("yyyy-MM-dd");
            ViewBag.FechaFin = fechaFin?.ToString("yyyy-MM-dd");
            ViewBag.Estado = estado;

            return View(lista);
        }

        [HttpPost]
        public IActionResult ExportarPDF(DateTime? fechaInicio, DateTime? fechaFin, int? estado)
        {
            // 1. Consultamos los datos con los filtros
            var lista = _usuarioLogica.ObtenerDetalleUsuariosReporte(fechaInicio, fechaFin, estado);

            // 2. VALIDACIÓN: Si no hay registros, mostramos error y NO generamos PDF
            if (lista == null || lista.Count == 0)
            {
                ViewBag.Error = "No hay datos para exportar con los filtros seleccionados.";

                ViewBag.FechaInicio = fechaInicio?.ToString("yyyy-MM-dd");
                ViewBag.FechaFin = fechaFin?.ToString("yyyy-MM-dd");
                ViewBag.Estado = estado;
                ViewBag.AnoMin = ValidacionesFecha.ObtenerAnoMinimo(); 

                // Retornamos la vista (pantalla) en lugar del archivo
                return View("Reportes", new List<UsuarioDetalleDTO>());
            }

            // 3. Si hay datos, generamos el PDF normalmente
            string logoPath = Path.Combine(_env.ContentRootPath, "Imagenes", "logo_usuario.png");

            var pdfBytes = Usuario.GenerarPdfUsuarios(lista, logoPath);

            return File(pdfBytes, "application/pdf", "ReporteUsuarios.pdf");
        }
    }
}