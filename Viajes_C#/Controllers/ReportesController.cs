using iTextSharp.text;
using iTextSharp.text.pdf;
using iTextSharp.text.pdf.draw;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Viajes.Logica;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;
using static Viajes.Logica.Usuario;
using static Viajes.Logica.Solicitud;

namespace Viajes.Controllers
{

    public class ReportesController : Controller
    {
        private readonly IWebHostEnvironment _env;
        private readonly Usuario _usuarioLogica = new Usuario();
        private readonly Solicitud _service = new Solicitud();
    

        public ReportesController(IWebHostEnvironment env, Solicitud service)
        {
            _env = env;
            
            
        }
        // Vista central de reportes
        [HttpGet]
        public IActionResult Index()
        {
            return View(); // Renderiza Index.cshtml en /Views/Reportes/
        }

        // Reporte de usuarios
        [HttpGet]
        public IActionResult Reportes()
        {
            ViewBag.AnoMin = ValidacionesFecha.ObtenerAnoMinimo();
            ViewBag.AnoMax = DateTime.Now.Year;

            return View(new List<UsuarioDetalleDTO>()); // Vista Reportes.cshtml
        }

        [HttpPost]
        public IActionResult Reportes(DateTime? fechaInicio, DateTime? fechaFin, int? estado)
        {
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

            var lista = _usuarioLogica.ObtenerDetalleUsuariosReporte(fechaInicio, fechaFin, estado);

            ViewBag.FechaInicio = fechaInicio?.ToString("yyyy-MM-dd");
            ViewBag.FechaFin = fechaFin?.ToString("yyyy-MM-dd");
            ViewBag.Estado = estado;
            ViewBag.AnoMin = ValidacionesFecha.ObtenerAnoMinimo();
            ViewBag.AnoMax = DateTime.Now.Year;

            return View(lista); // Vista Reportes.cshtml
        }

        [HttpPost]
        public IActionResult ExportarPDF(DateTime? fechaInicio, DateTime? fechaFin, int? estado)
        {
            var lista = _usuarioLogica.ObtenerDetalleUsuariosReporte(fechaInicio, fechaFin, estado);

            string logoPath = Path.Combine(_env.ContentRootPath, "Imagenes", "logo_usuario.png");
            var pdfBytes = GenerarPdfUsuarios(lista, logoPath);

            return File(pdfBytes, "application/pdf", "ReporteUsuarios.pdf");
        }
       

        // Listado con filtros
        public async Task<IActionResult> FiltroSolicitud(int? idEmpleado, int? idDepartamento, int? idEstado)
        {
            var solicitudes = await _service.FiltrarSolicitudesAsync(idEmpleado, idDepartamento, idEstado);
            return View("FiltroSolicitud", solicitudes); // Vista FiltroSolicitud.cshtml
        }

        // Reporte detallado
        public async Task<IActionResult> ReporteSolicitud(int id)
        {
            var dto = await _service.ObtenerReporteSolicitudAsync(id);
            if (dto == null) return NotFound();
            return View("ReporteSolicitud", dto); // Vista ReporteSolicitud.cshtml
        }

        // Exportar a PDF
        [HttpGet]
        public async Task<IActionResult> ExportarPDFSolicitud(int id)
        {
            var dto = await _service.ObtenerReporteSolicitudAsync(id);
            if (dto == null) return NotFound();

            string logoPath = Path.Combine(_env.ContentRootPath, "Imagenes", "logo_solicitudes.png");
            var pdfBytes = GenerarPdf(dto, logoPath);

            return File(pdfBytes, "application/pdf", $"Solicitud_{dto.IdSolicitudViaje}.pdf");
        }

    }

}



