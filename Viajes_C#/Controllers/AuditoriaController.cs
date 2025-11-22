
using Microsoft.AspNetCore.Mvc;
using Microsoft.CodeAnalysis.Elfie.Serialization;
using Newtonsoft.Json;
using Viajes.Logica;
using Viajes.Models.DTO;
using Viajes.Models.Helpers;


namespace Viajes.Controllers
{
    public class AuditoriaController : Controller
    {
        private readonly IWebHostEnvironment _env;

        public AuditoriaController(IWebHostEnvironment env)
        {
            _env = env;
        }


        [HttpGet]
        public IActionResult Auditoria()
        {
            ViewBag.AnoMin = ValidacionesFecha.ObtenerAnoMinimo();
            ViewBag.AnoMax = DateTime.Now.Year;
            ViewBag.Tablas = AuditoriaService.ObtenerTablasAuditoria();
            ViewBag.Operaciones = AuditoriaService.ObtenerOperacionesAuditoria();
            return View(new AuditoriaFiltroDto());
        }

        [HttpPost]
        public IActionResult Auditoria(AuditoriaFiltroDto filtro)
        {

            var auditoria = AuditoriaService.ConsultarAuditoriaFiltrada(filtro);

            if ((filtro.IdUsuarioAccion.HasValue || filtro.IdUsuarioAfectado.HasValue) && auditoria.Count == 0)
            {
                ViewBag.Error = "El ID ingresado no tiene registros en la auditoría.";
            }

            ViewBag.Resultados = auditoria;
            ViewBag.Tablas = AuditoriaService.ObtenerTablasAuditoria();
            ViewBag.Operaciones = AuditoriaService.ObtenerOperacionesAuditoria();

            return View(filtro);
        }
        [HttpPost]
        public IActionResult ExportarPDF(AuditoriaFiltroDto filtro)
        {
            string logoPath = Path.Combine(_env.ContentRootPath, "Imagenes", "logo_Reporte.png");
            // 1. Consultar registros con los filtros
            var registros = AuditoriaService.ConsultarAuditoriaFiltrada(filtro);

            // 2. Generar PDF
            var pdfBytes = AuditoriaService.GenerarPdfAuditoria(registros, logoPath);

            // 3. Devolver archivo descargable
            return File(pdfBytes, "application/pdf", "auditoria.pdf");
        }

       

    }
}
