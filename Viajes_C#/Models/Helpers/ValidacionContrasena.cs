using System.Text.RegularExpressions;

namespace Viajes.Models.Helpers
{
    public static class ValidacionContrasena
    {

        public static bool EsContrasenaValida(string contrasena, string usuario, out string mensaje, ILogger? logger = null)
        {
            mensaje = "";

            if (string.IsNullOrWhiteSpace(contrasena) || string.IsNullOrWhiteSpace(usuario))
            {
                mensaje = "La contraseña o el usuario no pueden estar vacíos.";
                logger?.LogWarning("Validación fallida: campos vacíos.");
                return false;
            }

            string usuarioNormalizado = usuario.Split('@')[0].ToLowerInvariant().Replace(" ", "").Replace(".", "").Replace("-", "");
            string contrasenaNormalizada = contrasena.ToLowerInvariant();

            bool longitud = contrasena.Length >= 8 && contrasena.Length <= 20;
            bool minuscula = Regex.IsMatch(contrasena, "[a-z]");
            bool mayuscula = Regex.IsMatch(contrasena, "[A-Z]");
            bool numero = Regex.IsMatch(contrasena, "[0-9]");
            bool especial = Regex.IsMatch(contrasena, "[^a-zA-Z0-9]");
            bool distintoUsuario = !contrasenaNormalizada.Contains(usuarioNormalizado);

            logger?.LogInformation("Validación contraseña: Longitud={Longitud}, Minúscula={Minuscula}, Mayúscula={Mayuscula}, Número={Numero}, Especial={Especial}, DistintoUsuario={DistintoUsuario}",
                longitud, minuscula, mayuscula, numero, especial, distintoUsuario);

            if (!longitud) mensaje = "La contraseña debe tener entre 8 y 20 caracteres.";
            else if (!minuscula) mensaje = "Debe contener al menos una letra minúscula.";
            else if (!mayuscula) mensaje = "Debe contener al menos una letra MAYÚSCULA.";
            else if (!numero) mensaje = "Debe contener al menos un número.";
            else if (!especial) mensaje = "Debe contener al menos un carácter especial.";
            else if (!distintoUsuario) mensaje = "La contraseña no puede contener tu nombre de usuario.";

            return longitud && minuscula && mayuscula && numero && especial && distintoUsuario;
        }

    }
}
