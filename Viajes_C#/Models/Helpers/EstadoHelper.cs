namespace Viajes.Models.Helpers
{
    public static class EstadoHelper
    {
        public static int MapearEstado(string estado)
        {
            switch (estado.ToLower())
            {
                case "pendiente": return 3;
                case "aprobado": return 4;
                case "rechazado": return 5;
                case "cerrada": return 6;
                case "todos": return 0;
                default: return 0;
            }
        }
    }
}
