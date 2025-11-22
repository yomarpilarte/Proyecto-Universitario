using Microsoft.AspNetCore.Mvc;

namespace Viajes.Controllers
{
    public class GastosController : Controller
    {
        [HttpGet]
        public IActionResult Gastos()
        {
            return View();
        }
    }


}