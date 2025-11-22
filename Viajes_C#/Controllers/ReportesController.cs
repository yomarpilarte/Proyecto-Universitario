using iTextSharp.text;
using iTextSharp.text.pdf;
using iTextSharp.text.pdf.draw;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using Viajes.Logica;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;
using static Viajes.Logica.Usuario;

namespace Viajes.Controllers
{

    public class ReportesController : Controller
    {


        private readonly IWebHostEnvironment _env;

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


        private readonly Usuario _usuarioLogica = new Usuario();

        [HttpPost]
        public IActionResult Reportes(DateTime? fechaInicio, DateTime? fechaFin, int? estado)
        {
             if (!ValidacionesFecha.NoEsFuturo(fechaInicio) ||
!ValidacionesFecha.NoEsFuturo(fechaFin))
  {
      ViewBag.Error = "No puede seleccionar fechas futuras.";
      return View(new List<UsuarioDetalleDTO>());
  }

  // Validar rango correcto
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
            
           
            return View(lista);
        }

        [HttpPost]
        public IActionResult ExportarPDF(DateTime? fechaInicio, DateTime? fechaFin, int? estado)
        {
            var lista = _usuarioLogica.ObtenerDetalleUsuariosReporte(fechaInicio, fechaFin, estado);

            string logoPath = Path.Combine(_env.ContentRootPath, "Imagenes", "logo_usuario.png");

            var pdfBytes = GenerarPdfUsuarios(lista, logoPath);

            return File(pdfBytes, "application/pdf", "ReporteUsuarios.pdf");
        }


    }
}



